"""Lists what a model is made of: every mesh object with its materials, its size and where it sits in the model's box
(fractions: x across, y front(0) to back(1), z up).

    blender.exe -b --python tools/blender/inventario.py -- model.glb
"""
import bpy, sys
from mathutils import Vector

src = sys.argv[sys.argv.index('--') + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
def box(o):
    pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
    return Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts))), Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
skip = [a for a in sys.argv[sys.argv.index('--') + 2:]]
boxes = {o.name: box(o) for o in meshes}
keep = [o for o in meshes if not any(s in [m.name for m in o.data.materials if m] for s in skip)]
lo = Vector((min(boxes[o.name][0].x for o in keep), min(boxes[o.name][0].y for o in keep), min(boxes[o.name][0].z for o in keep)))
hi = Vector((max(boxes[o.name][1].x for o in keep), max(boxes[o.name][1].y for o in keep), max(boxes[o.name][1].z for o in keep)))
size = hi - lo
print('INV %s: %d objects, box %s' % (src.replace('\\', '/').split('/')[-1], len(meshes), [round(v, 3) for v in size]))
for o in sorted(meshes, key=lambda o: o.name):
    a, b = boxes[o.name]
    f = lambda v, i: (v[i] - lo[i]) / size[i] if size[i] else 0
    print('INV  %-34s %5d polys  x %.2f..%.2f  y %.2f..%.2f  z %.2f..%.2f  %s' % (o.name[:34], len(o.data.polygons), f(a, 0), f(b, 0), f(a, 1), f(b, 1), f(a, 2), f(b, 2),
          ','.join(m.name for m in o.data.materials if m)))
