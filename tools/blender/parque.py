"""Readies the play equipment of the playground in the Plaza del Ayuntamiento.

Takes the chosen models of Tiny Treats' "Fun Playground" (Isa Lousberg, CC0; the download is in
tools/descargas/tinytreats_fun_playground/), joins each into one mesh, makes it its real size (the pack is drawn for
dolls of 2.4 units: a swing frame of 3.9 units is 2.2 m here), gives them all ONE material with the pack's small colour
atlas, and writes them into one GLB, each piece a node of its own standing at the origin. plaza.gd puts them in place.

    blender.exe -b --python tools/blender/parque.py -- SRC_FOLDER OUT.glb [texture_px]
"""
import bpy, sys, os
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index('--') + 1:]
SRC, DST = args[0], args[1]
PX = int(args[2]) if len(args) > 2 else 256

# name in the game: (file in the pack, how many metres one of its units is)
PIECES = [
    ('torre', 'slide_B', 0.56),             # the tower under a red roof, with its slide
    ('columpios', 'swing_A_large', 0.56),   # two swings on chains
    ('balancin', 'seesaw_large', 0.56),
    ('tiovivo', 'merry_go_round', 0.56),
    ('muelle_a', 'spring_horse_A', 0.46),   # the little horses on springs
    ('muelle_b', 'spring_horse_B', 0.46),
    ('arco', 'monkeybar_B', 0.56),          # the arch of rungs to climb over
    ('tobogan', 'slide_A', 0.56),           # the small slide
]

bpy.ops.wm.read_factory_settings(use_empty=True)
shared = None
made = []
for name, src, k in PIECES:
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, src + '.gltf'))
    new = [o for o in bpy.context.scene.objects if o not in before]
    meshes = [o for o in new if o.type == 'MESH']
    for o in meshes:                                   # (every part where it stands in the model, then no parents)
        mw = o.matrix_world.copy()
        o.parent = None
        o.data.transform(mw)
        o.matrix_world = Matrix.Identity(4)
    for o in new:
        if o.type != 'MESH':
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.name = name
    ob.data.name = name
    ob.data.transform(Matrix.Scale(k, 4))
    lo = Vector((min(v.co.x for v in ob.data.vertices), min(v.co.y for v in ob.data.vertices), min(v.co.z for v in ob.data.vertices)))
    hi = Vector((max(v.co.x for v in ob.data.vertices), max(v.co.y for v in ob.data.vertices), max(v.co.z for v in ob.data.vertices)))
    if lo.z < 0.0:                                     # (its feet on the floor)
        ob.data.transform(Matrix.Translation((0.0, 0.0, -lo.z)))
    mats = [m for m in ob.data.materials if m]
    if shared is None:
        shared = mats[0]
        shared.name = 'parque'
    for i in range(len(ob.data.materials)):
        ob.data.materials[i] = shared
    ob.data.calc_loop_triangles()
    print('PARQUE %-10s from %-16s x%.2f  across %.2f  deep %.2f (front %.2f, back %.2f)  tall %.2f  %d tris' % (
        name, src, k, hi.x - lo.x, hi.y - lo.y, -lo.y, hi.y, hi.z - lo.z, len(ob.data.loop_triangles)))
    made.append(ob)

for m in list(bpy.data.materials):                     # (the copies each import brought)
    if m != shared and m.users == 0:
        bpy.data.materials.remove(m)
bsdf = next(n for n in shared.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
bsdf.inputs['Roughness'].default_value = 0.72           # (painted wood and plastic: no glints)
img = next(n.image for n in shared.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image)
for other in list(bpy.data.images):
    if other != img and other.users == 0:
        bpy.data.images.remove(other)
w, h = img.size
if w > PX:
    img.scale(PX, PX)
print('PARQUE atlas %s %dx%d -> %dx%d, %d materials, %d images' % (img.name, w, h, img.size[0], img.size[1], len(bpy.data.materials), len(bpy.data.images)))
os.makedirs(os.path.dirname(DST), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', use_selection=False, export_image_format='AUTO',
                          export_apply=True, export_yup=True, export_animations=False, export_extras=False)
print('PARQUE wrote', DST, os.path.getsize(DST), 'bytes')
