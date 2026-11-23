"""The quiff (tupé) for Matritellus's people, made from nothing in Blender: no free model had one (the user, 17 November
2026, with a photo of a pompadour: "El tupé ... Ahora mismo es solo una bola, debería ser algo como la foto"). Of all the
pack pieces, the closest was an "upcomb" (OpenGameArt, CC0), much flatter.

    blender.exe -b --python tools/creador/tupe.py -- OUT_GLB [PREVIEW_PNG]

The hair of the top of the head, combed up from the forehead and back over the crown: a sheet over the ball (0.5 m round
(0, 0, 1.38), Blender's axes: z up, the face to -y), standing off it most just behind the hairline -- the front rising
steeply and leaning a little forward over the forehead -- and less and less towards the back of the crown, where it
lies flat. Across, it is rounded off at the edges, where it meets the sides (chara.gd shades those in the hair's colour,
fading out downwards: the "degradado"). Ridges and darker grooves run along it, front to back: the combed strands.
Written in the character's frame (y up, the face to +z) as one mesh with a vertex colour that the game multiplies in.
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:]
OUT = args[0]
PREV = args[1] if len(args) > 1 else ''
C = Vector((0.0, 0.0, 1.38))
R = 0.5
EPS = 0.006
N_PHI = 32            # along the head, front to back (kept low-poly for clean outlines)
N_LAT = 22            # across
STRANDS = 11.0        # ridges across the top


def smoothstep(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def phi0(b):          # where the hair starts in front (degrees round the side-to-side axis, 0 = straight ahead): further back at the temples
    return 30.0 + 7.0 * b * b


PHI1 = 150.0          # ...and where it ends, behind the crown (narrowing and lying flat: it melts into the faded back)


def lat_max(phi):     # how far down the sides it reaches (degrees from the top line)
    return 36.0 + 8.0 * smoothstep(30.0, 80.0, phi) - 18.0 * smoothstep(95.0, 150.0, phi)      # (narrower than the head: the faded sides show)


def height(phi, b):   # how far it stands off the head (m)
    p0 = phi0(b)
    rise = smoothstep(p0, p0 + 20.0, phi) ** 0.75
    top = 0.205 if phi <= 54.0 else 0.03 + 0.175 * math.exp(-((phi - 54.0) / 42.0) ** 2)
    end = 1.0 - smoothstep(95.0, PHI1, phi)
    across = max(0.0, 1.0 - abs(b) ** 3) ** 0.55
    ridge = 1.0 + 0.03 * math.sin(b * math.pi * STRANDS + phi * 0.012)
    return rise * top * end * across * ridge


def lean(phi, b):     # the front leaning forward over the forehead (m)
    across = max(0.0, 1.0 - abs(b) ** 2)
    return 0.042 * math.exp(-((phi - 50.0) / 13.0) ** 2) * across


def point(phi, b):
    lat = math.radians(b * lat_max(phi))
    ph = math.radians(phi)
    d = Vector((math.sin(lat), -math.cos(lat) * math.cos(ph), math.cos(lat) * math.sin(ph)))
    h = height(phi, b)
    return C + d * (R + EPS + h) + Vector((0.0, -1.0, 0.25)) * lean(phi, b), h


bm = bmesh.new()
grid = []
info = []
for i in range(N_PHI + 1):
    row = []
    s = i / N_PHI
    for j in range(N_LAT + 1):
        b = -1.0 + 2.0 * j / N_LAT
        p0 = phi0(b)
        phi = p0 + (PHI1 - p0) * (s ** 1.35)          # (closer rows in front, where it rises)
        co, h = point(phi, b)
        row.append(bm.verts.new(co))
        info.append((phi, b, h))
    grid.append(row)
for i in range(N_PHI):
    for j in range(N_LAT):
        bm.faces.new((grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
for f in bm.faces:                                  # (normals outward: away from the middle of the head)
    if f.normal.dot(f.calc_center_median() - C) < 0.0:
        f.normal_flip()

# the strands' shading: grooves along it, darker where it meets the head, a little lighter on top of the front
col = bm.loops.layers.color.new('Col')
tone = {}
k = 0
for i in range(N_PHI + 1):
    for j in range(N_LAT + 1):
        phi, b, h = info[k]
        groove = 0.5 + 0.5 * math.sin(b * math.pi * STRANDS + phi * 0.012)
        t = 0.84 + 0.16 * groove
        t *= 0.70 + 0.30 * smoothstep(0.0, 0.06, h)
        t *= 1.0 + 0.08 * math.exp(-((phi - 56.0) / 18.0) ** 2) * (1.0 - abs(b))
        tone[grid[i][j]] = min(1.0, t)
        k += 1
for f in bm.faces:
    for lp in f.loops:
        v = tone[lp.vert]
        lp[col] = (v, v, v, 1.0)

bpy.ops.wm.read_factory_settings(use_empty=True)
me = bpy.data.meshes.new('pelo_tupe')
bm.to_mesh(me)
for poly in me.polygons:
    poly.use_smooth = True
me.color_attributes.active_color = me.color_attributes['Col']
me.color_attributes.render_color_index = 0
me.materials.append(bpy.data.materials.new('pelo'))
ob = bpy.data.objects.new('pieza', me)
bpy.context.scene.collection.objects.link(ob)
ob.select_set(True)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, export_apply=True, export_materials='EXPORT',
                          export_vertex_color='ACTIVE', export_all_vertex_colors=False, export_active_vertex_color_when_no_material=True)
lo = Vector((min(v.co.x for v in me.vertices), min(v.co.y for v in me.vertices), min(v.co.z for v in me.vertices)))
hi = Vector((max(v.co.x for v in me.vertices), max(v.co.y for v in me.vertices), max(v.co.z for v in me.vertices)))
print('TUPE %d tris  x %.2f..%.2f  front %.2f..%.2f  up %.2f..%.2f' % (len(me.polygons) * 2, lo.x, hi.x, -hi.y, -lo.y, lo.z, hi.z))

if PREV:                                            # a quick look: on a plain ball, from the side and from the front
    bpy.ops.mesh.primitive_uv_sphere_add(radius=R, location=C, segments=32, ring_count=16)
    head = bpy.context.active_object
    mh = bpy.data.materials.new('piel')
    mh.diffuse_color = (0.98, 0.84, 0.70, 1.0)
    head.data.materials.append(mh)
    mp = bpy.data.materials['pelo']
    mp.diffuse_color = (0.35, 0.23, 0.13, 1.0)
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'MATERIAL'
    scene.render.resolution_x = 520
    scene.render.resolution_y = 520
    cam_d = bpy.data.cameras.new('cam')
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = 1.6
    cam = bpy.data.objects.new('cam', cam_d)
    scene.collection.objects.link(cam)
    scene.camera = cam
    for name, loc, rot in (('lado', (2.5, 0.0, 1.55), (math.pi / 2, 0.0, math.pi / 2)), ('frente', (0.0, -2.5, 1.55), (math.pi / 2, 0.0, 0.0)),
                           ('tresq', (1.6, -1.9, 1.95), (math.radians(78), 0.0, math.radians(40)))):
        cam.location = loc
        cam.rotation_euler = rot
        scene.render.filepath = PREV.replace('.png', '_%s.png' % name)
        bpy.ops.render.render(write_still=True)
