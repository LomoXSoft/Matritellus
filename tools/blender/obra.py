"""Readies the machines and gear of the demolition works by the old bridge of the Arroyuelo Medio (puente.gd).

Sources, all CC0, from OpenGameArt (the downloads as they came are in tools/descargas/oga_*/):
  - "Excavator" by Iacox: a wheeled excavator, an animated .blend. It is opened WITHOUT running the scripts it may
    carry; the machine is taken at chosen frames of its animation (its arm in one pose or another), every part put
    where it stands, joined into one mesh, set on the ground under its own wheels, made its real size, and its
    materials reduced to plain colours (the photograph packed in the file is not used).
  - "3D House Construction Site (LowPoly, CC0)" by Majadroid (Maik Hoffmann): a tipper truck, a skip, a barrel, planks.
  - "Construction Site Kit" by Silverknot: a traffic cone.

    blender.exe -b -Y --python tools/blender/obra.py -- poses EXCAVATOR.blend OUT_PREFIX frame [frame ...]
    blender.exe -b -Y --python tools/blender/obra.py -- build DESCARGAS_FOLDER OUT.glb [PREVIEW_PREFIX]

Each piece is a node of its own standing at the origin, its front towards +z in the game (-y here).
"""
import bpy, sys, os, math
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index('--') + 1:]
MODE = args[0]
EXC_SCALE = 1.65        # the cab's roof at 3 m
LEAVE_OUT = ('Icosphere', 'Tierra_pala')


def plain(name, col, rough=0.75, metal=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get('Principled BSDF')
    b.inputs['Base Color'].default_value = (col[0], col[1], col[2], 1.0)
    b.inputs['Roughness'].default_value = rough
    b.inputs['Metallic'].default_value = metal
    m.diffuse_color = (col[0], col[1], col[2], 1.0)
    return m


def colour_of(mat):
    if mat is None:
        return (0.5, 0.5, 0.5)
    if mat.use_nodes and mat.node_tree:
        for n in mat.node_tree.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                c = n.inputs['Base Color'].default_value
                return (c[0], c[1], c[2])
            if n.type in ('BSDF_DIFFUSE', 'BSDF_GLOSSY', 'BSDF_GLASS'):
                c = n.inputs['Color'].default_value
                return (c[0], c[1], c[2])
    c = mat.diffuse_color
    return (c[0], c[1], c[2])


def excavator_at(frame, name):
    """the excavator as it stands at a frame of its animation: one mesh object, in the scene"""
    scene = bpy.context.scene
    scene.frame_set(frame)
    dg = bpy.context.evaluated_depsgraph_get()
    made = []
    wheels = []
    for o in list(scene.objects):
        if o.type != 'MESH' or o.name.startswith(LEAVE_OUT) or o.name.startswith(('obra_', 'excavadora_')) or o.hide_render:
            continue
        if max(o.dimensions) > 15.0:
            continue
        ev = o.evaluated_get(dg)
        me = bpy.data.meshes.new_from_object(ev)
        me.transform(ev.matrix_world)
        n = bpy.data.objects.new('obra_part', me)
        scene.collection.objects.link(n)
        made.append(n)
        if o.name.startswith('Yanta'):
            wheels.append(n)
    bpy.ops.object.select_all(action='DESELECT')
    for n in made:
        n.select_set(True)
    bpy.context.view_layer.objects.active = made[0]
    bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.name = name
    # plain colours, one material for each colour
    by_col = {}
    for i, slot in enumerate(ob.material_slots):
        c = colour_of(slot.material)
        nm = slot.material.name if slot.material else 'gris'
        if nm.startswith('Material'):                # (the cab's glass)
            c = (0.2, 0.32, 0.4)
        key = tuple(round(v, 2) for v in c)
        if key not in by_col:
            by_col[key] = bpy.data.materials.get('obra_%02d_%02d_%02d' % tuple(int(v * 99) for v in key)) or plain('obra_%02d_%02d_%02d' % tuple(int(v * 99) for v in key), c, 0.55 if nm.lower().startswith(('gris_metal', 'negro_metal')) else 0.8)
        slot.material = by_col[key]
    bpy.ops.object.material_slot_remove_unused()
    # lighter: what is flat becomes one face again, and the many little round pins lose half their sides
    before = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    for kind, kw in (('DISSOLVE', {'angle_limit': math.radians(4.0)}), ('COLLAPSE', {'ratio': 0.55})):
        md = ob.modifiers.new('ligero', 'DECIMATE')
        md.decimate_type = kind
        if kind == 'DISSOLVE':
            md.angle_limit = kw['angle_limit']
            md.delimit = {'MATERIAL'}
        else:
            md.ratio = kw['ratio']
        bpy.ops.object.modifier_apply(modifier=md.name)
    print('OBRA: %s from %d to %d triangles' % (name, before, sum(len(p.vertices) - 2 for p in ob.data.polygons)))
    # on the ground, under the middle of its wheels; its arm towards -y
    pts = [ob.matrix_world @ v.co for v in ob.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    return ob, lo


def box_of(ob):
    pts = [ob.matrix_world @ v.co for v in ob.data.vertices]
    return Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts))), Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))


def settle(ob, k=1.0, turn=0.0, centre=None):
    """scaled, turned about the upright, standing on the ground with `centre` (or the middle of its box) at the origin"""
    ob.data.transform(Matrix.Rotation(turn, 4, 'Z') @ Matrix.Scale(k, 4))
    ob.matrix_world = Matrix.Identity(4)
    lo, hi = box_of(ob)
    c = centre if centre is not None else (lo + hi) / 2
    ob.data.transform(Matrix.Translation((-c.x, -c.y, -lo.z)))
    ob.data.update()


def render(prefix, obs, views=(('a', (0.9, -1, 0.45)), ('b', (-1, 0.5, 0.35)))):
    scene = bpy.context.scene
    lo = Vector((1e9, 1e9, 1e9)); hi = Vector((-1e9, -1e9, -1e9))
    for o in obs:
        a, b = box_of(o)
        lo = Vector(map(min, lo, a)); hi = Vector(map(max, hi, b))
    size = hi - lo; mid = (lo + hi) / 2
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'TEXTURE'
    scene.render.resolution_x = 900; scene.render.resolution_y = 600
    scene.render.image_settings.file_format = 'PNG'
    world = scene.world or bpy.data.worlds.new('w'); scene.world = world
    world.use_nodes = False; world.color = (0.6, 0.62, 0.65)
    cam = bpy.data.objects.get('obra_cam')
    if cam is None:
        cam = bpy.data.objects.new('obra_cam', bpy.data.cameras.new('obra_cam'))
        scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.lens = 50; cam.data.clip_start = 0.05; cam.data.clip_end = 500
    keep = {o.name: o.hide_render for o in scene.objects}
    for o in scene.objects:
        if o.type == 'MESH':
            o.hide_render = o not in obs
    for name, d in views:
        d = Vector(d).normalized()
        cam.location = mid + d * max(size) * 1.8
        cam.rotation_euler = (mid - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = '%s_%s.png' % (prefix, name)
        bpy.ops.render.render(write_still=True)
    for o in scene.objects:
        if o.name in keep:
            o.hide_render = keep[o.name]


if MODE == 'poses':
    src, prefix = args[1], args[2]
    bpy.ops.wm.open_mainfile(filepath=src, use_scripts=False)
    for f in [int(v) for v in args[3:]]:
        ob, lo = excavator_at(f, 'obra_pose_%d' % f)
        a, b = box_of(ob)
        print('POSE %d: box (%.2f %.2f %.2f)..(%.2f %.2f %.2f), %d triangles, %d materials' % (f, a.x, a.y, a.z, b.x, b.y, b.z, sum(len(p.vertices) - 2 for p in ob.data.polygons), len(ob.material_slots)))
        render('%s_%d' % (prefix, f), [ob], (('lado', (0.05, -1, 0.12)), ('a', (0.9, -1, 0.5))))
        bpy.data.objects.remove(ob)

if MODE == 'build':
    root, dst = args[1], args[2]
    prefix = args[3] if len(args) > 3 else ''
    # --- the excavator, twice ---
    bpy.ops.wm.open_mainfile(filepath=os.path.join(root, 'oga_excavadora', 'excavadora_0.blend'), use_scripts=False)
    made = []
    for name, frame in (('excavadora_a', int(os.environ.get('OBRA_POSE_A', '1'))), ('excavadora_b', int(os.environ.get('OBRA_POSE_B', '400')))):
        ob, lo = excavator_at(frame, name)
        # the middle of its four wheels is where it stands; its arm goes towards -x in the file: turned to -y
        me = ob.data
        ws = [v.co for v in me.vertices if v.co.z < lo.z + 0.25]
        cx = (min(p.x for p in ws) + max(p.x for p in ws)) / 2; cy = (min(p.y for p in ws) + max(p.y for p in ws)) / 2
        me.transform(Matrix.Translation((-cx, -cy, -lo.z)))
        me.transform(Matrix.Rotation(math.radians(90.0), 4, 'Z') @ Matrix.Scale(EXC_SCALE, 4))
        me.update()
        made.append(ob)
    keepers = set(made)
    for o in list(bpy.context.scene.objects):
        if o not in keepers:
            bpy.data.objects.remove(o)
    # --- the pieces of the two sets ---
    def fbx(path, wanted):
        before = set(bpy.context.scene.objects)
        bpy.ops.import_scene.fbx(filepath=path)
        out = {}
        for o in [o for o in bpy.context.scene.objects if o not in before]:
            if o.type == 'MESH' and o.name in wanted:
                mw = o.matrix_world.copy()
                o.parent = None
                o.data.transform(mw)
                o.matrix_world = Matrix.Identity(4)
                out[o.name] = o
            else:
                bpy.data.objects.remove(o)
        return out
    maja = os.path.join(root, 'oga_obra_majadroid', 'LowPoly-House-Construction-Site-By-Majadroid', 'fbx files')
    got = {}
    got.update(fbx(os.path.join(maja, 'Trucks.fbx'), {'Dumper Truck Red'}))
    got.update(fbx(os.path.join(maja, 'Containers.fbx'), {'Container Blue Small', 'Container Red'}))
    got.update(fbx(os.path.join(maja, 'Construction-Materials.fbx'), {'Barrel', 'Planks Wood V2'}))
    got.update(fbx(os.path.join(root, 'oga_obra_silverknot', 'kit', 'Warning_Cone.fbx'), {'Warning_Cone'}))
    names = {'Dumper Truck Red': 'camion', 'Container Blue Small': 'contenedor', 'Container Red': 'contenedor_b', 'Barrel': 'bidon', 'Planks Wood V2': 'tablones', 'Warning_Cone': 'cono'}
    # the truck's cab is red, which in this game only one car may be: its red faces take the white of the palette
    pal = bpy.data.images.get('ImphenziaPalette01-256-Gradient.png')
    if pal is not None and 'Dumper Truck Red' in got:
        w, h = pal.size
        px = list(pal.pixels)
        def at(u, v):
            i = (min(h - 1, max(0, int(v * h))) * w + min(w - 1, max(0, int(u * w)))) * 4
            return px[i], px[i + 1], px[i + 2]
        best = None
        for j in range(0, h, 4):
            for i in range(0, w, 4):
                r, g, b = at((i + 0.5) / w, (j + 0.5) / h)
                d = (r - 0.92) ** 2 + (g - 0.9) ** 2 + (b - 0.84) ** 2
                if best is None or d < best[0]:
                    best = (d, (i + 0.5) / w, (j + 0.5) / h)
        me = got['Dumper Truck Red'].data
        uv = me.uv_layers.active.data
        moved = 0
        for p in me.polygons:
            r, g, b = at(*uv[p.loop_start].uv)
            if r > 0.3 and g < r * 0.45 and b < r * 0.45:
                for li in p.loop_indices:
                    uv[li].uv = (best[1], best[2])
                moved += 1
        print('OBRA: the truck: %d red faces made white (palette colour at %.3f, %.3f)' % (moved, best[1], best[2]))
    cone = got.get('Warning_Cone')
    if cone is not None:
        cone.data.materials.clear()
        cone.data.materials.append(plain('obra_cono', (0.92, 0.33, 0.08), 0.6))
    for src_name, o in got.items():
        o.name = names[src_name]
        settle(o, 1.0, math.radians(180.0) if src_name.startswith(('Dumper', 'Container')) else 0.0)
        made.append(o)
    for o in made:
        a, b = box_of(o)
        print('OBRA %-14s box (%.2f %.2f %.2f)..(%.2f %.2f %.2f)  %5d triangles  materials %s' % (o.name, a.x, a.y, a.z, b.x, b.y, b.z, sum(len(p.vertices) - 2 for p in o.data.polygons), [s.material.name for s in o.material_slots if s.material]))
    if prefix:
        for o in made:
            render('%s_%s' % (prefix, o.name), [o])
    for img in list(bpy.data.images):                 # (only the palette goes out with the models)
        if img.name != 'ImphenziaPalette01-256-Gradient.png' and img.name != 'Render Result':
            img.user_clear()
    bpy.ops.object.select_all(action='DESELECT')
    for o in made:
        o.select_set(True)
    cam = bpy.data.objects.get('obra_cam')
    if cam is not None:
        bpy.data.objects.remove(cam)
    bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB', use_selection=True, export_apply=True, export_yup=True, export_animations=False)
    print('OBRA: wrote', dst, os.path.getsize(dst), 'bytes')
