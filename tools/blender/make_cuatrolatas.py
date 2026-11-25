"""Builds the exterior 3D model of the classic Renault 4-inspired village car ("Cuatro Latas")
from scratch in Blender 4.5.9 and exports it to godot/assets/vehiculos/sk/cuatrolatas.glb.

Run:
    blender.exe -b --python tools/blender/make_cuatrolatas.py

Conventions matching Modelos.SK (modelos.gd):
  - 5 mesh objects: `body`, `wheel_fl`, `wheel_fr`, `wheel_bl`, `wheel_br`
  - Each wheel object has its origin on its axle; `body` is at (0, 0, 0).
  - glTF (+Y up, +Z forward, +X left): helper V(x, y, z) maps Godot (left, up, fwd) -> Blender (x, -z, y).
  - Materials: `Carpaint` (dynamically repainted in Godot), `Window` (replaced with translucent glass),
    `Plastic`, `Chrome`, `Steel`, `Headlight`, `Taillight`, `Indicator`, `Plate`, `Tyre`, `Interior`.
"""
import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

OUT_GLB = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "godot", "assets", "vehiculos", "sk", "cuatrolatas.glb")
)

# ------------------------------------------------------------------ helpers
def V(x: float, y: float, z: float) -> Vector:
    """Godot car frame (x=left, y=up, z=forward) -> Blender (x, -z, y)."""
    return Vector((x, -z, y))


def make_mat(name: str, rgba, roughness=0.5, metallic=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = rgba
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return m


def add_bm_obj(name: str, bm: bmesh.types.BMesh, mats, smooth=False):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(m)
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return obj


def add_box(bm, mat_idx, center, size, rot_xyz=(0.0, 0.0, 0.0), bevel=0.0):
    sx, sy, sz = size
    cx, cy, cz = center
    rx, ry, rz = rot_xyz
    R = Matrix.Rotation(rz, 3, 'Z') @ Matrix.Rotation(ry, 3, 'Y') @ Matrix.Rotation(rx, 3, 'X')
    hx, hy, hz = sx * 0.5, sy * 0.5, sz * 0.5
    corners = [
        Vector((-hx, -hy, -hz)), Vector((hx, -hy, -hz)), Vector((hx, hy, -hz)), Vector((-hx, hy, -hz)),
        Vector((-hx, -hy,  hz)), Vector((hx, -hy,  hz)), Vector((hx, hy,  hz)), Vector((-hx, hy,  hz)),
    ]
    bvs = []
    for c in corners:
        p = R @ c + Vector((cx, cy, cz))
        bvs.append(bm.verts.new(V(p.x, p.y, p.z)))
    faces_idx = [
        (0, 3, 2, 1), (4, 5, 6, 7),
        (0, 1, 5, 4), (2, 3, 7, 6),
        (0, 4, 7, 3), (1, 2, 6, 5),
    ]
    created_faces = []
    created_edges = set()
    for fi in faces_idx:
        f = bm.faces.new([bvs[i] for i in fi])
        f.material_index = mat_idx
        created_faces.append(f)
        for e in f.edges:
            created_edges.add(e)
    if bevel > 0.0:
        bmesh.ops.bevel(bm, geom=list(created_edges), offset=bevel, segments=2, affect='EDGES', clamp_overlap=True)
    return created_faces


def add_cyl(bm, mat_idx, center, radius, length, axis='Z', segs=18, r_end=None, cap_a=True, cap_b=True):
    if r_end is None:
        r_end = radius
    cx, cy, cz = center
    hl = length * 0.5
    ring_a = []
    ring_b = []
    for i in range(segs):
        a = 2.0 * math.pi * i / segs
        ca, sa = math.cos(a), math.sin(a)
        if axis == 'Z':
            pa = (cx + radius * ca, cy + radius * sa, cz - hl)
            pb = (cx + r_end * ca, cy + r_end * sa, cz + hl)
        elif axis == 'Y':
            pa = (cx + radius * ca, cy - hl, cz + radius * sa)
            pb = (cx + r_end * ca, cy + hl, cz + r_end * sa)
        else:
            pa = (cx - hl, cy + radius * ca, cz + radius * sa)
            pb = (cx + hl, cy + r_end * ca, cz + r_end * sa)
        ring_a.append(bm.verts.new(V(*pa)))
        ring_b.append(bm.verts.new(V(*pb)))
    faces = []
    for i in range(segs):
        j = (i + 1) % segs
        f = bm.faces.new([ring_a[i], ring_a[j], ring_b[j], ring_b[i]])
        f.material_index = mat_idx
        faces.append(f)
    if cap_a and radius > 1e-5:
        fa = bm.faces.new(list(reversed(ring_a)))
        fa.material_index = mat_idx
        faces.append(fa)
    if cap_b and r_end > 1e-5:
        fb = bm.faces.new(ring_b)
        fb.material_index = mat_idx
        faces.append(fb)
    return faces


def add_rounded_rect_loop(pts_corners, r_corner=0.055, segs=3):
    """Given 4 corner 3D points (p0, p1, p2, p3) in loop order, rounds each corner smoothly."""
    out = []
    n = len(pts_corners)
    vs = [Vector(p) for p in pts_corners]
    for i in range(n):
        p_prev = vs[(i - 1) % n]
        p_cur = vs[i]
        p_next = vs[(i + 1) % n]
        d1 = (p_prev - p_cur)
        d2 = (p_next - p_cur)
        l1, l2 = d1.length, d2.length
        rc = min(r_corner, l1 * 0.35, l2 * 0.35)
        a = p_cur + d1.normalized() * rc
        b = p_cur + d2.normalized() * rc
        for k in range(segs + 1):
            t = k / segs
            # Quadratic Bezier corner rounding
            q = ((1.0 - t) ** 2) * a + 2.0 * (1.0 - t) * t * p_cur + (t * t) * b
            out.append((q.x, q.y, q.z))
    return out


def add_poly_pane(bm, mat_idx, pts, thick_vec):
    """Creates a thin closed polygon pane from a loop of 3D points extruded by thick_vec."""
    v0 = [bm.verts.new(V(*p)) for p in pts]
    tv = Vector(thick_vec)
    v1 = [bm.verts.new(V(p[0] + tv.x, p[1] + tv.y, p[2] + tv.z)) for p in pts]
    f_front = bm.faces.new(v0)
    f_front.material_index = mat_idx
    f_back = bm.faces.new(list(reversed(v1)))
    f_back.material_index = mat_idx
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        fs = bm.faces.new([v0[i], v0[j], v1[j], v1[i]])
        fs.material_index = mat_idx


def add_tube(bm, mat_idx, pts, r, segs=10, cap=True, closed=False):
    """Sweeps a circular tube along a 3D polyline (or closed loop) in Godot coords."""
    rings = []
    n = len(pts)
    for idx, pt in enumerate(pts):
        p = Vector(pt)
        if closed:
            t = (Vector(pts[(idx + 1) % n]) - Vector(pts[(idx - 1) % n])).normalized()
        elif idx == 0:
            t = (Vector(pts[1]) - p).normalized()
        elif idx == n - 1:
            t = (p - Vector(pts[idx - 1])).normalized()
        else:
            t = (Vector(pts[idx + 1]) - Vector(pts[idx - 1])).normalized()
        ref = Vector((0, 1, 0)) if abs(t.y) < 0.9 else Vector((1, 0, 0))
        u = t.cross(ref).normalized()
        w = t.cross(u).normalized()
        ring = []
        for k in range(segs):
            a = 2.0 * math.pi * k / segs
            q = p + (u * math.cos(a) + w * math.sin(a)) * r
            ring.append(bm.verts.new(V(q.x, q.y, q.z)))
        rings.append(ring)
    count = n if closed else n - 1
    for i in range(count):
        r0, r1 = rings[i], rings[(i + 1) % n]
        for k in range(segs):
            kn = (k + 1) % segs
            f = bm.faces.new([r0[k], r0[kn], r1[kn], r1[k]])
            f.material_index = mat_idx
    if cap and not closed:
        f0 = bm.faces.new(list(reversed(rings[0])))
        f0.material_index = mat_idx
        f1 = bm.faces.new(rings[-1])
        f1.material_index = mat_idx


# ------------------------------------------------------------------ wheel builder
def build_wheel(name: str, pos, is_left: bool, mats, M):
    """Classic Renault 4 pressed-steel wheel with gleaming domed chrome center hubcap."""
    bm = bmesh.new()
    segs = 24
    sgn = 1.0 if is_left else -1.0
    # 1) Rounded Tyre (r_outer = 0.305, r_rim = 0.175, half_w = 0.074)
    tyre_prof = [
        (-0.068, 0.172), (-0.074, 0.215), (-0.073, 0.268), (-0.060, 0.298), (-0.038, 0.305),
        ( 0.038, 0.305), ( 0.060, 0.298), ( 0.073, 0.268), ( 0.074, 0.215), ( 0.068, 0.172),
    ]
    rings = []
    for ax, rr in tyre_prof:
        ring = [bm.verts.new(V(sgn * ax, rr * math.cos(2.0 * math.pi * i / segs), rr * math.sin(2.0 * math.pi * i / segs))) for i in range(segs)]
        rings.append(ring)
    for p_i in range(len(rings)):
        r0, r1 = rings[p_i], rings[(p_i + 1) % len(rings)]
        for i in range(segs):
            j = (i + 1) % segs
            f = bm.faces.new([r0[i], r0[j], r1[j], r1[i]])
            f.material_index = M["Tyre"]

    # 2) Pressed-steel silver wheel rim & dish
    rim_prof = [
        (-0.058, 0.040), (-0.058, 0.176), (0.064, 0.176), (0.066, 0.164),
        (0.044, 0.152), (0.046, 0.118), (0.058, 0.102), (0.058, 0.088),
    ]
    rrings = []
    for ax, rr in rim_prof:
        ring = [bm.verts.new(V(sgn * ax, rr * math.cos(2.0 * math.pi * i / segs), rr * math.sin(2.0 * math.pi * i / segs))) for i in range(segs)]
        rrings.append(ring)
    for p_i in range(len(rrings) - 1):
        r0, r1 = rrings[p_i], rrings[p_i + 1]
        for i in range(segs):
            j = (i + 1) % segs
            f = bm.faces.new([r0[i], r0[j], r1[j], r1[i]])
            f.material_index = M["Steel"]
    f_back = bm.faces.new(list(reversed(rrings[0])))
    f_back.material_index = M["Steel"]

    # 3) Iconic domed chrome hubcap ("tapacubo cromado", Photos 1, 3 & 4)
    cap_prof = [(0.056, 0.098), (0.068, 0.092), (0.080, 0.070), (0.086, 0.036)]
    crings = []
    for ax, rr in cap_prof:
        ring = [bm.verts.new(V(sgn * ax, rr * math.cos(2.0 * math.pi * i / segs), rr * math.sin(2.0 * math.pi * i / segs))) for i in range(segs)]
        crings.append(ring)
    for p_i in range(len(crings) - 1):
        r0, r1 = crings[p_i], crings[p_i + 1]
        for i in range(segs):
            j = (i + 1) % segs
            f = bm.faces.new([r0[i], r0[j], r1[j], r1[i]])
            f.material_index = M["Chrome"]
    f_tip = bm.faces.new(crings[-1])
    f_tip.material_index = M["Chrome"]

    # 6 classic Renault 4 ventilation holes around the steel dish
    for k in range(6):
        a = 2.0 * math.pi * k / 6.0
        add_box(bm, M["Plastic"], (sgn * 0.049, 0.134 * math.cos(a), 0.134 * math.sin(a)), (0.012, 0.022, 0.022))

    obj = add_bm_obj(name, bm, mats, smooth=True)
    obj.location = V(*pos)
    return obj


# ------------------------------------------------------------------ main Renault 4 body builder
def build_body(mats, M):
    bm = bmesh.new()

    W_BELT = 0.760
    Y_SILL = 0.245
    Y_BELT = 0.935
    WF_Z, WF_Y, WF_R = 1.20, 0.305, 0.352
    WR_Z, WR_Y, WR_R = -1.12, 0.305, 0.348

    def body_half_w(z: float, y: float) -> float:
        """Classic Renault 4 planform: smooth rounded front & rear corners + subtle mid-door bulge."""
        if z > 1.32:
            t = min(1.0, (z - 1.32) / 0.48)
            w_top = W_BELT - 0.068 * (t ** 2.2)
        elif z < -1.26:
            t = min(1.0, (-1.26 - z) / 0.52)
            w_top = W_BELT - 0.062 * (t ** 2.1)
        else:
            w_top = W_BELT
        u = max(0.0, min(1.0, (y - Y_SILL) / (Y_BELT - Y_SILL)))
        belly = 0.028 * math.sin(u * math.pi)
        tuck = -0.042 * ((1.0 - u) ** 1.6)
        return w_top + belly + tuck

    def bonnet_y(x: float, z: float) -> float:
        """Signature Renault 4 clamshell bonnet: raised central rib + twin valleys + plump rounded front wings!"""
        t = max(0.0, min(1.0, (z - 0.56) / (1.78 - 0.56)))
        base = 0.945 - 0.088 * t - 0.075 * (max(0.0, (t - 0.78) / 0.22) ** 2.0)
        ax = abs(x)
        rib = 0.024 * math.exp(-((ax / 0.14) ** 2)) * (1.0 - 0.28 * t)
        fender = 0.022 * math.exp(-(((ax - 0.56) / 0.14) ** 2)) * (0.45 + 0.55 * t)
        edge_drop = -0.052 * (max(0.0, (ax - 0.60) / 0.16) ** 2.0)
        return base + rib + fender + edge_drop

    # Rear boundary of the lower side flank matches the EXACT sloped hatchback angle!
    # At y = 0.30 (bumper level): z_rear = -1.76; at y = 0.935 (beltline): z_rear = -1.53!
    def rear_z_at(y: float) -> float:
        u = max(0.0, min(1.0, (y - 0.30) / (Y_BELT - 0.30)))
        return -1.76 + 0.23 * u

    # Front boundary of the lower side flank rounds gently back at top & bottom to match the nose seamlessly!
    def front_z_at(y: float) -> float:
        u = max(0.0, min(1.0, (y - 0.30) / (0.81 - 0.30)))
        return 1.755 + 0.020 * math.sin(u * math.pi)

    # --------------------------------------------------------------
    # 1) SCULPTED BONNET TOP + SEAMLESS WRAP-AROUND FRONT NOSE!
    # --------------------------------------------------------------
    z_bonnet = [0.56, 0.72, 0.90, 1.08, 1.26, 1.44, 1.58, 1.68, 1.74, 1.775]
    x_fracs = [-1.0, -0.92, -0.80, -0.62, -0.42, -0.22, -0.10, 0.0, 0.10, 0.22, 0.42, 0.62, 0.80, 0.92, 1.0]
    bonnet_grid = []
    for zi, z in enumerate(z_bonnet):
        row = []
        hw = body_half_w(z, Y_BELT)
        for xf in x_fracs:
            x = xf * hw
            y = bonnet_y(x, z)
            # Pull front-most outer corners gently back to meet front_z_at(y) seamlessly with ZERO gap!
            z_cur = z
            if zi >= len(z_bonnet) - 2:
                f_pull = 1.0 if zi == len(z_bonnet) - 1 else 0.45
                z_cur = z - 0.020 * f_pull * (abs(xf) ** 2.4)
            row.append(bm.verts.new(V(x, y, z_cur)))
        bonnet_grid.append(row)
    for zi in range(len(bonnet_grid) - 1):
        for xi in range(len(x_fracs) - 1):
            f = bm.faces.new([bonnet_grid[zi][xi], bonnet_grid[zi][xi + 1], bonnet_grid[zi + 1][xi + 1], bonnet_grid[zi + 1][xi]])
            f.material_index = M["Carpaint"]

    # Front nose fascia stitched directly from bonnet_grid[-1] down to lower valence (3 smooth rows, zero corner seam!)
    nose_rows = [bonnet_grid[-1]]
    for y_n, bulge in ((0.64, 0.036), (0.46, 0.032), (0.295, 0.012)):
        row = []
        z_edge = front_z_at(y_n)
        hw = body_half_w(z_edge, y_n)
        for xf in x_fracs:
            x = xf * hw
            # Center bows slightly forward (+bulge), outer edge meets z_edge EXACTLY so side & front are watertight!
            z_pt = z_edge + bulge * (1.0 - abs(xf) ** 2.2)
            row.append(bm.verts.new(V(x, y_n, z_pt)))
        nose_rows.append(row)
    for ri in range(len(nose_rows) - 1):
        for xi in range(len(x_fracs) - 1):
            f = bm.faces.new([nose_rows[ri][xi], nose_rows[ri][xi + 1], nose_rows[ri + 1][xi + 1], nose_rows[ri + 1][xi]])
            f.material_index = M["Carpaint"]

    # --------------------------------------------------------------
    # 2) LEFT & RIGHT SCULPTED BODY SIDES (SEAMLESS SLOPED REAR + REAL WHEEL ARCHES!)
    # --------------------------------------------------------------
    def arch_bottom_y(z: float) -> float:
        y = Y_SILL
        if z > 1.54:
            y = max(y, Y_SILL + 0.055 * ((z - 1.54) / 0.24))
        elif z < -1.48:
            y = max(y, Y_SILL + 0.055 * ((-1.48 - z) / 0.28))
        df = abs(z - WF_Z)
        if df < WF_R:
            y = max(y, WF_Y + math.sqrt(max(0.0, WF_R * WF_R - df * df)))
        dr = abs(z - WR_Z)
        if dr < WR_R:
            y = max(y, WR_Y + math.sqrt(max(0.0, WR_R * WR_R - dr * dr)))
        return y

    def side_top_y(z: float) -> float:
        if z >= 0.56:
            hw = body_half_w(z, Y_BELT)
            return bonnet_y(hw, z)
        return Y_BELT

    # Build clean parametric columns from rear sloped edge to front curved edge!
    # Interior Z stations (strictly inside [-1.52 .. +1.73] so rear & front end columns slope cleanly!)
    z_mid = [-1.51]
    for k in range(11):
        ang = math.pi * (1.0 - k / 10.0)
        z_mid.append(WR_Z + WR_R * math.cos(ang))
    z_mid += [-0.58, -0.28, 0.05, 0.35, 0.56, 0.78]
    for k in range(11):
        ang = math.pi * (1.0 - k / 10.0)
        z_mid.append(WF_Z + WF_R * math.cos(ang))
    z_mid += [1.62, 1.71]
    z_mid = sorted(set(round(v, 4) for v in z_mid))

    for sgn in (1.0, -1.0):
        # First column = exact sloped rear edge (from y=0.295, z=-1.76 up to y=Y_BELT, z=-1.53)!
        rows = []
        rear_col = []
        for ri in range(4):
            u = ri / 3.0
            y = 0.295 + (Y_BELT - 0.295) * u
            z = rear_z_at(y)
            x = sgn * body_half_w(z, y)
            rear_col.append(bm.verts.new(V(x, y, z)))
        rows.append(rear_col)

        for z in z_mid:
            y0 = arch_bottom_y(z)
            y1 = side_top_y(z)
            col = []
            for ri in range(4):
                u = ri / 3.0
                y = y0 + (y1 - y0) * u
                # Clamp z behind sloped rear edge if near rear corner
                z_eff = max(z, rear_z_at(y) + 0.01) if z < -1.45 else z
                x = sgn * body_half_w(z_eff, y)
                col.append(bm.verts.new(V(x, y, z_eff)))
            rows.append(col)

        # Last column = exact curved front edge matching nose_rows outer edge!
        front_col = []
        y_top_f = bonnet_y(body_half_w(1.755, Y_BELT), 1.775)
        for ri in range(4):
            u = ri / 3.0
            y = 0.295 + (y_top_f - 0.295) * u
            z = front_z_at(y)
            x = sgn * body_half_w(z, y)
            front_col.append(bm.verts.new(V(x, y, z)))
        rows.append(front_col)

        for zi in range(len(rows) - 1):
            for ri in range(3):
                if sgn > 0:
                    f = bm.faces.new([rows[zi][ri], rows[zi + 1][ri], rows[zi + 1][ri + 1], rows[zi][ri + 1]])
                else:
                    f = bm.faces.new([rows[zi][ri], rows[zi][ri + 1], rows[zi + 1][ri + 1], rows[zi + 1][ri]])
                f.material_index = M["Carpaint"]

        # Recessed dark inner wheel-well liners + rolled painted eyebrow lip over both arches
        for wz, wy, wr in ((WF_Z, WF_Y, WF_R), (WR_Z, WR_Y, WR_R)):
            arch_out, arch_in = [], []
            for k in range(13):
                ang = math.pi * k / 12.0
                az = wz + wr * math.cos(ang)
                ay = max(Y_SILL, wy + wr * math.sin(ang))
                arch_out.append(bm.verts.new(V(sgn * (body_half_w(az, ay) - 0.004), ay, az)))
                arch_in.append(bm.verts.new(V(sgn * (body_half_w(az, ay) - 0.24), ay, az)))
            for k in range(12):
                f = bm.faces.new([arch_out[k], arch_out[k + 1], arch_in[k + 1], arch_in[k]])
                f.material_index = M["Plastic"]
            f_wall = bm.faces.new(arch_in)
            f_wall.material_index = M["Plastic"]

            lip_pts = []
            for k in range(11):
                ang = math.radians(14.0 + 152.0 * k / 10.0)
                az = wz + (wr + 0.011) * math.cos(ang)
                ay = wy + (wr + 0.011) * math.sin(ang)
                lip_pts.append((sgn * (body_half_w(az, ay) + 0.007), ay, az))
            add_tube(bm, M["Carpaint"], lip_pts, 0.014, segs=6, cap=True)

        # Signature diagonal front-wing seam ("aleta delantera") + front/rear door seams
        add_tube(bm, M["Plastic"], [
            (sgn * (body_half_w(0.55, 0.91) + 0.006), 0.91, 0.55),
            (sgn * (body_half_w(0.67, 0.60) + 0.006), 0.60, 0.68),
            (sgn * (body_half_w(0.80, 0.28) + 0.006), 0.28, 0.80),
        ], 0.005, segs=5)
        for dz in (-0.28, -0.94):
            add_tube(bm, M["Plastic"], [
                (sgn * (body_half_w(dz, 0.91) + 0.005), 0.91, dz),
                (sgn * (body_half_w(dz, 0.56) + 0.005), 0.56, dz),
                (sgn * (body_half_w(dz, 0.27) + 0.005), 0.27, dz),
            ], 0.0045, segs=5)

        # Classic thin chrome waist molding running cleanly along the entire side (Photos 1 & 4!)
        trim_pts = [(sgn * (body_half_w(tz, 0.835) + 0.008), 0.835, tz) for tz in (-1.52, -1.10, -0.60, -0.10, 0.40, 0.90, 1.48)]
        add_tube(bm, M["Chrome"], trim_pts, 0.010, segs=6, cap=True)
        # Subtle lower chrome rocker sill bar between the wheels
        add_tube(bm, M["Chrome"], [
            (sgn * (body_half_w(-0.74, 0.27) + 0.007), 0.27, -0.74),
            (sgn * (body_half_w(0.76, 0.27) + 0.007), 0.27, 0.76),
        ], 0.011, segs=6, cap=True)

        # Classic slim horizontal chrome door handles
        for hz in (-0.16, -0.82):
            hx = sgn * (body_half_w(hz, 0.880) + 0.018)
            add_box(bm, M["Chrome"], (hx, 0.880, hz), (0.016, 0.017, 0.105), bevel=0.003)
            add_box(bm, M["Plastic"], (hx - sgn * 0.010, 0.880, hz), (0.010, 0.021, 0.115))

    # --------------------------------------------------------------
    # 3) SLOPED HATCHBACK REAR TAILGATE (WATERTIGHT WITH SLOPED SIDE FLANKS, ZERO FINS!)
    # --------------------------------------------------------------
    rear_rows = []
    for ri in range(4):
        u = ri / 3.0
        ry = 0.295 + (Y_BELT - 0.295) * u
        rz = rear_z_at(ry)
        hw = body_half_w(rz, ry)
        row = []
        for xf in (-1.0, -0.82, -0.55, -0.25, 0.0, 0.25, 0.55, 0.82, 1.0):
            x = xf * hw
            # Center bows subtly outward (-0.022), outer edges match rz EXACTLY!
            zb = rz - 0.024 * (1.0 - abs(xf) ** 2.2)
            row.append(bm.verts.new(V(x, ry, zb)))
        rear_rows.append(row)
    for ri in range(len(rear_rows) - 1):
        for xi in range(len(rear_rows[0]) - 1):
            f = bm.faces.new([rear_rows[ri][xi], rear_rows[ri + 1][xi], rear_rows[ri + 1][xi + 1], rear_rows[ri][xi + 1]])
            f.material_index = M["Carpaint"]
    # Subtle vertical tailgate shut-lines on rear hatch (Photo 3!)
    for sgn in (1.0, -1.0):
        add_tube(bm, M["Plastic"], [
            (sgn * 0.50, 0.92, rear_z_at(0.92) - 0.014),
            (sgn * 0.52, 0.34, rear_z_at(0.34) - 0.016),
        ], 0.004, segs=4)

    # Underbody dark floor closing the bottom cleanly
    add_box(bm, M["Plastic"], (0.0, Y_SILL + 0.018, 0.0), (1.34, 0.036, 3.40))

    # --------------------------------------------------------------
    # 4) AUTHENTIC ROUNDED RENAULT 4 GREENHOUSE: 3 ROUNDED-CORNER WINDOWS PER SIDE + DOMED ROOF!
    # --------------------------------------------------------------
    Y_ROOF_EDGE = 1.465
    X_ROOF = 0.615
    ZF_BELT, ZF_ROOF = 0.56, 0.35
    ZR_BELT, ZR_ROOF = -1.53, -1.30

    def pill_x(y: float) -> float:
        u = max(0.0, min(1.0, (y - Y_BELT) / (Y_ROOF_EDGE - Y_BELT)))
        return W_BELT + (X_ROOF - W_BELT) * (u ** 1.15)

    # Softly crowned Renault 4 roof panel with rounded front & rear brow curve (Photos 1 & 3!)
    z_roof = [-1.29, -1.21, -1.06, -0.78, -0.40, 0.0, 0.22, 0.31, 0.36]
    x_rf = [-1.0, -0.88, -0.62, -0.30, 0.0, 0.30, 0.62, 0.88, 1.0]
    rgrid = []
    for rz in z_roof:
        row = []
        t_z = max(0.0, min(1.0, (rz - (-1.29)) / (0.36 - (-1.29))))
        z_crown = 0.036 * math.sin(t_z * math.pi) ** 0.72
        w_taper = 1.0 - 0.060 * ((2.0 * t_z - 1.0) ** 4)
        for xf in x_rf:
            x = xf * X_ROOF * w_taper
            x_crown = 0.044 * math.cos(xf * math.pi * 0.5)
            y = Y_ROOF_EDGE - 0.008 + z_crown + x_crown
            row.append(bm.verts.new(V(x, y, rz)))
        rgrid.append(row)
    for zi in range(len(rgrid) - 1):
        for xi in range(len(x_rf) - 1):
            f = bm.faces.new([rgrid[zi][xi], rgrid[zi][xi + 1], rgrid[zi + 1][xi + 1], rgrid[zi + 1][xi]])
            f.material_index = M["Carpaint"]
    # Clean roof headliner tucked flush inside the roof dome (zero protruding strip in 1st-person!)
    add_box(bm, M["Interior"], (0.0, Y_ROOF_EDGE + 0.032, -0.52), (1.12, 0.018, 1.44))

    # Smooth curved front & rear roof headers + painted lower cowl sill
    add_tube(bm, M["Carpaint"], [
        (-X_ROOF + 0.015, Y_ROOF_EDGE - 0.012, ZF_ROOF + 0.005),
        (-0.32, Y_ROOF_EDGE + 0.002, ZF_ROOF + 0.024),
        ( 0.00, Y_ROOF_EDGE + 0.008, ZF_ROOF + 0.030),
        ( 0.32, Y_ROOF_EDGE + 0.002, ZF_ROOF + 0.024),
        ( X_ROOF - 0.015, Y_ROOF_EDGE - 0.012, ZF_ROOF + 0.005),
    ], 0.032, segs=10, cap=True)
    add_tube(bm, M["Carpaint"], [
        (-X_ROOF + 0.015, Y_ROOF_EDGE - 0.012, ZR_ROOF - 0.005),
        (-0.32, Y_ROOF_EDGE + 0.002, ZR_ROOF - 0.022),
        ( 0.00, Y_ROOF_EDGE + 0.008, ZR_ROOF - 0.028),
        ( 0.32, Y_ROOF_EDGE + 0.002, ZR_ROOF - 0.022),
        ( X_ROOF - 0.015, Y_ROOF_EDGE - 0.012, ZR_ROOF - 0.005),
    ], 0.034, segs=10, cap=True)
    # Base cowl strip under windscreen
    add_box(bm, M["Carpaint"], (0.0, Y_BELT + 0.006, ZF_BELT), (1.48, 0.042, 0.068), bevel=0.008)

    for sgn in (1.0, -1.0):
        # Softly curved cant rail + slim chrome rain-gutter drip rail along roof edge
        add_tube(bm, M["Carpaint"], [
            (sgn * (X_ROOF - 0.008), Y_ROOF_EDGE - 0.010, ZF_ROOF),
            (sgn * (X_ROOF + 0.004), Y_ROOF_EDGE + 0.006, -0.48),
            (sgn * (X_ROOF - 0.008), Y_ROOF_EDGE - 0.010, ZR_ROOF),
        ], 0.030, segs=8, cap=True)
        add_tube(bm, M["Chrome"], [
            (sgn * (X_ROOF + 0.019), Y_ROOF_EDGE - 0.010, ZF_ROOF + 0.01),
            (sgn * (X_ROOF + 0.025), Y_ROOF_EDGE + 0.006, -0.48),
            (sgn * (X_ROOF + 0.019), Y_ROOF_EDGE - 0.010, ZR_ROOF - 0.01),
        ], 0.006, segs=6, cap=True)

        # 4 sculpted painted pillars per side (A, B, C, sloped D — creating the 3 iconic Renault 4 windows!)
        add_tube(bm, M["Carpaint"], [
            (sgn * (W_BELT - 0.022), Y_BELT, ZF_BELT),
            (sgn * (X_ROOF - 0.014), Y_ROOF_EDGE - 0.010, ZF_ROOF),
        ], 0.034, segs=8, cap=True)
        add_tube(bm, M["Carpaint"], [
            (sgn * (W_BELT - 0.022), Y_BELT, -0.28),
            (sgn * (X_ROOF - 0.012), Y_ROOF_EDGE, -0.28),
        ], 0.028, segs=8, cap=True)
        add_tube(bm, M["Carpaint"], [
            (sgn * (W_BELT - 0.022), Y_BELT, -0.94),
            (sgn * (X_ROOF - 0.012), Y_ROOF_EDGE, -0.94),
        ], 0.028, segs=8, cap=True)
        # D-pillar (sloped rear hatchback pillar sitting flush on the sloped tailgate shoulder — zero overhang!)
        add_tube(bm, M["Carpaint"], [
            (sgn * (W_BELT - 0.036), Y_BELT - 0.015, ZR_BELT + 0.038),
            (sgn * (X_ROOF - 0.016), Y_ROOF_EDGE - 0.014, ZR_ROOF + 0.015),
        ], 0.036, segs=8, cap=True)
        # 3 ROUNDED-CORNER Side Windows per side (Front door, Rear door, Iconic trapezoid rear-quarter!)
        win_defs = [
            (0.50, -0.245, 0.325, -0.245),
            (-0.315, -0.905, -0.315, -0.905),
            (-0.975, -1.43, -0.975, -1.25),
        ]
        for zfb, zrb, zft, zrt in win_defs:
            yb, yt = Y_BELT + 0.020, Y_ROOF_EDGE - 0.028
            xb, xt = sgn * (pill_x(yb) - 0.024), sgn * (pill_x(yt) - 0.020)
            loop = add_rounded_rect_loop([(xb, yb, zfb), (xb, yb, zrb), (xt, yt, zrt), (xt, yt, zft)], r_corner=0.055, segs=3)
            add_poly_pane(bm, M["Window"], loop, (-sgn * 0.006, 0.0, 0.0))
            add_tube(bm, M["Plastic"], loop, 0.011, segs=6, closed=True)

    # Rounded-corner Front Windscreen + black rubber seal
    yb_w, yt_w = Y_BELT + 0.024, Y_ROOF_EDGE - 0.026
    w_loop = add_rounded_rect_loop([
        ( 0.69, yb_w, ZF_BELT - 0.01),
        (-0.69, yb_w, ZF_BELT - 0.01),
        (-0.57, yt_w, ZF_ROOF + 0.012),
        ( 0.57, yt_w, ZF_ROOF + 0.012),
    ], r_corner=0.068, segs=3)
    add_poly_pane(bm, M["Window"], w_loop, (0.0, 0.0, -0.006))
    add_tube(bm, M["Plastic"], w_loop, 0.014, segs=6, closed=True)

    # Rounded-corner Rear Tailgate Window + black rubber seal (Photo 3!)
    r_loop = add_rounded_rect_loop([
        ( 0.60, Y_BELT + 0.042, ZR_BELT + 0.032),
        (-0.60, Y_BELT + 0.042, ZR_BELT + 0.032),
        (-0.52, Y_ROOF_EDGE - 0.032, ZR_ROOF - 0.010),
        ( 0.52, Y_ROOF_EDGE - 0.032, ZR_ROOF - 0.010),
    ], r_corner=0.072, segs=3)
    add_poly_pane(bm, M["Window"], r_loop, (0.0, 0.0, 0.006))
    add_tube(bm, M["Plastic"], r_loop, 0.015, segs=6, closed=True)

    # Iconic black rectangular cowl air-intake vent right beneath the windscreen (ALL 4 photos!)
    add_box(bm, M["Plastic"], (0.0, 0.952, 0.625), (0.44, 0.034, 0.090), rot_xyz=(0.14, 0.0, 0.0), bevel=0.005)
    # Two thin black windscreen wipers resting low & nearly flat along the bottom edge of the windscreen (Photo 2!)
    for wx in (0.12, -0.28):
        add_tube(bm, M["Plastic"], [
            (wx, 0.962, 0.565),
            (wx + 0.16, 0.995, 0.545),
            (wx + 0.34, 1.028, 0.528),
        ], 0.0055, segs=5, cap=True)

    # Classic driver's side wing mirror on left front door near A-pillar
    add_tube(bm, M["Plastic"], [(0.735, 0.940, 0.44), (0.835, 0.992, 0.42)], 0.008, segs=6)
    add_box(bm, M["Plastic"], (0.865, 1.012, 0.415), (0.105, 0.072, 0.028), rot_xyz=(0.0, -0.15, 0.0), bevel=0.006)
    add_box(bm, M["Chrome"], (0.865, 1.012, 0.400), (0.092, 0.058, 0.004), rot_xyz=(0.0, -0.15, 0.0))

    # --------------------------------------------------------------
    # 5) ICONIC FRONT FACE: ROUNDED RECTANGULAR GRILLE, ROUND HEADLIGHTS, AMBER INDICATORS & CHROME BUMPER!
    # --------------------------------------------------------------
    gz = 1.800
    # Rounded chrome outer grille frame loop (smooth stadium-like rectangle, Photos 1, 2 & 4!)
    g_loop = add_rounded_rect_loop([
        ( 0.54, 0.525, gz + 0.008),
        (-0.54, 0.525, gz + 0.008),
        (-0.54, 0.755, gz + 0.008),
        ( 0.54, 0.755, gz + 0.008),
    ], r_corner=0.048, segs=3)
    add_tube(bm, M["Chrome"], g_loop, 0.016, segs=8, closed=True)
    add_poly_pane(bm, M["Plastic"], g_loop, (0.0, 0.0, -0.024))
    # 5 crisp horizontal louvers across center between the round headlights
    for li in range(5):
        ly = 0.572 + li * 0.034
        add_box(bm, M["Steel"], (0.0, ly, gz + 0.011), (0.60, 0.010, 0.010))
    # Clean neutral small chrome vertical bar in center (no real Renault lozenge!)
    add_box(bm, M["Chrome"], (0.0, 0.640, gz + 0.015), (0.026, 0.086, 0.012), bevel=0.003)

    # TWO classic round headlights recessed inside the left & right ends of the grille!
    for sgn in (1.0, -1.0):
        hx = sgn * 0.415
        add_cyl(bm, M["Chrome"], (hx, 0.640, gz + 0.006), 0.094, 0.030, axis='Z', segs=22)
        add_cyl(bm, M["Headlight"], (hx, 0.640, gz + 0.016), 0.080, 0.018, axis='Z', segs=22, r_end=0.070)
        # Small rectangular amber front indicator below outer corner of grille
        add_box(bm, M["Plastic"], (sgn * 0.545, 0.440, 1.785), (0.102, 0.054, 0.026), bevel=0.004)
        add_box(bm, M["Indicator"], (sgn * 0.545, 0.440, 1.797), (0.086, 0.042, 0.014), bevel=0.003)

    # Lower cooling slot under main grille
    add_box(bm, M["Plastic"], (0.0, 0.422, 1.798), (0.46, 0.074, 0.022), bevel=0.004)
    for li in range(3):
        add_box(bm, M["Steel"], (0.0, 0.398 + li * 0.024, 1.809), (0.42, 0.008, 0.008))

    # Thin curved chrome front bumper + twin black vertical overriders ("topes") + clean white plate
    fb_pts = [
        (-0.74, 0.305, 1.70), (-0.68, 0.305, 1.81), (-0.40, 0.305, 1.848),
        ( 0.00, 0.305, 1.862),
        ( 0.40, 0.305, 1.848), ( 0.68, 0.305, 1.81), ( 0.74, 0.305, 1.70),
    ]
    add_tube(bm, M["Chrome"], fb_pts, 0.033, segs=10, cap=True)
    for sgn in (1.0, -1.0):
        add_box(bm, M["Plastic"], (sgn * 0.30, 0.335, 1.862), (0.042, 0.122, 0.050), bevel=0.008)
    add_box(bm, M["Plate"], (0.0, 0.312, 1.888), (0.37, 0.092, 0.014), bevel=0.002)

    # --------------------------------------------------------------
    # 6) ICONIC REAR FACE: VERTICAL PILL TAILLIGHTS, PLATE HOOD, HANDLE & CHROME BUMPER (Photo 3!)
    # --------------------------------------------------------------
    for sgn in (1.0, -1.0):
        tx = sgn * 0.565
        tz = rear_z_at(0.62) - 0.012
        add_box(bm, M["Plastic"], (tx, 0.62, tz - 0.018), (0.084, 0.180, 0.052), rot_xyz=(0.28, 0.0, 0.0), bevel=0.014)
        add_box(bm, M["Taillight"], (tx, 0.62, tz - 0.042), (0.068, 0.156, 0.040), rot_xyz=(0.28, 0.0, 0.0), bevel=0.018)
    tz_p = rear_z_at(0.56) - 0.025
    add_box(bm, M["Plate"], (0.0, 0.56, tz_p - 0.010), (0.28, 0.172, 0.014), rot_xyz=(0.30, 0.0, 0.0), bevel=0.002)
    add_box(bm, M["Plastic"], (0.0, 0.675, rear_z_at(0.675) - 0.036), (0.14, 0.038, 0.048), rot_xyz=(0.30, 0.0, 0.0), bevel=0.006)
    add_box(bm, M["Chrome"], (0.0, 0.425, rear_z_at(0.425) - 0.034), (0.066, 0.026, 0.024), bevel=0.004)
    # Tiny chrome fuel filler cap on right rear flank (Photo 3!)
    add_cyl(bm, M["Chrome"], (-0.745, 0.72, -1.46), 0.035, 0.026, axis='X', segs=14)
    # Small exhaust tailpipe peeking beneath left rear
    add_cyl(bm, M["Steel"], (0.40, 0.215, -1.75), 0.021, 0.18, axis='Z', segs=10)

    # Thin curved chrome rear bumper + twin black rubber overriders
    rb_pts = [
        (-0.73, 0.305, -1.68), (-0.67, 0.305, -1.79), (-0.40, 0.305, -1.825),
        ( 0.00, 0.305, -1.838),
        ( 0.40, 0.305, -1.825), ( 0.67, 0.305, -1.79), ( 0.73, 0.305, -1.68),
    ]
    add_tube(bm, M["Chrome"], rb_pts, 0.033, segs=10, cap=True)
    for sgn in (1.0, -1.0):
        add_box(bm, M["Plastic"], (sgn * 0.30, 0.335, -1.838), (0.042, 0.122, 0.050), bevel=0.008)

    # --------------------------------------------------------------
    # 7) CLEAN DARK INTERIOR SHELL
    # --------------------------------------------------------------
    for sgn in (1.0, -1.0):
        add_box(bm, M["Interior"], (sgn * 0.32, 0.46, -0.05), (0.45, 0.11, 0.45), bevel=0.02)
        add_box(bm, M["Interior"], (sgn * 0.32, 0.76, -0.26), (0.44, 0.55, 0.10), rot_xyz=(-0.18, 0.0, 0.0), bevel=0.02)
    add_box(bm, M["Interior"], (0.0, 0.48, -0.84), (1.24, 0.12, 0.45), bevel=0.02)
    add_box(bm, M["Interior"], (0.0, 0.78, -1.05), (1.24, 0.54, 0.10), rot_xyz=(-0.16, 0.0, 0.0), bevel=0.02)
    add_box(bm, M["Interior"], (0.0, 0.88, -1.30), (1.20, 0.04, 0.38))
    add_box(bm, M["Interior"], (0.0, 0.76, 0.54), (1.34, 0.32, 0.12))

    return add_bm_obj("body", bm, mats, smooth=False)


# ------------------------------------------------------------------ main
def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)

    mat_specs = [
        ("Carpaint",  (0.86, 0.18, 0.16, 1.0), 0.32, 0.08),
        ("Window",    (0.08, 0.12, 0.15, 1.0), 0.15, 0.10),
        ("Plastic",   (0.11, 0.12, 0.14, 1.0), 0.82, 0.02),
        ("Chrome",    (0.84, 0.86, 0.89, 1.0), 0.18, 0.88),
        ("Steel",     (0.68, 0.71, 0.75, 1.0), 0.38, 0.55),
        ("Headlight", (0.96, 0.95, 0.90, 1.0), 0.12, 0.05),
        ("Taillight", (0.76, 0.10, 0.10, 1.0), 0.18, 0.05),
        ("Indicator", (0.92, 0.52, 0.08, 1.0), 0.20, 0.05),
        ("Plate",     (0.92, 0.91, 0.88, 1.0), 0.50, 0.00),
        ("Tyre",      (0.10, 0.11, 0.12, 1.0), 0.90, 0.00),
        ("Interior",  (0.15, 0.16, 0.19, 1.0), 0.85, 0.00),
    ]
    mats = [make_mat(*sp) for sp in mat_specs]
    M = {sp[0]: idx for idx, sp in enumerate(mat_specs)}

    body = build_body(mats, M)
    for p in body.data.polygons:
        if p.material_index in (M["Carpaint"], M["Chrome"], M["Headlight"], M["Taillight"]):
            p.use_smooth = True

    build_wheel("wheel_fl", ( 0.665, 0.305,  1.20), True,  mats, M)
    build_wheel("wheel_fr", (-0.665, 0.305,  1.20), False, mats, M)
    build_wheel("wheel_bl", ( 0.665, 0.305, -1.12), True,  mats, M)
    build_wheel("wheel_br", (-0.665, 0.305, -1.12), False, mats, M)

    os.makedirs(os.path.dirname(OUT_GLB), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=OUT_GLB,
        export_format='GLB',
        export_yup=True,
        export_apply=True,
        export_normals=True,
    )
    total_tris = sum(len(o.data.polygons) for o in bpy.data.objects if o.type == 'MESH')
    print(f"EXPORTED {OUT_GLB}  |  objects={len(bpy.data.objects)}  |  polys={total_tris}")


if __name__ == "__main__":
    main()
