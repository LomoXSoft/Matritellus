"""Fits hair, beards, eyebrows and hats made for a human head (free models: tools/creador/piezas.json says which) onto
the head of Matritellus's people: a ball of 0.5 m round (0, 1.38, 0) in the character's frame (chara.gd), its big eyes
at 1.42, the cheeks at 1.27. The user, 16 November 2026: "Tenemos que importar assets de peinados, barbas y cejas ...
tienen que tener nuestra estética y ser de libre uso. Usa blender si lo necesitas para ajustarlos."

    blender.exe -b --python tools/creador/pelo.py -- tools/creador/piezas.json OUT_GLB_FOLDER [PREVIEW_FOLDER] [name ...]

How a piece is moved (Blender's axes: z up, the face to -y):
  - "pelo" / "barba" / "sombrero": every point is put on the ball by angles. Its height on the human head gives its
    elevation (the crown at the top, the eyes a little above the middle as ours are, the mouth and the chin further
    down the front than a human's: our faces are round), its place round the head gives its bearing, and how far it
    stands off the human's skin (the pack's own body, the nearest point of it) is how far it stands off the ball, in
    proportion. What hangs below the chin (long hair, a plait, a beard's point) hangs straight down from where the
    ball ends, kept out of the body (a cone: chara.gd _r).
  - "cejas": laid on the front of the ball over our eyes, by width and height.
Each piece is subdivided once (some packs are very blocky: our people are round) and smoothed, and written as
OUT/<name>.glb in the character's own frame (y up, the face to +z), with one material. A hairstyle also gets a second
mesh "gorro": the same without what a cap or a hat would cover (chara.gd uses it under a hat).
With PREVIEW_FOLDER: a picture of each, on a plain head and body, from the front and from behind.
"""
import bpy, bmesh, sys, os, json, math
from mathutils import Vector
from mathutils.bvhtree import BVHTree

args = sys.argv[sys.argv.index('--') + 1:]
SPEC = json.load(open(args[0], encoding='utf-8'))
OUT = args[1]
PREV = args[2] if len(args) > 2 and ('/' in args[2] or chr(92) in args[2]) else ''       # (a folder: it has a slash in it; otherwise it is a name)
ONLY = set(a for a in args[3 if PREV else 2:])
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(args[0]))))
C = Vector((0.0, 0.0, 1.38))          # the ball's middle (Blender: z up)
R = 0.5
EPS = 0.008
HAT_LINE = 1.6                        # under a hat, nothing of the hair above this (the cap's rim is at 1.6)
FILL_OFF = 0.008                      # how far off the ball the cap under the hair lies
HAT_LINE_HIGH = 1.7                   # ...or this, under a hat that sits higher (a straw hat, a beret)


def smoothstep(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def body_r(z):                        # chara.gd _r: the body is a cone, 0.44 at the foot (0.245) to 0.3 at the neck (0.995)
    return 0.44 - (z - 0.245) * 0.18667


def load_pack(pack, extra=None):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    path = os.path.join(ROOT, pack['dir'])
    for f in pack.get('files', []) + ([extra] if extra else []):
        p = os.path.join(path, f)
        if p.lower().endswith('.blend'):
            bpy.ops.wm.open_mainfile(filepath=p)
        elif p.lower().endswith(('.gltf', '.glb')):
            bpy.ops.import_scene.gltf(filepath=p)
        elif p.lower().endswith('.fbx'):
            bpy.ops.import_scene.fbx(filepath=p)


def world_mesh(o):
    """the object's mesh in world space, with its modifiers, as a new bmesh"""
    o.hide_viewport = False
    o.hide_render = False
    try:
        o.hide_set(False)
    except Exception:
        pass
    for c in o.users_collection:
        c.hide_viewport = False
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    ev = o.evaluated_get(dg)
    me = ev.to_mesh()
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.transform(o.matrix_world)
    ev.to_mesh_clear()
    return bm


def skin_tree(pack):
    o = bpy.data.objects[pack['skin']]
    bm = world_mesh(o)
    return BVHTree.FromBMesh(bm)


def elev(z, p, kind):
    """the elevation (radians) on the ball for a height z on the human head: piecewise by its marks"""
    keys = [(p['crown'], 90.0), (p['eye'], p.get('el_eye_' + kind, p.get('el_eye', 10.0))), (p['mouth'], -14.0), (p['chin'], -44.0)]
    if z >= keys[0][0]:
        return math.radians(90.0)
    for (z0, a0), (z1, a1) in zip(keys, keys[1:]):
        if z1 <= z <= z0:
            t = (z0 - z) / (z0 - z1)
            if z0 == p['crown']:
                t = t ** p.get('crown_ease', 1.0)
            return math.radians(a0 + (a1 - a0) * t)
    return math.radians(-44.0)


def put_on_ball(v, tree, p, kind, k_t):
    """where a point of a piece made for the human head goes on ours"""
    u = v.x / p['half_w']
    w = (v.y - p['cy']) / p['half_d']
    bearing = math.atan2(u, -w)                   # 0 at the front, + to the character's left (x+)
    hit = tree.find_nearest(v)
    t = 0.0
    if hit[0] is not None:
        d = v - hit[0]
        t = d.length if d.dot(hit[1]) >= 0.0 else -d.length
    far = max(t, 0.0) / p['half_w']                  # how far off the skin, in heads
    t = max(t, 0.0) * k_t
    z = v.z
    below = max(0.0, p['chin'] - z) if kind != 'cejas' else 0.0
    el = elev(min(max(z, p['chin']), 99.0), p, kind)
    rr = R + p.get('eps', EPS) + t
    pos = C + Vector((math.cos(el) * math.sin(bearing), -math.cos(el) * math.cos(bearing), math.sin(el))) * rr
    # What stands well off the head (a ponytail, a bun, a plait) keeps its own shape: put on by angles it would be
    # stretched round the ball, our heads being rounder than a human's. So the further off, the more it is just the
    # piece made bigger, from the middle of the head.
    k_far = smoothstep(p.get('far0', 0.15), p.get('far1', 0.6), far)
    if k_far > 0.0 and kind in ('pelo', 'sombrero'):
        zc = p['eye'] + (p['crown'] - p['eye']) * p.get('far_zc', 0.35)
        dz = v.z - zc
        if v.z < p['chin']:                          # (down the back: a human's hair is long for a head as big as ours)
            dz = (p['chin'] - zc) + (v.z - p['chin']) * p.get('far_drop', 0.4)
        if kind == 'pelo' and p.get('far_excess'):   # scale ONLY protrusion beyond the skull R, never squashing buns/afros flat into the head
            k_base = R / p['half_w']
            raw = Vector((v.x * k_base, (v.y - p['cy']) * k_base, dz * k_base))
            rl = raw.length
            if rl > R:
                same = C + raw.normalized() * (R + (rl - R) * p.get('far_k', 0.95))
            else:
                same = C + raw
        else:
            k_u = R / p['half_w'] * p.get('far_k', 0.95)
            same = C + Vector((v.x * k_u, (v.y - p['cy']) * k_u, dz * k_u))
        out = same - C
        if out.length < R + p.get('eps', EPS):
            same = C + out.normalized() * (R + p.get('eps', EPS))
        pos = pos.lerp(same, k_far)
        below = 0.0 if pos.z > 1.0 else below
    if below > 0.0:                                  # hanging below the chin: straight down from where the ball ends
        pos.z -= below * p.get('drop', 4.0)
        flat = Vector((pos.x, pos.y, 0.0))
        need = body_r(pos.z) + EPS + t if pos.z < 1.0 else 0.0
        if flat.length < need:
            flat = flat.normalized() * need if flat.length > 1e-6 else Vector((0.0, need, 0.0))
            pos.x, pos.y = flat.x, flat.y
    if not p.get('clean_drop'):
        low = p.get('lowest', 0.55)                  # (nothing down past the hips: the hands hang at 0.68)
        if pos.z < low + 0.15:
            pos.z = low + 0.15 * math.exp((pos.z - low - 0.15) / 0.15)
    return pos


def refine_pelo(bm, p):
    """Post-fit silhouette and base refinement for hair pieces (Matritellus 0.0.22):
    - Keeps the skull fit tight while scaling down excessive outer volume and width.
    - Prevents horizontal ducktail shelves on long hair by draping proportionally down the back.
    - Clears the hands zone (|x|~0.46, z~0.68) and compresses jutting front visors.
    - Applies controlled Laplacian smoothing on interior verts and enforces skull/body clearance.
    """
    eps = p.get('eps', EPS)
    vol_scale = p.get('vol_scale', 1.0)
    scale_x = p.get('scale_x', 1.0)
    front_max = p.get('front_max', None)
    back_max = p.get('back_max', None)
    z_min = p.get('z_min', None)
    drape_back = p.get('drape_back', None)
    side_back = p.get('side_back', 0.0)
    round_k = p.get('round_k', 0.0)
    round_r = p.get('round_r', 0.63)
    front_strand_z = p.get('front_strand_z', None)
    smooth_passes = p.get('smooth_passes', 0)

    # 1. Volume, width, visor and roundness shaping (acts only on excess outside R + eps)
    min_z_cur = min((v.co.z for v in bm.verts), default=1.0)
    hinge_z = p.get('hinge_z', 1.16)
    for v in bm.verts:
        co = v.co
        d = co - C
        r = d.length
        if r > R + eps:
            # Radial thickness scale above the base skull
            if vol_scale != 1.0:
                extra = (r - (R + eps)) * vol_scale
                d = d.normalized() * (R + eps + extra)
            # Roundness blend for afro/fluffy silhouettes
            if round_k > 0.0:
                rc = Vector((0.0, 0.04, 1.44))
                rd = (C + d) - rc
                if rd.length > R + eps:
                    target = rc + rd.normalized() * min(rd.length, round_r)
                    d = (C + d).lerp(target, round_k) - C
            # Width clamp outside the skull radius (smooth onset from 0.36..0.50)
            if scale_x != 1.0 and abs(d.x) > 0.36:
                sgn = 1.0 if d.x >= 0.0 else -1.0
                ax = abs(d.x)
                w = smoothstep(0.36, R, ax)
                target_x = R + (ax - R) * scale_x if ax > R else ax
                d.x = sgn * (ax + (target_x - ax) * w)
            # Prevent forward visor overhang (face is -y in Blender)
            if front_max is not None and -d.y > front_max:
                d.y = -(front_max + (-d.y - front_max) * 0.18)
            # Prevent backward protrusion above the nape (buns, poufs)
            if back_max is not None and d.y > back_max and (C.z + d.z) >= 1.12:
                d.y = back_max + (d.y - back_max) * 0.25
            co = C + d

        # 2. Front loose strands (e.g. feathered/curtain bangs): keep near chin height, not floating to hips
        if front_strand_z is not None and co.y < 0.05 and co.z < 1.25:
            if co.z < front_strand_z:
                co.z = front_strand_z - (front_strand_z - co.z) * 0.18
            # Pull floating front strands gently closer to cheek/neck silhouette
            flat_xy = Vector((co.x, co.y))
            want_r = R + 0.06 if co.z >= 1.05 else body_r(max(co.z, 0.35)) + 0.10
            if flat_xy.length > want_r:
                flat_xy = flat_xy.normalized() * (want_r + (flat_xy.length - want_r) * 0.35)
                co.x, co.y = flat_xy.x, flat_xy.y

        # 3. Proportional shortening of hanging hair below hinge_z (no horizontal ducktail shelf!)
        if z_min is not None and min_z_cur < z_min and co.z < hinge_z:
            span = max(hinge_z - min_z_cur, 1e-4)
            new_span = max(hinge_z - z_min, 0.05)
            co.z = hinge_z - (hinge_z - co.z) * (new_span / span)

        # 4. Vertical back draping below the skull: keep tails/braids/waves flowing down the back
        if drape_back is not None and co.z < hinge_z:
            k_down = smoothstep(hinge_z, hinge_z - 0.26, co.z)
            max_back_y = body_r(max(co.z, 0.35)) + drape_back
            if co.y > max_back_y:
                co.y = co.y + (max_back_y + (co.y - max_back_y) * 0.20 - co.y) * k_down
            if back_max is not None and co.y > back_max:
                co.y = back_max + (co.y - back_max) * 0.22

        # 5. Clear the hands zone (|x| ~ 0.46, z ~ 0.68) by sweeping low side locks slightly backward
        if side_back > 0.0 and co.z < 1.08 and abs(co.x) > 0.24 and co.y < 0.25:
            k_h = smoothstep(1.08, 0.78, co.z) * smoothstep(0.24, 0.42, abs(co.x))
            co.y += side_back * k_h

        v.co = co

    # 6. Controlled Laplacian smoothing on interior vertices (eliminates crown pinches and dirty outlines)
    if smooth_passes > 0:
        inner = [v for v in bm.verts if not v.is_boundary]
        for _ in range(smooth_passes):
            bmesh.ops.smooth_vert(bm, verts=inner, factor=0.30,
                                  use_axis_x=True, use_axis_y=True, use_axis_z=True)

    # 6b. Prevent flat low-poly chords from dipping into the R=0.50 sphere: split only overly long edges near the head
    max_edge = p.get('max_edge', 0.16)
    if max_edge > 0.0:
        long_edges = [e for e in bm.edges if e.calc_length() > max_edge and (e.verts[0].co.z >= 0.95 or e.verts[1].co.z >= 0.95)]
        if long_edges:
            bmesh.ops.subdivide_edges(bm, edges=long_edges, cuts=1, use_grid_fill=True, smooth=0.35)

    # 7. Final skull, eyes, and torso clearance pass (zero clipping, including chord clearance)
    min_head_r = R + max(eps, p.get('head_eps', 0.022))
    for v in bm.verts:
        co = v.co
        d = co - C
        if co.z >= 1.02 and d.length < min_head_r:
            co = C + d.normalized() * min_head_r
        elif co.z < 1.02:
            xy = Vector((co.x, co.y))
            need = body_r(max(co.z, 0.25)) + eps
            if xy.length < need and xy.length > 1e-5:
                xy = xy.normalized() * need
                co.x, co.y = xy.x, xy.y
        v.co = co


def refine_barba(bm, p):
    """Post-fit silhouette and cheek/sideburn refinement for beard pieces (Matritellus 0.0.22):
    - Pulls floating sideburn wings snugly against the R=0.50 sphere (no wide horns sticking out the sides).
    - Compresses excessive forward protrusion on mustaches/goatees and rounds overly sharp chin spikes.
    - Applies controlled interior smoothing and guarantees zero clipping into the head or shirt.
    """
    eps = p.get('eps', EPS)
    cheek_off = p.get('cheek_off', None)
    sideburn_top = p.get('sideburn_top', None)
    front_max = p.get('front_max', None)
    z_min = p.get('z_min', None)
    hinge_z = p.get('hinge_z', 1.12)
    smooth_passes = p.get('smooth_passes', 0)

    min_z_cur = min((v.co.z for v in bm.verts), default=1.0)
    for v in bm.verts:
        co = v.co
        d = co - C
        r = d.length
        bearing = abs(math.atan2(d.x, -d.y))          # 0 front, pi/2 sides
        # 1. Hug cheeks and sideburns to the sphere so beards never sprout sideways wings
        if cheek_off is not None and bearing > 0.55 and r > R + eps:
            k_side = smoothstep(0.55, 1.05, bearing)
            target_off = cheek_off
            if sideburn_top is not None and co.z > sideburn_top:
                k_top = smoothstep(sideburn_top, sideburn_top + 0.14, co.z)
                target_off = cheek_off + (eps - cheek_off) * k_top
                # keep sideburn tips from climbing past the temples
                co.z = sideburn_top + (co.z - sideburn_top) * 0.55
                d = co - C
                r = d.length
            want_r = R + target_off
            if r > want_r:
                new_r = r + (want_r + (r - want_r) * 0.18 - r) * k_side
                d = d.normalized() * new_r
                co = C + d
        # 2. Prevent overly jutting front blocks on mustaches/beards (face is -y in Blender)
        if front_max is not None and -co.y > front_max:
            co.y = -(front_max + (-co.y - front_max) * 0.20)
        # 3. Softly shorten overly long/spiky chin tips without flattening horizontally
        if z_min is not None and min_z_cur < z_min and co.z < hinge_z:
            span = max(hinge_z - min_z_cur, 1e-4)
            new_span = max(hinge_z - z_min, 0.05)
            co.z = hinge_z - (hinge_z - co.z) * (new_span / span)
        v.co = co

    if smooth_passes > 0:
        inner = [v for v in bm.verts if not v.is_boundary]
        for _ in range(smooth_passes):
            bmesh.ops.smooth_vert(bm, verts=inner, factor=0.28,
                                  use_axis_x=True, use_axis_y=True, use_axis_z=True)

    # Final skull & torso clearance
    min_head_r = R + eps
    for v in bm.verts:
        co = v.co
        d = co - C
        if co.z >= 1.00 and d.length < min_head_r:
            co = C + d.normalized() * min_head_r
        elif co.z < 1.00:
            xy = Vector((co.x, co.y))
            need = body_r(max(co.z, 0.25)) + eps
            if xy.length < need and xy.length > 1e-5:
                xy = xy.normalized() * need
                co.x, co.y = xy.x, xy.y
        v.co = co


def refine_cuerpo(bm, p):
    """Post-fit silhouette, shoulder, hand-clearance and head-clearance refinement for clothes (Matritellus 0.0.22):
    - Pulls open shoulder/armhole rims snugly onto the torso cone so cut sleeves never flare into wings/funnels.
    - Clamps excessive lower bell/puffer ballooning and clears the hands zone (|x|~0.46, z~0.68).
    - Prevents collars/turtlenecks from penetrating the head sphere (C=(0,0,1.38), R=0.50).
    - Optionally lifts secondary detail surfaces (e.g. hoodie drawstrings) slightly above the primary cloth.
    """
    eps = p.get('eps', EPS)
    max_off = p.get('max_off', 0.045)
    shoulder_off = p.get('shoulder_off', 0.020)
    z_max = p.get('z_max', 0.99)
    z_min = p.get('z_min', 0.255)
    keep_hood_back = p.get('keep_hood_back', False)
    turtleneck = p.get('turtleneck', False)
    clear_head = p.get('clear_head', True)
    detail_lift = float(p.get('detail_lift', 0.0))
    smooth_passes = p.get('smooth_passes', 0)
    smooth_armhole = p.get('smooth_armhole', False)
    stretch_top = p.get('stretch_top', None)
    uniform_base = p.get('uniform_base', None)
    ripple_gain = float(p.get('ripple_gain', 0.0))
    uniform_max = float(p.get('uniform_max', max_off))
    skirt_flare = float(p.get('skirt_flare', 0.0))
    button_below_z = p.get('button_below_z', None)

    # 0a. Optionally button open-front jackets closed below button_below_z (keeps upper lapel V open)
    if button_below_z is not None and bm.verts:
        bz = float(button_below_z)
        front_vs = [v for v in bm.verts if v.co.y < -0.05 and v.link_faces and any(f.material_index == 0 for f in v.link_faces)]
        if front_vs:
            orig_ang = {v: math.atan2(v.co.x, -v.co.y) for v in front_vs}
            orig_z = {v: v.co.z for v in front_vs}
            def gap_ang_at(zq):
                sub = [abs(orig_ang[v]) for v in front_vs if abs(orig_z[v] - zq) < 0.08]
                return min(sub) if sub else 0.0
            for v in front_vs:
                vz = orig_z[v]
                if vz < bz + 0.06:
                    k_close = smoothstep(bz + 0.06, bz - 0.05, vz)
                    ang = orig_ang[v]
                    a = abs(ang)
                    if a < 1.35:
                        gap = gap_ang_at(vz)
                        if gap > 0.005:
                            t = max(0.0, min(1.0, (a - gap) / max(0.25, 1.35 - gap)))
                            target_a = t * 1.35
                            new_a = a + (target_a - a) * k_close
                            sgn = 1.0 if ang >= 0.0 else -1.0
                            r_xy = math.hypot(v.co.x, v.co.y)
                            v.co.x = math.sin(sgn * new_a) * r_xy
                            v.co.y = -math.cos(sgn * new_a) * r_xy

    # 0. Optionally stretch garments whose source top sits mid-chest up to the neck
    if stretch_top is not None and bm.verts:
        z_lo = min(v.co.z for v in bm.verts)
        z_hi = max(v.co.z for v in bm.verts)
        if z_hi > z_lo + 0.05 and z_hi < stretch_top:
            for v in bm.verts:
                old_z = v.co.z
                br_old = body_r(min(max(old_z, 0.245), 0.995))
                xy = Vector((v.co.x, v.co.y))
                off = xy.length - br_old
                new_z = z_lo + (old_z - z_lo) / (z_hi - z_lo) * (stretch_top - z_lo)
                br_new = body_r(min(max(new_z, 0.245), 0.995))
                if xy.length > 1e-5:
                    xy = xy.normalized() * max(br_new + eps, br_new + off)
                    v.co.x, v.co.y = xy.x, xy.y
                v.co.z = new_z

    # 0b. Optional 360-degree uniform silhouette with preserved local relief (e.g. quilted puffer ribs, fitted striped tee)
    if uniform_base is not None and bm.verts:
        raw_off = {}
        for v in bm.verts:
            br = body_r(min(max(v.co.z, 0.245), 0.995))
            raw_off[v] = Vector((v.co.x, v.co.y)).length - br
        sm_off = dict(raw_off)
        if ripple_gain > 0.0:
            for _ in range(3):
                nxt = {}
                for v in bm.verts:
                    nbs = [e.other_vert(v) for e in v.link_edges]
                    nxt[v] = 0.5 * sm_off[v] + 0.5 * (sum(sm_off[u] for u in nbs) / len(nbs)) if nbs else sm_off[v]
                sm_off = nxt
        for v in bm.verts:
            co = v.co
            if co.z > z_max:
                co.z = z_max + (co.z - z_max) * 0.15
            if co.z < z_min:
                co.z = z_min - (z_min - co.z) * 0.15
            br = body_r(min(max(co.z, 0.245), 0.995))
            xy = Vector((co.x, co.y))
            if xy.length > 1e-5:
                detail = (raw_off[v] - sm_off[v]) * ripple_gain if ripple_gain > 0.0 else 0.0
                flare = skirt_flare * smoothstep(0.60, 0.24, co.z) if skirt_flare > 0.0 else 0.0
                want = max(eps, min(uniform_max + flare, float(uniform_base) + flare + detail))
                xy = xy.normalized() * (br + want)
                co.x, co.y = xy.x, xy.y
            v.co = co
    else:
        for v in bm.verts:
            co = v.co
            # 1. Clamp vertical bounds softly (no collars climbing into chin, no hems dipping under feet)
            if co.z > z_max:
                co.z = z_max + (co.z - z_max) * 0.15
            if co.z < z_min:
                co.z = z_min - (z_min - co.z) * 0.15
            br = body_r(min(max(co.z, 0.245), 0.995))
            xy = Vector((co.x, co.y))
            r_xy = xy.length
            if r_xy > 1e-5:
                # 2. Clamp excessive outer ballooning (Michelin/bell skirts), while preserving folded hoodie back
                is_hood = keep_hood_back and co.z > 0.74 and co.y > 0.04
                cap_off = 0.11 if is_hood else max_off
                if r_xy > br + cap_off:
                    new_r = br + cap_off + (r_xy - (br + cap_off)) * 0.22
                    xy = xy.normalized() * new_r
                    r_xy = new_r
                # 3. Tuck open shoulder/armhole rims above z=0.80 onto the cone (eliminates side funnels/wings)
                if co.z > 0.80 and not is_hood and not turtleneck:
                    k_sh = smoothstep(0.80, 0.95, co.z)
                    want_r = br + shoulder_off
                    if r_xy > want_r:
                        new_r = r_xy + (want_r + (r_xy - want_r) * 0.15 - r_xy) * k_sh
                        xy = xy.normalized() * new_r
                        r_xy = new_r
                # 4. Clear hands zone (|x| ~ 0.46, y ~ 0, z ~ 0.68, hand radius 0.12)
                if 0.52 <= co.z <= 0.84 and abs(co.y) < 0.18 and abs(co.x) > br * 0.75:
                    k_h = smoothstep(0.18, 0.06, abs(co.y)) * (1.0 - abs(co.z - 0.68) / 0.16)
                    k_h = max(0.0, min(1.0, k_h))
                    want_h = br + eps + 0.006
                    if r_xy > want_h:
                        new_r = r_xy + (want_h - r_xy) * (0.85 * k_h)
                        xy = xy.normalized() * new_r
                co.x, co.y = xy.x, xy.y
            v.co = co

    # 5. Controlled smoothing on interior vertices (preserves hems, necklines and material borders)
    if smooth_passes > 0:
        inner = [v for v in bm.verts if not v.is_boundary and len({f.material_index for f in v.link_faces}) == 1]
        for _ in range(smooth_passes):
            bmesh.ops.smooth_vert(bm, verts=inner, factor=0.25,
                                  use_axis_x=True, use_axis_y=True, use_axis_z=True)
    if smooth_armhole:
        arm = [v for v in bm.verts if v.is_boundary and abs(v.co.x) > 0.25 and 0.52 < v.co.z < 0.94]
        for _ in range(2):
            bmesh.ops.smooth_vert(bm, verts=arm, factor=0.35,
                                  use_axis_x=True, use_axis_y=True, use_axis_z=True)
    if p.get('close_armholes'):
        # cap cut-sleeve armholes on sleeved jackets so no white undershirt hole shows on the side
        b_edges = {e for e in bm.edges if e.is_boundary and len(e.link_faces) == 1 and e.link_faces[0].material_index == 0}
        visited = set()
        for e0 in list(b_edges):
            if e0 in visited:
                continue
            loop_e = []
            cur = e0
            while cur and cur not in visited:
                visited.add(cur)
                loop_e.append(cur)
                nxt = None
                for v in cur.verts:
                    for ne in v.link_edges:
                        if ne in b_edges and ne not in visited:
                            nxt = ne
                            break
                    if nxt:
                        break
                cur = nxt
            lvs = list({v for e in loop_e for v in e.verts})
            if len(lvs) >= 4:
                cx = sum(v.co.x for v in lvs) / len(lvs)
                cz = sum(v.co.z for v in lvs) / len(lvs)
                if abs(cx) > 0.28 and 0.55 < cz < 0.94:
                    cy = sum(v.co.y for v in lvs) / len(lvs)
                    br = body_r(min(max(cz, 0.245), 0.995))
                    xy = Vector((cx, cy))
                    if xy.length > 1e-5:
                        xy = xy.normalized() * (br + eps + 0.014)
                    cv = bm.verts.new(Vector((xy.x, xy.y, cz)))
                    for e in loop_e:
                        f0 = e.link_faces[0]
                        v1, v2 = e.verts[0], e.verts[1]
                        # match winding with adjacent face so normal points outward
                        el = [l for l in f0.loops if l.edge == e][0]
                        va, vb = el.vert, el.link_loop_next.vert
                        try:
                            nf = bm.faces.new((vb, va, cv))
                            nf.material_index = f0.material_index
                            nf.smooth = True
                        except ValueError:
                            pass

    # 6. Split overly long edges so coarse subd:0 quads never sag into the curved torso cone
    max_edge = p.get('max_edge', 0.16)
    if max_edge > 0.0:
        long_edges = [e for e in bm.edges if e.calc_length() > max_edge]
        if long_edges:
            bmesh.ops.subdivide_edges(bm, edges=long_edges, cuts=1, use_grid_fill=True, smooth=0.25)

    # 7. Lift detail-only vertices (e.g. hoodie strings, hi-vis stripes, front tie) slightly off the majority cloth material
    layer_lifts = p.get('layer_lifts')
    if layer_lifts:
        front_only = p.get('lift_front_only', False)
        for v in bm.verts:
            if v.link_faces:
                if front_only and v.co.y > -0.04:
                    continue
                lift = max(float(layer_lifts[f.material_index]) for f in v.link_faces if f.material_index < len(layer_lifts))
                if lift > 0.0:
                    xy = Vector((v.co.x, v.co.y))
                    if xy.length > 1e-5:
                        xy = xy + xy.normalized() * lift
                        v.co.x, v.co.y = xy.x, xy.y
    elif detail_lift > 0.0:
        mcounts = {}
        for f in bm.faces:
            mcounts[f.material_index] = mcounts.get(f.material_index, 0) + 1
        main_mat = max(mcounts, key=mcounts.get) if mcounts else 0
        for v in bm.verts:
            if v.link_faces and all(f.material_index != main_mat for f in v.link_faces):
                xy = Vector((v.co.x, v.co.y))
                if xy.length > 1e-5:
                    xy = xy + xy.normalized() * detail_lift
                    v.co.x, v.co.y = xy.x, xy.y

    # 8. Final torso & head clearance pass (zero clipping into body cone or head sphere)
    for v in bm.verts:
        co = v.co
        br = body_r(min(max(co.z, 0.245), 0.995))
        xy = Vector((co.x, co.y))
        need = br + eps
        if xy.length < need and xy.length > 1e-5:
            xy = xy.normalized() * need
            co.x, co.y = xy.x, xy.y
        if clear_head and co.z > 0.90:
            d = co - C
            if d.length < R + 0.008:
                if turtleneck:
                    # flare high collar neatly around the chin/neck seam instead of crushing it flat
                    dz = max(0.05, C.z - co.z)
                    need_r = math.sqrt(max(0.0, (R + 0.012) ** 2 - dz * dz))
                    if xy.length < need_r and xy.length > 1e-5:
                        xy = xy.normalized() * need_r
                        co.x, co.y = xy.x, xy.y
                else:
                    # drop cleanly to below the chin/neck seam rather than inflating into the cheeks
                    max_z = C.z - math.sqrt(max(0.0, (R + 0.008) ** 2 - co.x * co.x - co.y * co.y))
                    co.z = min(co.z, max_z)
        v.co = co


def base_colour(m):
    """a material's own colour (its Principled BSDF's, or its viewport colour)"""
    if m is None:
        return (0.5, 0.5, 0.5, 1.0)
    if m.use_nodes and m.node_tree:
        for n in m.node_tree.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                c = n.inputs['Base Color'].default_value
                return (c[0], c[1], c[2], 1.0)
    c = m.diffuse_color
    return (c[0], c[1], c[2], 1.0)


def put_on_body(v, tree, p, k_t):
    """clothes: from the human's chest and back onto our body, a cone (chara.gd _r), by bearing and height; what stands
    off the skin stands off the cone in proportion"""
    u = v.x / p['torso_half_w']
    w = (v.y - p['torso_cy']) / p['torso_half_d']
    bearing = math.atan2(u, -w)
    hit = tree.find_nearest(v)
    t = 0.0
    if hit[0] is not None:
        d = v - hit[0]
        t = max(0.0, d.length if d.dot(hit[1]) >= 0.0 else -d.length) * k_t
    top, bottom = p.get('body_top', 0.97), p.get('body_bottom', 0.27)
    h = (p['neck'] - v.z) / (p['neck'] - p['waist'])
    yz = top - h * (top - bottom)
    if v.z > p['neck']:                               # a collar or a hood, up the neck: into the head (it is round there)
        yz = top + (v.z - p['neck']) * p.get('up_k', 0.8)
    rr = (body_r(min(yz, 0.995)) if yz < 0.995 else 0.3) + p.get('eps', EPS) + t
    if yz < 0.25:
        yz = 0.25 - (0.25 - yz) * 0.3
    return Vector((math.sin(bearing) * rr, -math.cos(bearing) * rr, yz))


def layers(bm, off_skin):
    """Clothes of one colour (the user, 16 Nov 2026: "Algunas ropas necesitan más de un color plano para diferenciarse
    las distintas capas y partes que tienen"): what stands further off the skin than the rest -- a collar, a hood lying
    on the back, a pocket, the bands of a quilted vest, a lapel -- keeps the colour as chosen; what lies underneath goes
    darker, by degrees (a tone per point, multiplied into the colour with the shading of the folds: dirt)."""
    vals = sorted(off_skin.values())
    if len(vals) < 20:
        return {}
    lo = vals[int(len(vals) * 0.3)]
    hi = vals[int(len(vals) * 0.92)]
    if hi - lo < 1e-4:
        return {}
    tone = {v: 0.8 + 0.2 * min(1.0, max(0.0, (off_skin.get(v, lo) - lo) / (hi - lo))) for v in bm.verts}
    return smooth_values(tone, 3)


def smooth_values(val, passes):
    """each point's value evened out with its neighbours' (so that a shade comes in by degrees, not in blotches)"""
    for _ in range(passes):
        nxt = {}
        for v, x in val.items():
            near = [val[e.other_vert(v)] for e in v.link_edges if e.other_vert(v) in val]
            nxt[v] = (x + sum(near)) / (1 + len(near)) if near else x
        val = nxt
    return val


def fill_scalp(bm, p):
    """Under the hair, a cap of the hair's colour where it grows (the user: "hay algunos peinados que deja calvas"):
    the ball, a hair's breadth out, wherever hair lies close on the head, a little round it too"""
    from mathutils.kdtree import KDTree
    near = R + p.get('eps', EPS) + 0.07
    roots = [(v.co - C).normalized() for v in bm.verts if (v.co - C).length < near and v.co.z > 1.12]
    if not roots:
        return
    kd = KDTree(len(roots))
    for i, d in enumerate(roots):
        kd.insert(d, i)
    kd.balance()
    reach = 2.0 * math.sin(math.radians(p.get('fill_deg', 14.0)) / 2.0)
    cap = bmesh.new()
    bmesh.ops.create_uvsphere(cap, u_segments=32, v_segments=18, radius=R + 0.012)
    # Where the hair grows close on the head, and the crown all round: but never down the forehead, where under a fringe
    # it showed as a band with a straight edge, "un gorro de piscina debajo del pelo" (the user, 16 Nov 2026). In front
    # it stops up at the hairline; down the sides and the back it goes as far as the hair does (never peeking under the nape).
    # Low-poly 32x18 stays safely outside R=0.50 without chord sag while saving ~2300 hidden tris per hairpiece vs 96x48.
    def lowest(v):                                  # how far down it may come here (elevation, degrees), by the bearing round the head
        d = v.co.normalized()
        front = max(0.0, -d.y / max(1e-6, math.hypot(d.x, d.y)))          # 1 straight ahead, 0 at the sides and behind
        return p.get('fill_back', 12.0) + (p.get('fill_front', 36.0) - p.get('fill_back', 12.0)) * front ** 1.5
    def elev(v):
        return math.degrees(math.asin(max(-1.0, min(1.0, v.co.normalized().z))))
    def ok(v):
        e = elev(v)
        if e < lowest(v) or v.co.z < -0.3:
            return False
        if e >= lowest(v) + p.get('fill_top', 16.0):
            return True
        hits = kd.find_range(v.co.normalized(), reach)
        if len(hits) >= 1:
            min_hair_e = min(math.degrees(math.asin(max(-1.0, min(1.0, h[0].z)))) for h in hits)
            return e >= min_hair_e + 1.5
        return False
    covered = {v: ok(v) for v in cap.verts}
    gone = [f for f in cap.faces if not all(covered[v] for v in f.verts)]      # (only inside where the hair is: its edge stays the hair's own)
    bmesh.ops.delete(cap, geom=gone, context='FACES')
    bmesh.ops.translate(cap, verts=cap.verts[:], vec=C)
    col = cap.loops.layers.color.new('Col')
    for f in cap.faces:
        f.smooth = True
        f.material_index = 0
        for lp in f.loops:
            lp[col] = (0.92, 0.92, 0.92, 1.0)       # (the hair's own colour, as shaded as the hair round it: it is not a cap of its own)
    me = bpy.data.meshes.new('cap')
    cap.to_mesh(me)
    bm.from_mesh(me)


def dirt(bm, tone=None):
    """Shade in the folds and where one layer meets another, as a vertex colour the game multiplies in (Blender's own
    "dirty vertex colours", done by hand): a point whose neighbours stand out in front of it is darker. `tone`: a
    further shade for each point (layers)"""
    tone = tone or {}
    for group in (bm.loops.layers.color, bm.loops.layers.float_color, bm.verts.layers.color, bm.verts.layers.float_color):
        for old in list(group.values()):              # (the pack's own colour layers: the game reads the first one only, and that is ours)
            group.remove(old)
    col = bm.loops.layers.color.new('Col')
    bm.normal_update()
    shade = {}
    for v in bm.verts:
        if not v.link_edges:
            shade[v] = 1.0
            continue
        s = 0.0
        for e in v.link_edges:
            o = e.other_vert(v)
            d = o.co - v.co
            if d.length > 1e-6:
                s += d.normalized().dot(v.normal)
        s /= len(v.link_edges)
        shade[v] = min(1.0, max(0.68, 1.0 - max(0.0, s) * 1.3))
    shade = smooth_values(shade, 2)
    for f in bm.faces:
        for lp in f.loops:
            k = shade[lp.vert] * tone.get(lp.vert, 1.0)
            lp[col] = (k, k, k, 1.0)


def put_hat(bm, p):
    """a hat with a brim (a fedora, a bowler, a flat cap): a stiff thing, made bigger all of a piece, its lowest edge at
    the height of our caps' rim, and pushed off the ball wherever it would go into it. Not as tall as it would come out:
    its crown down near the top of our heads (the user, 16 Nov 2026: "Otros sombreros están muy altos sobre la cabeza")"""
    zs = [v.co.z for v in bm.verts]
    k = R / p['half_w'] * p.get('hat_k', 1.05)
    low = min(zs)
    rim = p.get('rim', 1.58)
    kz = min(k, (p.get('hat_top', 2.02) - rim) / max(max(zs) - low, 1e-6))
    for v in bm.verts:
        c = v.co
        q = Vector((c.x * k, (c.y - p['cy']) * k, (c.z - low) * kz + rim))
        out = q - C
        if out.length < R + p.get('eps', EPS):
            q = C + out.normalized() * (R + p.get('eps', EPS))
        if p.get('over_hair'):                       # (and off the old styles' ball of hair, which stands out of the head behind: chara.gd _hair, (0, 1.5, -0.06) x (0.5, 0.42, 0.5))
            hc = Vector((0.0, 0.06, 1.5))
            e = Vector(((q.x - hc.x) / 0.5, (q.y - hc.y) / 0.5, (q.z - hc.z) / 0.42))
            if q.z > 1.55 and e.length < 1.05:
                e = e.normalized() * 1.05
                q = Vector((hc.x + e.x * 0.5, hc.y + e.y * 0.5, hc.z + e.z * 0.42))
        v.co = q


def put_shoe(bm, p):
    """a shoe made to the size of our feet (chara.gd _foot: a ball of 0.15 x 0.13 x 0.2 whose middle is 0.13 over the
    ground): its sole on the ground, as long as the foot and a little more, not so tall that it goes up into the body"""
    xs = [v.co.x for v in bm.verts]; ys = [v.co.y for v in bm.verts]; zs = [v.co.z for v in bm.verts]
    lo = Vector((min(xs), min(ys), min(zs))); hi = Vector((max(xs), max(ys), max(zs)))
    size = hi - lo
    k = p.get('shoe_long', 0.44) / max(size.y, 1e-6)
    kx = p.get('shoe_wide', 0.3) / max(size.x, 1e-6)
    kz = min(k, p.get('shoe_tall', 0.34) / max(size.z, 1e-6))
    mid = (lo + hi) / 2.0
    for v in bm.verts:
        c = v.co
        v.co = Vector(((c.x - mid.x) * kx, (c.y - mid.y) * k - 0.02, (c.z - lo.z) * kz - 0.13))


def put_brows(v, tree, p, k_t):
    """eyebrows: across the front of the ball over our eyes"""
    x = v.x * (0.25 / p['brow_half_w'])
    z0 = p.get('brow_anchor_z', 1.555)
    z = z0 + (v.z - p['brow_z0']) * p.get('brow_k', 2.0)
    hit = tree.find_nearest(v)
    t = 0.0
    if hit[0] is not None:
        d = v - hit[0]
        t = max(0.0, d.length if d.dot(hit[1]) >= 0.0 else -d.length) * k_t
    q = Vector((x, 0.0, z)) - C
    inside = max(0.0, (R + p.get('eps', EPS) + t) ** 2 - q.x * q.x - q.z * q.z)
    return C + Vector((q.x, -math.sqrt(inside), q.z))


def clean_brows_source(bm, p):
    """Removes stray eyelash islands bundled inside Quaternius eyebrow meshes (keeps only the top 2 islands = brows)
    and optionally thickens the brows vertically around each island's centreline before projection."""
    visited = set()
    islands = []
    for f in bm.faces:
        if f in visited:
            continue
        comp = []
        stack = [f]
        visited.add(f)
        while stack:
            cur = stack.pop()
            comp.append(cur)
            for v in cur.verts:
                for nf in v.link_faces:
                    if nf not in visited:
                        visited.add(nf)
                        stack.append(nf)
        verts = list({v for cf in comp for v in cf.verts})
        mean_z = sum(v.co.z for v in verts) / max(1, len(verts))
        islands.append((mean_z, comp, verts))
    keep_n = int(p.get('keep_top_islands', 2))
    if len(islands) > keep_n:
        islands.sort(key=lambda item: -item[0])
        drop_faces = [f for _, comp, _ in islands[keep_n:] for f in comp]
        bmesh.ops.delete(bm, geom=drop_faces, context='FACES')
        loose = [v for v in bm.verts if not v.link_faces]
        if loose:
            bmesh.ops.delete(bm, geom=loose, context='VERTS')
        islands = islands[:keep_n]
    scale_z = float(p.get('brow_scale_z', 1.0))
    if scale_z != 1.0:
        for _, _, verts in islands:
            live = [v for v in verts if v.is_valid]
            if not live:
                continue
            mz = sum(v.co.z for v in live) / len(live)
            for v in live:
                v.co.z = mz + (v.co.z - mz) * scale_z


def fit(piece, packs):
    p = dict(packs[piece['pack']])
    p.update({k: v for k, v in piece.items() if k not in ('name', 'pack', 'obj', 'file', 'kind')})     # (a piece may set its own marks)
    load_pack(p, piece.get('file'))
    tree = skin_tree(p)
    names = piece['obj'] if isinstance(piece['obj'], list) else [piece['obj']]
    kind = piece['kind']
    bm = bmesh.new()
    cols = []                                         # the source's materials: [name, colour]
    for n in names:
        o = bpy.data.objects[n]
        base_m = len(cols)
        for slot in o.material_slots:
            cols.append([slot.material.name if slot.material else 'm', base_colour(slot.material)])
        src = world_mesh(o)
        me = bpy.data.meshes.new('tmp')
        src.to_mesh(me)
        prev = len(bm.faces)
        bm.from_mesh(me)
        bm.faces.ensure_lookup_table()
        if base_m:
            for f in bm.faces[prev:]:
                f.material_index += base_m
    for f in bm.faces:
        f.smooth = True
    if p.get('shift'):                               # (a piece made for another of the pack's heads: moved onto the one measured)
        bmesh.ops.translate(bm, verts=bm.verts[:], vec=Vector(p['shift']))
    if piece.get('rot_x'):                           # (tipped up behind, round the side-to-side axis through the pack's eyes: a headband sitting lower behind than ours can)
        import mathutils
        pivot = Vector((0.0, p['cy'], p['eye']))
        rot = mathutils.Matrix.Rotation(math.radians(piece['rot_x']), 4, 'X')
        for v in bm.verts:
            v.co = pivot + rot @ (v.co - pivot)
    if piece.get('squash_y'):                        # (shorter front to back, round its middle: a cap too long for our round heads)
        mid_y = sum(v.co.y for v in bm.verts) / max(1, len(bm.verts))
        for v in bm.verts:
            v.co.y = mid_y + (v.co.y - mid_y) * piece['squash_y']
    if piece.get('squash_z'):                        # (narrower top to bottom, round its middle: a band that would come out too wide on our round heads)
        mid_z = sum(v.co.z for v in bm.verts) / max(1, len(bm.verts))
        for v in bm.verts:
            v.co.z = mid_z + (v.co.z - mid_z) * piece['squash_z']
    if piece.get('cut_below') is not None:          # (what hangs below this height on the pack's body goes: a headscarf's knotted ends; our heads sit on the body)
        gone = [f for f in bm.faces if sum(v.co.z for v in f.verts) / len(f.verts) < piece['cut_below']]
        bmesh.ops.delete(bm, geom=gone, context='FACES')
        loose = [v for v in bm.verts if not v.link_faces]
        bmesh.ops.delete(bm, geom=loose, context='VERTS')
    if kind == 'cuerpo' and p.get('trim_tie_back'):    # keep only front knot + blade of tie, shortened to waist
        gone = [f for f in bm.faces if f.material_index == 1 and sum(v.co.y for v in f.verts) / len(f.verts) > -0.22]
        if gone:
            bmesh.ops.delete(bm, geom=gone, context='FACES')
            loose = [v for v in bm.verts if not v.link_faces]
            if loose:
                bmesh.ops.delete(bm, geom=loose, context='VERTS')
        tie_vs = [v for v in bm.verts if v.link_faces and all(f.material_index == 1 for f in v.link_faces)]
        if tie_vs:
            tz_hi = max(v.co.z for v in tie_vs)
            tz_lo = min(v.co.z for v in tie_vs)
            tie_scale = float(p.get('tie_scale', 0.72))
            if tz_hi > tz_lo + 0.1:
                for v in tie_vs:
                    v.co.z = tz_hi - (tz_hi - v.co.z) * tie_scale
    if kind == 'cuerpo' and p.get('cut_x'):          # (our people have no arms: the sleeves go)
        gone = [f for f in bm.faces if any(abs(v.co.x) > p['cut_x'] for v in f.verts)]
        bmesh.ops.delete(bm, geom=gone, context='FACES')
    if kind == 'pie':                                # one shoe of the pair
        gone = [f for f in bm.faces if sum(v.co.x for v in f.verts) / len(f.verts) > 0.0]
        bmesh.ops.delete(bm, geom=gone, context='FACES')
        loose = [v for v in bm.verts if not v.link_faces]
        bmesh.ops.delete(bm, geom=loose, context='VERTS')
    if kind == 'cejas' and p.get('keep_top_islands'):
        clean_brows_source(bm, p)
    subd = piece.get('subd', p.get('subd', 0))
    if subd:
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=1, use_grid_fill=True, smooth=1.0)
    k_t = piece.get('thick', p.get('thick', 4.0))
    off_skin = {}                                     # how far off the pack's skin each point stood, in heads (clothes: torsos)
    for v in bm.verts:
        hit = tree.find_nearest(v.co)
        off_skin[v] = ((v.co - hit[0]).length if hit[0] is not None else 0.0) / p.get('torso_half_w' if kind == 'cuerpo' else 'half_w', 1.0)
    if kind == 'pie':
        put_shoe(bm, p)
    elif kind == 'rigido':
        put_hat(bm, p)
    else:
        for v in bm.verts:
            if kind == 'cejas':
                v.co = put_brows(v.co.copy(), tree, p, k_t)
            elif kind == 'cuerpo':
                v.co = put_on_body(v.co.copy(), tree, p, k_t)
            else:
                v.co = put_on_ball(v.co.copy(), tree, p, kind, k_t)
    if kind == 'pelo':
        refine_pelo(bm, p)
    elif kind == 'barba':
        refine_barba(bm, p)
    elif kind == 'cuerpo' and p.get('refine_body'):
        refine_cuerpo(bm, p)
    bm.normal_update()
    # the material with most of the piece first: that one takes the colour chosen in the game (hair, shirt, hat, shoes)
    count = {}
    for f in bm.faces:
        count[f.material_index] = count.get(f.material_index, 0) + 1
    override_cols = p.get('override_cols')
    if override_cols:
        for idx_s, rgb in override_cols.items():
            ii = int(idx_s)
            if ii < len(cols):
                cols[ii][1] = (float(rgb[0]), float(rgb[1]), float(rgb[2]), 1.0)
    order = sorted(count.keys()) if p.get('keep_mat_order') else sorted(count, key=lambda i: -count[i])
    remap = {old: new for new, old in enumerate(order)}
    for f in bm.faces:
        f.material_index = remap[f.material_index]
    capa = False
    tone = layers(bm, off_skin) if kind == 'cuerpo' else {}
    if kind != 'cejas':
        dirt(bm, tone)
    if kind == 'pelo':                               # (after the shading: the cap under the hair is a shade of its own)
        fill_scalp(bm, p)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mesh2 = bpy.data.meshes.new(piece['name'])
    bm.to_mesh(mesh2)
    ob = bpy.data.objects.new('pieza', mesh2)
    bpy.context.scene.collection.objects.link(ob)
    if p.get('decimate'):                             # keep overly dense source brows low-poly to match the 324-tri head
        mod = ob.modifiers.new('Dec', 'DECIMATE')
        mod.ratio = float(p['decimate'])
        bpy.context.view_layer.update()
        dg = bpy.context.evaluated_depsgraph_get()
        ev = ob.evaluated_get(dg)
        me_dec = bpy.data.meshes.new_from_object(ev)
        ob.modifiers.clear()
        ob.data = me_dec
        mesh2 = me_dec
    print('COLORES', piece['name'], [(a.name, a.domain, a.data_type) for a in mesh2.color_attributes])
    if 'Col' in mesh2.color_attributes:
        for a in [a for a in mesh2.color_attributes if a.name != 'Col']:
            mesh2.color_attributes.remove(a)
        mesh2.color_attributes.active_color = mesh2.color_attributes['Col']
        mesh2.color_attributes.render_color_index = 0
    if kind in ('pelo', 'barba', 'cejas'):
        mesh2.materials.append(bpy.data.materials.new('pelo'))
    else:
        for old in order:
            name, col = cols[old] if old < len(cols) else ['m', (0.5, 0.5, 0.5, 1.0)]
            m = bpy.data.materials.new(name)
            m.use_nodes = True
            m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = col
            m.diffuse_color = col
            mesh2.materials.append(m)
        if capa:                                     # the layers that stand off the rest: the chosen colour, shaded (chara.gd)
            m = bpy.data.materials.new('capa')
            m.diffuse_color = (0.3, 0.3, 0.3, 1.0)
            mesh2.materials.append(m)
    for poly in mesh2.polygons:
        poly.use_smooth = True
    obs = [ob]
    if kind == 'pelo':                               # the same, under a hat: what is above its rim taken away (a cap's, or a higher one's)
        for cut_name, line in (('gorro', HAT_LINE), ('gorro_alto', HAT_LINE_HIGH)):
            bm2 = bmesh.new()
            bm2.from_mesh(mesh2)
            gone = [f for f in bm2.faces if sum(v.co.z for v in f.verts) / len(f.verts) > line]
            bmesh.ops.delete(bm2, geom=gone, context='FACES')
            mesh3 = bpy.data.meshes.new(piece['name'] + '_' + cut_name)
            bm2.to_mesh(mesh3)
            if len(mesh3.polygons) > 0:
                ob3 = bpy.data.objects.new(cut_name, mesh3)
                bpy.context.scene.collection.objects.link(ob3)
                for poly in mesh3.polygons:
                    poly.use_smooth = True
                obs.append(ob3)
    os.makedirs(OUT, exist_ok=True)
    for o in bpy.context.scene.objects:
        o.select_set(o in obs)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, piece['name'] + '.glb'), export_format='GLB', use_selection=True,
                              export_apply=True, export_materials='EXPORT', export_vertex_color='ACTIVE', export_all_vertex_colors=False,
                              export_active_vertex_color_when_no_material=True)       # (the shading of folds and layers: dirt)
    lo = Vector((min(v.co.x for v in mesh2.vertices), min(v.co.y for v in mesh2.vertices), min(v.co.z for v in mesh2.vertices)))
    hi = Vector((max(v.co.x for v in mesh2.vertices), max(v.co.y for v in mesh2.vertices), max(v.co.z for v in mesh2.vertices)))
    print('PIEZA %-22s %5d tris  x %.2f..%.2f  front %.2f..%.2f  up %.2f..%.2f' % (piece['name'], sum(len(pl.vertices) - 2 for pl in mesh2.polygons), lo.x, hi.x, -hi.y, -lo.y, lo.z, hi.z))
    if PREV:
        preview(ob, piece)


def preview(ob, piece):
    """a plain head and body of ours, the piece on it: front three-quarters and back three-quarters"""
    def add(mesh, loc, scale, col):
        o = bpy.data.objects.new('x', mesh)
        o.location = loc
        o.scale = scale
        m = bpy.data.materials.new('c')
        m.diffuse_color = col
        mesh.materials.append(m)
        bpy.context.scene.collection.objects.link(o)
        for poly in mesh.polygons:
            poly.use_smooth = True
        return o
    bpy.ops.mesh.primitive_uv_sphere_add(radius=R, location=C, segments=32, ring_count=16)
    head = bpy.context.active_object
    head.data.materials.append(bpy.data.materials.new('skin'))
    head.data.materials[0].diffuse_color = (0.96, 0.79, 0.63, 1)
    for poly in head.data.polygons:
        poly.use_smooth = True
    bpy.ops.mesh.primitive_cone_add(radius1=0.44, radius2=0.3, depth=0.75, location=(0, 0, 0.62), vertices=24)
    bpy.context.active_object.data.materials.append(bpy.data.materials.new('shirt'))
    bpy.context.active_object.data.materials[0].diffuse_color = (0.85, 0.3, 0.22, 1)
    for sx in (-1, 1):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=(sx * 0.17, -0.45, 1.42))
        e = bpy.context.active_object
        e.scale = (0.078, 0.045, 0.098)
        e.data.materials.append(bpy.data.materials.new('eye'))
        e.data.materials[0].diffuse_color = (1, 1, 1, 1)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=(sx * 0.17, -0.49, 1.415))
        i = bpy.context.active_object
        i.scale = (0.05, 0.03, 0.05)
        i.data.materials.append(bpy.data.materials.new('iris'))
        i.data.materials[0].diffuse_color = (0.1, 0.07, 0.05, 1)
    if piece['kind'] in ('pelo', 'barba', 'cejas'):
        ob.data.materials[0].diffuse_color = (0.35, 0.22, 0.13, 1)
    look_z, far = 1.25, 4.2
    if piece['kind'] == 'pie':                       # (a pair, on the feet; and the camera down by them)
        ob.location = (-0.17, 0.0, 0.13)
        other = bpy.data.objects.new('otro', ob.data)
        other.location = (0.17, 0.0, 0.13)
        other.scale = (-1.0, 1.0, 1.0)
        bpy.context.scene.collection.objects.link(other)
        look_z, far = 0.35, 2.2
    elif piece['kind'] == 'cuerpo':
        look_z, far = 0.9, 3.6
    for o in bpy.context.scene.objects:
        if o.name == 'gorro':
            o.hide_render = True
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'MATERIAL'
    scene.display.shading.show_cavity = True
    scene.render.resolution_x = 300
    scene.render.resolution_y = 300
    scene.render.film_transparent = False
    world = bpy.data.worlds.new('w')
    scene.world = world
    world.color = (0.9, 0.9, 0.9)
    cam_data = bpy.data.cameras.new('cam')
    cam = bpy.data.objects.new('cam', cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam_data.lens = 50
    os.makedirs(PREV, exist_ok=True)
    for tag, d in (('a', Vector((0.55, -1.0, 0.25))), ('b', Vector((-0.6, 1.0, 0.35)))):
        look = Vector((0, 0, look_z))
        cam.location = look + d.normalized() * far
        cam.rotation_euler = (look - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = os.path.join(PREV, '%s_%s.png' % (piece['name'], tag))
        bpy.ops.render.render(write_still=True)


packs = SPEC['packs']
for piece in SPEC['piezas']:
    if ONLY and piece['name'] not in ONLY:
        continue
    try:
        fit(piece, packs)
    except Exception as e:
        print('FALLO', piece['name'], repr(e))
