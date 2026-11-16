"""A side and a front picture of a model's head, with a ruler of heights: to find where a pack's eyes, mouth and chin
are (tools/creador/piezas.json).

    blender.exe -b --python tools/creador/ver_cabeza.py -- FILE OUT_PNG Z_LOW Z_HIGH [object ...]
"""
import bpy, sys, os
from mathutils import Vector

a = sys.argv[sys.argv.index('--') + 1:]
f, out, z0, z1 = a[0], a[1], float(a[2]), float(a[3])
show = set(a[4:])
if f.lower().endswith('.blend'):
    bpy.ops.wm.open_mainfile(filepath=f)
else:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if f.lower().endswith('.fbx'):
        bpy.ops.import_scene.fbx(filepath=f)
    else:
        bpy.ops.import_scene.gltf(filepath=f)
for o in bpy.context.scene.objects:
    if o.type == 'MESH':
        vis = (not show) or o.name in show
        o.hide_render = not vis
        o.hide_viewport = not vis
        for c in o.users_collection:
            c.hide_render = False
            c.hide_viewport = False
scene = bpy.context.scene
scene.render.engine = 'BLENDER_WORKBENCH'
scene.display.shading.light = 'STUDIO'
scene.display.shading.color_type = 'MATERIAL'
scene.render.resolution_x = 500
scene.render.resolution_y = 500
cam_data = bpy.data.cameras.new('cam')
cam_data.type = 'ORTHO'
cam_data.ortho_scale = (z1 - z0)
cam = bpy.data.objects.new('cam', cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
mid = (z0 + z1) / 2
for i in range(11):                                     # a ruler: a thin bar every tenth of the range
    z = z0 + (z1 - z0) * i / 10
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, z))
    b = bpy.context.active_object
    b.scale = ((z1 - z0) * 2, 0.001 * (z1 - z0), 0.002 * (z1 - z0))
    m = bpy.data.materials.new('r')
    m.diffuse_color = (1, 0, 0, 1) if i % 5 == 0 else (0, 0.6, 1, 1)
    b.data.materials.append(m)
for tag, loc, rot in (('frente', (0, -10, mid), (1.5708, 0, 0)), ('lado', (10, 0, mid), (1.5708, 0, 1.5708))):
    cam.location = loc
    cam.rotation_euler = rot
    scene.render.filepath = out.replace('.png', '_%s.png' % tag)
    bpy.ops.render.render(write_still=True)
