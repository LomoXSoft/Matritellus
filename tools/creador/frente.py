"""How much of the front of the head each fitted hairstyle leaves bare: rays from outside towards the middle of the head,
over the forehead and the top (bearing within +-50 degrees of straight ahead, elevation 30..86); a ray that meets the
ball before any of the piece is bare skin. For finding the hairstyles whose hairline sits too high on our heads.

    blender.exe -b --python tools/creador/frente.py -- GLB [GLB ...]
"""
import bpy, sys, math
from mathutils import Vector
from mathutils.bvhtree import BVHTree
import bmesh

C = Vector((0.0, 0.0, 1.38))
R = 0.5
for f in sys.argv[sys.argv.index('--') + 1:]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=f)
    obs = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.name == 'pieza']
    if not obs:
        continue
    o = obs[0]
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.transform(o.matrix_world)
    tree = BVHTree.FromBMesh(bm)
    bare = []
    total = 0
    lowest_front = 99
    for el in range(30, 90, 4):
        for b in range(-50, 51, 5):
            e, a = math.radians(el), math.radians(b)
            d = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))     # (the face is to -y)
            start = C + d * 1.5
            hit = tree.ray_cast(start, -d, 1.5 - R)
            total += 1
            if hit[0] is None:
                bare.append((b, el))
            elif abs(b) <= 10:
                lowest_front = min(lowest_front, el)
    centre = [el for b, el in bare if abs(b) <= 15]
    print('FRENTE %-22s bare %3d of %d   hairline in the middle at %s degrees (the eyebrows ~20, the top 90)' % (
        f.replace('\\', '/').split('/')[-1][:-4], len(bare), total, (max(centre) + 4) if centre else '<30'))
