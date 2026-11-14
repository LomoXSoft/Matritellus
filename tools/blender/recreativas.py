"""Readies the bought-in arcade machines (Sketchfab, CC-BY: godot/assets/recreativas/CREDITOS.txt) for the game.

    blender.exe -b --python tools/blender/recreativas.py -- <in.glb> <out.glb> [--px=512] [--turn=degrees] [--height=metres] [object or material to leave out ...]

It puts the model's transforms into its meshes, leaves out what is not the machine (a floor, a backdrop: named after
the size), joins it all into one object with its materials, turns it about the upright so that its front (the screen)
faces glTF +z (--turn, from looking at it: tools/blender's renders), makes it --height metres high standing on y = 0
with its middle on the upright axis, shrinks every texture to the size given (the installer
grows with every megabyte), and writes a GLB with the textures in JPEG (PNG where they have transparency). It prints
the box of the result and, for every material, where its faces are in that box (fractions: x across, y from the front
(0) to the back (1), z up), which is how the screen, the marquee and the panel are found for recress_sala.gd.
In Blender a glTF's front (+z) is -y and up is +z.
"""
import bpy, sys
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:]
SRC, DST = args[0], args[1]
OPT = {a[2:].split('=')[0]: a.split('=', 1)[1] for a in args[2:] if a.startswith('--')}
MAX_PX = int(OPT.get('px', 512))
TURN = float(OPT.get('turn', 0.0))
HEIGHT = float(OPT.get('height', 0.0))
DROP = [a for a in args[2:] if not a.startswith('--')]

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
for o in meshes():
    if o.data.users > 1:
        o.data = o.data.copy()
for o in list(meshes()):
    if o.name in DROP or any(m and m.name in DROP for m in o.data.materials):
        print('RECRE drop', o.name)
        bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active = meshes()[0]
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
if len(meshes()) > 1:
    bpy.ops.object.join()
body = meshes()[0]
body.name = 'maquina'
import math
from mathutils import Matrix
me = body.data
if TURN:
    me.transform(Matrix.Rotation(math.radians(TURN), 4, 'Z'))
pts = [v.co for v in me.vertices]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
k = HEIGHT / (hi.z - lo.z) if HEIGHT > 0 else 1.0
me.transform(Matrix.Scale(k, 4) @ Matrix.Translation(Vector((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z))))
me.update()

# the box, and where each material's faces are in it
me = body.data
pts = [v.co for v in me.vertices]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
size = hi - lo
print('RECRE box (x across, y front-back, z up): %.3f %.3f %.3f  faces %d' % (size.x, size.y, size.z, len(me.polygons)))
acc = {}
for p in me.polygons:
    m = me.materials[p.material_index].name if me.materials and me.materials[p.material_index] else '-'
    a = acc.setdefault(m, [0.0, Vector((0, 0, 0)), Vector((9, 9, 9)), Vector((-9, -9, -9)), Vector((0, 0, 0))])
    a[0] += p.area
    a[1] += p.center * p.area
    a[4] += p.normal * p.area
    for vi in p.vertices:
        c = me.vertices[vi].co
        a[2] = Vector((min(a[2].x, c.x), min(a[2].y, c.y), min(a[2].z, c.z)))
        a[3] = Vector((max(a[3].x, c.x), max(a[3].y, c.y), max(a[3].z, c.z)))
f = lambda v, i: (v[i] - lo[i]) / size[i] if size[i] else 0.0
for m, a in sorted(acc.items(), key=lambda kv: -kv[1][0]):
    c = a[1] / max(a[0], 1e-9)
    n = a[4].normalized() if a[4].length > 0 else a[4]
    print('RECRE mat %-28s area %6.3f  x %.2f..%.2f  y %.2f..%.2f  z %.2f..%.2f  middle %.2f %.2f %.2f  facing %+.2f %+.2f %+.2f' % (
        m[:28], a[0], f(a[2], 0), f(a[3], 0), f(a[2], 1), f(a[3], 1), f(a[2], 2), f(a[3], 2), f(c, 0), f(c, 1), f(c, 2), n.x, n.y, n.z))

# the textures, smaller
for img in bpy.data.images:
    if img.size[0] == 0:
        continue
    w, h = img.size
    k = min(1.0, MAX_PX / max(w, h))
    if k < 1.0:
        img.scale(max(4, int(w * k)), max(4, int(h * k)))
    print('RECRE image %-30s %dx%d -> %dx%d' % (img.name[:30], w, h, img.size[0], img.size[1]))

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', use_selection=False, export_image_format='AUTO', export_jpeg_quality=85,
                          export_apply=True, export_yup=True)
print('RECRE written', DST)
