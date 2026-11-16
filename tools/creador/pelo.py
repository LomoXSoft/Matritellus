"""Fits hair, beards, eyebrows and hats made for a human head (free models: tools/creador/piezas.json says which) onto
the head of Matritellus's people: a ball of 0.5 m round (0, 1.38, 0) in the character's frame (chara.gd), its big eyes
at 1.42, the cheeks at 1.27. The user, 16 November 2026: "Tenemos que importar assets de peinados, barbas y cejas ...
tienen que tener nuestra estética y ser de libre uso. Usa blender si lo necesitas para ajustarlos."

    blender.exe -b --python tools/creador/pelo.py -- tools/creador/piezas.json OUT_GLB_FOLDER [PREVIEW_FOLDER] [name ...]

How a piece is moved (Blender's axes: z up, the face to -y):
  - "pelo" / "barba" / "sombrero": every point is put on the ball by angles. Its height on the human head gives its
    elevation (the crown at the top, the eyes a little above the middle as ours are, the mouth and the chin further
    down the front than a human's: our faces are round), its place round the head gives its bearing, and how far it
    stands off the human's skin (the pack's own body, the nearest point of it) is how far it stands off the ball, in
    proportion. What hangs below the chin (long hair, a plait, a beard's point) hangs straight down from where the
    ball ends, kept out of the body (a cone: chara.gd _r).
  - "cejas": laid on the front of the ball over our eyes, by width and height.
Each piece is subdivided once (some packs are very blocky: our people are round) and smoothed, and written as
OUT/<name>.glb in the character's own frame (y up, the face to +z), with one material. A hairstyle also gets a second
mesh "gorro": the same without what a cap or a hat would cover (chara.gd uses it under a hat).
With PREVIEW_FOLDER: a picture of each, on a plain head and body, from the front and from behind.
"""
import bpy, bmesh, sys, os, json, math
from mathutils import Vector
from mathutils.bvhtree import BVHTree

args = sys.argv[sys.argv.index('--') + 1:]
SPEC = json.load(open(args[0], encoding='utf-8'))
OUT = args[1]
PREV = args[2] if len(args) > 2 and ('/' in args[2] or chr(92) in args[2]) else ''       # (a folder: it has a slash in it; otherwise it is a name)
ONLY = set(a for a in args[3 if PREV else 2:])
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(args[0]))))
C = Vector((0.0, 0.0, 1.38))          # the ball's middle (Blender: z up)
R = 0.5
EPS = 0.008
HAT_LINE = 1.6                        # under a hat, nothing of the hair above this (the cap's rim is at 1.6)
FILL_OFF = 0.008                      # how far off the ball the cap under the hair lies
HAT_LINE_HIGH = 1.7                   # ...or this, under a hat that sits higher (a straw hat, a beret)


def smoothstep(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def body_r(z):                        # chara.gd _r: the body is a cone, 0.44 at the foot (0.245) to 0.3 at the neck (0.995)
    return 0.44 - (z - 0.245) * 0.18667


def load_pack(pack, extra=None):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    path = os.path.join(ROOT, pack['dir'])
    for f in pack.get('files', []) + ([extra] if extra else []):
        p = os.path.join(path, f)
        if p.lower().endswith('.blend'):
            bpy.ops.wm.open_mainfile(filepath=p)
        elif p.lower().endswith(('.gltf', '.glb')):
            bpy.ops.import_scene.gltf(filepath=p)
        elif p.lower().endswith('.fbx'):
            bpy.ops.import_scene.fbx(filepath=p)


def world_mesh(o):
    """the object's mesh in world space, with its modifiers, as a new bmesh"""
    o.hide_viewport = False
    o.hide_render = False
    try:
        o.hide_set(False)
    except Exception:
        pass
    for c in o.users_collection:
        c.hide_viewport = False
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    ev = o.evaluated_get(dg)
    me = ev.to_mesh()
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.transform(o.matrix_world)
    ev.to_mesh_clear()
    return bm


def skin_tree(pack):
    o = bpy.data.objects[pack['skin']]
    bm = world_mesh(o)
    return BVHTree.FromBMesh(bm)


def elev(z, p, kind):
    """the elevation (radians) on the ball for a height z on the human head: piecewise by its marks"""
    keys = [(p['crown'], 90.0), (p['eye'], p.get('el_eye_' + kind, p.get('el_eye', 10.0))), (p['mouth'], -14.0), (p['chin'], -44.0)]
    if z >= keys[0][0]:
        return math.radians(90.0)
    for (z0, a0), (z1, a1) in zip(keys, keys[1:]):
        if z1 <= z <= z0:
            t = (z0 - z) / (z0 - z1)
            if z0 == p['crown']:
                t = t ** p.get('crown_ease', 1.0)
            return math.radians(a0 + (a1 - a0) * t)
    return math.radians(-44.0)


def put_on_ball(v, tree, p, kind, k_t):
    """where a point of a piece made for the human head goes on ours"""
    u = v.x / p['half_w']
    w = (v.y - p['cy']) / p['half_d']
    bearing = math.atan2(u, -w)                   # 0 at the front, + to the character's left (x+)
    hit = tree.find_nearest(v)
    t = 0.0
    if hit[0] is not None:
        d = v - hit[0]
        t = d.length if d.dot(hit[1]) >= 0.0 else -d.length
    far = max(t, 0.0) / p['half_w']                  # how far off the skin, in heads
    t = max(t, 0.0) * k_t
    z = v.z
    below = max(0.0, p['chin'] - z) if kind != 'cejas' else 0.0
    el = elev(min(max(z, p['chin']), 99.0), p, kind)
    rr = R + p.get('eps', EPS) + t
    pos = C + Vector((math.cos(el) * math.sin(bearing), -math.cos(el) * math.cos(bearing), math.sin(el))) * rr
    # What stands well off the head (a ponytail, a bun, a plait) keeps its own shape: put on by angles it would be
    # stretched round the ball, our heads being rounder than a human's. So the further off, the more it is just the
    # piece made bigger, from the middle of the head.
    k_far = smoothstep(p.get('far0', 0.15), p.get('far1', 0.6), far)
    if k_far > 0.0 and kind in ('pelo', 'sombrero'):
        k_u = R / p['half_w'] * p.get('far_k', 0.95)
        zc = p['eye'] + (p['crown'] - p['eye']) * p.get('far_zc', 0.35)
        dz = v.z - zc
        if v.z < p['chin']:                          # (down the back: a human's hair is long for a head as big as ours)
            dz = (p['chin'] - zc) + (v.z - p['chin']) * p.get('far_drop', 0.4)
        same = C + Vector((v.x * k_u, (v.y - p['cy']) * k_u, dz * k_u))
        out = same - C
        if out.length < R + p.get('eps', EPS):
            same = C + out.normalized() * (R + p.get('eps', EPS))
        pos = pos.lerp(same, k_far)
        below = 0.0 if pos.z > 1.0 else below
    if below > 0.0:                                  # hanging below the chin: straight down from where the ball ends
        pos.z -= below * p.get('drop', 4.0)
        flat = Vector((pos.x, pos.y, 0.0))
        need = body_r(pos.z) + EPS + t if pos.z < 1.0 else 0.0
        if flat.length < need:
            flat = flat.normalized() * need if flat.length > 1e-6 else Vector((0.0, need, 0.0))
            pos.x, pos.y = flat.x, flat.y
    low = p.get('lowest', 0.55)                      # (nothing down past the hips: the hands hang at 0.68)
    if pos.z < low + 0.15:
        pos.z = low + 0.15 * math.exp((pos.z - low - 0.15) / 0.15)
    return pos


def base_colour(m):
    """a material's own colour (its Principled BSDF's, or its viewport colour)"""
    if m is None:
        return (0.5, 0.5, 0.5, 1.0)
    if m.use_nodes and m.node_tree:
        for n in m.node_tree.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                c = n.inputs['Base Color'].default_value
                return (c[0], c[1], c[2], 1.0)
    c = m.diffuse_color
    return (c[0], c[1], c[2], 1.0)


def put_on_body(v, tree, p, k_t):
    """clothes: from the human's chest and back onto our body, a cone (chara.gd _r), by bearing and height; what stands
    off the skin stands off the cone in proportion"""
    u = v.x / p['torso_half_w']
    w = (v.y - p['torso_cy']) / p['torso_half_d']
    bearing = math.atan2(u, -w)
    hit = tree.find_nearest(v)
    t = 0.0
    if hit[0] is not None:
        d = v - hit[0]
        t = max(0.0, d.length if d.dot(hit[1]) >= 0.0 else -d.length) * k_t
    top, bottom = p.get('body_top', 0.97), p.get('body_bottom', 0.27)
    h = (p['neck'] - v.z) / (p['neck'] - p['waist'])
    yz = top - h * (top - bottom)
    if v.z > p['neck']:                               # a collar or a hood, up the neck: into the head (it is round there)
        yz = top + (v.z - p['neck']) * p.get('up_k', 0.8)
    rr = (body_r(min(yz, 0.995)) if yz < 0.995 else 0.3) + p.get('eps', EPS) + t
    if yz < 0.25:
        yz = 0.25 - (0.25 - yz) * 0.3
    return Vector((math.sin(bearing) * rr, -math.cos(bearing) * rr, yz))


def layers(bm, off_skin):
    """Clothes of one colour (the user, 16 Nov 2026: "Algunas ropas necesitan más de un color plano para diferenciarse
    las distintas capas y partes que tienen"): what stands further off the skin than the rest -- a collar, a hood lying
    on the back, a pocket, the bands of a quilted vest, a lapel -- keeps the colour as chosen; what lies underneath goes
    darker, by degrees (a tone per point, multiplied into the colour with the shading of the folds: dirt)."""
    vals = sorted(off_skin.values())
    if len(vals) < 20:
        return {}
    lo = vals[int(len(vals) * 0.3)]
    hi = vals[int(len(vals) * 0.92)]
    if hi - lo < 1e-4:
        return {}
    tone = {v: 0.8 + 0.2 * min(1.0, max(0.0, (off_skin.get(v, lo) - lo) / (hi - lo))) for v in bm.verts}
    return smooth_values(tone, 3)


def smooth_values(val, passes):
    """each point's value evened out with its neighbours' (so that a shade comes in by degrees, not in blotches)"""
    for _ in range(passes):
        nxt = {}
        for v, x in val.items():
            near = [val[e.other_vert(v)] for e in v.link_edges if e.other_vert(v) in val]
            nxt[v] = (x + sum(near)) / (1 + len(near)) if near else x
        val = nxt
    return val


def fill_scalp(bm, p):
    """Under the hair, a cap of the hair's colour where it grows (the user: "hay algunos peinados que deja calvas"):
    the ball, a hair's breadth out, wherever hair lies close on the head, a little round it too"""
    from mathutils.kdtree import KDTree
    near = R + p.get('eps', EPS) + 0.07
    roots = [(v.co - C).normalized() for v in bm.verts if (v.co - C).length < near and v.co.z > 1.12]
    if not roots:
        return
    kd = KDTree(len(roots))
    for i, d in enumerate(roots):
        kd.insert(d, i)
    kd.balance()
    reach = 2.0 * math.sin(math.radians(p.get('fill_deg', 4.0)) / 2.0)
    cap = bmesh.new()
    bmesh.ops.create_uvsphere(cap, u_segments=96, v_segments=48, radius=R + FILL_OFF)
    # Where the hair grows close on the head, and the crown all round: but never down the forehead, where under a fringe
    # it showed as a band with a straight edge, "un gorro de piscina debajo del pelo" (the user, 16 Nov 2026). In front
    # it stops up at the hairline; down the sides and the back it goes as far as the hair does. (The bald specks seen
    # from a few metres were Godot's simplified meshes, not gaps: assets/creador/pelo/*.import, generate_lods=false.)
    def lowest(v):                                  # how far down it may come here (elevation, degrees), by the bearing round the head
        d = v.co.normalized()
        front = max(0.0, -d.y / max(1e-6, math.hypot(d.x, d.y)))          # 1 straight ahead, 0 at the sides and behind
        return p.get('fill_back', 8.0) + (p.get('fill_front', 38.0) - p.get('fill_back', 8.0)) * front ** 1.5
    def elev(v):
        return math.degrees(math.asin(max(-1.0, min(1.0, v.co.normalized().z))))
    def ok(v):
        e = elev(v)
        if e < lowest(v) or v.co.z < -0.3:
            return False
        return len(kd.find_range(v.co.normalized(), reach)) >= 3 or e >= lowest(v) + p.get('fill_top', 22.0)
    covered = {v: ok(v) for v in cap.verts}
    gone = [f for f in cap.faces if not all(covered[v] for v in f.verts)]      # (only inside where the hair is: its edge stays the hair's own)
    bmesh.ops.delete(cap, geom=gone, context='FACES')
    bmesh.ops.translate(cap, verts=cap.verts[:], vec=C)
    col = cap.loops.layers.color.new('Col')
    for f in cap.faces:
        f.smooth = True
        f.material_index = 0
        for lp in f.loops:
            lp[col] = (0.92, 0.92, 0.92, 1.0)       # (the hair's own colour, as shaded as the hair round it: it is not a cap of its own)
    me = bpy.data.meshes.new('cap')
    cap.to_mesh(me)
    bm.from_mesh(me)


def dirt(bm, tone=None):
    """Shade in the folds and where one layer meets another, as a vertex colour the game multiplies in (Blender's own
    "dirty vertex colours", done by hand): a point whose neighbours stand out in front of it is darker. `tone`: a
    further shade for each point (layers)"""
    tone = tone or {}
    for group in (bm.loops.layers.color, bm.loops.layers.float_color, bm.verts.layers.color, bm.verts.layers.float_color):
        for old in list(group.values()):              # (the pack's own colour layers: the game reads the first one only, and that is ours)
            group.remove(old)
    col = bm.loops.layers.color.new('Col')
    bm.normal_update()
    shade = {}
    for v in bm.verts:
        if not v.link_edges:
            shade[v] = 1.0
            continue
        s = 0.0
        for e in v.link_edges:
            o = e.other_vert(v)
            d = o.co - v.co
            if d.length > 1e-6:
                s += d.normalized().dot(v.normal)
        s /= len(v.link_edges)
        shade[v] = min(1.0, max(0.68, 1.0 - max(0.0, s) * 1.3))
    shade = smooth_values(shade, 2)
    for f in bm.faces:
        for lp in f.loops:
            k = shade[lp.vert] * tone.get(lp.vert, 1.0)
            lp[col] = (k, k, k, 1.0)


def put_hat(bm, p):
    """a hat with a brim (a fedora, a bowler, a flat cap): a stiff thing, made bigger all of a piece, its lowest edge at
    the height of our caps' rim, and pushed off the ball wherever it would go into it. Not as tall as it would come out:
    its crown down near the top of our heads (the user, 16 Nov 2026: "Otros sombreros están muy altos sobre la cabeza")"""
    zs = [v.co.z for v in bm.verts]
    k = R / p['half_w'] * p.get('hat_k', 1.05)
    low = min(zs)
    rim = p.get('rim', 1.58)
    kz = min(k, (p.get('hat_top', 2.02) - rim) / max(max(zs) - low, 1e-6))
    for v in bm.verts:
        c = v.co
        q = Vector((c.x * k, (c.y - p['cy']) * k, (c.z - low) * kz + rim))
        out = q - C
        if out.length < R + p.get('eps', EPS):
            q = C + out.normalized() * (R + p.get('eps', EPS))
        v.co = q


def put_shoe(bm, p):
    """a shoe made to the size of our feet (chara.gd _foot: a ball of 0.15 x 0.13 x 0.2 whose middle is 0.13 over the
    ground): its sole on the ground, as long as the foot and a little more, not so tall that it goes up into the body"""
    xs = [v.co.x for v in bm.verts]; ys = [v.co.y for v in bm.verts]; zs = [v.co.z for v in bm.verts]
    lo = Vector((min(xs), min(ys), min(zs))); hi = Vector((max(xs), max(ys), max(zs)))
    size = hi - lo
    k = p.get('shoe_long', 0.44) / max(size.y, 1e-6)
    kx = p.get('shoe_wide', 0.3) / max(size.x, 1e-6)
    kz = min(k, p.get('shoe_tall', 0.34) / max(size.z, 1e-6))
    mid = (lo + hi) / 2.0
    for v in bm.verts:
        c = v.co
        v.co = Vector(((c.x - mid.x) * kx, (c.y - mid.y) * k - 0.02, (c.z - lo.z) * kz - 0.13))


def put_brows(v, tree, p, k_t):
    """eyebrows: across the front of the ball over our eyes"""
    x = v.x * (0.25 / p['brow_half_w'])
    z = 1.535 + (v.z - p['brow_z0']) * p.get('brow_k', 2.0)
    hit = tree.find_nearest(v)
    t = 0.0
    if hit[0] is not None:
        d = v - hit[0]
        t = max(0.0, d.length if d.dot(hit[1]) >= 0.0 else -d.length) * k_t
    q = Vector((x, 0.0, z)) - C
    inside = max(0.0, (R + EPS + t) ** 2 - q.x * q.x - q.z * q.z)
    return C + Vector((q.x, -math.sqrt(inside), q.z))


def fit(piece, packs):
    p = dict(packs[piece['pack']])
    p.update({k: v for k, v in piece.items() if k not in ('name', 'pack', 'obj', 'file', 'kind')})     # (a piece may set its own marks)
    load_pack(p, piece.get('file'))
    tree = skin_tree(p)
    names = piece['obj'] if isinstance(piece['obj'], list) else [piece['obj']]
    kind = piece['kind']
    bm = bmesh.new()
    cols = []                                         # the source's materials: [name, colour]
    for n in names:
        o = bpy.data.objects[n]
        for slot in o.material_slots:
            cols.append([slot.material.name if slot.material else 'm', base_colour(slot.material)])
        src = world_mesh(o)
        me = bpy.data.meshes.new('tmp')
        src.to_mesh(me)
        bm.from_mesh(me)
    for f in bm.faces:
        f.smooth = True
    if p.get('shift'):                               # (a piece made for another of the pack's heads: moved onto the one measured)
        bmesh.ops.translate(bm, verts=bm.verts[:], vec=Vector(p['shift']))
    if kind == 'cuerpo' and p.get('cut_x'):          # (our people have no arms: the sleeves go)
        gone = [f for f in bm.faces if any(abs(v.co.x) > p['cut_x'] for v in f.verts)]
        bmesh.ops.delete(bm, geom=gone, context='FACES')
    if kind == 'pie':                                # one shoe of the pair
        gone = [f for f in bm.faces if sum(v.co.x for v in f.verts) / len(f.verts) > 0.0]
        bmesh.ops.delete(bm, geom=gone, context='FACES')
        loose = [v for v in bm.verts if not v.link_faces]
        bmesh.ops.delete(bm, geom=loose, context='VERTS')
    subd = piece.get('subd', p.get('subd', 0))
    if subd:
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=1, use_grid_fill=True, smooth=1.0)
    k_t = piece.get('thick', p.get('thick', 4.0))
    off_skin = {}                                     # how far off the pack's skin each point stood, in heads (clothes: torsos)
    for v in bm.verts:
        hit = tree.find_nearest(v.co)
        off_skin[v] = ((v.co - hit[0]).length if hit[0] is not None else 0.0) / p.get('torso_half_w' if kind == 'cuerpo' else 'half_w', 1.0)
    if kind == 'pie':
        put_shoe(bm, p)
    elif kind == 'rigido':
        put_hat(bm, p)
    else:
        for v in bm.verts:
            if kind == 'cejas':
                v.co = put_brows(v.co.copy(), tree, p, k_t)
            elif kind == 'cuerpo':
                v.co = put_on_body(v.co.copy(), tree, p, k_t)
            else:
                v.co = put_on_ball(v.co.copy(), tree, p, kind, k_t)
    bm.normal_update()
    # the material with most of the piece first: that one takes the colour chosen in the game (hair, shirt, hat, shoes)
    count = {}
    for f in bm.faces:
        count[f.material_index] = count.get(f.material_index, 0) + 1
    order = sorted(count, key=lambda i: -count[i])
    remap = {old: new for new, old in enumerate(order)}
    for f in bm.faces:
        f.material_index = remap[f.material_index]
    capa = False
    tone = layers(bm, off_skin) if kind == 'cuerpo' else {}
    if kind != 'cejas':
        dirt(bm, tone)
    if kind == 'pelo':                               # (after the shading: the cap under the hair is a shade of its own)
        fill_scalp(bm, p)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mesh2 = bpy.data.meshes.new(piece['name'])
    bm.to_mesh(mesh2)
    ob = bpy.data.objects.new('pieza', mesh2)
    bpy.context.scene.collection.objects.link(ob)
    print('COLORES', piece['name'], [(a.name, a.domain, a.data_type) for a in mesh2.color_attributes])
    if 'Col' in mesh2.color_attributes:
        for a in [a for a in mesh2.color_attributes if a.name != 'Col']:
            mesh2.color_attributes.remove(a)
        mesh2.color_attributes.active_color = mesh2.color_attributes['Col']
        mesh2.color_attributes.render_color_index = 0
    if kind in ('pelo', 'barba', 'cejas'):
        mesh2.materials.append(bpy.data.materials.new('pelo'))
    else:
        for old in order:
            name, col = cols[old] if old < len(cols) else ['m', (0.5, 0.5, 0.5, 1.0)]
            m = bpy.data.materials.new(name)
            m.use_nodes = True
            m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = col
            m.diffuse_color = col
            mesh2.materials.append(m)
        if capa:                                     # the layers that stand off the rest: the chosen colour, shaded (chara.gd)
            m = bpy.data.materials.new('capa')
            m.diffuse_color = (0.3, 0.3, 0.3, 1.0)
            mesh2.materials.append(m)
    for poly in mesh2.polygons:
        poly.use_smooth = True
    obs = [ob]
    if kind == 'pelo':                               # the same, under a hat: what is above its rim taken away (a cap's, or a higher one's)
        for cut_name, line in (('gorro', HAT_LINE), ('gorro_alto', HAT_LINE_HIGH)):
            bm2 = bmesh.new()
            bm2.from_mesh(mesh2)
            gone = [f for f in bm2.faces if sum(v.co.z for v in f.verts) / len(f.verts) > line]
            bmesh.ops.delete(bm2, geom=gone, context='FACES')
            mesh3 = bpy.data.meshes.new(piece['name'] + '_' + cut_name)
            bm2.to_mesh(mesh3)
            if len(mesh3.polygons) > 0:
                ob3 = bpy.data.objects.new(cut_name, mesh3)
                bpy.context.scene.collection.objects.link(ob3)
                for poly in mesh3.polygons:
                    poly.use_smooth = True
                obs.append(ob3)
    os.makedirs(OUT, exist_ok=True)
    for o in bpy.context.scene.objects:
        o.select_set(o in obs)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, piece['name'] + '.glb'), export_format='GLB', use_selection=True,
                              export_apply=True, export_materials='EXPORT', export_vertex_color='ACTIVE', export_all_vertex_colors=False,
                              export_active_vertex_color_when_no_material=True)       # (the shading of folds and layers: dirt)
    lo = Vector((min(v.co.x for v in mesh2.vertices), min(v.co.y for v in mesh2.vertices), min(v.co.z for v in mesh2.vertices)))
    hi = Vector((max(v.co.x for v in mesh2.vertices), max(v.co.y for v in mesh2.vertices), max(v.co.z for v in mesh2.vertices)))
    print('PIEZA %-22s %5d tris  x %.2f..%.2f  front %.2f..%.2f  up %.2f..%.2f' % (piece['name'], sum(len(pl.vertices) - 2 for pl in mesh2.polygons), lo.x, hi.x, -hi.y, -lo.y, lo.z, hi.z))
    if PREV:
        preview(ob, piece)


def preview(ob, piece):
    """a plain head and body of ours, the piece on it: front three-quarters and back three-quarters"""
    def add(mesh, loc, scale, col):
        o = bpy.data.objects.new('x', mesh)
        o.location = loc
        o.scale = scale
        m = bpy.data.materials.new('c')
        m.diffuse_color = col
        mesh.materials.append(m)
        bpy.context.scene.collection.objects.link(o)
        for poly in mesh.polygons:
            poly.use_smooth = True
        return o
    bpy.ops.mesh.primitive_uv_sphere_add(radius=R, location=C, segments=32, ring_count=16)
    head = bpy.context.active_object
    head.data.materials.append(bpy.data.materials.new('skin'))
    head.data.materials[0].diffuse_color = (0.96, 0.79, 0.63, 1)
    for poly in head.data.polygons:
        poly.use_smooth = True
    bpy.ops.mesh.primitive_cone_add(radius1=0.44, radius2=0.3, depth=0.75, location=(0, 0, 0.62), vertices=24)
    bpy.context.active_object.data.materials.append(bpy.data.materials.new('shirt'))
    bpy.context.active_object.data.materials[0].diffuse_color = (0.85, 0.3, 0.22, 1)
    for sx in (-1, 1):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=(sx * 0.17, -0.45, 1.42))
        e = bpy.context.active_object
        e.scale = (0.078, 0.045, 0.098)
        e.data.materials.append(bpy.data.materials.new('eye'))
        e.data.materials[0].diffuse_color = (1, 1, 1, 1)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=(sx * 0.17, -0.49, 1.415))
        i = bpy.context.active_object
        i.scale = (0.05, 0.03, 0.05)
        i.data.materials.append(bpy.data.materials.new('iris'))
        i.data.materials[0].diffuse_color = (0.1, 0.07, 0.05, 1)
    if piece['kind'] in ('pelo', 'barba', 'cejas'):
        ob.data.materials[0].diffuse_color = (0.35, 0.22, 0.13, 1)
    look_z, far = 1.25, 4.2
    if piece['kind'] == 'pie':                       # (a pair, on the feet; and the camera down by them)
        ob.location = (-0.17, 0.0, 0.13)
        other = bpy.data.objects.new('otro', ob.data)
        other.location = (0.17, 0.0, 0.13)
        other.scale = (-1.0, 1.0, 1.0)
        bpy.context.scene.collection.objects.link(other)
        look_z, far = 0.35, 2.2
    elif piece['kind'] == 'cuerpo':
        look_z, far = 0.9, 3.6
    for o in bpy.context.scene.objects:
        if o.name == 'gorro':
            o.hide_render = True
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'MATERIAL'
    scene.display.shading.show_cavity = True
    scene.render.resolution_x = 300
    scene.render.resolution_y = 300
    scene.render.film_transparent = False
    world = bpy.data.worlds.new('w')
    scene.world = world
    world.color = (0.9, 0.9, 0.9)
    cam_data = bpy.data.cameras.new('cam')
    cam = bpy.data.objects.new('cam', cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam_data.lens = 50
    os.makedirs(PREV, exist_ok=True)
    for tag, d in (('a', Vector((0.55, -1.0, 0.25))), ('b', Vector((-0.6, 1.0, 0.35)))):
        look = Vector((0, 0, look_z))
        cam.location = look + d.normalized() * far
        cam.rotation_euler = (look - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = os.path.join(PREV, '%s_%s.png' % (piece['name'], tag))
        bpy.ops.render.render(write_still=True)


packs = SPEC['packs']
for piece in SPEC['piezas']:
    if ONLY and piece['name'] not in ONLY:
        continue
    try:
        fit(piece, packs)
    except Exception as e:
        print('FALLO', piece['name'], repr(e))
