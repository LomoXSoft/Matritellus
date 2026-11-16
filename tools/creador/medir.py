"""Lists the meshes of a model file (a .blend, or glTF/FBX files): name, collection, box (Blender's axes, z up) and
triangles. For choosing the hair, beards and clothes of the character creator.

    blender.exe -b --python tools/creador/medir.py -- FILE [FILE ...]
"""
import bpy, sys, os
from mathutils import Vector

files = sys.argv[sys.argv.index('--') + 1:]
for f in files:
    if f.lower().endswith('.blend'):
        bpy.ops.wm.open_mainfile(filepath=f)
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        for g in [f]:
            if g.lower().endswith(('.gltf', '.glb')):
                bpy.ops.import_scene.gltf(filepath=g)
            elif g.lower().endswith('.fbx'):
                bpy.ops.import_scene.fbx(filepath=g)
    print('FILE', os.path.basename(f))
    for o in sorted(bpy.context.scene.objects, key=lambda o: (o.users_collection[0].name if o.users_collection else '', o.name)):
        if o.type != 'MESH':
            continue
        pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
        lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        o.data.calc_loop_triangles()
        col = o.users_collection[0].name if o.users_collection else ''
        print('MESH %-28s %-22s lo %6.3f %6.3f %6.3f  hi %6.3f %6.3f %6.3f  %5d tris  hidden=%s mats=%s' % (
            o.name[:28], col[:22], lo.x, lo.y, lo.z, hi.x, hi.y, hi.z, len(o.data.loop_triangles), o.hide_get() or o.hide_render,
            ','.join(m.name for m in o.data.materials if m)[:40]))
