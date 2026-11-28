"""A low-poly skull and a long bone, modelled here from nothing (no download): the hidden bones of the Colegio Público,
built over the ruins of the old cemetery (the user, 27 Nov 2026: "si quieres poner algunos huesos o calaveras en algún
sitio como easter egg estaría guay"). colegiopub.gd places them.

    blender.exe -b --factory-startup --python tools/blender/calavera.py -- OUT.glb [PREVIEW.png]

Two nodes, each standing at the origin, its front towards +z in the game (-y here): "calavera" (about 15 cm wide,
20 cm tall with its jaw) and "hueso" (a femur, 42 cm, lying along x). Materials: bone, and the dark of the holes.
"""
import bpy, sys, os, math

args = sys.argv[sys.argv.index('--') + 1:]
OUT = args[0]
PREVIEW = args[1] if len(args) > 1 else None

bpy.ops.wm.read_factory_settings(use_empty=True)


def plain(name, col, rough=0.8):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get('Principled BSDF')
    b.inputs['Base Color'].default_value = (col[0], col[1], col[2], 1.0)
    b.inputs['Roughness'].default_value = rough
    m.diffuse_color = (col[0], col[1], col[2], 1.0)
    return m


BONE = plain('hueso', (0.86, 0.80, 0.66))
DARK = plain('cuenca', (0.10, 0.08, 0.07))


def sphere(name, loc, scale, seg=12, rings=8, mat=BONE):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=1.0, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    o.data.materials.append(mat)
    return o


def cube(name, loc, scale, mat=BONE, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=2.0, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    o.data.materials.append(mat)
    return o


def apply(o):
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.select_set(False)


def boolean(target, other, op):
    """join (UNION) or cut (DIFFERENCE) one closed mesh with another and drop the other; a cut's new faces take the
    cutter's (dark) material. Both must be closed: joining overlapping pieces first and cutting after breaks the solver."""
    for m in other.data.materials:
        if m.name not in [t.name for t in target.data.materials]:
            target.data.materials.append(m)
    mod = target.modifiers.new('b', 'BOOLEAN')
    mod.operation = op
    mod.solver = 'EXACT'
    mod.object = other
    try:
        mod.material_mode = 'TRANSFER'
    except Exception:
        pass
    bpy.context.view_layer.objects.active = target
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(other, do_unlink=True)


def join(objs, name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = name
    return o


def bevel_box(name, loc, scale, width, rot=(0, 0, 0)):
    o = cube(name, loc, scale, BONE, rot)
    apply(o)
    bev = o.modifiers.new('bev', 'BEVEL')
    bev.width = width
    bev.segments = 2
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier='bev')
    return o


# ---------------- the skull (metres; Blender: x across, -y its front, z up) ----------------
skull = sphere('calavera', (0, 0.015, 0.128), (0.071, 0.09, 0.077), 16, 10)
apply(skull)
boolean(skull, bevel_box('face', (0, -0.047, 0.074), (0.049, 0.034, 0.034), 0.014), 'UNION')
for s in (-1, 1):
    c = sphere('cheek', (s * 0.045, -0.044, 0.09), (0.022, 0.026, 0.019), 10, 7)
    apply(c)
    boolean(skull, c, 'UNION')
# eye sockets and the nose cut into the face
for s in (-1, 1):
    eye = sphere('eye', (s * 0.026, -0.08, 0.108), (0.021, 0.03, 0.02), 12, 8, DARK)
    apply(eye)
    boolean(skull, eye, 'DIFFERENCE')
nose = cube('nose', (0, -0.083, 0.077), (0.011, 0.03, 0.011), DARK, (0, math.radians(45), 0))
apply(nose)
nose.scale = (1.0, 1.0, 1.5)
apply(nose)
boolean(skull, nose, 'DIFFERENCE')
# the upper teeth, a row under the face (overlapping pieces are fine once the cuts are done)
parts = [skull]
for i in range(8):
    x = (i - 3.5) * 0.0095
    t = cube('tooth', (x, -0.074 + abs(i - 3.5) * 0.0045, 0.045), (0.0042, 0.005, 0.0075))
    apply(t)
    parts.append(t)
# the jaw: a horseshoe of three pieces and its teeth
jaw = cube('jaw_f', (0, -0.061, 0.022), (0.035, 0.015, 0.013))
apply(jaw)
parts.append(jaw)
for s in (-1, 1):
    j = cube('jaw_s', (s * 0.038, -0.038, 0.032), (0.0065, 0.026, 0.014), BONE, (math.radians(30), 0, 0))
    apply(j)
    parts.append(j)
for i in range(6):
    x = (i - 2.5) * 0.0095
    t = cube('ltooth', (x, -0.07 + abs(i - 2.5) * 0.004, 0.036), (0.0042, 0.005, 0.0065))
    apply(t)
    parts.append(t)
skull = join(parts, 'calavera')
bpy.ops.object.shade_flat()

# ---------------- the long bone ----------------
shaft = None
bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.013, depth=0.34, location=(0, 0, 0), rotation=(0, math.radians(90), 0))
shaft = bpy.context.active_object
shaft.data.materials.append(BONE)
apply(shaft)
knobs = []
for s in (-1, 1):
    for k in (-1, 1):
        kn = sphere('knob', (s * 0.178, 0, k * 0.012), (0.024, 0.022, 0.02), 8, 6)
        apply(kn)
        knobs.append(kn)
bone = join([shaft] + knobs, 'hueso')
bpy.ops.object.shade_flat()
bone.location = (0, 0, 0.022)

# both standing on the ground at the origin
for o in (skull, bone):
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    zmin = min((o.matrix_world @ v.co).z for v in o.data.vertices)
    o.location.z -= zmin
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    print('PIECE', o.name, 'tris', sum(len(p.vertices) - 2 for p in o.data.polygons), 'size', [round(v, 3) for v in o.dimensions])

if PREVIEW:
    scn = bpy.context.scene
    scn.render.engine = 'BLENDER_WORKBENCH'
    scn.render.resolution_x = 640
    scn.render.resolution_y = 400
    scn.display.shading.light = 'STUDIO'
    scn.display.shading.color_type = 'MATERIAL'
    skull.location = (-0.12, 0, 0)
    skull.rotation_euler = (0, 0, math.radians(-30))
    bone.location = (0.16, 0.05, 0)
    cam = bpy.data.cameras.new('cam')
    co = bpy.data.objects.new('cam', cam)
    scn.collection.objects.link(co)
    co.location = (0.05, -0.75, 0.32)
    co.rotation_euler = (math.radians(73), 0, 0)
    cam.lens = 50
    scn.camera = co
    scn.render.filepath = PREVIEW
    bpy.ops.render.render(write_still=True)
    skull.location = (0, 0, 0)
    skull.rotation_euler = (0, 0, 0)
    bone.location = (0, 0, 0)

os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.object.select_all(action='DESELECT')
for o in (skull, bone):
    o.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, export_apply=True, export_yup=True, export_animations=False)
print('CALAVERA: wrote', OUT, os.path.getsize(OUT), 'bytes')
