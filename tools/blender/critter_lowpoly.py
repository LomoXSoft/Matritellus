"""
Generador de personaje y props low-poly estilizados para Godot
--------------------------------------------------------------
Blender 3.6 / 4.x

Uso:
  1. Abre un archivo NUEVO de Blender (el script borra la escena actual).
  2. Pestaña "Scripting" -> Abrir este archivo -> "Run Script".
     (o por terminal:  blender -b -P critter_lowpoly.py)
  3. Los .glb se guardan en assets/modelos3d/ de godot/ en Matritellus.

Genera:
  - critter.glb  -> personaje chibi con esqueleto y animaciones idle-loop y walk-loop
  - tree.glb     -> árbol de copa redondeada
  - rock.glb     -> roca facetada
"""

import bpy
import bmesh
import math
import os
import random
from mathutils import Vector, Euler

# ============================================================
# CONFIGURACIÓN: cambia esto para crear variantes
# ============================================================
CONFIG = {
    "ears": "round",          # "round" (oso/mapache), "pointy" (gato/zorro), "long" (conejo)
    "tail": True,
    "faceted": False,         # True = look low-poly duro (caras planas); False = suave tipo juguete
    "segments": 12,           # resolución base de las esferas (8-16)
    "export_dir": r"X:\Matritellus\godot\assets\modelos3d",
    "colors": {
        "fur":     (0.93, 0.66, 0.38),
        "muzzle":  (1.00, 0.92, 0.80),
        "clothes": (0.30, 0.58, 0.86),
        "dark":    (0.10, 0.08, 0.08),
        "white":   (1.00, 1.00, 1.00),
        "cheek":   (1.00, 0.55, 0.55),
        "bark":    (0.45, 0.30, 0.18),
        "leaves":  (0.36, 0.72, 0.36),
        "leaves2": (0.45, 0.80, 0.40),
        "stone":   (0.60, 0.60, 0.62),
    },
}

# ============================================================
# Utilidades
# ============================================================
SCENE_COLL = bpy.context.scene.collection


def clear_scene():
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)


_mats = {}


def mat(key):
    """Material mate tipo plastilina (roughness alta, sin metal)."""
    if key in _mats:
        return _mats[key]
    rgb = CONFIG["colors"][key]
    m = bpy.data.materials.new(key)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.85
        bsdf.inputs["Metallic"].default_value = 0.0
    m.diffuse_color = (*rgb, 1.0)
    _mats[key] = m
    return m


def part(name, kind, size, loc, rot=(0, 0, 0), material="fur",
         bone=None, segs=None, jitter=0.0):
    """Crea una pieza (sphere/cone/cylinder) ya escalada, rotada y colocada."""
    segs = segs or CONFIG["segments"]
    bm = bmesh.new()
    if kind == "sphere":
        bmesh.ops.create_uvsphere(bm, u_segments=segs,
                                  v_segments=max(5, segs * 2 // 3), radius=1.0)
    elif kind == "cone":
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs,
                              radius1=1.0, radius2=0.0, depth=2.0)
    elif kind == "cylinder":
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs,
                              radius1=1.0, radius2=1.0, depth=2.0)
    elif kind == "taper":  # cilindro con la parte superior más estrecha
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs,
                              radius1=1.0, radius2=0.7, depth=2.0)
    else:
        raise ValueError(kind)

    if jitter:
        for v in bm.verts:
            v.co += Vector((random.uniform(-jitter, jitter) for _ in range(3)))

    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    bmesh.ops.rotate(bm, cent=(0, 0, 0), matrix=Euler(rot).to_matrix(), verts=bm.verts)
    bmesh.ops.translate(bm, vec=Vector(loc), verts=bm.verts)

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    SCENE_COLL.objects.link(obj)
    me.materials.append(mat(material))
    for p in me.polygons:
        p.use_smooth = not CONFIG["faceted"]
    if bone:
        vg = obj.vertex_groups.new(name=bone)
        vg.add(list(range(len(me.vertices))), 1.0, "REPLACE")
    return obj


def mirror(name, kind, size, loc, rot=(0, 0, 0), **kw):
    """Crea la pieza en +X (.L) y su espejo en -X (.R)."""
    bone = kw.pop("bone", None)
    x, y, z = loc
    rx, ry, rz = rot
    a = part(name + ".L", kind, size, (x, y, z), (rx, ry, rz),
             bone=bone + ".L" if bone else None, **kw)
    b = part(name + ".R", kind, size, (-x, y, z), (rx, -ry, -rz),
             bone=bone + ".R" if bone else None, **kw)
    return [a, b]


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = obj.data.name = name
    return obj


def soften(obj, levels=1):
    if not CONFIG["faceted"]:
        mod = obj.modifiers.new("Subdivision", "SUBSURF")
        mod.levels = mod.render_levels = levels


def export(objs, filename):
    os.makedirs(CONFIG["export_dir"], exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    path = os.path.join(CONFIG["export_dir"], filename)
    kwargs = dict(filepath=path, export_format="GLB", use_selection=True,
                  export_apply=True, export_animations=True)
    try:
        bpy.ops.export_scene.gltf(export_animation_mode="ACTIONS", **kwargs)
    except TypeError:  # versiones sin ese parámetro
        bpy.ops.export_scene.gltf(**kwargs)
    print("Exportado:", path)


# ============================================================
# Personaje
# ============================================================
def build_character():
    p = []
    # Cuerpo y extremidades
    p.append(part("Body", "sphere", (0.19, 0.16, 0.20), (0, 0, 0.30),
                  material="clothes", bone="body"))
    p += mirror("Arm", "sphere", (0.055, 0.055, 0.11), (0.21, 0, 0.33),
                material="fur", bone="arm")
    p += mirror("Leg", "sphere", (0.075, 0.08, 0.09), (0.09, -0.01, 0.09),
                material="fur", bone="leg")
    if CONFIG["tail"]:
        p.append(part("Tail", "sphere", (0.07, 0.07, 0.07), (0, 0.18, 0.24),
                      material="fur", bone="body"))

    # Cabeza (grande, proporción chibi)
    p.append(part("Head", "sphere", (0.34, 0.30, 0.30), (0, 0, 0.78), bone="head"))
    p.append(part("Muzzle", "sphere", (0.13, 0.09, 0.09), (0, -0.25, 0.72),
                  material="muzzle", bone="head"))
    p.append(part("Nose", "sphere", (0.04, 0.03, 0.03), (0, -0.34, 0.75),
                  material="dark", bone="head", segs=8))
    p += mirror("Eye", "sphere", (0.035, 0.02, 0.05), (0.11, -0.27, 0.84),
                material="dark", bone="head", segs=10)
    p += mirror("EyeShine", "sphere", (0.012, 0.01, 0.012), (0.10, -0.29, 0.86),
                material="white", bone="head", segs=6)
    p += mirror("Cheek", "sphere", (0.04, 0.015, 0.03), (0.17, -0.25, 0.74),
                material="cheek", bone="head", segs=8)

    # Orejas
    ears = CONFIG["ears"]
    if ears == "round":
        p += mirror("Ear", "sphere", (0.08, 0.03, 0.08), (0.20, 0, 1.06),
                    rot=(0, 0.4, 0), bone="head")
    elif ears == "pointy":
        p += mirror("Ear", "cone", (0.07, 0.035, 0.08), (0.17, 0, 1.08),
                    rot=(0, 0.3, 0), bone="head", segs=6)
    elif ears == "long":
        p += mirror("Ear", "sphere", (0.05, 0.03, 0.18), (0.10, 0.02, 1.20),
                    rot=(0, 0.15, 0), bone="head")

    # Los vertex groups se fusionan por nombre al unir
    mesh = join(p, "Critter")
    soften(mesh)
    return mesh


def build_rig(mesh):
    data = bpy.data.armatures.new("CritterRig")
    rig = bpy.data.objects.new("CritterRig", data)
    SCENE_COLL.objects.link(rig)

    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    eb = data.edit_bones

    def bone(name, head, tail, parent=None):
        b = eb.new(name)
        b.head, b.tail = head, tail
        if parent:
            b.parent = eb[parent]

    bone("root", (0, 0, 0), (0, 0, 0.1))
    bone("body", (0, 0, 0.12), (0, 0, 0.50), "root")
    bone("head", (0, 0, 0.50), (0, 0, 1.00), "body")
    for s, x in (("L", 0.21), ("R", -0.21)):
        bone(f"arm.{s}", (x, 0, 0.43), (x, 0, 0.23), "body")
    for s, x in (("L", 0.09), ("R", -0.09)):
        bone(f"leg.{s}", (x, 0, 0.17), (x, 0, 0.0), "root")
    bpy.ops.object.mode_set(mode="OBJECT")

    mesh.parent = rig
    mod = mesh.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    # El armature debe ir antes que la subdivisión
    while mesh.modifiers.find("Armature") > 0:
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = mesh
        bpy.ops.object.modifier_move_up(modifier="Armature")
    return rig


def build_animations(rig):
    rig.animation_data_create()
    for pb in rig.pose.bones:
        pb.rotation_mode = "XYZ"

    def reset_pose():
        for pb in rig.pose.bones:
            pb.location = (0, 0, 0)
            pb.rotation_euler = (0, 0, 0)

    def key(bone, path, idx, frame, value):
        pb = rig.pose.bones[bone]
        getattr(pb, path)[idx] = value
        pb.keyframe_insert(data_path=path, index=idx, frame=frame)

    def new_action(name):
        reset_pose()
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        rig.animation_data.action = act
        return act

    def push_to_nla(act):
        track = rig.animation_data.nla_tracks.new()
        track.name = act.name
        track.strips.new(act.name, 1, act)
        rig.animation_data.action = None

    # --- Idle: respiración + balanceo de cabeza (48 frames) ---
    act = new_action("idle-loop")
    for f, bob, tilt, arm in [(1, 0, 0, 0), (13, 0.012, 0.06, 0.05),
                              (25, 0, 0, 0), (37, 0.012, -0.06, 0.05), (49, 0, 0, 0)]:
        key("body", "location", 1, f, bob)          # Y local = arriba
        key("head", "rotation_euler", 2, f, tilt)   # inclinación lateral
        key("arm.L", "rotation_euler", 2, f, arm)
        key("arm.R", "rotation_euler", 2, f, -arm)
    push_to_nla(act)

    # --- Walk: ciclo de 24 frames ---
    act = new_action("walk-loop")
    for f, s, bob in [(1, 0, 0.02), (7, 1, 0), (13, 0, 0.02), (19, -1, 0), (25, 0, 0.02)]:
        key("leg.L", "rotation_euler", 0, f, 0.55 * s)
        key("leg.R", "rotation_euler", 0, f, -0.55 * s)
        key("arm.L", "rotation_euler", 0, f, -0.45 * s)
        key("arm.R", "rotation_euler", 0, f, 0.45 * s)
        key("body", "location", 1, f, bob)
        key("head", "rotation_euler", 2, f, 0.04 * s)
    push_to_nla(act)
    reset_pose()


# ============================================================
# Props
# ============================================================
def build_tree(offset=(1.5, 0, 0)):
    ox, oy, oz = offset
    p = [part("Trunk", "taper", (0.11, 0.11, 0.35), (ox, oy, 0.35),
              material="bark", segs=8)]
    for i, (r, h, z) in enumerate([(0.50, 0.38, 0.95), (0.40, 0.32, 1.25), (0.24, 0.20, 1.50)]):
        p.append(part(f"Leaves{i}", "sphere", (r, r, h), (ox, oy, z),
                      material="leaves" if i % 2 == 0 else "leaves2", segs=10))
    tree = join(p, "Tree")
    soften(tree)
    return tree


def build_rock(offset=(-1.2, 0, 0), seed=7):
    random.seed(seed)
    old = CONFIG["faceted"]
    CONFIG["faceted"] = True  # las rocas quedan mejor siempre facetadas
    rock = part("Rock", "sphere", (0.35, 0.28, 0.22), (offset[0], offset[1], 0.15),
                material="stone", segs=7, jitter=0.18)
    CONFIG["faceted"] = old
    return rock


# ============================================================
# Main
# ============================================================
def main():
    clear_scene()
    mesh = build_character()
    rig = build_rig(mesh)
    build_animations(rig)
    export([rig, mesh], "critter.glb")

    tree = build_tree()
    export([tree], "tree.glb")

    rock = build_rock()
    export([rock], "rock.glb")
    print("Listo. Assets en:", CONFIG["export_dir"])


main()
