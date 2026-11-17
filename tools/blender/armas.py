"""The riot's weapons (motin.gd), from free models, into ONE GLB with three nodes: "bate", "cuchillo", "puno".

    blender.exe -b --python tools/blender/armas.py -- SRC_FOLDER OUT.glb

The user, 17 Nov 2026: in the roast ham riot the neighbours bring out weapons whose "diseños son muy pobres y no se
entiende lo que hacen": free models instead.
  bate      CreativeTrio's baseball bat (CC0, poly.pizza/m/i2JCd3w8gh), with nails of our own driven through the barrel
  cuchillo  Kenney's cleaver, "cooking-knife-chopping" from the Food Kit (CC0): it is the riot outside a kitchen
  puno      Qubzy's "SCI-FI Brass-Knuckles" (CC-BY 3.0, poly.pizza/m/Ay1ru6N012), in brass instead of blue

Each comes out held: the grip at the origin, pointing up (+Z here, +Y in Godot), the broad side facing forward
(Blender -Y, Godot +Z, where the close-up's camera is), and bigger than life, so that it reads from the street.
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector, Matrix

args = sys.argv[sys.argv.index('--') + 1:]
src, out = args[0], args[1]
bpy.ops.wm.read_factory_settings(use_empty=True)


def load(name: str):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(src, name))
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == 'MESH']
    for o in meshes:                                   # (off their parents, keeping where they are)
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
    for o in new:
        if o.type != 'MESH':
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return o


def verts(o):
    return [v.co.copy() for v in o.data.vertices]


def place(o, basis: Matrix):
    """basis: the model's own axes (columns) that are to become x, y, z here"""
    o.data.transform(basis.transposed().to_4x4())
    o.data.update()


def box(o):
    vs = verts(o)
    lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
    hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    return lo, hi


def spread_at(o, z0: float, z1: float) -> float:
    """how far the model reaches across, between two heights"""
    vs = [v for v in verts(o) if z0 <= v.z <= z1]
    return max((Vector((v.x, v.y)).length for v in vs), default=0.0)


def across(o, z0: float, z1: float) -> float:
    """how wide and deep the model is between two heights: by its faces that reach in there (a low model has corners
    only at the ends of each piece -- a blade's at its edge and its tip -- so its corners alone would say nothing)"""
    xs, ys = [], []
    for p in o.data.polygons:
        cs = [o.data.vertices[i].co for i in p.vertices]
        if min(c.z for c in cs) <= z1 and max(c.z for c in cs) >= z0:
            xs += [c.x for c in cs]
            ys += [c.y for c in cs]
    if not xs:
        return 0.0
    return (max(xs) - min(xs)) + (max(ys) - min(ys))


def to_size(o, length: float, grip: float):
    """long along z, the thin end down, scaled to `length`, with the grip (a share of the length from the thin end) at 0"""
    lo, hi = box(o)
    centre = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, 0))
    o.data.transform(Matrix.Translation(-centre))
    lo, hi = box(o)
    L = hi.z - lo.z
    # which end is the thick one (the barrel, the blade): how far across each end reaches. (Measured from the middle of
    # the box, the bat came out the wrong way up: the user, 17 Nov 2026, "he is holding the wide part and the slim part
    # had the nails"; and by halves, the cleaver did.)
    low, high = across(o, lo.z, lo.z + L * 0.12), across(o, hi.z - L * 0.12, hi.z)
    print('ARMA   %s: across %.3f at the lower end, %.3f at the upper' % (o.name, low, high))
    if low > high:                                       # the thick end is down: turn it over
        o.data.transform(Matrix.Rotation(math.pi, 4, 'X'))
        lo, hi = box(o)
    k = length / L
    o.data.transform(Matrix.Scale(k, 4))
    lo, hi = box(o)
    # the grip in the middle of the hand: the middle of the handle (its lowest stretch), not of the whole box -- a
    # cleaver's handle runs along the back of the blade, off to one side (the user, 17 Nov 2026: "el cuchillo lo están
    # sujetando al revés", its edge to their own head)
    hz = lo.z + length * grip
    xs, ys = [], []
    for p in o.data.polygons:
        cs = [o.data.vertices[i].co for i in p.vertices]
        if min(c.z for c in cs) <= hz + length * 0.05 and max(c.z for c in cs) >= hz - length * 0.05:
            xs += [c.x for c in cs if abs(c.z - hz) <= length * 0.12]
            ys += [c.y for c in cs if abs(c.z - hz) <= length * 0.12]
    hx = (min(xs) + max(xs)) / 2 if xs else 0.0
    hy = (min(ys) + max(ys)) / 2 if ys else 0.0
    o.data.transform(Matrix.Translation(Vector((-hx, -hy, -hz))))
    o.data.update()


def long_axis(o):
    lo, hi = box(o)
    d = hi - lo
    order = sorted(range(3), key=lambda i: d[i])       # thin, broad, long
    cols = [Vector([1.0 if j == i else 0.0 for j in range(3)]) for i in range(3)]
    return cols[order[0]], cols[order[1]], cols[order[2]]


def mat(name, rgb, metal=0.0, rough=0.6):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*rgb, 1.0)
    b.inputs['Metallic'].default_value = metal
    b.inputs['Roughness'].default_value = rough
    return m


# ---------------- the bat, with nails ----------------
bat = load('bate_d_creativetrio.glb')
thin, broad, lng = long_axis(bat)
place(bat, Matrix((broad, -thin, lng)).transposed())   # (round: which way across does not matter)
to_size(bat, 1.05, 0.1)
bat.data.transform(Matrix.Scale(1.5, 4, Vector((1, 0, 0))))
bat.data.transform(Matrix.Scale(1.5, 4, Vector((0, 1, 0))))     # (fatter: it has to read from the street)
bat.name = 'bate'
iron = mat('clavo', (0.42, 0.42, 0.44), 0.35, 0.55)        # (dull: a shiny one takes the sky's blue)
lo, hi = box(bat)
nails = []
for k, (h, turn) in enumerate([(0.62, 0.0), (0.7, 2.1), (0.78, 4.2), (0.86, 1.0), (0.93, 3.1), (0.74, 5.2), (0.98, 0.5)]):
    z = lo.z + (hi.z - lo.z) * h
    r = spread_at(bat, z - 0.03, z + 0.03)
    bm = bmesh.new()
    # a nail: the shank from inside the barrel out, a point at the end (pointing out, as when driven through)
    bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=0.014, radius2=0.014, depth=0.15)
    for v in bm.verts:
        v.co.z += 0.075
    tip = bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=0.014, radius2=0.0, depth=0.05)
    for v in tip['verts']:
        v.co.z += 0.175
    me = bpy.data.meshes.new('clavo%d' % k)
    bm.to_mesh(me)
    bm.free()
    n = bpy.data.objects.new('clavo%d' % k, me)
    bpy.context.collection.objects.link(n)
    me.materials.append(iron)
    tilt = math.radians(80)                             # (nearly straight out of the barrel, a little up or down)
    n.matrix_world = Matrix.Translation(Vector((0, 0, z))) @ Matrix.Rotation(turn, 4, 'Z') @ Matrix.Rotation(tilt + (k % 3 - 1) * 0.25, 4, 'Y') \
        @ Matrix.Translation(Vector((0, 0, r * 0.4)))
    nails.append(n)
bpy.ops.object.select_all(action='DESELECT')
for n in nails:
    n.select_set(True)
bat.select_set(True)
bpy.context.view_layer.objects.active = bat
bpy.ops.object.join()
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# ---------------- the cleaver ----------------
cleaver = load('kenney_cooking-knife-chopping.glb')
thin, broad, lng = long_axis(cleaver)
place(cleaver, Matrix((broad, -thin, lng)).transposed())   # broad side across (x), its face forward (-y)
to_size(cleaver, 0.62, 0.12)
cleaver.name = 'cuchillo'
lo, hi = box(cleaver)
print('ARMA   cuchillo: from the handle, %.2f to one side and %.2f to the other' % (lo.x, hi.x))
if abs(lo.x) > abs(hi.x):                               # (the blade out to the side away from the head, its edge facing out)
    cleaver.data.transform(Matrix.Scale(-1, 4, Vector((1, 0, 0))))
    cleaver.data.flip_normals()

# ---------------- the knuckle-duster ----------------
knuckles = load('puno_qubzy.glb')
thin, broad, lng = long_axis(knuckles)                 # thin: through the holes; long: across the fingers
place(knuckles, Matrix((lng, -thin, broad)).transposed())
lo, hi = box(knuckles)
c = (lo + hi) / 2
knuckles.data.transform(Matrix.Translation(-c))
k = 0.42 / (hi.x - lo.x)
knuckles.data.transform(Matrix.Scale(k, 4))
knuckles.data.transform(Matrix.Scale(2.5, 4, Vector((0, 1, 0))))     # (thicker through the holes: a thin plate of brass would not be seen)
knuckles.name = 'puno'
brass = mat('laton', (0.86, 0.64, 0.2), 0.9, 0.3)
knuckles.data.materials.clear()
knuckles.data.materials.append(brass)
for p in knuckles.data.polygons:
    p.material_index = 0

for o in (bat, cleaver, knuckles):
    o.location = (0, 0, 0)
    lo, hi = box(o)
    print('ARMA %-9s %5.2f x %5.2f x %5.2f  %d tris' % (o.name, hi.x - lo.x, hi.y - lo.y, hi.z - lo.z,
          sum(len(p.vertices) - 2 for p in o.data.polygons)))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', use_selection=True, export_yup=True, export_apply=True)
print('ARMAS ->', out)
