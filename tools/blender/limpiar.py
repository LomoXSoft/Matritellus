"""Cleans the bought-in car models (Sketchfab, CC-BY: godot/assets/vehiculos/sk/CREDITOS.txt) for the game.

    blender.exe -b --python tools/blender/limpiar.py -- <name> <in.glb> <out.glb>

What it does to each (see RECIPES):
  - takes off what belongs to a real make: badges, lettering, number plates with a number on them, official emblems
    (whole objects, pieces of an object, or the part of a texture they are painted on);
  - leaves out what is not the car (a ground plane);
  - cuts the four wheels out as objects of their own (wheel_fl, wheel_fr, wheel_bl, wheel_br: front/back, left = +x),
    each with its origin on its axle, and joins everything else into one object, `body`;
  - merges plain materials of the same colour, and lightens the heavy models;
  - gives the Tunero what a tuned car has (see tunero_kit).
In Blender a glTF's front (+z) is -y and up is +z; positions in recipes are fractions of the model's box:
x across (0..1), y from the front (0) to the back (1), z up from the ground (0..1).
"""
import bpy, bmesh, sys, math
import numpy as np
from mathutils import Vector, Matrix

args = sys.argv[sys.argv.index('--') + 1:]
NAME, SRC, DST = args[0], args[1], args[2]

RECIPES = {
    'panda': dict(drop_mats=['Ground'], drop_objs=['Object_44', 'Object_40']),
    'z15': dict(drop_parts=[('Object_14', (0.18, 0.31, 0.97, 1.01, 0.52, 0.57)), ('Object_14', (0.70, 0.82, 0.97, 1.01, 0.53, 0.575)), ('Object_22', (0.70, 0.82, 0.97, 1.01, 0.53, 0.575))] + [(n, (0.45, 0.55, 0.0, 0.05, 0.31, 0.385)) for n in ('Object_27', 'Object_16', 'Object_24')], lighten=0.45),
    'hebro': dict(),
    'yondir': dict(),
    'tunero': dict(drop_objs=['Plane006', 'Plane007']),
    'edison': dict(lighten=0.42),
    'julietta': dict(drop_objs=['Object_32', 'Object_34', 'Object_36', 'Object_62'], drop_parts=[('Object_74', (0.41, 0.59, 0.0, 0.06, 0.15, 0.48))], lighten=0.5),
    'grua': dict(),
    'tricornio': dict(drop_mats=['pEGATINAS'], drop_parts=[('Object_4', (0.46, 0.54, 0.04, 0.09, 0.36, 0.46))]),
}
R = RECIPES[NAME]
KEEP = ('Carpaint', 'M_0136', 'Charcoal', 'Part23Mtl', 'Part42Mtl', 'AluShiny', 'Window', 'Glass', 'glas', 'Part144')      # materials the game looks for by name

def log(*a):
    print('LIMPIAR', NAME + ':', *a)

# ---------------------------------------------------------------- in
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
scene = bpy.context.scene
def meshes():
    return [o for o in scene.objects if o.type == 'MESH']
for o in meshes():
    mw = o.matrix_world.copy()
    o.parent = None
    o.matrix_world = mw
for o in [o for o in scene.objects if o.type != 'MESH']:
    bpy.data.objects.remove(o, do_unlink=True)
for o in meshes():                                  # (each on its own: some share their mesh)
    if o.data.users > 1:
        o.data = o.data.copy()
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active = meshes()[0]
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

def mats_of(o):
    return [m.name for m in o.data.materials if m]

def named(o, prefix):
    return o.name == prefix or (o.name.startswith(prefix) and not o.name[len(prefix)].isdigit())

n0 = len(meshes())
for o in meshes():
    if any(any(m.startswith(d) for d in R.get('drop_mats', [])) for m in mats_of(o)) or any(named(o, d) for d in R.get('drop_objs', [])):
        log('left out', o.name, mats_of(o))
        bpy.data.objects.remove(o, do_unlink=True)

def model_box(objs=None):
    lo = Vector((1e9, 1e9, 1e9)); hi = Vector((-1e9, -1e9, -1e9))
    for o in (objs or meshes()):
        for v in o.data.vertices:
            lo = Vector(map(min, lo, v.co)); hi = Vector(map(max, hi, v.co))
    return lo, hi
LO, HI = model_box()
SIZE = HI - LO
def frac(p):
    return Vector(((p.x - LO.x) / SIZE.x, (p.y - LO.y) / SIZE.y, (p.z - LO.z) / SIZE.z))
log('box', [round(v, 3) for v in SIZE], 'objects', n0, '->', len(meshes()))

# ---------------------------------------------------------------- pieces of an object (by what touches what)
def pieces(o):
    """the object's faces grouped into connected pieces (vertices at the same place count as one): [face indices]"""
    me = o.data
    key = {}
    parent = list(range(len(me.vertices)))
    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a
    tol = max(SIZE) * 2e-4
    for v in me.vertices:
        k = (round(v.co.x / tol), round(v.co.y / tol), round(v.co.z / tol))
        if k in key:
            parent[find(v.index)] = find(key[k])
        else:
            key[k] = v.index
    for p in me.polygons:
        vs = list(p.vertices)
        for a in vs[1:]:
            ra, rb = find(vs[0]), find(a)
            if ra != rb:
                parent[ra] = rb
    groups = {}
    for p in me.polygons:
        groups.setdefault(find(p.vertices[0]), []).append(p.index)
    return list(groups.values())

def piece_box(o, faces):
    me = o.data
    idx = set()
    for f in faces:
        idx.update(me.polygons[f].vertices)
    cos = [me.vertices[i].co for i in idx]
    return Vector((min(c.x for c in cos), min(c.y for c in cos), min(c.z for c in cos))), Vector((max(c.x for c in cos), max(c.y for c in cos), max(c.z for c in cos)))

def delete_faces(o, faces):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[i] for i in faces], context='FACES')
    bm.to_mesh(o.data)
    bm.free()

for prefix, (x0, x1, y0, y1, z0, z1) in R.get('drop_parts', []):
    for o in meshes():
        if not named(o, prefix):
            continue
        gone = []
        for faces in pieces(o):
            a, b = piece_box(o, faces)
            fa, fb = frac(a), frac(b)
            if fa.x >= x0 and fb.x <= x1 and fa.y >= y0 and fb.y <= y1 and fa.z >= z0 and fb.z <= z1:
                gone += faces
        if gone:
            delete_faces(o, gone)
            log('took', len(gone), 'faces off', o.name)

# ---------------------------------------------------------------- textures
def base_image(mat):
    if mat is None or not mat.use_nodes:
        return None
    for n in mat.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            link = n.inputs['Base Color'].links
            if link and link[0].from_node.type == 'TEX_IMAGE':
                return link[0].from_node.image
    return None

def image_of(mat_prefix):
    for m in bpy.data.materials:
        if m.name.startswith(mat_prefix):
            img = base_image(m)
            if img is not None:
                return img
    return None

def pixels(img):
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    return px.reshape(h, w, 4)[::-1].copy()         # row 0 at the top, as the picture is looked at

def store(img, px):
    img.pixels.foreach_set(px[::-1].ravel())
    img.update()
    img.pack()

def heal(px, x0, y0, x1, y1, along='x'):
    """paints a rectangle over with what is either side of it (above and below for along='x', left and right for 'y')"""
    if along == 'x':
        top = px[y0 - 2, x0:x1, :3]; bottom = px[y1 + 2, x0:x1, :3]
        for y in range(y0, y1 + 1):
            t = (y - y0 + 1) / (y1 - y0 + 2)
            px[y, x0:x1, :3] = top * (1 - t) + bottom * t
    else:
        left = px[y0:y1, x0 - 2, :3]; right = px[y0:y1, x1 + 2, :3]
        for x in range(x0, x1 + 1):
            t = (x - x0 + 1) / (x1 - x0 + 2)
            px[y0:y1, x, :3] = left * (1 - t) + right * t

def paint_faces(o, img, box, pick, colour):
    """the pixels that the faces inside `box` (fractions) are painted with, where pick(pixels) says so, set to colour"""
    px = pixels(img)
    h, w = px.shape[:2]
    me = o.data
    uv = me.uv_layers.active.data
    done = 0
    x0, x1, y0, y1, z0, z1 = box
    for p in me.polygons:
        c = frac(p.center)
        if not (x0 <= c.x <= x1 and y0 <= c.y <= y1 and z0 <= c.z <= z1):
            continue
        pts = np.array([[uv[l].uv.x % 1.0 * w, (1.0 - uv[l].uv.y % 1.0) * h] for l in p.loop_indices])
        ax, ay = int(max(0, math.floor(pts[:, 0].min()))), int(max(0, math.floor(pts[:, 1].min())))
        bx, by = int(min(w - 1, math.ceil(pts[:, 0].max()))), int(min(h - 1, math.ceil(pts[:, 1].max())))
        if bx <= ax or by <= ay or (bx - ax) * (by - ay) > 40000:
            continue
        region = px[ay:by + 1, ax:bx + 1, :3]
        mask = pick(region)
        region[mask] = colour
        done += int(mask.sum())
    store(img, px)
    return done

if NAME == 'tunero':
    img = image_of('Material_265')                  # the photo of the back panel: the make and the model written on it
    px = pixels(img)
    s = img.size[0] / 256.0
    for x0, x1 in ((56, 88), (122, 141), (176, 208)):
        heal(px, int(x0 * s), int(33 * s), int(x1 * s), int(50 * s), 'x')
    store(img, px)
    img = image_of('Material_268')                  # the photo of a wheel: the make on its hub cap
    px = pixels(img)
    h, w = px.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    cap = (xx - 0.486 * w) ** 2 + (yy - 0.461 * h) ** 2 < (0.062 * w) ** 2
    px[cap, :3] = (0.62, 0.63, 0.65)
    px[(xx - 0.486 * w) ** 2 + (yy - 0.461 * h) ** 2 < (0.022 * w) ** 2, :3] = (0.3, 0.3, 0.32)
    store(img, px)
    log('painted over the lettering of the back panel and the hub caps')
if NAME == 'z15':
    img = image_of('M_53387984')                    # the number plate: a real number
    px = pixels(img)
    h, w = px.shape[:2]
    px[int(h * 0.08):int(h * 0.92), int(w * 0.105):int(w * 0.895), :3] = (0.93, 0.93, 0.92)
    store(img, px)
    log('blanked the number plate')
if NAME == 'hebro':
    img = image_of('Material.005')                  # the make and model along both sides of the bonnet
    px = pixels(img)
    s = img.size[0] / 1024.0
    heal(px, int(134 * s), int(206 * s), int(174 * s), int(350 * s), 'y')
    heal(px, int(480 * s), int(650 * s), int(612 * s), int(694 * s), 'x')
    store(img, px)
    log('painted over the lettering on the bonnet')
if NAME == 'edison':
    o = meshes()[0]
    img = image_of('material_0')
    off_white = lambda r: r.mean(axis=-1) < 0.84
    a = paint_faces(o, img, (0.455, 0.545, 0.0, 0.16, 0.42, 0.72), off_white, (0.94, 0.94, 0.94))
    b = paint_faces(o, img, (0.45, 0.55, 0.90, 1.0, 0.55, 0.70), off_white, (0.94, 0.94, 0.94))
    log('painted over the badge on the nose (%d px) and the one on the tail (%d px)' % (a, b))

if NAME == 'grua':
    for o in meshes():
        if not o.name.startswith('TowTruck'):
            continue
        img = base_image(o.data.materials[0])
        px = pixels(img)
        h, w = px.shape[:2]
        uv = o.data.uv_layers.active.data
        gone = []
        for p_ in o.data.polygons:
            top = max(frac(o.data.vertices[i].co).z for i in p_.vertices)
            if frac(p_.center).y > 0.46 and top > 0.455:
                c = sum((uv[l].uv for l in p_.loop_indices), Vector((0, 0))) / len(p_.loop_indices)
                r, g, b_ = px[min(h - 1, int((1.0 - c.y % 1.0) * h)), min(w - 1, int(c.x % 1.0 * w)), :3]
                if abs(r - 0.894) + abs(g - 0.706) + abs(b_ - 0.188) < 0.36:
                    gone.append(p_.index)
        delete_faces(o, gone)
        log('took the %d faces of the sides of its bed off' % len(gone))

# ---------------------------------------------------------------- wheels
def find_wheels():
    """[(object, faces, lo, hi)] for every connected piece; then which pieces are the four tyres and what turns with each"""
    parts = []
    for o in meshes():
        for faces in pieces(o):
            a, b = piece_box(o, faces)
            parts.append([o, faces, a, b])
    tyres = {}
    for arg in args:                                # debug=x0,x1,y0,y1,z0,z1 lists the pieces inside that box
        if arg.startswith('debug='):
            q = [float(v) for v in arg[6:].split(',')]
            for o, faces, a, b in sorted(parts, key=lambda p_: -len(p_[1])):
                fa, fb = frac(a), frac(b)
                if fa.x >= q[0] and fb.x <= q[1] and fa.y >= q[2] and fb.y <= q[3] and fa.z >= q[4] and fb.z <= q[5]:
                    print('PIEZA %-16s %5d faces x %.3f..%.3f y %.3f..%.3f z %.3f..%.3f %s' % (o.name[:16], len(faces), fa.x, fb.x, fa.y, fb.y, fa.z, fb.z, mats_of(o)[:2]))
    for i, (o, faces, a, b) in enumerate(parts):
        s = b - a
        if len(faces) < 10 or s.y <= 0 or s.z <= 0:
            continue
        if frac(a).z > 0.07 or abs(s.y - s.z) / max(s.y, s.z) > 0.24 or s.z < 0.17 * SIZE.z or s.z > 0.78 * SIZE.z or s.x > 0.42 * SIZE.x:
            continue
        mid = frac((a + b) / 2)
        if 0.3 < mid.x < 0.7:
            continue
        corner = ('f' if mid.y < 0.5 else 'b') + ('l' if mid.x > 0.5 else 'r')
        if corner not in tyres or s.z > (parts[tyres[corner]][3] - parts[tyres[corner]][2]).z:
            tyres[corner] = i
    wheels = {}
    drums = {}
    for corner, ti in tyres.items():
        a, b = parts[ti][2], parts[ti][3]
        drums[corner] = ((a + b) / 2, max(b.y - a.y, b.z - a.z) / 2, a.x, b.x)
    if len(drums) == 3:                             # the fourth: where its twin across the car is, mirrored
        missing = [k for k in ('fl', 'fr', 'bl', 'br') if k not in drums][0]
        twin = missing[0] + ('r' if missing[1] == 'l' else 'l')
        c, r, x0, x1 = drums[twin]
        mx = LO.x + HI.x
        drums[missing] = (Vector((mx - c.x, c.y, c.z)), r, mx - x1, mx - x0)
        log('the', missing, 'wheel is taken to be where its twin is, mirrored')
    for corner, (c, r, x0, x1) in drums.items():
        members = []
        for i, (o, faces, pa, pb) in enumerate(parts):
            if pa.x < x0 - 0.09 * SIZE.x or pb.x > x1 + 0.09 * SIZE.x:
                continue
            far = max(math.hypot(y - c.y, z - c.z) for y in (pa.y, pb.y) for z in (pa.z, pb.z))
            if far <= r * 1.03 or (corner in tyres and i == tyres[corner]):
                members.append(i)
        wheels[corner] = (c, r, members)
    return parts, wheels

def wheels_by_shape():
    """For a model that is all one piece: the wheels found by their shape. At each corner, where the bodywork touches the
    ground is the tyre; it is as tall as the first gap above it (the wheel arch). The faces inside that drum are the wheel."""
    o = meshes()[0]
    me = o.data
    co = np.array([v.co[:] for v in me.vertices])
    W, L, H = SIZE.x, SIZE.y, SIZE.z
    spots = {}
    radii = []
    z0 = 0.06 * H                                   # (lower than any sill: at that height there is only tyre)
    for corner in ('fl', 'fr', 'bl', 'br'):
        left = corner[1] == 'l'
        front = corner[0] == 'f'
        side = co[:, 0] > LO.x + 0.62 * W if left else co[:, 0] < LO.x + 0.38 * W
        half = co[:, 1] < LO.y + 0.5 * L if front else co[:, 1] > LO.y + 0.5 * L
        foot = co[side & half & (co[:, 2] < LO.z + 0.025 * H)]
        if len(foot) < 3:
            return None
        cy = (foot[:, 1].min() + foot[:, 1].max()) / 2
        x0, x1 = foot[:, 0].min(), foot[:, 0].max()
        band = co[side & half & (np.abs(co[:, 1] - cy) < 0.2 * L) & (np.abs(co[:, 2] - LO.z - z0) < 0.012 * H) & (co[:, 0] > x0 - 0.02 * W) & (co[:, 0] < x1 + 0.02 * W)]
        if len(band) < 2:
            return None
        chord = np.abs(band[:, 1] - cy).max()       # half the tyre's width along the car at that height: a chord of its circle
        radii.append((chord * chord + z0 * z0) / (2 * z0))
        spots[corner] = (cy, x0, x1)
    r = min(float(np.median(radii)), 0.245 * H)     # (no car's wheel is more than about half its height across)
    if r < 0.14 * H:
        return None
    found = {}
    for corner, (cy, x0, x1) in spots.items():
        c = Vector(((x0 + x1) / 2, cy, LO.z + r))
        faces = []
        for p in me.polygons:
            ok = True
            for vi in p.vertices:
                v = co[vi]
                if v[0] < x0 - 0.03 * W or v[0] > x1 + 0.03 * W or math.hypot(v[1] - cy, v[2] - c.z) > r * 1.05:
                    ok = False
                    break
            if ok:
                faces.append(p.index)
        found[corner] = (o, c, r, faces)
    return found

parts, wheels = find_wheels()
log('wheels found:', {k: (round(v[1] / SIZE.z, 2), len(v[2])) for k, v in wheels.items()})
made = {}
shaped = wheels_by_shape() if len(wheels) < 4 and len(meshes()) == 1 else None
if shaped:
    wheels = {k: (v[1], v[2], []) for k, v in shaped.items()}
    log('wheels by their shape:', {k: (round(v[2] / SIZE.z, 2), len(v[3])) for k, v in shaped.items()})
if len(wheels) == 4:
    by_obj = {}
    for corner, (c, r, members) in wheels.items():
        for i in members:
            by_obj.setdefault((parts[i][0].name, corner), []).extend(parts[i][1])
    if shaped:
        for corner, (o, c, r, faces) in shaped.items():
            by_obj[(o.name, corner)] = faces
    # every wheel's faces out of their objects, one corner at a time
    for (oname, corner), faces in sorted(by_obj.items()):
        o = bpy.data.objects[oname]
        if len(faces) == len(o.data.polygons):      # the whole object is that wheel
            made.setdefault(corner, []).append(o)
            continue
        new_me = o.data.copy()
        new = bpy.data.objects.new('tmp_' + corner, new_me)
        scene.collection.objects.link(new)
        keep = set(faces)
        delete_faces(new, [p.index for p in new_me.polygons if p.index not in keep])
        made.setdefault(corner, []).append((new, oname, faces))
    # (deleting from the originals after, so that the face numbers above still hold)
    gone = {}
    for corner, items in made.items():
        for it in items:
            if isinstance(it, tuple):
                gone.setdefault(it[1], []).extend(it[2])
    for oname, faces in gone.items():
        delete_faces(bpy.data.objects[oname], faces)
    for corner, items in made.items():
        objs = [it[0] if isinstance(it, tuple) else it for it in items]
        bpy.ops.object.select_all(action='DESELECT')
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        w = bpy.context.view_layer.objects.active
        w.name = 'wheel_' + corner
        c = wheels[corner][0]
        w.data.transform(Matrix.Translation(-c))
        w.location = c
        made[corner] = w
else:
    log('WARNING: could not tell the four wheels apart; they stay part of the body')
wheel_objs = [w for w in made.values() if not isinstance(w, list)]

# ---------------------------------------------------------------- one body
def colour_key(m):
    if m is None or not m.use_nodes or any(m.name.startswith(k) for k in KEEP):
        return None
    for n in m.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            if any(n.inputs[k].links for k in ('Base Color', 'Alpha', 'Metallic', 'Roughness', 'Normal', 'Emission Color', 'Emission') if k in n.inputs):
                return None
            c = n.inputs['Base Color'].default_value
            emis = n.inputs['Emission Strength'].default_value if 'Emission Strength' in n.inputs else 0.0
            glow = n.inputs['Emission Color'].default_value if 'Emission Color' in n.inputs else (0, 0, 0, 1)     # (lamps are told apart by what they give off)
            return (round(c[0], 2), round(c[1], 2), round(c[2], 2), round(n.inputs['Alpha'].default_value, 2), m.blend_method, round(emis, 1),
                    round(glow[0], 2), round(glow[1], 2), round(glow[2], 2), round(n.inputs['Metallic'].default_value, 1))
    return None
first = {}
merged = 0
for o in meshes():
    for slot in o.material_slots:
        k = colour_key(slot.material)
        if k is None:
            continue
        if k in first and first[k] != slot.material:
            slot.material = first[k]
            merged += 1
        else:
            first[k] = slot.material
rest = [o for o in meshes() if o not in wheel_objs and len(o.data.polygons) > 0]
for o in [o for o in meshes() if len(o.data.polygons) == 0]:
    bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action='DESELECT')
for o in rest:
    o.select_set(True)
bpy.context.view_layer.objects.active = rest[0]
if len(rest) > 1:
    bpy.ops.object.join()
body = bpy.context.view_layer.objects.active
body.name = 'body'
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
bpy.ops.object.material_slot_remove_unused()
log('body: %d faces, %d materials (%d slots merged)' % (len(body.data.polygons), len(body.material_slots), merged))

# ---------------------------------------------------------------- the Tunero's kit
def add_box(name, lo, hi, mat, bevel=0.0, tilt=0.0):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    size = Vector(hi) - Vector(lo)
    for v in bm.verts:
        v.co = Vector((v.co.x * size.x, v.co.y * size.y, v.co.z * size.z))
    if bevel > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=2, affect='EDGES')
    if tilt:
        bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(tilt, 3, 'X'))
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    o = bpy.data.objects.new(name, me)
    o.location = (Vector(lo) + Vector(hi)) / 2
    me.materials.append(mat)
    scene.collection.objects.link(o)
    return o

def plain(name, rgb, rough=0.6, metal=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (rgb[0], rgb[1], rgb[2], 1)
    b.inputs['Roughness'].default_value = rough
    b.inputs['Metallic'].default_value = metal
    return m

def tunero_kit():
    """Lower, on bigger wheels, with a splitter under the nose, skirts along the sills, a diffuser and two tail pipes
    under the back, and a spoiler that carries the roof on over the back window (not a wing stood on the boot)."""
    me = body.data
    W, L, H = SIZE.x, SIZE.y, SIZE.z
    cx = (LO.x + HI.x) / 2
    paint = next(m for m in bpy.data.materials if m.name.startswith('Carpaint'))
    black = plain('kit_black', (0.012, 0.012, 0.014), 0.55)
    chrome = plain('kit_chrome', (0.75, 0.75, 0.78), 0.2, 1.0)
    co = np.array([v.co[:] for v in me.vertices])
    # the roof and where it ends: the highest points along the middle of the car, from the front to the back
    mid = co[np.abs(co[:, 0] - cx) < 0.2 * W]
    roof_z = mid[:, 2].max()
    high = mid[mid[:, 2] > roof_z - 0.035 * H]
    roof_end = high[:, 1].max()
    at_end = co[(np.abs(co[:, 1] - roof_end) < 0.035 * L) & (co[:, 2] > roof_z - 0.09 * H)]
    roof_w = at_end[:, 0].max() - at_end[:, 0].min()
    end_z = mid[np.abs(mid[:, 1] - roof_end) < 0.02 * L][:, 2].max()
    # the lowest edge of the bodywork: under the nose, along the sills, under the tail
    nose = co[co[:, 1] < LO.y + 0.05 * L]
    tail = co[co[:, 1] > HI.y - 0.05 * L]
    fw, bw = made['fl'], made['bl']
    rf, rb = wheels['fl'][1], wheels['bl'][1]
    sill = co[(co[:, 1] > fw.location.y + rf * 1.2) & (co[:, 1] < bw.location.y - rb * 1.2)]
    sill_z = sill[:, 2].min()
    side_x = sill[sill[:, 2] < sill_z + 0.05 * H][:, 0]
    log('kit: roof ends %.2f along, %.2f of the width; sill at %.2f of the height' % ((roof_end - LO.y) / L, roof_w / W, (sill_z - LO.z) / H))
    kit = []
    # a scoop on the bonnet: a low black wedge lying on its slope
    glass_y = min(v.co.y for p_ in me.polygons if me.materials[p_.material_index].name.startswith('Glass') for v in [me.vertices[i] for i in p_.vertices])
    def bonnet_z(y):
        near = co[(np.abs(co[:, 0] - cx) < 0.1 * W) & (np.abs(co[:, 1] - y) < 0.03 * L)]
        return near[:, 2].max()
    sy = LO.y + (glass_y - LO.y) * 0.52
    slope = math.atan2(bonnet_z(sy + 0.04 * L) - bonnet_z(sy - 0.04 * L), 0.08 * L)
    kit.append(add_box('scoop', (cx - 0.1 * W, sy - 0.04 * L, bonnet_z(sy) - 0.004 * H), (cx + 0.1 * W, sy + 0.04 * L, bonnet_z(sy) + 0.022 * H), black, bevel=0.004 * H, tilt=slope))
    # the roof spoiler: a short lip that carries the roof on over the back window and kicks up at its tail, no wider than the roof
    top = co[(np.abs(co[:, 1] - roof_end) < 0.03 * L) & (co[:, 2] > end_z - 0.02 * H)]
    lip_w = (top[:, 0].max() - top[:, 0].min()) * 0.94
    kit.append(add_box('spoiler', (cx - lip_w * 0.5, roof_end - 0.012 * L, end_z - 0.004 * H), (cx + lip_w * 0.5, roof_end + 0.052 * L, end_z + 0.014 * H), paint, bevel=0.005 * H, tilt=math.radians(-9)))
    kit.append(add_box('spoiler_foot', (cx - lip_w * 0.47, roof_end - 0.004 * L, end_z - 0.034 * H), (cx + lip_w * 0.47, roof_end + 0.036 * L, end_z - 0.002 * H), black, tilt=math.radians(-20)))
    # the splitter: a black lip under the nose, hardly further forward than the bumper
    nz = nose[:, 2].min()
    nw = nose[:, 0].max() - nose[:, 0].min()
    kit.append(add_box('splitter', (cx - nw * 0.49, LO.y - 0.008 * L, nz - 0.004 * H), (cx + nw * 0.49, LO.y + 0.05 * L, nz + 0.01 * H), black, bevel=0.002 * H))
    # wider arches: a black flare over each wheel
    for corner in ('fl', 'fr', 'bl', 'br'):
        wc, wr = wheels[corner][0], wheels[corner][1]
        out = 1.0 if corner[1] == 'l' else -1.0
        x_side = (side_x.max() if out > 0 else side_x.min())
        fm = bpy.data.meshes.new('flare')
        fb = bmesh.new()
        ring = []
        n_seg = 10
        for k in range(n_seg + 1):
            ang = math.radians(12 + 156 * k / n_seg)
            row = []
            for rad in (wr * 1.13, wr * 1.3):
                for dx in (-0.012 * W, 0.022 * W):
                    row.append(fb.verts.new((x_side + out * dx, wc.y + math.cos(ang) * rad, wc.z + math.sin(ang) * rad)))
            ring.append(row)
        for k in range(n_seg):
            a0, b0 = ring[k], ring[k + 1]
            for i0, i1 in ((0, 1), (1, 3), (3, 2), (2, 0)):
                fb.faces.new((a0[i0], a0[i1], b0[i1], b0[i0]))
        fb.faces.new(ring[0]) if False else None
        bmesh.ops.recalc_face_normals(fb, faces=fb.faces)
        fb.to_mesh(fm)
        fb.free()
        fo = bpy.data.objects.new('flare', fm)
        fm.materials.append(black)
        scene.collection.objects.link(fo)
        kit.append(fo)
    # the skirts
    for s in (-1, 1):
        x = side_x.max() if s > 0 else side_x.min()
        kit.append(add_box('skirt', (x - 0.012 * W, fw.location.y + rf * 1.12, sill_z - 0.012 * H), (x + 0.014 * W, bw.location.y - rb * 1.12, sill_z + 0.03 * H), black, bevel=0.003 * H))
    # the diffuser, its fins, and two tail pipes
    tz = tail[:, 2].min()
    tw_ = tail[:, 0].max() - tail[:, 0].min()
    kit.append(add_box('diffuser', (cx - tw_ * 0.36, HI.y - 0.045 * L, tz - 0.006 * H), (cx + tw_ * 0.36, HI.y + 0.006 * L, tz + 0.03 * H), black, bevel=0.002 * H))
    for k in range(5):
        x = cx + (k - 2) * tw_ * 0.12
        kit.append(add_box('diffuser_fin', (x - 0.004 * W, HI.y - 0.04 * L, tz - 0.022 * H), (x + 0.004 * W, HI.y + 0.008 * L, tz + 0.002 * H), black))
    for k in range(2):
        pm = bpy.data.meshes.new('pipe')
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=0.021 * W, radius2=0.021 * W, depth=0.04 * L)
        bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 3, 'X'))
        bm.to_mesh(pm)
        bm.free()
        po = bpy.data.objects.new('pipe', pm)
        po.location = (cx + tw_ * (0.2 + k * 0.075), HI.y - 0.004 * L, tz + 0.018 * H)
        pm.materials.append(chrome)
        scene.collection.objects.link(po)
        kit.append(po)
    bpy.ops.object.select_all(action='DESELECT')
    for o in kit:
        o.select_set(True)
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    # lower, on bigger wheels
    drop = 0.03 * H
    body.data.transform(Matrix.Translation((0, 0, -drop)))
    body.data.update()
    for w in wheel_objs:
        r = wheels[w.name[-2:]][1]
        w.scale = (1.0, 1.07, 1.07)
        w.location.z += r * 0.07
    bpy.ops.object.select_all(action='DESELECT')
    for w in wheel_objs:
        w.select_set(True)
    bpy.context.view_layer.objects.active = wheel_objs[0]
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

if NAME == 'tunero' and len(wheel_objs) == 4:
    tunero_kit()

def yondir_mend_wheels():
    """The Sketchfab Yondir's tyre lugs (Part51Mtl) and rear rim rings (Part42Mtl) are loose sub-pieces that the generic
    radius cut left partly inside `body` (all 288 of bl, 120 of br, 36 of fr + 24 rim-ring faces). Move every remaining
    Part51Mtl/Part42Mtl face from `body` to its matching corner wheel and re-centre each wheel on its full tyre axle."""
    mid_x = sum(w.location.x for w in wheel_objs) / 4.0
    mid_y = sum(w.location.y for w in wheel_objs) / 4.0
    by_corner = {'fl': [], 'fr': [], 'bl': [], 'br': []}
    me = body.data
    for p in me.polygons:
        m = me.materials[p.material_index] if p.material_index < len(me.materials) else None
        if m is None or not (m.name.startswith('Part51Mtl') or m.name.startswith('Part42Mtl')):
            continue
        c = body.matrix_world @ p.center
        corner = ('f' if c.y < mid_y else 'b') + ('l' if c.x > mid_x else 'r')
        by_corner[corner].append(p.index)
    moved_all = []
    for corner, faces in by_corner.items():
        if not faces:
            continue
        moved_all.extend(faces)
        extra_me = me.copy()
        extra = bpy.data.objects.new('tmp_yondir_' + corner, extra_me)
        scene.collection.objects.link(extra)
        keep = set(faces)
        delete_faces(extra, [p.index for p in extra_me.polygons if p.index not in keep])
        w = made[corner]
        # Join in world space so coordinates stay exact, then re-centre on the full tyre bbox
        bpy.ops.object.select_all(action='DESELECT')
        w.select_set(True)
        extra.select_set(True)
        bpy.context.view_layer.objects.active = w
        bpy.ops.object.join()
    if moved_all:
        delete_faces(body, moved_all)
        bpy.ops.object.select_all(action='DESELECT')
        body.select_set(True)
        bpy.context.view_layer.objects.active = body
        bpy.ops.object.material_slot_remove_unused()
    for corner in ('fl', 'fr', 'bl', 'br'):
        w = made[corner]
        w.data.transform(Matrix.Translation(w.location))
        w.location = Vector((0, 0, 0))
        pts = [w.data.vertices[vi].co for p in w.data.polygons
               if p.material_index < len(w.data.materials) and w.data.materials[p.material_index]
               and w.data.materials[p.material_index].name.startswith('Part51Mtl')
               for vi in p.vertices]
        if pts:
            c = Vector(((min(v.x for v in pts) + max(v.x for v in pts)) / 2.0,
                        (min(v.y for v in pts) + max(v.y for v in pts)) / 2.0,
                        (min(v.z for v in pts) + max(v.z for v in pts)) / 2.0))
            w.data.transform(Matrix.Translation(-c))
            w.location = c
        w.data.update()
    log('yondir wheels mended: moved %d faces from body (%s)' % (len(moved_all), {k: len(v) for k, v in by_corner.items()}))

if NAME == 'yondir' and len(wheel_objs) == 4:
    yondir_mend_wheels()

# ---------------------------------------------------------------- lighter
def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)
before = sum(tris(o) for o in meshes())
if 'lighten' in R:
    for o, ratio in [(body, R['lighten'])] + [(w, min(1.0, R['lighten'] * 1.5)) for w in wheel_objs]:
        bm = bmesh.new()                            # weld first: these come as loose triangles, which cannot be simplified
        bm.from_mesh(o.data)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=max(SIZE) * 1e-4)
        bm.to_mesh(o.data)
        bm.free()
        m = o.modifiers.new('lighten', 'DECIMATE')
        m.ratio = ratio
        bpy.ops.object.select_all(action='DESELECT')
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier='lighten')
after = sum(tris(o) for o in meshes())

# ---------------------------------------------------------------- out
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_apply=True)
log('written: %d objects (%s), triangles %d -> %d' % (len(meshes()), ', '.join(sorted(o.name for o in meshes())), before, after))
