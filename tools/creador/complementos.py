"""Custom low-poly stylized accessories (glasses & neckwear) for Matritellus,
sculpted cleanly from scratch in Blender for the game's spherical head
(C = (0, 0, 1.38), R = 0.50 m; Blender axes: +X char-left, -Y front, +Z up)
and conical torso (z in [0.245, 0.995], R(z) = 0.44 - (z - 0.245) * 0.18667).

    blender.exe -b --python tools/creador/complementos.py -- OUT_DIR [name1 name2 ...]

Each piece is exported as godot/assets/creador/pelo/<name>.glb with smooth outward
normals, subtle baked vertex-color shading ('Col') for the game's flat-shaded +
screen-space ink outline aesthetic, and crisp multi-material surfaces.
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector, Matrix

C = Vector((0.0, 0.0, 1.38))
R_HEAD = 0.50
HAIR_C = Vector((0.0, 0.06, 1.50))
HAIR_R = Vector((0.515, 0.515, 0.435))


def srgb_to_lin_ch(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_lin(h):
    r = ((h >> 16) & 0xFF) / 255.0
    g = ((h >> 8) & 0xFF) / 255.0
    b = (h & 0xFF) / 255.0
    return (srgb_to_lin_ch(r), srgb_to_lin_ch(g), srgb_to_lin_ch(b), 1.0)


def r_cone(z):
    return 0.44 - (z - 0.245) * 0.18667


def push_outside_head(q, pad=0.016, over_hair=False):
    d = q - C
    if d.length < R_HEAD + pad and d.length > 1e-5:
        q = C + d.normalized() * (R_HEAD + pad)
    if over_hair and q.z > 1.32:
        e = Vector(((q.x - HAIR_C.x) / HAIR_R.x,
                    (q.y - HAIR_C.y) / HAIR_R.y,
                    (q.z - HAIR_C.z) / HAIR_R.z))
        if e.length < 1.045 and e.length > 1e-5:
            e = e.normalized() * 1.045
            q = Vector((HAIR_C.x + e.x * HAIR_R.x,
                        HAIR_C.y + e.y * HAIR_R.y,
                        HAIR_C.z + e.z * HAIR_R.z))
    return q


def push_outside_body_and_head(q, body_pad=0.015, head_pad=0.016):
    if 0.22 <= q.z <= 1.02:
        xy = Vector((q.x, q.y))
        rc = r_cone(min(0.995, max(0.245, q.z))) + body_pad
        if xy.length < rc and xy.length > 1e-5:
            xy = xy.normalized() * rc
            q = Vector((xy.x, xy.y, q.z))
    q = push_outside_head(q, pad=head_pad, over_hair=False)
    return q


def add_tube(bm, pts, radii, n_sides=8, closed_loop=False, cap_ends=True, mat_idx=0):
    """Sweep a circular/elliptical tube along a 3D polyline.
    radii can be a float, a (rx, ry) tuple, or a list matching len(pts).
    """
    n = len(pts)
    if n < 2:
        return []
    rings = []
    for i in range(n):
        p = pts[i]
        if closed_loop:
            t = (pts[(i + 1) % n] - pts[(i - 1) % n])
        elif i == 0:
            t = pts[1] - pts[0]
        elif i == n - 1:
            t = pts[-1] - pts[-2]
        else:
            t = pts[i + 1] - pts[i - 1]
        if t.length < 1e-6:
            t = Vector((0.0, 0.0, 1.0))
        else:
            t.normalize()
        ref = Vector((0.0, 0.0, 1.0)) if abs(t.z) < 0.9 else Vector((1.0, 0.0, 0.0))
        u = t.cross(ref).normalized()
        v = t.cross(u).normalized()
        r = radii[i] if isinstance(radii, list) else radii
        rx, ry = (r[0], r[1]) if isinstance(r, tuple) else (r, r)
        ring = []
        for j in range(n_sides):
            a = j * math.tau / n_sides
            q = p + u * (math.cos(a) * rx) + v * (math.sin(a) * ry)
            ring.append(bm.verts.new(q))
        rings.append(ring)

    seg_count = n if closed_loop else n - 1
    for i in range(seg_count):
        r0 = rings[i]
        r1 = rings[(i + 1) % n]
        for j in range(n_sides):
            jn = (j + 1) % n_sides
            f = bm.faces.new((r0[j], r0[jn], r1[jn], r1[j]))
            f.material_index = mat_idx
            f.smooth = True

    if cap_ends and not closed_loop:
        c0 = bm.verts.new(pts[0])
        c1 = bm.verts.new(pts[-1])
        for j in range(n_sides):
            jn = (j + 1) % n_sides
            f0 = bm.faces.new((rings[0][jn], rings[0][j], c0))
            f0.material_index = mat_idx
            f0.smooth = True
            f1 = bm.faces.new((rings[-1][j], rings[-1][jn], c1))
            f1.material_index = mat_idx
            f1.smooth = True
    return rings


def add_lathe(bm, rings, mat_idx=0, closed_top=False, closed_bottom=False):
    n_u = len(rings[0])
    v_rings = [[bm.verts.new(p) for p in ring] for ring in rings]
    for i in range(len(v_rings) - 1):
        r0, r1 = v_rings[i], v_rings[i + 1]
        for j in range(n_u):
            jn = (j + 1) % n_u
            f = bm.faces.new((r0[j], r0[jn], r1[jn], r1[j]))
            f.material_index = mat_idx
            f.smooth = True
    if closed_top:
        top_r = v_rings[-1]
        tc = sum((v.co for v in top_r), Vector()) / len(top_r)
        tv = bm.verts.new(tc)
        for j in range(n_u):
            jn = (j + 1) % n_u
            f = bm.faces.new((top_r[j], top_r[jn], tv))
            f.material_index = mat_idx
            f.smooth = True
    if closed_bottom:
        bot_r = v_rings[0]
        bc = sum((v.co for v in bot_r), Vector()) / len(bot_r)
        bv = bm.verts.new(bc)
        for j in range(n_u):
            jn = (j + 1) % n_u
            f = bm.faces.new((bot_r[jn], bot_r[j], bv))
            f.material_index = mat_idx
            f.smooth = True
    return v_rings


def add_grid_slab(bm, front_grid, back_grid, mat_idx=0):
    """Build a solid closed slab from two matching (rows x cols) grids of Vectors."""
    rows = len(front_grid)
    cols = len(front_grid[0])
    fv = [[bm.verts.new(p) for p in row] for row in front_grid]
    bv = [[bm.verts.new(p) for p in row] for row in back_grid]
    for r in range(rows - 1):
        for c in range(cols - 1):
            f1 = bm.faces.new((fv[r][c], fv[r][c + 1], fv[r + 1][c + 1], fv[r + 1][c]))
            f1.material_index = mat_idx
            f1.smooth = True
            f2 = bm.faces.new((bv[r][c + 1], bv[r][c], bv[r + 1][c], bv[r + 1][c + 1]))
            f2.material_index = mat_idx
            f2.smooth = True
    # Perimeter walls
    for c in range(cols - 1):
        f = bm.faces.new((bv[0][c], bv[0][c + 1], fv[0][c + 1], fv[0][c]))
        f.material_index = mat_idx
        f.smooth = True
        f = bm.faces.new((fv[-1][c], fv[-1][c + 1], bv[-1][c + 1], bv[-1][c]))
        f.material_index = mat_idx
        f.smooth = True
    for r in range(rows - 1):
        f = bm.faces.new((fv[r][0], fv[r + 1][0], bv[r + 1][0], bv[r][0]))
        f.material_index = mat_idx
        f.smooth = True
        f = bm.faces.new((bv[r][-1], bv[r + 1][-1], fv[r + 1][-1], fv[r][-1]))
        f.material_index = mat_idx
        f.smooth = True


def add_sphere(bm, center, scale, mat_idx=0, u=10, v=6, rot_x=0.0, rot_y=0.0, rot_z=0.0):
    res = bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    rot = Matrix.Rotation(rot_z, 3, 'Z') @ Matrix.Rotation(rot_y, 3, 'Y') @ Matrix.Rotation(rot_x, 3, 'X')
    for vert in res['verts']:
        p = Vector((vert.co.x * scale[0], vert.co.y * scale[1], vert.co.z * scale[2]))
        vert.co = center + rot @ p
        for f in vert.link_faces:
            f.material_index = mat_idx
            f.smooth = True


def add_box(bm, center, size, mat_idx=0, rot_x=0.0, rot_y=0.0, rot_z=0.0, bevel=0.0):
    res = bmesh.ops.create_cube(bm, size=1.0)
    verts = res['verts']
    rot = Matrix.Rotation(rot_z, 3, 'Z') @ Matrix.Rotation(rot_y, 3, 'Y') @ Matrix.Rotation(rot_x, 3, 'X')
    for vert in verts:
        p = Vector((vert.co.x * size[0], vert.co.y * size[1], vert.co.z * size[2]))
        vert.co = center + rot @ p
    if bevel > 0.0:
        edges = list({e for v in verts for e in v.link_edges})
        bmesh.ops.bevel(bm, geom=edges, offset=bevel, segments=2, affect='EDGES', clamp_overlap=True)
    for f in bm.faces:
        if any(v in verts for v in f.verts) or f.material_index == 0:
            pass
    # Assign material safely on newly created faces via bounding or explicit tracking
    # Better: create in temp bmesh when beveling; here we only bevel when needed via helper below.


def add_bevel_box(bm, center, size, mat_idx=0, rot_x=0.0, rot_y=0.0, rot_z=0.0, bevel=0.012):
    tmp = bmesh.new()
    bmesh.ops.create_cube(tmp, size=1.0)
    for v in tmp.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    if bevel > 0.0:
        bmesh.ops.bevel(tmp, geom=list(tmp.edges), offset=bevel, segments=2, affect='EDGES', clamp_overlap=True)
    rot = Matrix.Rotation(rot_z, 3, 'Z') @ Matrix.Rotation(rot_y, 3, 'Y') @ Matrix.Rotation(rot_x, 3, 'X')
    vmap = {}
    for v in tmp.verts:
        vmap[v] = bm.verts.new(center + rot @ v.co)
    for f in tmp.faces:
        nf = bm.faces.new([vmap[v] for v in f.verts])
        nf.material_index = mat_idx
        nf.smooth = True
    tmp.free()


def add_cyl(bm, center, radius, height, mat_idx=0, segs=14, rot_x=0.0, rot_y=0.0, rot_z=0.0):
    tmp = bmesh.new()
    bmesh.ops.create_cone(tmp, cap_ends=True, cap_tris=False, segments=segs,
                          radius1=radius, radius2=radius, depth=height)
    rot = Matrix.Rotation(rot_z, 3, 'Z') @ Matrix.Rotation(rot_y, 3, 'Y') @ Matrix.Rotation(rot_x, 3, 'X')
    vmap = {}
    for v in tmp.verts:
        vmap[v] = bm.verts.new(center + rot @ v.co)
    for f in tmp.faces:
        nf = bm.faces.new([vmap[v] for v in f.verts])
        nf.material_index = mat_idx
        nf.smooth = True
    tmp.free()


# ==================== GLASSES HELPERS ====================

def face_curve_y(x, z, y_front=-0.535, wrap=0.18):
    """Gentle wraparound curve following the front of the head sphere."""
    return y_front + wrap * (x * x) + 0.06 * ((z - 1.42) ** 2)


def add_glasses_lens_and_rim(bm, contour_2d, cx, cz, sx, rim_r=0.015, y_front=-0.538,
                             wrap=0.18, with_lens=True, rim_mat=0, lens_mat=1, rim_sides=8):
    """Build one glasses rim (swept tube) and optional curved solid lens from a 2D loop
    defined in local (u, v) where +u is outward from nose, +v is up.
    """
    pts_3d = []
    for (u, v) in contour_2d:
        x = cx + sx * u
        z = cz + v
        y = face_curve_y(x, z, y_front=y_front, wrap=wrap)
        pts_3d.append(Vector((x, y, z)))
    # Ensure consistent winding
    add_tube(bm, pts_3d, rim_r, n_sides=rim_sides, closed_loop=True, cap_ends=False, mat_idx=rim_mat)

    if with_lens:
        n = len(contour_2d)
        # Front and back lens faces with center vertex for smooth slight dome
        cf = Vector((cx, face_curve_y(cx, cz, y_front=y_front - 0.008, wrap=wrap), cz))
        cb = Vector((cx, face_curve_y(cx, cz, y_front=y_front + 0.009, wrap=wrap), cz))
        vf_c = bm.verts.new(cf)
        vb_c = bm.verts.new(cb)
        ring_f = []
        ring_b = []
        for (u, v) in contour_2d:
            # Slightly inset so lens sits inside rim cleanly
            x = cx + sx * (u * 0.96)
            z = cz + (v * 0.96)
            yf = face_curve_y(x, z, y_front=y_front - 0.003, wrap=wrap)
            yb = face_curve_y(x, z, y_front=y_front + 0.008, wrap=wrap)
            ring_f.append(bm.verts.new(Vector((x, yf, z))))
            ring_b.append(bm.verts.new(Vector((x, yb, z))))
        for i in range(n):
            inext = (i + 1) % n
            # Winding depends on sx
            if sx > 0:
                ff = bm.faces.new((vf_c, ring_f[i], ring_f[inext]))
                fb = bm.faces.new((vb_c, ring_b[inext], ring_b[i]))
            else:
                ff = bm.faces.new((vf_c, ring_f[inext], ring_f[i]))
                fb = bm.faces.new((vb_c, ring_b[i], ring_b[inext]))
            ff.material_index = lens_mat
            ff.smooth = True
            fb.material_index = lens_mat
            fb.smooth = True


def add_temple_arm(bm, start_pt, sx, thick=0.014, mat_idx=0):
    """Sleek temple arm sweeping from outer frame hinge back along side of head."""
    # Stay strictly outside head sphere R=0.50
    z_arm = start_pt.z
    pts = [
        start_pt,
        Vector((sx * max(abs(start_pt.x) + 0.025, 0.345), start_pt.y + 0.02, z_arm)),
        Vector((sx * 0.455, -0.34, z_arm)),
        Vector((sx * 0.506, -0.14, z_arm)),
        Vector((sx * 0.512, 0.02, z_arm - 0.008)),
        Vector((sx * 0.505, 0.075, z_arm - 0.048)),
    ]
    pts = [push_outside_head(p, pad=0.010, over_hair=False) for p in pts]
    radii = [(thick * 0.85, thick * 1.05)] * (len(pts) - 1) + [(thick * 0.7, thick * 0.85)]
    add_tube(bm, pts, radii, n_sides=6, closed_loop=False, cap_ends=True, mat_idx=mat_idx)


# ==================== 1. GLASSES MODELS ====================

def build_gafas_sol():
    """5 · De sol — Classic Wayfarer sunglasses with flat browline, dark lenses, silver rivets."""
    bm = bmesh.new()
    # Rounded trapezoid Wayfarer contour (u: outward from nose, v: up)
    n_pts = 24
    contour = []
    for i in range(n_pts):
        a = i * math.tau / n_pts
        ca, sa = math.cos(a), math.sin(a)
        # Superellipse-like boxy top, slightly narrower rounded bottom
        su = math.copysign(abs(ca) ** 0.72, ca)
        sv = math.copysign(abs(sa) ** 0.75, sa)
        u = su * 0.132
        v = sv * 0.098
        # Flatten top browline and taper bottom slightly inward
        if v > 0.03:
            v = min(v, 0.092) + 0.008 * su  # slight subtle lift at outer top corner
        if v < 0.0:
            u *= 1.0 - 0.12 * (-v / 0.10)
        contour.append((u, v))

    cx, cz = 0.178, 1.425
    for sx in (-1.0, 1.0):
        add_glasses_lens_and_rim(bm, contour, sx * cx, cz, sx,
                                 rim_r=0.017, y_front=-0.538, wrap=0.16,
                                 with_lens=True, rim_mat=0, lens_mat=1, rim_sides=8)
        # Outer temple lug + arm
        hinge = Vector((sx * 0.312, face_curve_y(0.312, cz + 0.075, -0.536, 0.16), cz + 0.068))
        add_temple_arm(bm, hinge, sx, thick=0.016, mat_idx=0)
        # Classic tiny silver rivet on outer upper corner
        rivet_p = Vector((sx * 0.298, face_curve_y(0.298, cz + 0.070, -0.552, 0.16), cz + 0.068))
        add_sphere(bm, rivet_p, (0.012, 0.008, 0.010), mat_idx=2, u=8, v=5)

    # Thick straight Wayfarer bridge across top-middle
    bridge_pts = [
        Vector((-0.075, face_curve_y(-0.075, cz + 0.062, -0.538, 0.16), cz + 0.060)),
        Vector((0.0,    face_curve_y(0.0,    cz + 0.068, -0.541, 0.16), cz + 0.066)),
        Vector((0.075,  face_curve_y(0.075,  cz + 0.062, -0.538, 0.16), cz + 0.060)),
    ]
    add_tube(bm, bridge_pts, (0.016, 0.019), n_sides=8, cap_ends=True, mat_idx=0)

    mats = [
        ("WayfarerFrame", hex_lin(0x1b1b20), 0.35, 0.05),
        ("WayfarerLens",  hex_lin(0x0f1216), 0.12, 0.08),
        ("WayfarerRivet", hex_lin(0xd4d9df), 0.25, 0.55),
    ]
    return bm, mats


def build_gafas_aviador():
    """6 · De aviador — Classic teardrop aviators with gold wire frame & double bridge."""
    bm = bmesh.new()
    n_pts = 24
    contour = []
    for i in range(n_pts):
        a = i * math.tau / n_pts
        ca, sa = math.cos(a), math.sin(a)
        # Iconic aviator teardrop: flat-ish top, fuller lower-outer cheek drop
        u = ca * 0.132
        v = sa * 0.105
        if sa > 0.0:
            v = min(v, 0.084)
        else:
            # Drop lower on the outer-bottom quadrant (u > 0, v < 0)
            drop = 0.032 * max(0.0, (ca + 0.35) / 1.35) * (-sa)
            v -= drop
            # Slightly narrower near inner nose bottom
            if ca < 0.0:
                u *= 1.0 - 0.18 * (-sa)
        contour.append((u, v))

    cx, cz = 0.175, 1.425
    for sx in (-1.0, 1.0):
        add_glasses_lens_and_rim(bm, contour, sx * cx, cz, sx,
                                 rim_r=0.010, y_front=-0.536, wrap=0.18,
                                 with_lens=True, rim_mat=0, lens_mat=1, rim_sides=8)
        hinge = Vector((sx * 0.308, face_curve_y(0.308, cz + 0.048, -0.535, 0.18), cz + 0.048))
        add_temple_arm(bm, hinge, sx, thick=0.009, mat_idx=0)

    # Iconic DOUBLE GOLD BRIDGE (top sweatbar + lower nose bridge)
    top_bar = [
        Vector((-0.095, face_curve_y(-0.095, cz + 0.084, -0.537, 0.18), cz + 0.084)),
        Vector((0.0,    face_curve_y(0.0,    cz + 0.088, -0.540, 0.18), cz + 0.088)),
        Vector((0.095,  face_curve_y(0.095,  cz + 0.084, -0.537, 0.18), cz + 0.084)),
    ]
    low_bar = [
        Vector((-0.068, face_curve_y(-0.068, cz + 0.038, -0.537, 0.18), cz + 0.038)),
        Vector((0.0,    face_curve_y(0.0,    cz + 0.048, -0.541, 0.18), cz + 0.048)),
        Vector((0.068,  face_curve_y(0.068,  cz + 0.038, -0.537, 0.18), cz + 0.038)),
    ]
    add_tube(bm, top_bar, 0.009, n_sides=6, cap_ends=True, mat_idx=0)
    add_tube(bm, low_bar, 0.009, n_sides=6, cap_ends=True, mat_idx=0)

    mats = [
        ("AviatorGold", hex_lin(0xd4aa3b), 0.28, 0.60),
        ("AviatorLens", hex_lin(0x2d4a36), 0.16, 0.05),
    ]
    return bm, mats


def build_gafas_gato():
    """8 · De ojo de gato — Retro upswept crimson cat-eye frames (open rims + gold wing studs)."""
    bm = bmesh.new()
    n_pts = 24
    contour = []
    for i in range(n_pts):
        a = i * math.tau / n_pts
        ca, sa = math.cos(a), math.sin(a)
        u = ca * 0.125
        v = sa * 0.086
        # Upswept winged outer-upper corner!
        wing = max(0.0, ca) * max(0.0, sa)
        u += 0.055 * (wing ** 0.75)
        v += 0.052 * (wing ** 0.75)
        # Slightly pinched lower-inner curve
        if sa < 0.0:
            v *= 0.92
        contour.append((u, v))

    cx, cz = 0.174, 1.420
    for sx in (-1.0, 1.0):
        add_glasses_lens_and_rim(bm, contour, sx * cx, cz, sx,
                                 rim_r=0.017, y_front=-0.536, wrap=0.18,
                                 with_lens=False, rim_mat=0, lens_mat=1, rim_sides=8)
        # Winged temple hinge
        hinge = Vector((sx * 0.326, face_curve_y(0.326, cz + 0.088, -0.534, 0.18), cz + 0.082))
        add_temple_arm(bm, hinge, sx, thick=0.013, mat_idx=0)
        # Gold vintage corner accent stud on the upswept tip
        stud = Vector((sx * 0.312, face_curve_y(0.312, cz + 0.088, -0.551, 0.18), cz + 0.085))
        add_sphere(bm, stud, (0.015, 0.009, 0.011), mat_idx=1, u=8, v=5)

    bridge = [
        Vector((-0.068, face_curve_y(-0.068, cz + 0.025, -0.536, 0.18), cz + 0.025)),
        Vector((0.0,    face_curve_y(0.0,    cz + 0.036, -0.540, 0.18), cz + 0.036)),
        Vector((0.068,  face_curve_y(0.068,  cz + 0.025, -0.536, 0.18), cz + 0.025)),
    ]
    add_tube(bm, bridge, 0.013, n_sides=8, cap_ends=True, mat_idx=0)

    mats = [
        ("CatEyeRed",  hex_lin(0xb22234), 0.35, 0.05),
        ("CatEyeGold", hex_lin(0xe5c158), 0.25, 0.55),
    ]
    return bm, mats


def build_gafas_corazon():
    """9 · De corazón — Playful red/pink heart-shaped sunglasses."""
    bm = bmesh.new()
    n_pts = 28
    contour = []
    for i in range(n_pts):
        t = i * math.tau / n_pts
        # Parametric heart curve, normalized nicely around (0, 0)
        hx = 16.0 * (math.sin(t) ** 3)
        hy = 13.0 * math.cos(t) - 5.0 * math.cos(2.0 * t) - 2.0 * math.cos(3.0 * t) - math.cos(4.0 * t)
        # Scale to ~0.135 half-width, ~0.125 half-height
        u = (hx / 16.0) * 0.138
        v = ((hy + 2.2) / 14.5) * 0.122
        contour.append((u, v))

    cx, cz = 0.178, 1.418
    for sx in (-1.0, 1.0):
        add_glasses_lens_and_rim(bm, contour, sx * cx, cz, sx,
                                 rim_r=0.016, y_front=-0.540, wrap=0.16,
                                 with_lens=True, rim_mat=0, lens_mat=1, rim_sides=8)
        hinge = Vector((sx * 0.312, face_curve_y(0.312, cz + 0.055, -0.538, 0.16), cz + 0.055))
        add_temple_arm(bm, hinge, sx, thick=0.013, mat_idx=0)

    bridge = [
        Vector((-0.068, face_curve_y(-0.068, cz + 0.045, -0.540, 0.16), cz + 0.045)),
        Vector((0.0,    face_curve_y(0.0,    cz + 0.055, -0.543, 0.16), cz + 0.055)),
        Vector((0.068,  face_curve_y(0.068,  cz + 0.045, -0.540, 0.16), cz + 0.045)),
    ]
    add_tube(bm, bridge, 0.013, n_sides=8, cap_ends=True, mat_idx=0)

    mats = [
        ("HeartFrame", hex_lin(0xe83b5c), 0.35, 0.05),
        ("HeartLens",  hex_lin(0x4a1628), 0.16, 0.05),
    ]
    return bm, mats


def build_gafas_parche():
    """11 · Parche de pirata — Curved leather eyepatch over left eye (+X) with diagonal strap."""
    bm = bmesh.new()
    cx, cz = 0.172, 1.420
    # Rounded triangular / classic shield patch hugging the head sphere
    n_pts = 20
    contour = []
    for i in range(n_pts):
        a = i * math.tau / n_pts
        ca, sa = math.cos(a), math.sin(a)
        u = ca * 0.125
        v = sa * 0.118
        if sa > 0.0:
            v *= 0.88  # straighter top edge
        else:
            u *= 1.0 - 0.20 * (-sa)  # slightly tapered bottom
        contour.append((u, v))

    # Build curved patch dome over the head sphere (R_HEAD + 0.028)
    def patch_pt(u, v, dr=0.0):
        x = cx + u
        z = cz + v
        # Project onto sphere of radius R_HEAD + 0.028 + dr around C
        d = Vector((x, -0.50, z)) - C
        d.normalize()
        return C + d * (R_HEAD + 0.032 + dr)

    cf = patch_pt(0.0, 0.0, dr=0.014)
    cb = patch_pt(0.0, 0.0, dr=-0.008)
    vf_c = bm.verts.new(cf)
    vb_c = bm.verts.new(cb)
    ring_f, ring_b, rim_pts = [], [], []
    for (u, v) in contour:
        pf = patch_pt(u, v, dr=0.005)
        pb = patch_pt(u, v, dr=-0.010)
        ring_f.append(bm.verts.new(pf))
        ring_b.append(bm.verts.new(pb))
        rim_pts.append(patch_pt(u, v, dr=0.003))
    for i in range(n_pts):
        inext = (i + 1) % n_pts
        f1 = bm.faces.new((vf_c, ring_f[i], ring_f[inext]))
        f1.material_index = 0
        f1.smooth = True
        f2 = bm.faces.new((vb_c, ring_b[inext], ring_b[i]))
        f2.material_index = 0
        f2.smooth = True
    # Crisp stitched leather border rim
    add_tube(bm, rim_pts, 0.012, n_sides=8, closed_loop=True, cap_ends=False, mat_idx=1)

    # Diagonal strap wrapping around the whole head cleanly (over right brow, round back, under left temple)
    strap_pts = []
    n_s = 36
    # Plane normal tilted ~20 deg so strap crosses high over right forehead (-X) and lower on left (+X)
    for i in range(n_s):
        ang = i * math.tau / n_s  # 0 = front (-Y), pi/2 = +X (left), pi = back (+Y), 3pi/2 = -X (right)
        # Base height at patch (ang ~ 0.34 rad -> z = 1.46); higher on -X forehead, lower at back
        z = 1.475 - 0.105 * math.sin(ang + 0.15) + 0.035 * math.cos(ang)
        dz = z - C.z
        rr = math.sqrt(max(0.04, (R_HEAD + 0.022) ** 2 - dz * dz))
        p = Vector((math.sin(ang) * rr, -math.cos(ang) * rr, z))
        p = push_outside_head(p, pad=0.022, over_hair=False)
        strap_pts.append(p)
    add_tube(bm, strap_pts, (0.011, 0.015), n_sides=6, closed_loop=True, cap_ends=False, mat_idx=0)

    mats = [
        ("PatchBlack", hex_lin(0x1b1b20), 0.72, 0.02),
        ("PatchRim",   hex_lin(0x3a322c), 0.65, 0.05),
    ]
    return bm, mats


# ==================== 2. NECKWEAR MODELS ====================

def neck_ring_pt(ang, z, pad=0.016):
    """Point on torso cone at height z and azimuth ang (0 = front -Y), pushed outside head & body."""
    rr = r_cone(min(0.995, max(0.245, z))) + pad
    p = Vector((math.sin(ang) * rr, -math.cos(ang) * rr, z))
    return push_outside_body_and_head(p, body_pad=pad, head_pad=0.016)


def build_cuello_corbata():
    """6 · Corbata — Snug collar band, crisp Windsor knot, and beveled burgundy striped blade."""
    bm = bmesh.new()

    # 1. Snug collar band around the neck
    n_u = 28
    band_pts = []
    for j in range(n_u):
        a = j * math.tau / n_u
        z = 0.942 + 0.014 * (1.0 - math.cos(a)) * 0.5  # sits slightly higher in back
        band_pts.append(neck_ring_pt(a, z, pad=0.014))
    add_tube(bm, band_pts, (0.014, 0.018), n_sides=8, closed_loop=True, cap_ends=False, mat_idx=0)

    # 2. Windsor knot at front throat (tapered rounded trapezoid prism)
    knot_rows = [
        (0.955, 0.044, 0.032),
        (0.930, 0.048, 0.038),
        (0.900, 0.036, 0.034),
        (0.882, 0.026, 0.024),
    ]
    k_fg, k_bg = [], []
    for (z, hw, th) in knot_rows:
        frow, brow = [], []
        for s in (-1.0, -0.45, 0.45, 1.0):
            x = s * hw
            rc = r_cone(z)
            # Curve around front of torso
            ang = x / rc
            bulge = 1.0 - 0.35 * (s * s)
            pf = Vector((math.sin(ang) * (rc + 0.016 + th * bulge),
                         -math.cos(ang) * (rc + 0.016 + th * bulge), z))
            pb = Vector((math.sin(ang) * (rc + 0.008),
                         -math.cos(ang) * (rc + 0.008), z))
            frow.append(push_outside_body_and_head(pf, body_pad=0.014, head_pad=0.016))
            brow.append(push_outside_body_and_head(pb, body_pad=0.010, head_pad=0.016))
        k_fg.append(frow)
        k_bg.append(brow)
    add_grid_slab(bm, k_fg, k_bg, mat_idx=0)

    # 3. Tie blade hugging front torso cone smoothly down to diamond tip
    blade_profile = [
        (0.886, 0.025),
        (0.820, 0.036),
        (0.720, 0.048),
        (0.600, 0.058),
        (0.490, 0.066),
        (0.415, 0.064),
        (0.345, 0.004),  # sharp classic diamond tip
    ]
    b_fg, b_bg = [], []
    for (z, hw) in blade_profile:
        frow, brow = [], []
        rc = r_cone(z)
        for s in (-1.0, -0.4, 0.4, 1.0):
            x = s * hw
            ang = x / rc
            # Subtle center ridge thickness
            th = 0.018 * (1.0 - 0.45 * (s * s)) + 0.006
            pf = Vector((math.sin(ang) * (rc + 0.014 + th),
                         -math.cos(ang) * (rc + 0.014 + th), z))
            pb = Vector((math.sin(ang) * (rc + 0.011),
                         -math.cos(ang) * (rc + 0.011), z))
            frow.append(push_outside_body_and_head(pf, body_pad=0.014, head_pad=0.016))
            brow.append(push_outside_body_and_head(pb, body_pad=0.011, head_pad=0.016))
        b_fg.append(frow)
        b_bg.append(brow)
    add_grid_slab(bm, b_fg, b_bg, mat_idx=0)

    # 4. Crisp diagonal gold-cream regimental stripes on the tie blade
    def blade_hw(z):
        for i in range(len(blade_profile) - 1):
            z0, w0 = blade_profile[i]
            z1, w1 = blade_profile[i + 1]
            if z1 <= z <= z0:
                t = (z0 - z) / (z0 - z1)
                return w0 + (w1 - w0) * t
        return 0.04

    for z_mid in (0.78, 0.66, 0.54, 0.43):
        s_fg, s_bg = [], []
        for dz in (0.010, -0.010):
            frow, brow = [], []
            for s in (-0.94, 0.0, 0.94):
                z = z_mid + dz + s * 0.022
                hw = blade_hw(z)
                x = s * hw
                rc = r_cone(z)
                ang = x / rc
                th = 0.018 * (1.0 - 0.45 * (s * s)) + 0.006
                pf = Vector((math.sin(ang) * (rc + 0.019 + th),
                             -math.cos(ang) * (rc + 0.019 + th), z))
                pb = Vector((math.sin(ang) * (rc + 0.012 + th),
                             -math.cos(ang) * (rc + 0.012 + th), z))
                frow.append(push_outside_body_and_head(pf, body_pad=0.016, head_pad=0.016))
                brow.append(push_outside_body_and_head(pb, body_pad=0.012, head_pad=0.016))
            s_fg.append(frow)
            s_bg.append(brow)
        add_grid_slab(bm, s_fg, s_bg, mat_idx=1)

    mats = [
        ("TieBurgundy", hex_lin(0x8e1e2b), 0.78, 0.02),
        ("TieStripe",   hex_lin(0xe2c478), 0.72, 0.05),
    ]
    return bm, mats


def build_cuello_pajarita():
    """7 · Pajarita — Classic tuxedo black bow tie with puffy pleated wings & snug neck band."""
    bm = bmesh.new()

    # 1. Snug collar band
    n_u = 28
    band_pts = []
    for j in range(n_u):
        a = j * math.tau / n_u
        z = 0.935 + 0.014 * (1.0 - math.cos(a)) * 0.5
        band_pts.append(neck_ring_pt(a, z, pad=0.013))
    add_tube(bm, band_pts, (0.011, 0.015), n_sides=8, closed_loop=True, cap_ends=False, mat_idx=0)

    # 2. Puffy sculpted wings on left and right
    z_c = 0.918
    rc = r_cone(z_c)
    for sx in (-1.0, 1.0):
        # Lathe rings going outward along the bow wing
        rings = []
        steps = [
            (0.016, 0.018, 0.016),
            (0.045, 0.036, 0.024),
            (0.088, 0.054, 0.028),
            (0.118, 0.060, 0.024),
            (0.128, 0.048, 0.014),
        ]
        n_ring = 14
        for (dist, hh, hd) in steps:
            ring = []
            ang = sx * (dist / (rc + 0.035))
            # Wing center along curved front of neck
            base = Vector((math.sin(ang) * (rc + 0.040), -math.cos(ang) * (rc + 0.040), z_c))
            out_dir = Vector((math.sin(ang), -math.cos(ang), 0.0)).normalized()
            for j in range(n_ring):
                b = j * math.tau / n_ring
                # Pinch front center subtly like fabric pleat
                pleat = 1.0 - 0.18 * (math.cos(b) ** 2) * (1.0 - abs(math.sin(b)))
                dz = math.sin(b) * hh
                dr = math.cos(b) * hd * pleat
                p = base + out_dir * dr + Vector((0.0, 0.0, dz))
                ring.append(push_outside_body_and_head(p, body_pad=0.014, head_pad=0.016))
            rings.append(ring if sx > 0 else list(reversed(ring)))
        add_lathe(bm, rings, mat_idx=0, closed_top=True, closed_bottom=True)

    # 3. Crisp center wrap knot
    knot_c = push_outside_body_and_head(Vector((0.0, -(rc + 0.046), z_c)), body_pad=0.016, head_pad=0.016)
    add_bevel_box(bm, knot_c, (0.042, 0.042, 0.050), mat_idx=1, rot_x=-0.16, bevel=0.010)

    mats = [
        ("BowBlack", hex_lin(0x1f2026), 0.62, 0.04),
        ("BowKnot",  hex_lin(0x2e303a), 0.55, 0.06),
    ]
    return bm, mats


def build_cuello_delantal():
    """8 · Delantal — Classic cream-white apron with navy straps, front pocket, and back waist bow."""
    bm = bmesh.new()

    # 1. Halter neck strap (clean loop from top of bib up and round back of neck)
    neck_pts = []
    n_s = 22
    for i in range(n_s):
        t = i / (n_s - 1)
        # Angle from -0.34 rad (right bib corner) round back (pi) to +0.34 rad (left bib corner)
        ang = -0.34 - t * (math.tau - 0.68)
        # Rise smoothly from bib top z=0.885 to neck back z=0.955
        s = math.sin(t * math.pi)
        z = 0.885 + 0.072 * (s ** 0.7)
        neck_pts.append(neck_ring_pt(ang, z, pad=0.015))
    add_tube(bm, neck_pts, (0.012, 0.015), n_sides=6, closed_loop=False, cap_ends=True, mat_idx=1)

    # 2. Upper chest bib (smooth curved slab hugging front torso)
    bib_z = [0.890, 0.820, 0.740, 0.655, 0.610]
    bib_fg, bib_bg = [], []
    n_c = 10
    for z in bib_z:
        # Slightly wider toward waist
        span = 0.36 + 0.14 * ((0.890 - z) / 0.280)
        rc = r_cone(z)
        frow, brow = [], []
        for c in range(n_c):
            u = (c / (n_c - 1)) * 2.0 - 1.0
            a = u * span
            pf = Vector((math.sin(a) * (rc + 0.026), -math.cos(a) * (rc + 0.026), z))
            pb = Vector((math.sin(a) * (rc + 0.013), -math.cos(a) * (rc + 0.013), z))
            frow.append(push_outside_body_and_head(pf, body_pad=0.016, head_pad=0.016))
            brow.append(push_outside_body_and_head(pb, body_pad=0.012, head_pad=0.016))
        bib_fg.append(frow)
        bib_bg.append(brow)
    add_grid_slab(bm, bib_fg, bib_bg, mat_idx=0)

    # 3. Lower flared apron skirt wrapping front & sides cleanly (z=0.615 -> 0.265)
    skirt_z = [0.615, 0.530, 0.440, 0.350, 0.265]
    sk_fg, sk_bg = [], []
    n_sk = 18
    for idx, z in enumerate(skirt_z):
        t = idx / (len(skirt_z) - 1)
        span = 1.55 + 0.12 * t  # wraps nicely past the sides without clumsy rear wings
        flare = 0.026 + 0.020 * t  # gentle A-line skirt flare
        rc = r_cone(z)
        frow, brow = [], []
        for c in range(n_sk):
            u = (c / (n_sk - 1)) * 2.0 - 1.0
            a = u * span
            pf = Vector((math.sin(a) * (rc + flare), -math.cos(a) * (rc + flare), z))
            pb = Vector((math.sin(a) * (rc + flare - 0.014), -math.cos(a) * (rc + flare - 0.014), z))
            frow.append(push_outside_body_and_head(pf, body_pad=0.014, head_pad=0.016))
            brow.append(push_outside_body_and_head(pb, body_pad=0.011, head_pad=0.016))
        sk_fg.append(frow)
        sk_bg.append(brow)
    add_grid_slab(bm, sk_fg, sk_bg, mat_idx=0)

    # 4. Crisp waist belt strap wrapping 360° at z=0.615
    belt_pts = [neck_ring_pt(j * math.tau / 28, 0.615, pad=0.028) for j in range(28)]
    add_tube(bm, belt_pts, (0.014, 0.020), n_sides=8, closed_loop=True, cap_ends=False, mat_idx=1)

    # 5. Cute sculpted bow knot & two short tie tails at the back (ang = pi)
    rc_w = r_cone(0.615)
    back_knot = Vector((0.0, rc_w + 0.044, 0.615))
    add_sphere(bm, back_knot, (0.032, 0.026, 0.026), mat_idx=1, u=8, v=6)
    for sx in (-1.0, 1.0):
        # Bow loop
        loop_pts = []
        for k in range(12):
            th = k * math.tau / 12
            lx = sx * (0.025 + 0.052 * (0.5 - 0.5 * math.cos(th)))
            lz = 0.615 + 0.030 * math.sin(th)
            ly = rc_w + 0.044 + 0.014 * (0.5 - 0.5 * math.cos(th))
            loop_pts.append(Vector((lx, ly, lz)))
        add_tube(bm, loop_pts, (0.011, 0.014), n_sides=6, closed_loop=True, cap_ends=False, mat_idx=1)
        # Short hanging tie tail
        tail_pts = [
            Vector((sx * 0.018, rc_w + 0.042, 0.605)),
            Vector((sx * 0.045, r_cone(0.515) + 0.036, 0.515)),
            Vector((sx * 0.068, r_cone(0.430) + 0.032, 0.430)),
        ]
        add_tube(bm, tail_pts, [(0.013, 0.008), (0.016, 0.008), (0.018, 0.006)], n_sides=6, cap_ends=True, mat_idx=1)

    # 6. Front kangaroo pocket with navy top trim
    pk_z = [0.545, 0.475, 0.400]
    pk_fg, pk_bg = [], []
    for idx, z in enumerate(pk_z):
        t = idx / (len(pk_z) - 1)
        rc = r_cone(z)
        flare = 0.026 + 0.020 * ((0.615 - z) / 0.350)
        frow, brow = [], []
        for c in range(7):
            u = (c / 6.0) * 2.0 - 1.0
            a = u * 0.42
            pf = Vector((math.sin(a) * (rc + flare + 0.014), -math.cos(a) * (rc + flare + 0.014), z))
            pb = Vector((math.sin(a) * (rc + flare - 0.002), -math.cos(a) * (rc + flare - 0.002), z))
            frow.append(pf)
            brow.append(pb)
        pk_fg.append(frow)
        pk_bg.append(brow)
    add_grid_slab(bm, pk_fg, pk_bg, mat_idx=0)
    # Navy top trim on pocket
    trim_pts = []
    for c in range(9):
        u = (c / 8.0) * 2.0 - 1.0
        a = u * 0.43
        z = 0.548
        rc = r_cone(z)
        flare = 0.026 + 0.020 * ((0.615 - z) / 0.350)
        trim_pts.append(Vector((math.sin(a) * (rc + flare + 0.016), -math.cos(a) * (rc + flare + 0.016), z)))
    add_tube(bm, trim_pts, (0.009, 0.012), n_sides=6, cap_ends=True, mat_idx=1)

    mats = [
        ("ApronCloth", hex_lin(0xf4efe4), 0.85, 0.0),
        ("ApronStrap", hex_lin(0x283a58), 0.80, 0.02),
    ]
    return bm, mats


def build_cuello_bufanda():
    """9 · Bufanda — Cozy plush knitted scarf with zero chin clipping, stripes, and fringe."""
    bm = bmesh.new()

    # 1. Plush double-wrapped knitted collar around the neck (strictly outside head & torso)
    n_u = 32
    # Lower wrap + slightly offset upper wrap for chunky knit fullness
    for (z_base, rx_t, rz_t, pad_extra) in ((0.880, 0.044, 0.040, 0.036), (0.935, 0.042, 0.036, 0.038)):
        rings = []
        for j in range(n_u):
            a = j * math.tau / n_u
            # Gentle wavy knit height, dipping slightly lower at front so chin stays totally clear
            z_c = z_base - 0.018 * math.cos(a) + 0.008 * math.sin(2.0 * a)
            rc = r_cone(min(0.995, max(0.245, z_c))) + pad_extra
            center = Vector((math.sin(a) * rc, -math.cos(a) * rc, z_c))
            out_dir = Vector((math.sin(a), -math.cos(a), 0.0)).normalized()
            ring = []
            for k in range(10):
                b = k * math.tau / 10
                p = center + out_dir * (math.cos(b) * rx_t) + Vector((0.0, 0.0, math.sin(b) * rz_t))
                p = push_outside_body_and_head(p, body_pad=0.015, head_pad=0.018)
                ring.append(p)
            rings.append(ring)
        # Connect closed torus rings
        v_rings = [[bm.verts.new(p) for p in ring] for ring in rings]
        for j in range(n_u):
            jn = (j + 1) % n_u
            for k in range(10):
                kn = (k + 1) % 10
                f = bm.faces.new((v_rings[j][k], v_rings[jn][k], v_rings[jn][kn], v_rings[j][kn]))
                f.material_index = 0
                f.smooth = True

    # 2. Draped long front tail on character's left chest (+X side, visible in front & 3/4!)
    tail_z = [0.875, 0.800, 0.720, 0.635, 0.550, 0.470, 0.405]
    t_fg, t_bg = [], []
    for idx, z in enumerate(tail_z):
        t = idx / (len(tail_z) - 1)
        rc = r_cone(z)
        a_center = 0.28 + 0.06 * math.sin(t * math.pi)  # hangs nicely slightly off-center (+X)
        hw_ang = 0.24 + 0.04 * t
        frow, brow = [], []
        for c in range(5):
            u = (c / 4.0) * 2.0 - 1.0
            a = a_center + u * hw_ang
            lift = 0.046 + 0.008 * (1.0 - u * u) - 0.010 * t
            pf = Vector((math.sin(a) * (rc + lift + 0.016), -math.cos(a) * (rc + lift + 0.016), z))
            pb = Vector((math.sin(a) * (rc + lift - 0.012), -math.cos(a) * (rc + lift - 0.012), z))
            frow.append(push_outside_body_and_head(pf, body_pad=0.016, head_pad=0.018))
            brow.append(push_outside_body_and_head(pb, body_pad=0.012, head_pad=0.018))
        t_fg.append(frow)
        t_bg.append(brow)
    add_grid_slab(bm, t_fg, t_bg, mat_idx=0)

    # 3. Cream-gold knitted stripe band near the bottom of the tail
    st_fg, st_bg = [], []
    for z in (0.485, 0.455):
        t = (0.875 - z) / (0.875 - 0.405)
        rc = r_cone(z)
        a_center = 0.28 + 0.06 * math.sin(t * math.pi)
        hw_ang = 0.245 + 0.04 * t
        frow, brow = [], []
        for c in range(5):
            u = (c / 4.0) * 2.0 - 1.0
            a = a_center + u * hw_ang
            lift = 0.046 + 0.008 * (1.0 - u * u) - 0.010 * t
            pf = Vector((math.sin(a) * (rc + lift + 0.020), -math.cos(a) * (rc + lift + 0.020), z))
            pb = Vector((math.sin(a) * (rc + lift - 0.015), -math.cos(a) * (rc + lift - 0.015), z))
            frow.append(push_outside_body_and_head(pf, body_pad=0.016, head_pad=0.018))
            brow.append(push_outside_body_and_head(pb, body_pad=0.012, head_pad=0.018))
        st_fg.append(frow)
        st_bg.append(brow)
    add_grid_slab(bm, st_fg, st_bg, mat_idx=1)

    # 4. Cute fringe tassels along the bottom edge of the tail
    z_bot = 0.405
    rc_bot = r_cone(z_bot)
    a_c = 0.28
    for k in range(5):
        u = (k / 4.0) * 2.0 - 1.0
        a = a_c + u * 0.24
        p0 = Vector((math.sin(a) * (rc_bot + 0.040), -math.cos(a) * (rc_bot + 0.040), z_bot + 0.005))
        p1 = Vector((math.sin(a) * (r_cone(z_bot - 0.055) + 0.036),
                     -math.cos(a) * (r_cone(z_bot - 0.055) + 0.036), z_bot - 0.055))
        add_tube(bm, [p0, p1], 0.009, n_sides=6, cap_ends=True, mat_idx=1)

    # 5. Short secondary tucked tail on the right (-X) for cozy asymmetric balance
    st2_z = [0.870, 0.785, 0.700, 0.630]
    t2_fg, t2_bg = [], []
    for idx, z in enumerate(st2_z):
        t = idx / (len(st2_z) - 1)
        rc = r_cone(z)
        a_center = -0.32 - 0.03 * t
        hw_ang = 0.20 + 0.03 * t
        frow, brow = [], []
        for c in range(5):
            u = (c / 4.0) * 2.0 - 1.0
            a = a_center + u * hw_ang
            lift = 0.036 + 0.006 * (1.0 - u * u) - 0.008 * t
            pf = Vector((math.sin(a) * (rc + lift + 0.014), -math.cos(a) * (rc + lift + 0.014), z))
            pb = Vector((math.sin(a) * (rc + lift - 0.010), -math.cos(a) * (rc + lift - 0.010), z))
            frow.append(push_outside_body_and_head(pf, body_pad=0.014, head_pad=0.018))
            brow.append(push_outside_body_and_head(pb, body_pad=0.011, head_pad=0.018))
        t2_fg.append(frow)
        t2_bg.append(brow)
    add_grid_slab(bm, t2_fg, t2_bg, mat_idx=0)

    mats = [
        ("ScarfRed",   hex_lin(0xc83238), 0.88, 0.0),
        ("ScarfCream", hex_lin(0xf2e4c4), 0.88, 0.0),
    ]
    return bm, mats


def build_cuello_camara():
    """10 · Cámara de fotos — Retro silver-and-black tourist camera hanging on a neck strap."""
    bm = bmesh.new()

    # Camera resting cleanly on the front chest (z_c = 0.65), pitched along cone slope (-0.185 rad)
    z_c = 0.655
    rc = r_cone(z_c)
    tilt = 0.185  # Blender +X rotation tilts top back (+Y) and bottom forward (-Y), matching front cone!
    cam_pos = Vector((0.0, -(rc + 0.056), z_c))

    # 1. Neck strap looping from left lug -> around neck -> right lug
    strap_pts = []
    # Right side going up from camera lug (-0.095, z=0.69) to neck right (-0.52 rad, z=0.94)
    lug_y = -(r_cone(0.695) + 0.044)
    strap_pts.append(Vector((-0.092, lug_y, 0.695)))
    strap_pts.append(neck_ring_pt(-0.34, 0.79, pad=0.022))
    strap_pts.append(neck_ring_pt(-0.56, 0.89, pad=0.018))
    # Around back of neck
    for k in range(13):
        t = k / 12.0
        a = -0.68 - t * (math.tau - 1.36)
        z = 0.945 + 0.015 * math.sin(t * math.pi)
        strap_pts.append(neck_ring_pt(a, z, pad=0.015))
    strap_pts.append(neck_ring_pt(0.56, 0.89, pad=0.018))
    strap_pts.append(neck_ring_pt(0.34, 0.79, pad=0.022))
    strap_pts.append(Vector((0.092, lug_y, 0.695)))
    add_tube(bm, strap_pts, (0.010, 0.014), n_sides=6, closed_loop=False, cap_ends=True, mat_idx=0)

    # 2. Camera main black leatherette body + brushed silver top plate
    add_bevel_box(bm, cam_pos, (0.215, 0.072, 0.118), mat_idx=0, rot_x=tilt, bevel=0.012)
    rot_m = Matrix.Rotation(tilt, 3, 'X')
    top_plate = cam_pos + rot_m @ Vector((0.0, 0.0, 0.048))
    add_bevel_box(bm, top_plate, (0.210, 0.070, 0.036), mat_idx=1, rot_x=tilt, bevel=0.008)
    # Prism viewfinder hump in center-top
    prism_p = cam_pos + rot_m @ Vector((0.0, 0.002, 0.074))
    add_bevel_box(bm, prism_p, (0.076, 0.062, 0.034), mat_idx=1, rot_x=tilt, bevel=0.007)
    # Shutter button on top-right (-X in Blender = viewer's left, classic camera right hand!)
    shut_p = cam_pos + rot_m @ Vector((-0.070, -0.006, 0.074))
    add_cyl(bm, shut_p, 0.014, 0.022, mat_idx=1, segs=10, rot_x=tilt)
    # Flash window on upper left (+X)
    flash_p = cam_pos + rot_m @ Vector((0.068, -0.035, 0.044))
    add_bevel_box(bm, flash_p, (0.034, 0.012, 0.020), mat_idx=2, rot_x=tilt, bevel=0.003)

    # 3. Protruding retro lens barrel (black barrel + silver focus ring + dark glass lens)
    lens_base = cam_pos + rot_m @ Vector((0.0, -0.052, -0.006))
    add_cyl(bm, lens_base, 0.048, 0.048, mat_idx=0, segs=16, rot_x=tilt + math.pi / 2.0)
    lens_ring = cam_pos + rot_m @ Vector((0.0, -0.066, -0.006))
    add_cyl(bm, lens_ring, 0.051, 0.016, mat_idx=1, segs=16, rot_x=tilt + math.pi / 2.0)
    lens_glass = cam_pos + rot_m @ Vector((0.0, -0.078, -0.006))
    add_cyl(bm, lens_glass, 0.038, 0.010, mat_idx=2, segs=16, rot_x=tilt + math.pi / 2.0)

    mats = [
        ("CamBlack",  hex_lin(0x1f2026), 0.65, 0.05),
        ("CamSilver", hex_lin(0xcfd4da), 0.28, 0.65),
        ("CamGlass",  hex_lin(0x1e3852), 0.12, 0.15),
    ]
    return bm, mats


def build_cuello_flores():
    """11 · Collar de flores — Colorful 360° Hawaiian flower lei garland."""
    bm = bmesh.new()

    n_fl = 14
    for i in range(n_fl):
        a = i * math.tau / n_fl
        # Drape gracefully lower across the front chest, higher behind the neck
        z = 0.875 - 0.080 * math.cos(a)
        rc = r_cone(z) + 0.032
        center = Vector((math.sin(a) * rc, -math.cos(a) * rc, z))
        center = push_outside_body_and_head(center, body_pad=0.024, head_pad=0.018)

        # Outward normal of the cone at this angle
        out_n = Vector((math.sin(a) * 0.98, -math.cos(a) * 0.98, 0.185)).normalized()
        tan_u = Vector((math.cos(a), math.sin(a), 0.0)).normalized()
        tan_v = out_n.cross(tan_u).normalized()

        # Alternate cheerful tropical blossom colors (coral pink, sunny yellow, crisp white)
        flower_mat = i % 3

        # 5 plump stylized petals around flower center
        for p in range(5):
            pa = p * math.tau / 5.0 + (i * 0.35)
            p_dir = tan_u * math.cos(pa) + tan_v * math.sin(pa)
            pet_c = center + p_dir * 0.036 + out_n * 0.004
            # Build flattened petal ellipsoid aligned to p_dir / out_n
            res = bmesh.ops.create_uvsphere(bm, u_segments=6, v_segments=4, radius=1.0)
            p_side = out_n.cross(p_dir).normalized()
            for vert in res['verts']:
                q = (pet_c
                     + p_dir * (vert.co.x * 0.033)
                     + p_side * (vert.co.y * 0.026)
                     + out_n * (vert.co.z * 0.015))
                vert.co = q
                for f in vert.link_faces:
                    f.material_index = flower_mat
                    f.smooth = True

        # Contrasting sunny center pistil
        center_mat = 1 if flower_mat != 1 else 0
        add_sphere(bm, center + out_n * 0.014, (0.016, 0.016, 0.016), mat_idx=center_mat, u=6, v=4)

        # Little tropical green leaf tucked between blossoms
        a_leaf = a + math.tau / (2.0 * n_fl)
        z_l = 0.875 - 0.080 * math.cos(a_leaf)
        rc_l = r_cone(z_l) + 0.024
        lc = push_outside_body_and_head(Vector((math.sin(a_leaf) * rc_l, -math.cos(a_leaf) * rc_l, z_l)),
                                        body_pad=0.018, head_pad=0.018)
        l_out = Vector((math.sin(a_leaf) * 0.98, -math.cos(a_leaf) * 0.98, 0.185)).normalized()
        l_u = Vector((math.cos(a_leaf), math.sin(a_leaf), 0.0)).normalized()
        l_v = l_out.cross(l_u).normalized()
        l_dir = (l_u * 0.55 + l_v * (0.83 if i % 2 == 0 else -0.83)).normalized()
        l_side = l_out.cross(l_dir).normalized()
        res = bmesh.ops.create_uvsphere(bm, u_segments=6, v_segments=3, radius=1.0)
        for vert in res['verts']:
            vert.co = (lc + l_dir * (vert.co.x * 0.038)
                       + l_side * (vert.co.y * 0.019)
                       + l_out * (vert.co.z * 0.010))
            for f in vert.link_faces:
                f.material_index = 3
                f.smooth = True

    mats = [
        ("LeiPink",   hex_lin(0xf05078), 0.78, 0.0),
        ("LeiYellow", hex_lin(0xf6c830), 0.78, 0.0),
        ("LeiWhite",  hex_lin(0xf8f4ec), 0.80, 0.0),
        ("LeiLeaf",   hex_lin(0x3a943c), 0.82, 0.0),
    ]
    return bm, mats


def build_cuello_gargantilla():
    """12 · Gargantilla — Sleek matte black leather choker with silver O-ring & micro-studs."""
    bm = bmesh.new()

    # 1. Flat-ish snug black collar band hugging the throat cleanly
    n_u = 32
    rings = []
    z_lo, z_hi = 0.916, 0.966
    for (z, dr) in ((z_lo, 0.0), (z_lo, 0.015), (z_hi, 0.015), (z_hi, 0.0)):
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            p = neck_ring_pt(a, z, pad=0.014)
            xy = Vector((p.x, p.y))
            if xy.length > 1e-5:
                xy = xy + xy.normalized() * dr
            ring.append(push_outside_body_and_head(Vector((xy.x, xy.y, p.z)), body_pad=0.013, head_pad=0.016))
        rings.append(ring)
    add_lathe(bm, rings, mat_idx=0, closed_top=False, closed_bottom=False)

    # 2. Silver front O-ring hanging cleanly at front center
    z_ring = 0.910
    rc_front = r_cone(z_ring) + 0.036
    o_pts = []
    n_o = 18
    for j in range(n_o):
        th = j * math.tau / n_o
        # Ring lies flat against front cone slope
        x = math.cos(th) * 0.042
        dz = math.sin(th) * 0.042
        z = z_ring + dz
        y = -(r_cone(z) + 0.036)
        o_pts.append(push_outside_body_and_head(Vector((x, y, z)), body_pad=0.018, head_pad=0.016))
    add_tube(bm, o_pts, 0.009, n_sides=8, closed_loop=True, cap_ends=False, mat_idx=1)

    # Small metal clasp holding the O-ring to the leather band
    clasp_p = push_outside_body_and_head(Vector((0.0, -(r_cone(0.942) + 0.034), 0.942)), body_pad=0.018, head_pad=0.016)
    add_bevel_box(bm, clasp_p, (0.024, 0.022, 0.036), mat_idx=1, rot_x=0.18, bevel=0.004)

    # 3. Neat little silver pyramid/dome studs spaced around the choker
    for deg in (-140, -100, -60, -28, 28, 60, 100, 140):
        a = math.radians(deg)
        p = neck_ring_pt(a, 0.941, pad=0.030)
        add_sphere(bm, p, (0.013, 0.013, 0.013), mat_idx=1, u=8, v=5)

    mats = [
        ("ChokerBlack",  hex_lin(0x1c1c22), 0.68, 0.05),
        ("ChokerSilver", hex_lin(0xd4dae0), 0.22, 0.72),
    ]
    return bm, mats


# ==================== EXPORT PIPELINE ====================

def bake_vc(mesh, is_head=False):
    """Bake gentle directional + ambient shading into 'Col' vertex colour attribute."""
    col_attr = mesh.color_attributes.new(name="Col", type='BYTE_COLOR', domain='CORNER')
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            v = mesh.vertices[mesh.loops[li].vertex_index]
            n = v.normal
            # Gentle top-front light + soft underside tint
            nd = max(-1.0, min(1.0, n.z * 0.55 - n.y * 0.30))
            v_shade = 0.88 + 0.12 * (0.5 + 0.5 * nd)
            col_attr.data[li].color = (v_shade, v_shade, v_shade, 1.0)


def make_mat(name, rgba, roughness=0.75, metallic=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = rgba
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return m


BUILDERS = {
    "gafas_sol":          (build_gafas_sol, True),
    "gafas_aviador":      (build_gafas_aviador, True),
    "gafas_gato":         (build_gafas_gato, True),
    "gafas_corazon":      (build_gafas_corazon, True),
    "gafas_parche":       (build_gafas_parche, True),
    "cuello_corbata":     (build_cuello_corbata, False),
    "cuello_pajarita":    (build_cuello_pajarita, False),
    "cuello_delantal":    (build_cuello_delantal, False),
    "cuello_bufanda":     (build_cuello_bufanda, False),
    "cuello_camara":      (build_cuello_camara, False),
    "cuello_flores":      (build_cuello_flores, False),
    "cuello_gargantilla": (build_cuello_gargantilla, False),
}


def export_one(name, out_dir):
    fn, is_head = BUILDERS[name]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bm, mat_specs = fn()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()

    for (mname, rgba, rough, metal) in mat_specs:
        mesh.materials.append(make_mat(mname, rgba, rough, metal))

    mesh.update()
    bake_vc(mesh, is_head=is_head)

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)

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
        export_all_vertex_colors=True,
    )
    tris = sum(len(p.vertices) - 2 for p in mesh.polygons)
    print(f"BUILT {name}: {tris} tris, {len(mat_specs)} surfs -> {out_path}")


def main():
    argv = sys.argv
    if "--" not in argv:
        raise SystemExit("Usage: blender -b --python complementos.py -- OUT_DIR [names...]")
    args = argv[argv.index("--") + 1:]
    out_dir = args[0]
    names = args[1:] if len(args) > 1 else list(BUILDERS.keys())
    for n in names:
        if n not in BUILDERS:
            raise SystemExit(f"Unknown piece: {n}")
        export_one(n, out_dir)


if __name__ == "__main__":
    main()
