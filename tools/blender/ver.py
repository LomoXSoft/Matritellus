"""Looks at a model without opening Blender's window: imports a GLB and renders it from a few sides.

    blender.exe -b --python tools/blender/ver.py -- model.glb out_prefix [front|rear|side|top|quarter|back_quarter ...]

Each view is written to <out_prefix>_<view>.png. With `closeup=x,y,z,r` (fractions of the model's box, and a radius in
the same) after the views, the camera goes to that spot instead of framing the whole model.
"""
import bpy, sys, math
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:]
src, prefix = args[0], args[1]
views = [a for a in args[2:] if '=' not in a] or ['front', 'rear', 'side', 'quarter']
close = [a.split('=', 1)[1] for a in args[2:] if a.startswith('closeup=')]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
lo = Vector((1e9, 1e9, 1e9)); hi = Vector((-1e9, -1e9, -1e9))
for o in meshes:
    for c in o.bound_box:
        w = o.matrix_world @ Vector(c)
        lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
size = hi - lo
mid = (lo + hi) / 2
print('VER: box', [round(v, 3) for v in lo], [round(v, 3) for v in hi], 'objects', len(meshes))

scene = bpy.context.scene
scene.render.engine = 'BLENDER_WORKBENCH'
scene.display.shading.light = 'STUDIO'
scene.display.shading.color_type = 'TEXTURE'
scene.display.shading.show_cavity = True
scene.render.resolution_x = 900
scene.render.resolution_y = 600
scene.render.film_transparent = False
world = bpy.data.worlds.new('w'); scene.world = world
world.color = (0.55, 0.57, 0.6)
cam_data = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cam_data)
scene.collection.objects.link(cam); scene.camera = cam
cam_data.lens = 60
cam_data.clip_start = max(size) * 0.01; cam_data.clip_end = max(size) * 100

# in Blender the glTF's +z (forward) is -y, and up is +z
DIRS = {'front': Vector((0, -1, 0.12)), 'rear': Vector((0, 1, 0.12)), 'side': Vector((1, 0, 0.1)), 'top': Vector((0, -0.001, 1)),
        'quarter': Vector((0.8, -1, 0.45)), 'back_quarter': Vector((-0.8, 1, 0.45))}
def shoot(name, target, dist):
    d = DIRS[name].normalized()
    cam.location = target + d * dist
    cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = '%s_%s.png' % (prefix, name)
    bpy.ops.render.render(write_still=True)

if close:
    for i, spec in enumerate(close):
        fx, fy, fz, r = [float(v) for v in spec.split(',')]
        target = Vector((lo.x + size.x * fx, lo.y + size.y * fy, lo.z + size.z * fz))
        for v in views:
            scene.render.filepath = ''
            d = DIRS[v].normalized()
            cam.location = target + d * max(size) * r * 3.2
            cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
            scene.render.filepath = '%s_c%d_%s.png' % (prefix, i, v)
            bpy.ops.render.render(write_still=True)
else:
    for v in views:
        shoot(v, mid, max(size) * (1.25 if v in ("front", "rear") else 1.9))
print('VER OK')
