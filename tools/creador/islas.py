"""How many loose parts (islands) and materials each named mesh of a .blend has: to colour the layers of clothes apart.

    blender.exe -b --python tools/creador/islas.py -- FILE.blend NAME [NAME ...]
"""
import bpy, bmesh, sys

a = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.open_mainfile(filepath=a[0])
for n in a[1:]:
    o = bpy.data.objects.get(n)
    if o is None:
        print('ISLAS', n, 'missing')
        continue
    bm = bmesh.new()
    bm.from_mesh(o.data)
    seen = set()
    sizes = []
    for f in bm.faces:
        if f.index in seen:
            continue
        todo = [f]
        seen.add(f.index)
        k = 0
        while todo:
            g = todo.pop()
            k += 1
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen:
                        seen.add(h.index)
                        todo.append(h)
        sizes.append(k)
    sizes.sort(reverse=True)
    print('ISLAS %-30s %3d islands %s  mats=%s  mods=%s' % (n[:30], len(sizes), sizes[:10], [s.material.name if s.material else '' for s in o.material_slots], [m.type for m in o.modifiers]))
