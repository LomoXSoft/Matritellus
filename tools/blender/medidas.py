"""Measures every glTF/GLB model in a folder and (with an output folder) renders a small picture of each.

    blender.exe -b --python tools/blender/medidas.py -- FOLDER [OUT_FOLDER] [name ...]

Prints one line per model: its box (Blender's axes: x across, y depth, z up, in the file's own units), where the box
sits (lowest and highest corner) and how many triangles it has. With names after the output folder, only those.
"""
import bpy, sys, os, math
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:]
folder = args[0]
out = args[1] if len(args) > 1 else ''
only = set(args[2:])
names = sorted(f for f in os.listdir(folder) if f.lower().endswith(('.gltf', '.glb')))
if only:
    names = [n for n in names if n.rsplit('.', 1)[0] in only]
if out:
    os.makedirs(out, exist_ok=True)

for name in names:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(folder, name))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    lo = Vector((1e9, 1e9, 1e9)); hi = Vector((-1e9, -1e9, -1e9))
    tris = 0
    for o in meshes:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
        o.data.calc_loop_triangles()
        tris += len(o.data.loop_triangles)
    size = hi - lo
    print('MED %-32s size %5.2f %5.2f %5.2f   lo %6.2f %6.2f %6.2f   hi %6.2f %6.2f %6.2f   %5d tris  %d objects  [%s]' % (
        name.rsplit('.', 1)[0], size.x, size.y, size.z, lo.x, lo.y, lo.z, hi.x, hi.y, hi.z, tris, len(meshes),
        ', '.join(sorted(o.name for o in meshes))[:90]))
    if not out:
        continue
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'TEXTURE'
    scene.display.shading.show_cavity = True
    scene.render.resolution_x = 360
    scene.render.resolution_y = 300
    world = bpy.data.worlds.new('w'); scene.world = world
    world.color = (0.62, 0.64, 0.66)
    cam_data = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cam_data)
    scene.collection.objects.link(cam); scene.camera = cam
    cam_data.lens = 55
    mid = (lo + hi) / 2
    r = max(size.length, 0.3)
    d = Vector((0.75, -1.0, 0.55)).normalized()
    cam.location = mid + d * r * 2.3
    look = mid - cam.location
    cam.rotation_euler = look.to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = os.path.join(out, name.rsplit('.', 1)[0] + '.png')
    bpy.ops.render.render(write_still=True)
