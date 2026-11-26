"""Ten custom stylized low-poly short / men's hairstyles for Matritellus,
sculpted from scratch in Blender for the game's spherical head
(C = (0, 0, 1.38), R = 0.50 m; Blender axes: +X char-left, -Y front, +Z up).

    blender.exe -b --python tools/creador/pelos_cortos.py -- OUT_DIR [name1 ...]

Each GLB contains:
  - 'pieza'      : full hairstyle mesh with smooth outward normals and baked 'Col' vertex shading
  - 'gorro'      : optional trimmed variant (below z = 1.57) for under caps/hats (hat_cut == 1)
  - 'gorro_alto' : optional trimmed variant (below z = 1.67) for higher hats (hat_cut == 2)
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector, Matrix

C = Vector((0.0, 0.0, 1.38))
R = 0.50


def smoothstep(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def sph_pt(az, el_deg, rad):
    """Point on sphere around C. az=0 is front (-Y), +az is char-left (+X), el_deg in [-90, 90]."""
    el = math.radians(el_deg)
    return C + Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el))) * rad


def push_out_head(p, pad=0.010):
    d = p - C
    if d.length < R + pad and d.length > 1e-6:
        return C + d.normalized() * (R + pad)
    return p


def add_spike(bm, base_az, base_el, height, r_base, tip_az_off=0.0, tip_el_off=14.0,
              lean_vec=None, segs=6, rings=3):
    """Add a sculpted curved stylized hair tuft/spike rooted slightly inside the cap."""
    p0 = sph_pt(base_az, base_el, R + 0.008)
    out0 = (p0 - C).normalized()
    p_tip = sph_pt(base_az + tip_az_off, min(88.0, base_el + tip_el_off), R + height)
    if lean_vec is not None:
        p_tip = p_tip + lean_vec
    p_mid = p0.lerp(p_tip, 0.52) + out0 * (height * 0.22)

    pts = []
    rads = []
    for k in range(rings + 1):
        t = k / rings
        # Quadratic Bezier spine
        q = (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p_mid + t * t * p_tip
        pts.append(q)
        # Smooth bulbous-to-sharp tuft taper
        rads.append(r_base * ((1.0 - t) ** 0.72) * (1.0 + 0.18 * math.sin(t * math.pi)))

    v_rings = []
    for i in range(rings):
        p = pts[i]
        tang = (pts[i + 1] - pts[max(0, i - 1)]).normalized()
        ref = Vector((0.0, 0.0, 1.0)) if abs(tang.z) < 0.9 else Vector((1.0, 0.0, 0.0))
        u = tang.cross(ref).normalized()
        v = tang.cross(u).normalized()
        r = rads[i]
        ring = []
        for j in range(segs):
            a = j * math.tau / segs
            q = p + u * (math.cos(a) * r) + v * (math.sin(a) * r * 0.82)
            ring.append(bm.verts.new(q))
        v_rings.append(ring)

    # Side quads
    for i in range(rings - 1):
        r0, r1 = v_rings[i], v_rings[i + 1]
        for j in range(segs):
            jn = (j + 1) % segs
            f = bm.faces.new((r0[j], r0[jn], r1[jn], r1[j]))
            f.smooth = True
    # Pointed tip cap
    vt = bm.verts.new(pts[-1])
    for j in range(segs):
        jn = (j + 1) % segs
        f = bm.faces.new((v_rings[-1][j], v_rings[-1][jn], vt))
        f.smooth = True
    # Base cap
    vb = bm.verts.new(pts[0])
    for j in range(segs):
        jn = (j + 1) % segs
        f = bm.faces.new((v_rings[0][jn], v_rings[0][j], vb))
        f.smooth = True


def add_lock(bm, spine_pts, rx_list, ry_list=None, segs=6, round_tip=True):
    """Sweep a smooth stylized hair lock/dread along a 3D spine with optional rounded tip."""
    if ry_list is None:
        ry_list = rx_list
    n = len(spine_pts)
    v_rings = []
    for i in range(n):
        p = spine_pts[i]
        if i == 0:
            t = (spine_pts[1] - spine_pts[0]).normalized()
        elif i == n - 1:
            t = (spine_pts[-1] - spine_pts[-2]).normalized()
        else:
            t = (spine_pts[i + 1] - spine_pts[i - 1]).normalized()
        out_n = (p - C).normalized()
        side = t.cross(out_n)
        if side.length < 1e-4:
            side = t.cross(Vector((0.0, 0.0, 1.0))).normalized()
        else:
            side.normalize()
        rad_v = side.cross(t).normalized()
        if rad_v.dot(out_n) < 0.0:
            rad_v = -rad_v
        rx, ry = rx_list[i], ry_list[i]
        ring = []
        for j in range(segs):
            a = j * math.tau / segs
            q = p + side * (math.cos(a) * rx) + rad_v * (math.sin(a) * ry)
            ring.append(bm.verts.new(q))
        v_rings.append(ring)

    for i in range(n - 1):
        r0, r1 = v_rings[i], v_rings[i + 1]
        for j in range(segs):
            jn = (j + 1) % segs
            f = bm.faces.new((r0[j], r0[jn], r1[jn], r1[j]))
            f.smooth = True
    # Caps
    c0 = bm.verts.new(spine_pts[0])
    t_end = (spine_pts[-1] - spine_pts[-2]).normalized()
    c1 = bm.verts.new(spine_pts[-1] + (t_end * (rx_list[-1] * 0.7) if round_tip else Vector()))
    for j in range(segs):
        jn = (j + 1) % segs
        bm.faces.new((v_rings[0][jn], v_rings[0][j], c0)).smooth = True
        bm.faces.new((v_rings[-1][j], v_rings[-1][jn], c1)).smooth = True


def add_cap_shell(bm, el_min_fn, thick_fn, n_u=32, n_v=14, el_top=88.0, add_rim_tuck=True):
    """Build a closed low-poly scalp hair shell covering elevation el_min_fn(az)..el_top.
    Returns (outer_rings, crown_vert) for reference.
    """
    rings = []
    # Tuck ring slightly inside the skull along the bottom hairline so there's never an open razor gap
    if add_rim_tuck:
        tuck = []
        for j in range(n_u):
            az = j * math.tau / n_u
            el0 = el_min_fn(az)
            tuck.append(bm.verts.new(sph_pt(az, el0 + 1.5, R - 0.004)))
        rings.append(tuck)

    for i in range(n_v + 1):
        t = i / n_v
        ring = []
        for j in range(n_u):
            az = j * math.tau / n_u
            el0 = el_min_fn(az)
            # Denser sampling near hairline for crisp silhouette
            el = el0 + (el_top - el0) * (t ** 1.15)
            th = thick_fn(az, el, t)
            # Taper softly into the tuck at t=0
            th_eff = th * smoothstep(0.0, 0.14, t) + 0.012
            ring.append(bm.verts.new(sph_pt(az, el, R + th_eff)))
        rings.append(ring)

    for i in range(len(rings) - 1):
        r0, r1 = rings[i], rings[i + 1]
        for j in range(n_u):
            jn = (j + 1) % n_u
            f = bm.faces.new((r0[j], r0[jn], r1[jn], r1[j]))
            f.smooth = True

    top_r = rings[-1]
    tc = sum((v.co for v in top_r), Vector()) / len(top_r)
    # Raise pole cleanly to match top thickness
    d = (tc - C)
    if d.length > 1e-5:
        tc = C + d.normalized() * (R + thick_fn(0.0, 90.0, 1.0) + 0.012)
    tv = bm.verts.new(tc)
    for j in range(n_u):
        jn = (j + 1) % n_u
        bm.faces.new((top_r[j], top_r[jn], tv)).smooth = True
    return rings, tv


def add_curl_puff(bm, az, el_deg, rad, rx, ry=None, rz=None, u=8, v=5):
    """Add a plump stylized curl puff on the head sphere."""
    if ry is None:
        ry = rx
    if rz is None:
        rz = rx * 0.85
    center = sph_pt(az, el_deg, rad)
    out = (center - C).normalized()
    ref = Vector((0.0, 0.0, 1.0)) if abs(out.z) < 0.9 else Vector((1.0, 0.0, 0.0))
    tu = out.cross(ref).normalized()
    tv = out.cross(tu).normalized()
    res = bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    for vert in res['verts']:
        vert.co = center + tu * (vert.co.x * rx) + tv * (vert.co.y * ry) + out * (vert.co.z * rz)
        for f in vert.link_faces:
            f.smooth = True


# ==================== 10 HAIRSTYLE BUILDERS ====================

def build_pelo_pincho():
    """36 · De pincho — Iconic spiky short hair on top over faded sides (_degradado)."""
    bm = bmesh.new()

    # Compact textured crown base sitting cleanly on top of the fade
    def el_min(az):
        ca = math.cos(az)
        return 37.0 - 5.0 * max(0.0, ca) + 5.0 * (math.sin(az) ** 2)

    def thick(az, el, t):
        return 0.038 + 0.024 * math.sin(t * math.pi)

    add_cap_shell(bm, el_min, thick, n_u=26, n_v=8, el_top=86.0)

    # Chunkier, lively stylized spikes covering front, crown AND upper back cleanly
    front_specs = [
        (-0.62, 39.0, 0.150, 0.066, -0.06, 18.0),
        (-0.30, 36.0, 0.180, 0.074, -0.03, 20.0),
        (0.00,  35.0, 0.195, 0.078,  0.01, 21.0),
        (0.30,  36.0, 0.178, 0.074,  0.04, 19.0),
        (0.62,  39.0, 0.150, 0.066,  0.07, 17.0),
    ]
    for (az, el, h, rb, daz, delv) in front_specs:
        add_spike(bm, az, el, h, rb, daz, delv, lean_vec=Vector((0.0, -0.022, 0.015)), segs=6, rings=3)

    mid_specs = [
        (-0.98, 48.0, 0.148, 0.066, -0.06, 15.0),
        (-0.48, 52.0, 0.185, 0.076, -0.03, 15.0),
        (0.02,  53.0, 0.195, 0.078,  0.02, 15.0),
        (0.48,  52.0, 0.182, 0.076,  0.04, 14.0),
        (0.98,  48.0, 0.148, 0.066,  0.06, 15.0),
    ]
    for (az, el, h, rb, daz, delv) in mid_specs:
        add_spike(bm, az, el, h, rb, daz, delv, segs=6, rings=3)

    # Full crown & back-crown spikes so the back silhouette is lively too
    top_specs = [
        (-1.48, 52.0, 0.140, 0.066, -0.05, 11.0),
        (-2.05, 48.0, 0.132, 0.066, -0.03, 9.0),
        (-2.62, 46.0, 0.132, 0.066,  0.00, 8.0),
        (3.14,  46.0, 0.138, 0.068,  0.00, 8.0),
        (2.62,  46.0, 0.132, 0.066,  0.00, 8.0),
        (2.05,  48.0, 0.132, 0.066,  0.03, 9.0),
        (1.48,  52.0, 0.140, 0.066,  0.05, 11.0),
        (-0.55, 68.0, 0.180, 0.076,  0.00, 10.0),
        (0.55,  68.0, 0.180, 0.076,  0.00, 10.0),
        (-2.25, 64.0, 0.155, 0.072,  0.00, 8.0),
        (2.25,  64.0, 0.155, 0.072,  0.00, 8.0),
        (3.14,  66.0, 0.162, 0.074,  0.00, 8.0),
        (0.00,  78.0, 0.180, 0.076,  0.00, 6.0),
    ]
    for (az, el, h, rb, daz, delv) in top_specs:
        add_spike(bm, az, el, h, rb, daz, delv, segs=6, rings=3)

    return bm, False  # faded sides handle under-hat cleanly


def build_pelo_patras():
    """37 · Peinao pa' trás — Sleek slicked-back hair with smooth combed wave and neat nape."""
    bm = bmesh.new()

    def el_min(az):
        a = abs(((az + math.pi) % math.tau) - math.pi)
        base = 30.0 * (0.5 + 0.5 * math.cos(az)) ** 1.3 - 18.0 * (0.5 - 0.5 * math.cos(az))
        temple_recess = 5.5 * math.exp(-((a - 0.62) / 0.24) ** 2)
        sideburn = -10.5 * math.exp(-((a - 1.35) / 0.20) ** 2)
        return base + temple_recess + sideburn

    def thick(az, el, t):
        a = abs(((az + math.pi) % math.tau) - math.pi)
        # Full slicked-back pompadour wave sweeping smoothly from forehead over crown to upper back
        front_roll = 0.076 * math.exp(-((el - 52.0) / 24.0) ** 2) * math.exp(-(a / 1.05) ** 2)
        crown_vol = 0.048 * smoothstep(14.0, 62.0, el)
        back_taper = 0.018 * smoothstep(0.0, 50.0, el) * (0.5 - 0.5 * math.cos(az))
        side_sleek = 0.022
        # Continuous silky front-to-back combed grooves fading cleanly at front/back edges (zero blocky teeth!)
        p_unit = sph_pt(az, el, 1.0) - C
        groove_mask = smoothstep(0.18, 0.45, t) * (1.0 - smoothstep(0.55, 0.90, abs(p_unit.x)))
        grooves = 0.011 * math.sin(p_unit.x * 28.0) * groove_mask
        return side_sleek + crown_vol + front_roll + back_taper + grooves

    add_cap_shell(bm, el_min, thick, n_u=44, n_v=18, el_top=88.0)
    return bm, True


def build_pelo_brocoli():
    """38 · De brócoli — Iconic modern curly fade (fluffy cluster of curls on top, faded sides)."""
    bm = bmesh.new()

    def el_min(az):
        return 42.0 - 7.0 * max(0.0, math.cos(az)) + 6.0 * (math.sin(az) ** 2)

    def thick(az, el, t):
        return 0.048 + 0.028 * math.sin(t * math.pi)

    add_cap_shell(bm, el_min, thick, n_u=24, n_v=8, el_top=86.0)

    front_curls = [
        (-0.72, 42.0, 0.565, 0.088),
        (-0.46, 37.0, 0.580, 0.098),
        (-0.22, 35.0, 0.592, 0.104),
        (0.02,  34.0, 0.596, 0.106),
        (0.26,  35.0, 0.590, 0.102),
        (0.50,  38.0, 0.578, 0.096),
        (0.74,  43.0, 0.562, 0.086),
    ]
    mid_curls = [
        (-1.12, 49.0, 0.568, 0.092),
        (-1.60, 52.0, 0.560, 0.088),
        (-2.15, 52.0, 0.556, 0.088),
        (-2.72, 50.0, 0.554, 0.088),
        (3.14,  50.0, 0.554, 0.090),
        (2.68,  51.0, 0.556, 0.088),
        (2.12,  52.0, 0.558, 0.088),
        (1.58,  52.0, 0.562, 0.088),
        (1.10,  49.0, 0.568, 0.092),
    ]
    top_curls = [
        (-0.58, 58.0, 0.598, 0.104),
        (-0.18, 56.0, 0.610, 0.110),
        (0.22,  56.0, 0.608, 0.108),
        (0.62,  58.0, 0.596, 0.104),
        (-1.35, 64.0, 0.588, 0.100),
        (-2.25, 64.0, 0.582, 0.098),
        (2.25,  64.0, 0.582, 0.098),
        (1.35,  64.0, 0.588, 0.100),
        (-0.45, 76.0, 0.608, 0.108),
        (0.45,  76.0, 0.608, 0.108),
        (3.14,  75.0, 0.596, 0.104),
        (0.00,  86.0, 0.606, 0.106),
    ]
    for (az, el, rad, r0) in front_curls + mid_curls + top_curls:
        add_curl_puff(bm, az, el, rad, r0, r0 * 0.94, r0 * 0.80, u=8, v=5)

    return bm, False


def build_pelo_alborotao():
    """39 · Alborotao — Casual messy short hair with layered tousled locks all around."""
    bm = bmesh.new()

    def el_min(az):
        a = abs(((az + math.pi) % math.tau) - math.pi)
        base = 28.0 * (0.5 + 0.5 * math.cos(az)) ** 1.2 - 20.0 * (0.5 - 0.5 * math.cos(az))
        sideburn = -10.0 * math.exp(-((a - 1.38) / 0.24) ** 2)
        wave = 3.0 * math.sin(az * 5.0 + 0.6)
        return base + sideburn + wave

    def thick(az, el, t):
        wave = 0.014 * math.sin(az * 7.0 + el * 0.09)
        return 0.040 + 0.022 * smoothstep(10.0, 60.0, el) + wave

    add_cap_shell(bm, el_min, thick, n_u=32, n_v=14, el_top=88.0)

    # Tousled front bangs sweeping down-and-sideways at varied angles (kept cleanly above eyes!)
    bang_specs = [
        (-0.62, 46.0, -0.74, 24.0, 0.056, 0.028),
        (-0.40, 48.0, -0.50, 22.0, 0.062, 0.030),
        (-0.16, 48.0, -0.08, 21.0, 0.064, 0.032),
        (0.08,  49.0,  0.22, 22.0, 0.062, 0.030),
        (0.34,  48.0,  0.48, 23.0, 0.060, 0.028),
        (0.58,  46.0,  0.72, 25.0, 0.054, 0.026),
    ]
    for (az0, el0, az1, el1, w, d) in bang_specs:
        pts = [
            sph_pt(az0, el0, R + 0.046),
            sph_pt((az0 + az1) * 0.5, (el0 + el1) * 0.5 + 2.0, R + 0.070),
            sph_pt(az1, el1, R + 0.048),
            sph_pt(az1 + (az1 - az0) * 0.25, el1 - 3.5, R + 0.026),
        ]
        add_lock(bm, pts, [w * 0.85, w, w * 0.72, w * 0.22], [d * 0.8, d, d * 0.7, d * 0.28], segs=6)

    # Wide flat-layered tousled locks sweeping across crown, sides, and back with flipped-out ends!
    layered_locks = [
        # Side swept layers (left & right)
        (-0.85, 62.0, -1.18, 34.0, 0.082, 0.036, 0.092),
        (-1.35, 58.0, -1.62, 22.0, 0.084, 0.036, 0.090),
        (0.85,  62.0,  1.18, 34.0, 0.082, 0.036, 0.092),
        (1.35,  58.0,  1.62, 22.0, 0.084, 0.036, 0.090),
        # Back tousled layers draping down with lively flipped tips
        (-2.05, 60.0, -2.18, 16.0, 0.086, 0.038, 0.090),
        (-2.68, 62.0, -2.75, 14.0, 0.086, 0.038, 0.090),
        (3.14,  64.0,  3.06, 12.0, 0.088, 0.038, 0.092),
        (2.58,  62.0,  2.66, 14.0, 0.086, 0.038, 0.090),
        (2.00,  60.0,  2.14, 16.0, 0.086, 0.038, 0.090),
        # Crown bedhead cowlicks sweeping across top
        (-0.45, 76.0,  0.18, 64.0, 0.074, 0.036, 0.118),
        (0.42,  76.0, -0.15, 66.0, 0.072, 0.034, 0.116),
        (-2.40, 74.0, -1.85, 52.0, 0.076, 0.036, 0.108),
        (2.40,  74.0,  1.85, 52.0, 0.076, 0.036, 0.108),
    ]
    for (az0, el0, az1, el1, w, d, tip_out) in layered_locks:
        pts = [
            sph_pt(az0, el0, R + 0.044),
            sph_pt((az0 + az1) * 0.5, (el0 + el1) * 0.5 + 3.0, R + 0.074),
            sph_pt(az1, el1, R + tip_out),
            sph_pt(az1 + (az1 - az0) * 0.18, el1 - 5.0, R + tip_out + 0.018),
        ]
        add_lock(bm, pts, [w * 0.72, w, w * 0.78, w * 0.22], [d * 0.75, d, d * 0.72, d * 0.24], segs=6)

    return bm, True


def build_pelo_entradas():
    """40 · Con entradas — Authentic receding M-shaped hairline with crisp widow's peak & neat sides."""
    bm = bmesh.new()

    def el_min(az):
        a = abs(((az + math.pi) % math.tau) - math.pi)
        base = 34.0 * (0.5 + 0.5 * math.cos(az)) ** 1.2 - 19.0 * (0.5 - 0.5 * math.cos(az))
        entradas = 29.0 * math.exp(-((a - 0.58) / 0.24) ** 2)
        peak = -5.5 * math.exp(-(a / 0.20) ** 2)
        sideburn = -13.0 * math.exp(-((a - 1.38) / 0.20) ** 2)
        return base + entradas + peak + sideburn

    def thick(az, el, t):
        a = abs(((az + math.pi) % math.tau) - math.pi)
        crown_thin = 0.030 + 0.012 * (1.0 - math.exp(-(a / 0.9) ** 2))
        front_tuft = 0.012 * math.exp(-(a / 0.22) ** 2) * math.exp(-((el - 44.0) / 16.0) ** 2)
        grooves = 0.006 * math.sin(az * 14.0) * smoothstep(20.0, 65.0, el)
        return crown_thin + front_tuft + grooves

    add_cap_shell(bm, el_min, thick, n_u=42, n_v=16, el_top=88.0)
    return bm, True


def build_pelo_monito():
    """41 · Moñito — Modern man bun / top knot pulled back over faded sides (_degradado)."""
    bm = bmesh.new()

    bun_center = sph_pt(math.pi, 58.0, R + 0.120)
    bun_base = sph_pt(math.pi, 58.0, R + 0.036)

    def el_min(az):
        a = abs(((az + math.pi) % math.tau) - math.pi)
        # Slightly wider sleek top panel blending smoothly into the fade
        return 42.0 - 9.0 * math.exp(-(a / 0.95) ** 2) + 7.0 * (math.sin(az) ** 2)

    def thick(az, el, t):
        p_unit = sph_pt(az, el, 1.0) - C
        grooves = 0.008 * math.sin(p_unit.x * 24.0) * smoothstep(0.2, 0.5, t)
        return 0.028 + 0.018 * math.sin(t * math.pi) + grooves

    add_cap_shell(bm, el_min, thick, n_u=30, n_v=10, el_top=88.0)

    # 5 sleek pulled-back combed strands converging neatly into the bun tie
    for x_s in (-0.20, -0.10, 0.0, 0.10, 0.20):
        p0 = (C + Vector((x_s, -0.78, 0.62)).normalized() * (R + 0.032))
        p1 = (C + Vector((x_s * 0.72, -0.20, 0.96)).normalized() * (R + 0.056))
        p2 = (C + Vector((x_s * 0.35, 0.42, 0.90)).normalized() * (R + 0.052))
        add_lock(bm, [p0, p1, p2, bun_base], [0.032, 0.042, 0.038, 0.028], [0.018, 0.022, 0.020, 0.020], segs=6)

    # Cinched hair-tie collar at bun base
    tie_p0 = bun_base.lerp(bun_center, 0.18)
    tie_p1 = bun_base.lerp(bun_center, 0.46)
    add_lock(bm, [tie_p0, tie_p1], [0.068, 0.066], [0.068, 0.066], segs=12, round_tip=False)

    # Fuller sculpted knotted man bun clearly readable from front, side, and back!
    out = (bun_center - C).normalized()
    tu = Vector((1.0, 0.0, 0.0))
    tv = out.cross(tu).normalized()
    res = bmesh.ops.create_uvsphere(bm, u_segments=14, v_segments=9, radius=1.0)
    for vert in res['verts']:
        ang = math.atan2(vert.co.y, vert.co.x)
        rib = 1.0 + 0.07 * math.sin(ang * 3.0 + vert.co.z * 2.5)
        vert.co = (bun_center
                   + tu * (vert.co.x * 0.148 * rib)
                   + tv * (vert.co.y * 0.136 * rib)
                   + out * (vert.co.z * 0.112))
        for f in vert.link_faces:
            f.smooth = True
    # Little stray tucked tail at the bottom-back of the knot
    tail0 = bun_center - tv * 0.078 + out * 0.02
    tail1 = tail0 - tv * 0.085 - out * 0.02
    add_lock(bm, [tail0, tail1], [0.046, 0.014], [0.034, 0.010], segs=6, round_tip=True)

    return bm, False


def build_pelo_flequillo_lao():
    """42 · Flequillo de lao — Short back/sides with a bold asymmetric diagonal swept fringe."""
    bm = bmesh.new()

    def el_min(az):
        a = abs(((az + math.pi) % math.tau) - math.pi)
        base = 30.0 * (0.5 + 0.5 * math.cos(az)) ** 1.3 - 19.0 * (0.5 - 0.5 * math.cos(az))
        asym = -7.0 * math.exp(-((az - 0.55) / 0.45) ** 2) + 6.0 * math.exp(-((az + 0.55) / 0.35) ** 2)
        sideburn = -10.0 * math.exp(-((a - 1.38) / 0.22) ** 2)
        return base + asym + sideburn

    def thick(az, el, t):
        sweep = 0.024 * math.exp(-((az - 0.45) / 0.85) ** 2) * smoothstep(20.0, 58.0, el)
        return 0.032 + 0.018 * smoothstep(10.0, 62.0, el) + sweep

    add_cap_shell(bm, el_min, thick, n_u=34, n_v=14, el_top=88.0)

    # Smoothly integrated diagonal fringe sweeping cleanly across forehead without abrupt side bump
    fringe_locks = [
        (-0.55, 48.0, -0.05, 34.0, 0.52, 22.0, 0.78, 16.0, 0.052, 0.024),
        (-0.48, 52.0,  0.04, 39.0, 0.60, 26.0, 0.88, 19.0, 0.058, 0.026),
        (-0.38, 56.0,  0.15, 45.0, 0.72, 31.0, 1.02, 22.0, 0.056, 0.024),
        (-0.22, 60.0,  0.30, 50.0, 0.86, 36.0, 1.15, 25.0, 0.052, 0.022),
        (-0.58, 42.0, -0.20, 29.0, 0.22, 21.0, 0.46, 18.0, 0.046, 0.022),
    ]
    for (a0, e0, a1, e1, a2, e2, a3, e3, w, d) in fringe_locks:
        pts = [
            sph_pt(a0, e0, R + 0.036),
            sph_pt(a1, e1, R + 0.056),
            sph_pt(a2, e2, R + 0.054),
            sph_pt(a3, e3, R + 0.030),
        ]
        add_lock(bm, pts, [w * 0.75, w, w * 0.82, w * 0.22], [d * 0.75, d, d * 0.78, d * 0.26], segs=6)

    return bm, True


def build_pelo_cepillo():
    """43 · De cepillo — Crisp architectural flat-top / crew cut over faded sides (_degradado)."""
    bm = bmesh.new()

    n_u = 36
    z_top = 1.942  # sharper, sportier flat-top height (less tall than a hat box)

    rings = []
    # Subtle classic upward flare from the fade up to a crisp squared flat plateau
    levels = [
        (0.00, 0.92, 0.0),
        (0.18, 0.97, 0.0),
        (0.55, 1.02, 0.0),
        (0.90, 1.05, 0.0),   # classic crisp flat-top corner flare
        (0.97, 1.00, 0.0),
        (1.00, 0.88, 0.0),
    ]
    for (tv, s_rad, _) in levels:
        ring = []
        for j in range(n_u):
            az = j * math.tau / n_u
            ca, sa = math.cos(az), math.sin(az)
            # Subtle bristle-ribbed squared superellipse silhouette
            bristle = 1.0 + (0.012 * math.sin(az * 18.0) if 0.15 < tv < 0.96 else 0.0)
            rx_base = 0.365 * (1.0 + 0.06 * (ca * ca * sa * sa * 4.0)) * bristle
            ry_base = 0.398 * (1.0 + 0.05 * (ca * ca * sa * sa * 4.0)) * bristle
            x = math.sin(az) * rx_base * s_rad
            y = -math.cos(az) * ry_base * s_rad + 0.022
            r_xy2 = x * x + y * y
            z_skull = C.z + math.sqrt(max(0.01, (R + 0.006) ** 2 - min(r_xy2, (R - 0.02) ** 2)))
            z_hi = z_top + 0.022 * max(0.0, ca) - 0.016 * max(0.0, -ca)
            if tv == 0.0:
                z = z_skull - 0.016
            else:
                z = z_skull + (z_hi - z_skull) * tv
            p = Vector((x, y, z))
            if tv > 0.0:
                p = push_out_head(p, pad=0.012)
            ring.append(bm.verts.new(p))
        rings.append(ring)

    for i in range(len(rings) - 1):
        r0, r1 = rings[i], rings[i + 1]
        for j in range(n_u):
            jn = (j + 1) % n_u
            f = bm.faces.new((r0[j], r0[jn], r1[jn], r1[j]))
            f.smooth = True

    top_r = rings[-1]
    tc = sum((v.co for v in top_r), Vector()) / len(top_r)
    tv_c = bm.verts.new(tc)
    for j in range(n_u):
        jn = (j + 1) % n_u
        bm.faces.new((top_r[j], top_r[jn], tv_c)).smooth = True

    return bm, False


def build_pelo_raya_medio():
    """44 · Raya al medio — Clean short-medium middle part with two symmetrical front curtains."""
    bm = bmesh.new()

    def el_min(az):
        a = abs(((az + math.pi) % math.tau) - math.pi)
        base = 29.0 * (0.5 + 0.5 * math.cos(az)) ** 1.2 - 20.0 * (0.5 - 0.5 * math.cos(az))
        part_v = 12.5 * math.exp(-(a / 0.17) ** 2)
        side_curt = -7.0 * math.exp(-((a - 0.65) / 0.36) ** 2)
        sideburn = -10.5 * math.exp(-((a - 1.35) / 0.24) ** 2)
        return base + part_v + side_curt + sideburn

    def thick(az, el, t):
        a = abs(((az + math.pi) % math.tau) - math.pi)
        part_groove = -0.028 * math.exp(-(a / 0.13) ** 2) * smoothstep(26.0, 48.0, el) * (1.0 - smoothstep(78.0, 90.0, el))
        mounds = 0.032 * math.exp(-((a - 0.42) / 0.36) ** 2) * smoothstep(20.0, 68.0, el)
        return max(0.015, 0.036 + 0.018 * smoothstep(10.0, 60.0, el) + mounds + part_groove)

    add_cap_shell(bm, el_min, thick, n_u=40, n_v=16, el_top=88.0)

    # Plumper symmetrical curtains framing either side of the center part cleanly outside the eyes
    for sx in (-1.0, 1.0):
        locks = [
            (0.09, 56.0, 0.35, 41.0, 0.60, 23.0, 0.76, 13.0, 0.060, 0.032),
            (0.14, 62.0, 0.48, 47.0, 0.78, 28.0, 0.96, 15.0, 0.062, 0.032),
            (0.20, 66.0, 0.62, 51.0, 0.96, 31.0, 1.18, 16.0, 0.056, 0.028),
        ]
        for (a0, e0, a1, e1, a2, e2, a3, e3, w, d) in locks:
            pts = [
                sph_pt(sx * a0, e0, R + 0.044),
                sph_pt(sx * a1, e1, R + 0.074),
                sph_pt(sx * a2, e2, R + 0.066),
                sph_pt(sx * a3, e3, R + 0.036),
            ]
            add_lock(bm, pts, [w * 0.75, w, w * 0.84, w * 0.25], [d * 0.75, d, d * 0.78, d * 0.28], segs=6)

    return bm, True


def build_pelo_rastas_cortas():
    """45 · Rastas cortas — Chunky short stylized dreadlocks/twists over faded sides (_degradado)."""
    bm = bmesh.new()

    # Fuller crown root cushion so zero bare fade peeks between dread roots
    def el_min(az):
        return 41.0 - 4.0 * max(0.0, math.cos(az))

    def thick(az, el, t):
        return 0.040 + 0.024 * math.sin(t * math.pi)

    add_cap_shell(bm, el_min, thick, n_u=24, n_v=8, el_top=86.0)

    # 24 chunky rounded short dreads radiating cleanly from crown and draping naturally all around
    dread_specs = [
        # Front ring (draping gently forward/sideways, stopping cleanly above brows)
        (-0.80, 47.0, -0.94, 21.0, 0.115),
        (-0.48, 45.0, -0.56, 22.0, 0.118),
        (-0.16, 45.0, -0.18, 24.0, 0.115),
        (0.16,  45.0,  0.18, 24.0, 0.115),
        (0.48,  45.0,  0.56, 22.0, 0.118),
        (0.80,  47.0,  0.94, 21.0, 0.115),
        # Side & back outer ring
        (-1.24, 48.0, -1.34, 15.0, 0.120),
        (-1.72, 48.0, -1.80, 12.0, 0.120),
        (-2.24, 46.0, -2.30, 10.0, 0.118),
        (-2.78, 46.0, -2.82, 10.0, 0.118),
        (2.78,  46.0,  2.82, 10.0, 0.118),
        (2.24,  46.0,  2.30, 10.0, 0.118),
        (1.72,  48.0,  1.80, 12.0, 0.120),
        (1.24,  48.0,  1.34, 15.0, 0.120),
        # Mid-crown dreads filling sides/back seamlessly
        (-1.05, 62.0, -1.25, 32.0, 0.125),
        (1.05,  62.0,  1.25, 32.0, 0.125),
        (-1.75, 64.0, -1.92, 30.0, 0.125),
        (1.75,  64.0,  1.92, 30.0, 0.125),
        (-2.55, 64.0, -2.65, 28.0, 0.124),
        (2.55,  64.0,  2.65, 28.0, 0.124),
        # Top crown dreads arching out over the outer ring
        (-0.52, 70.0, -0.68, 42.0, 0.126),
        (0.52,  70.0,  0.68, 42.0, 0.126),
        (0.00,  76.0,  0.10, 46.0, 0.128),
        (3.14,  74.0,  3.14, 42.0, 0.126),
    ]
    for (a0, e0, a1, e1, arch_r) in dread_specs:
        pts = [
            sph_pt(a0, e0, R + 0.024),
            sph_pt(a0 + (a1 - a0) * 0.35, e0 + (e1 - e0) * 0.25 + 6.0, R + arch_r * 0.85),
            sph_pt(a0 + (a1 - a0) * 0.72, e0 + (e1 - e0) * 0.65 + 2.0, R + arch_r * 0.78),
            sph_pt(a1, e1, R + arch_r * 0.56),
        ]
        add_lock(bm, pts, [0.038, 0.045, 0.043, 0.035], [0.035, 0.042, 0.040, 0.032], segs=7, round_tip=True)

    return bm, False


# ==================== HAT-CUT TRIMMING & EXPORT ====================

def make_hat_cut(bm_src, z_cut, keep_crown=False):
    """Return a clean hat-fitted copy of bm_src.
    - keep_crown=False (gorro, cut==1): trims faces above z_cut and tucks the rim snugly inside caps.
    - keep_crown=True  (gorro_alto, cut==2): keeps the entire scalp covered (no bald gap under tilted berets!)
      while smoothly compressing everything above z_cut radially flush onto the skull (R + 0.009, z <= 1.882)
      so nothing pokes through berets, straw hats, tophats, tricorns, or chef hats.
    """
    bm = bm_src.copy()
    if keep_crown:
        for v in bm.verts:
            if v.co.z > z_cut - 0.06:
                t = smoothstep(z_cut - 0.06, z_cut + 0.05, v.co.z)
                d = v.co - C
                if d.length > R + 0.009:
                    target = R + 0.009 + (d.length - (R + 0.009)) * (1.0 - t)
                    v.co = C + d.normalized() * target
                if v.co.z > 1.882:
                    v.co.z = 1.882
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return bm

    kill = [f for f in bm.faces if f.calc_center_median().z >= z_cut]
    if len(kill) >= len(bm.faces) - 6:
        bm.free()
        return None
    bmesh.ops.delete(bm, geom=kill, context='FACES')
    loose = [v for v in bm.verts if not v.link_faces]
    if loose:
        bmesh.ops.delete(bm, geom=loose, context='VERTS')
    if len(bm.faces) < 6:
        bm.free()
        return None
    # Pull upper rim vertices snugly toward skull so they tuck cleanly inside a cap rim
    for v in bm.verts:
        if v.co.z > z_cut - 0.11:
            t = smoothstep(z_cut - 0.11, z_cut, v.co.z)
            d = v.co - C
            if d.length > R + 0.015:
                target = R + 0.015 + (d.length - (R + 0.015)) * (1.0 - 0.80 * t)
                v.co = C + d.normalized() * target
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def bake_hair_vc(mesh):
    """Bake subtle AO/top-light + strand shading into 'Col' vertex colour attribute."""
    col_attr = mesh.color_attributes.new(name="Col", type='BYTE_COLOR', domain='CORNER')
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            v = mesh.vertices[mesh.loops[li].vertex_index]
            d = v.co - C
            h = max(0.0, d.length - R)
            n = v.normal
            # Slightly darker at roots & undersides, crisper/brighter on crown & tuft tips
            root_ao = 0.78 + 0.22 * smoothstep(0.0, 0.075, h)
            top_l = 0.90 + 0.10 * max(-1.0, min(1.0, n.z * 0.65 - n.y * 0.25))
            val = min(1.0, max(0.68, root_ao * top_l))
            col_attr.data[li].color = (val, val, val, 1.0)


def bm_to_obj(bm, obj_name, mat):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    # Ensure normals point generally outward on shells
    mesh = bpy.data.meshes.new(obj_name)
    bm.to_mesh(mesh)
    for p in mesh.polygons:
        p.use_smooth = True
    mesh.materials.append(mat)
    mesh.update()
    bake_hair_vc(mesh)
    mesh.color_attributes.active_color = mesh.color_attributes["Col"]
    mesh.color_attributes.render_color_index = 0
    obj = bpy.data.objects.new(obj_name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj, sum(len(p.vertices) - 2 for p in mesh.polygons)


BUILDERS = {
    "pelo_pincho":        build_pelo_pincho,
    "pelo_patras":        build_pelo_patras,
    "pelo_brocoli":       build_pelo_brocoli,
    "pelo_alborotao":     build_pelo_alborotao,
    "pelo_entradas":      build_pelo_entradas,
    "pelo_monito":        build_pelo_monito,
    "pelo_flequillo_lao": build_pelo_flequillo_lao,
    "pelo_cepillo":       build_pelo_cepillo,
    "pelo_raya_medio":    build_pelo_raya_medio,
    "pelo_rastas_cortas": build_pelo_rastas_cortas,
}


def export_one(name, out_dir):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bm_full, keep_hat_cuts = BUILDERS[name]()
    mat = bpy.data.materials.new("pelo")

    objs = []
    obj_main, tris_main = bm_to_obj(bm_full, "pieza", mat)
    objs.append(obj_main)

    cut_info = []
    if keep_hat_cuts:
        for cname, zc, kc in (("gorro", 1.615, False), ("gorro_alto", 1.68, True)):
            bm_c = make_hat_cut(bm_full, zc, keep_crown=kc)
            if bm_c is not None:
                oc, tc = bm_to_obj(bm_c, cname, mat)
                objs.append(oc)
                cut_info.append(f"{cname}={tc}")
                bm_c.free()
    bm_full.free()

    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]

    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{name}.glb")
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format='GLB',
        use_selection=True,
        export_yup=True,
        export_normals=True,
        export_materials='EXPORT',
        export_vertex_color='ACTIVE',
        export_all_vertex_colors=False,
    )
    cuts_str = (" [" + ", ".join(cut_info) + "]") if cut_info else " [fade-only under hat]"
    print(f"BUILT {name:20s}: {tris_main:4d} tris{cuts_str} -> {out_path}")


def main():
    argv = sys.argv
    if "--" not in argv:
        raise SystemExit("Usage: blender -b --python pelos_cortos.py -- OUT_DIR [names...]")
    args = argv[argv.index("--") + 1:]
    out_dir = args[0]
    names = args[1:] if len(args) > 1 else list(BUILDERS.keys())
    for n in names:
        if n not in BUILDERS:
            raise SystemExit(f"Unknown hairstyle: {n}")
        export_one(n, out_dir)


if __name__ == "__main__":
    main()
