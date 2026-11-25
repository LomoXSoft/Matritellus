"""Generate three Manchego dog breeds (galgo, mastin, chucho) in Blender from
godot/assets/ajedrez/perro.glb (Quaternius Shiba Inu, CC0), preserving its
armature and all 12 animations, and render a quick side-by-side preview sheet.

Run with:
  blender --background --python tools/make_perros.py
"""
import math
import os
import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC = os.path.join(ROOT, "godot", "assets", "ajedrez", "perro.glb")
OUT_DIR = os.path.join(ROOT, "godot", "assets", "perros")
PREVIEW = os.path.join(ROOT, "tools", "perros_preview.png")


def _weight(v, vg_indices):
    w = 0.0
    for g in v.groups:
        if g.group in vg_indices:
            w += g.weight
    return min(1.0, w)


def _vgroups(obj, prefixes):
    out = set()
    for g in obj.vertex_groups:
        for p in prefixes:
            if g.name == p or g.name.startswith(p):
                out.add(g.index)
                break
    return out


def _clamp(val, lo=0.0, hi=1.0):
    return max(lo, min(hi, val))


def _set_mat_color(obj, name, rgba):
    for m in obj.data.materials:
        if m and m.name == name:
            m.use_nodes = True
            bsdf = m.node_tree.nodes.get("Principled BSDF")
            if bsdf:
                bsdf.inputs["Base Color"].default_value = rgba


def _ear_factor(v, ear_flap_vgs, ear_all_vgs):
    """Smooth 0..1 mask strictly on the protruding ear flap (never the skull crown!).
    Measured in ShibaInu local space: ear flaps start around |x| >= 0.0021, y <= -0.0284."""
    wf = _weight(v, ear_flap_vgs)
    wa = _weight(v, ear_all_vgs)
    if wf > 0.2:
        return _clamp(wf)
    if wa > 0.35 and abs(v.co.x) > 0.0020 and v.co.y < -0.0282:
        fx = _clamp((abs(v.co.x) - 0.0020) / 0.0008)
        fy = _clamp((-v.co.y - 0.0282) / 0.0010)
        return _clamp(wa * fx * fy)
    return 0.0


def _tail_factor(v, tail_tip_vgs, tail1_vg):
    """Smooth 0..1 mask along the tail past the rump (Tail2/Tail3 + outer Tail1)."""
    wt = _weight(v, tail_tip_vgs)
    if wt > 0.05:
        return _clamp(wt)
    w1 = _weight(v, tail1_vg)
    if w1 > 0.35 and v.co.z > 0.0108:
        return _clamp(w1 * (v.co.z - 0.0108) / 0.0012)
    return 0.0


def _deform_galgo(mesh_obj):
    """Tall, slender Manchego sighthound: tucked waist, deep narrow chest, long fine snout,
    swept-back rose ears, slender legs, long drooping whip tail."""
    ear_flap = _vgroups(mesh_obj, ["Ear2", "Ear3", "Ear4"])
    ear_all = _vgroups(mesh_obj, ["Ear"])
    head = _vgroups(mesh_obj, ["Head"])
    neck = _vgroups(mesh_obj, ["Neck"])
    tail_tip = _vgroups(mesh_obj, ["Tail2", "Tail3"])
    tail1 = _vgroups(mesh_obj, ["Tail1"])
    legs = _vgroups(mesh_obj, ["FrontUpperLeg", "FrontLowerLeg", "BackLeg", "BackUpperLeg", "BackLowerLeg", "FF", "IK"])
    torso = _vgroups(mesh_obj, ["Torso", "Back"])

    for v in mesh_obj.data.vertices:
        co = v.co.copy()
        we = _ear_factor(v, ear_flap, ear_all)
        wh = _weight(v, head)
        wn = _weight(v, neck)
        wt = _tail_factor(v, tail_tip, tail1)
        wl = _weight(v, legs)
        wb = _weight(v, torso)

        # In ShibaInu local space: x = left/right, -y = UP, -z = FORWARD (nose), +z = BACK (tail)
        # 1) Deep narrow chest + dramatic tucked sighthound waist
        if wb > 0.05 and wt < 0.2:
            if -0.013 < co.z < -0.002 and co.y > -0.017:
                t = math.sin(_clamp((co.z + 0.013) / 0.011) * math.pi)
                co.y += 0.0016 * t * wb
            if -0.002 < co.z < 0.0095 and co.y > -0.0175:
                t = math.sin(_clamp((co.z + 0.002) / 0.0115) * math.pi)
                belly = _clamp((co.y + 0.0175) / 0.007)
                co.y -= 0.0036 * t * belly * wb
                co.x *= 1.0 - 0.24 * t * wb

        # 2) Sleek narrow neck
        if wn > 0.05:
            co.x *= 1.0 - 0.16 * wn

        # 3) Slender sighthound head + elongated pointed muzzle (eyes at z=[-0.0207..-0.0198] untouched!)
        if wh > 0.05 and we < 0.1:
            co.x *= 1.0 - 0.12 * wh
            if co.z < -0.0208:
                snout = (-0.0208 - co.z) / 0.0035  # 0 just ahead of eyes -> ~1 at nose tip
                co.z -= 0.0038 * snout * wh
                co.x *= 1.0 - 0.24 * min(1.1, snout) * wh
                co.y = -0.0258 + (co.y + 0.0258) * (1.0 - 0.18 * min(1.1, snout) * wh)

        # 4) Swept-back rose ears (skull crown stays 100% round!)
        if we > 0.01:
            sx = 1.0 if co.x >= 0.0 else -1.0
            up = max(0.0, -0.0282 - co.y)
            new_x = abs(co.x) + up * 0.12
            new_y = -0.0282 + up * 0.45
            new_z = co.z + up * 1.45
            co.x = co.x * (1.0 - we) + sx * new_x * we
            co.y = co.y * (1.0 - we) + new_y * we
            co.z = co.z * (1.0 - we) + new_z * we

        # 5) Long slender drooping whip tail (uncurl Shiba's upward loop into a graceful downward arc)
        if wt > 0.01:
            # Measure how far along the curled tail this vertex is (base around y=-0.0185, z=0.011)
            arc = math.hypot(max(0.0, -0.0185 - co.y), max(0.0, co.z - 0.0105))
            # Map arc into a long downward-and-back whip curve
            new_x = co.x * 0.55
            new_y = -0.0182 + arc * 1.15
            new_z = 0.0110 + arc * 0.95
            co.x = co.x * (1.0 - wt) + new_x * wt
            co.y = co.y * (1.0 - wt) + new_y * wt
            co.z = co.z * (1.0 - wt) + new_z * wt

        # 6) Slimmer sinewy legs
        if wl > 0.15:
            sx = 1.0 if co.x >= 0.0 else -1.0
            cx = 0.0034
            co.x = sx * (cx + (abs(co.x) - cx) * (1.0 - 0.24 * wl))

        v.co = co


def _deform_mastin(mesh_obj):
    """Big, sturdy Manchego mastiff: broad chest, thick neck & jowls, big floppy hanging ears,
    stocky legs, plush drooping tail."""
    ear_flap = _vgroups(mesh_obj, ["Ear2", "Ear3", "Ear4"])
    ear_all = _vgroups(mesh_obj, ["Ear"])
    head = _vgroups(mesh_obj, ["Head"])
    neck = _vgroups(mesh_obj, ["Neck"])
    tail_tip = _vgroups(mesh_obj, ["Tail2", "Tail3"])
    tail1 = _vgroups(mesh_obj, ["Tail1"])
    legs = _vgroups(mesh_obj, ["FrontUpperLeg", "FrontLowerLeg", "BackLeg", "BackUpperLeg", "BackLowerLeg", "FF", "IK"])
    torso = _vgroups(mesh_obj, ["Torso", "Back"])

    for v in mesh_obj.data.vertices:
        co = v.co.copy()
        we = _ear_factor(v, ear_flap, ear_all)
        wh = _weight(v, head)
        wn = _weight(v, neck)
        wt = _tail_factor(v, tail_tip, tail1)
        wl = _weight(v, legs)
        wb = _weight(v, torso)

        # 1) Deep heavy barrel chest & sturdy back
        if wb > 0.05 and wt < 0.2:
            co.x *= 1.0 + 0.15 * wb
            if co.y > -0.017:
                co.y += 0.0018 * wb

        # 2) Thick dewlap neck
        if wn > 0.05:
            co.x *= 1.0 + 0.22 * wn
            if co.y > -0.022:
                co.y += 0.0020 * wn

        # 3) Broad blocky mastiff skull & deeper heavy muzzle (crown stays round!)
        if wh > 0.05 and we < 0.1:
            co.x *= 1.0 + 0.14 * wh
            if co.z < -0.0208:
                snout = (-0.0208 - co.z) / 0.0035
                co.z += 0.0009 * snout * wh
                co.x *= 1.0 + 0.22 * min(1.0, snout) * wh
                if co.y > -0.0258:
                    co.y += 0.0015 * min(1.0, snout) * wh

        # 4) Big floppy hanging ears alongside cheeks (strictly on ear flaps!)
        if we > 0.01:
            sx = 1.0 if co.x >= 0.0 else -1.0
            up = max(0.0, -0.0282 - co.y)
            new_x = max(abs(co.x), 0.0028) + up * 0.55
            new_y = -0.0278 + up * 1.65
            new_z = co.z + up * 0.25
            co.x = co.x * (1.0 - we) + sx * new_x * we
            co.y = co.y * (1.0 - we) + new_y * we
            co.z = co.z * (1.0 - we) + new_z * we

        # 5) Plush thicker hanging tail
        if wt > 0.01:
            arc = math.hypot(max(0.0, -0.0185 - co.y), max(0.0, co.z - 0.0105))
            new_x = co.x * 1.35
            new_y = -0.0182 + arc * 0.85
            new_z = 0.0110 + arc * 0.90
            co.x = co.x * (1.0 - wt) + new_x * wt
            co.y = co.y * (1.0 - wt) + new_y * wt
            co.z = co.z * (1.0 - wt) + new_z * wt

        # 6) Stockier legs
        if wl > 0.15:
            sx = 1.0 if co.x >= 0.0 else -1.0
            cx = 0.0034
            co.x = sx * (cx + (abs(co.x) - cx) * (1.0 + 0.26 * wl))

        v.co = co


def _deform_chucho(mesh_obj):
    """Lively compact street mutt: big expressive perky podenco-ish ears (with the right
    ear tip playfully folded forward), cute compact snout, cheerful high curled tail."""
    ear_flap = _vgroups(mesh_obj, ["Ear2", "Ear3", "Ear4"])
    ear_all = _vgroups(mesh_obj, ["Ear"])
    ear_r_tip = _vgroups(mesh_obj, ["Ear3.R", "Ear4.R"])
    head = _vgroups(mesh_obj, ["Head"])
    tail_tip = _vgroups(mesh_obj, ["Tail2", "Tail3"])
    tail1 = _vgroups(mesh_obj, ["Tail1"])

    for v in mesh_obj.data.vertices:
        co = v.co.copy()
        we = _ear_factor(v, ear_flap, ear_all)
        wer = _weight(v, ear_r_tip)
        wh = _weight(v, head)
        wt = _tail_factor(v, tail_tip, tail1)

        # 1) Slightly fuller cute head + slightly shorter compact snout
        if wh > 0.05 and we < 0.1:
            co.x *= 1.0 + 0.05 * wh
            if co.z < -0.0208:
                snout = (-0.0208 - co.z) / 0.0035
                co.z += 0.0008 * snout * wh

        # 2) Taller expressive ears, right ear tip playfully flopped forward!
        if we > 0.01:
            sx = 1.0 if co.x >= 0.0 else -1.0
            up = max(0.0, -0.0282 - co.y)
            new_x = abs(co.x) + up * 0.25
            new_y = -0.0282 - up * 1.55
            new_z = co.z
            if wer > 0.2 and co.x < 0.0:
                new_y += 0.0026 * wer
                new_z -= 0.0018 * wer
                new_x += 0.0008 * wer
            co.x = co.x * (1.0 - we) + sx * new_x * we
            co.y = co.y * (1.0 - we) + new_y * we
            co.z = co.z * (1.0 - we) + new_z * we

        # 3) Cheerful high curled tail
        if wt > 0.01:
            co.y -= 0.0010 * wt
            co.z -= 0.0006 * wt

        v.co = co


BREEDS = [
    ("galgo", (0.74, 1.18, 1.14), _deform_galgo, (0.44, 0.30, 0.17, 1.0), (0.70, 0.58, 0.42, 1.0)),
    ("mastin", (1.26, 1.08, 1.06), _deform_mastin, (0.58, 0.45, 0.27, 1.0), (0.84, 0.76, 0.62, 1.0)),
    ("chucho", (0.95, 0.84, 0.88), _deform_chucho, (0.38, 0.18, 0.07, 1.0), (0.78, 0.68, 0.54, 1.0)),
]


def build_breed(name, root_scale, deform_fn, col_main, col_light):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=SRC)

    ico = bpy.data.objects.get("Icosphere")
    if ico:
        bpy.data.objects.remove(ico, do_unlink=True)

    root = bpy.data.objects.get("RootNode")
    mesh_obj = bpy.data.objects.get("ShibaInu")
    assert root and mesh_obj, "Expected RootNode and ShibaInu in perro.glb"

    deform_fn(mesh_obj)
    mesh_obj.data.update()

    # Non-uniform breed proportion on RootNode (Blender Z-up: X=width, Y=length, Z=height)
    sx, sy_h, sz_l = root_scale
    root.scale = (sx, sz_l, sy_h)

    _set_mat_color(mesh_obj, "Main", col_main)
    _set_mat_color(mesh_obj, "Main_Light", col_light)

    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, f"{name}.glb")
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format="GLB",
        export_animations=True,
        export_materials="EXPORT",
        export_yup=True,
    )
    print(f"Exported {out_path} ({os.path.getsize(out_path)} bytes)")
    return out_path


def render_preview(paths):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1320
    scene.render.resolution_y = 540
    scene.render.filepath = PREVIEW

    world = bpy.data.worlds.new("W")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs["Color"].default_value = (0.78, 0.87, 0.96, 1.0)
        bg.inputs["Strength"].default_value = 0.85

    bpy.ops.mesh.primitive_plane_add(size=40.0, location=(0.0, 0.0, 0.0))
    plane = bpy.context.active_object
    mat = bpy.data.materials.new("Ground")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.72, 0.66, 0.56, 1.0)
    plane.data.materials.append(mat)

    bpy.ops.object.light_add(type="SUN", location=(6.0, -8.0, 12.0))
    sun = bpy.context.active_object
    sun.data.energy = 3.2
    sun.rotation_euler = (math.radians(48), math.radians(15), math.radians(28))

    # Place all 3 breeds in clean 3/4 side profile so ears, snouts, chests, waists & tails all show!
    xs = [-5.2, 0.0, 5.2]
    for idx, p in enumerate(paths):
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=p)
        added = [o for o in bpy.data.objects if o not in before]
        top = [o for o in added if o.parent is None]
        for o in top:
            o.location = (xs[idx], 0.0, 0.0)
            o.rotation_euler = (0.0, 0.0, math.radians(52))

    bpy.ops.object.camera_add(location=(0.0, -16.5, 4.2))
    cam = bpy.context.active_object
    cam.data.lens = 42.0
    direction = Vector((0.0, 0.0, 1.45)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam

    bpy.ops.render.render(write_still=True)
    print(f"Preview rendered to {PREVIEW}")


if __name__ == "__main__":
    out_paths = [build_breed(*spec) for spec in BREEDS]
    render_preview(out_paths)
