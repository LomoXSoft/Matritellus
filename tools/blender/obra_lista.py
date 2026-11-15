"""Lists what is in a downloaded .blend or .fbx (every object: kind, parent, size, where it sits, triangles, materials)
and, with an output prefix, renders it from two sides. A .blend is opened WITHOUT running the scripts it may carry.

    blender.exe -b -Y --python tools/blender/obra_lista.py -- FILE [OUT_PREFIX]
"""
import bpy, sys, math
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:]
src = args[0]
prefix = args[1] if len(args) > 1 else ''
if src.lower().endswith('.blend'):
    bpy.ops.wm.open_mainfile(filepath=src, use_scripts=False)
else:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=src)
scene = bpy.context.scene
print('LISTA %s: frame %d..%d, %d objects' % (src.replace('\\', '/').split('/')[-1], scene.frame_start, scene.frame_end, len(scene.objects)))
lo = Vector((1e9, 1e9, 1e9)); hi = Vector((-1e9, -1e9, -1e9))
for o in sorted(scene.objects, key=lambda o: o.name):
    line = '  %-34s %-8s parent %-22s' % (o.name[:34], o.type, (o.parent.name if o.parent else '-')[:22])
    if o.type == 'MESH':
        pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
        a = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        b = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        if not o.hide_render and not o.hide_get():
            lo = Vector(map(min, lo, a)); hi = Vector(map(max, hi, b))
        tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
        line += ' box (%.2f %.2f %.2f)..(%.2f %.2f %.2f) tris %5d mats %s%s' % (a.x, a.y, a.z, b.x, b.y, b.z, tris, [m.name for m in o.data.materials if m][:4], ' HIDDEN' if o.hide_render else '')
    print(line)
print('  whole: (%.2f %.2f %.2f)..(%.2f %.2f %.2f)' % (lo.x, lo.y, lo.z, hi.x, hi.y, hi.z), '| images:', [(i.name, i.size[0], i.size[1], bool(i.packed_file)) for i in bpy.data.images][:8])
if prefix:
    size = hi - lo
    mid = (lo + hi) / 2
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'TEXTURE'
    scene.render.resolution_x = 900
    scene.render.resolution_y = 600
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = 'PNG'
    cam_data = bpy.data.cameras.new('cam_lista'); cam = bpy.data.objects.new('cam_lista', cam_data)
    scene.collection.objects.link(cam); scene.camera = cam
    cam_data.lens = 50
    cam_data.clip_start = max(size) * 0.01; cam_data.clip_end = max(size) * 100
    for name, d in (('a', Vector((0.8, -1, 0.5))), ('b', Vector((-0.9, 0.8, 0.4))), ('arriba', Vector((0.001, -0.001, 1)))):
        d = d.normalized()
        cam.location = mid + d * max(size) * 1.9
        cam.rotation_euler = (mid - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = '%s_%s.png' % (prefix, name)
        bpy.ops.render.render(write_still=True)
