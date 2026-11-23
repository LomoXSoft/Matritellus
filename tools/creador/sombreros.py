"""Custom low-poly stylized hats for Matritellus, sculpted cleanly from scratch in Blender for the game's
spherical head (C = (0, 0, 1.38), R = 0.50 m; Blender axes: +Z up, -Y face) and short-hair ellipsoid
(H = (0, 0.06, 1.50), radii (0.50, 0.50, 0.42)).

    blender.exe -b --python tools/creador/sombreros.py -- OUT_DIR [name1 name2 ...]

Each hat is exported as godot/assets/creador/pelo/<name>.glb with smooth outward normals, baked subtle
vertex-color shading ('Col') for the game's flat-shaded + screen-space ink outline style, and 1 or 2
surfaces (surface 0 takes the creator's hat_color; surface 1 keeps its own contrasting ribbon/visor colour).
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector, Matrix

C = Vector((0.0, 0.0, 1.38))
R = 0.50
HAIR_C = Vector((0.0, 0.06, 1.50))
HAIR_R = Vector((0.515, 0.515, 0.435))


def smoothstep(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def push_outside_head(q, pad=0.018, over_hair=True):
    """Ensure a point stays outside the head sphere (and optionally the primitive short-hair ball)."""
    d = q - C
    if d.length < R + pad and d.length > 1e-5:
        q = C + d.normalized() * (R + pad)
    if over_hair and q.z > 1.32:
        e = Vector(((q.x - HAIR_C.x) / HAIR_R.x, (q.y - HAIR_C.y) / HAIR_R.y, (q.z - HAIR_C.z) / HAIR_R.z))
        if e.length < 1.05 and e.length > 1e-5:
            e = e.normalized() * 1.05
            q = Vector((HAIR_C.x + e.x * HAIR_R.x, HAIR_C.y + e.y * HAIR_R.y, HAIR_C.z + e.z * HAIR_R.z))
    return q


def head_r_at(z, ang, pad=0.022, over_hair=True):
    """Minimum horizontal radius at height z and azimuth ang (0 = front -Y) to clear head + hair."""
    r = 0.0
    dz = z - C.z
    if abs(dz) < R + pad:
        r = max(r, math.sqrt(max(0.0, (R + pad) ** 2 - dz * dz)))
    if over_hair and z > 1.50:
        hz = (z - HAIR_C.z) / HAIR_R.z
        if abs(hz) < 1.03:
            # ellipse centered at y = +HAIR_C.y along ray (sin(ang), -cos(ang))
            hr = HAIR_R.x * math.sqrt(max(0.0, 1.03 * 1.03 - hz * hz))
            # ray: x = t*sin(a), y = -t*cos(a); distance to (0, cy): t^2 + 2*t*cy*cos(a) + cy^2 = hr^2
            cy = HAIR_C.y
            b = cy * math.cos(ang)
            disc = b * b + hr * hr - cy * cy
            if disc > 0.0:
                t = -b + math.sqrt(disc)
                r = max(r, t)
    return r


def add_lathe(bm, rings, mat_idx=0, closed_top=True, closed_bottom=False):
    """Build a smooth closed-ring surface from a list of rings (each a list of Vector of equal length)."""
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


def add_ribbon(bm, z0, z1, r_fn, n_u=28, mat_idx=1, thick=0.014):
    """Add a clean solid hatband ribbon wrapping cleanly outside the crown (and hair clearance)."""
    rings = []
    for z, dr in ((z0, 0.0), (z0, thick), (z1, thick), (z1, 0.0)):
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            rr = r_fn(z, a)
            base = push_outside_head(Vector((math.sin(a) * rr, -math.cos(a) * rr, z)), pad=0.022, over_hair=True)
            xy = Vector((base.x, base.y))
            if xy.length > 1e-5:
                xy = xy + xy.normalized() * dr
            ring.append(Vector((xy.x, xy.y, base.z)))
        rings.append(ring)
    add_lathe(bm, rings, mat_idx=mat_idx, closed_top=False, closed_bottom=False)


def add_button(bm, pos, radius, mat_idx=0):
    res = bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=radius)
    for v in res['verts']:
        v.co.z *= 0.65
        v.co += pos
        for f in v.link_faces:
            f.material_index = mat_idx
            f.smooth = True


def add_bow(bm, center, normal_ang, mat_idx=1, scale=1.0):
    """Tiny flat ribbon bow on the side/back of a hatband."""
    for sgn in (-1.0, 1.0):
        res = bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=5, radius=1.0)
        rot = Matrix.Rotation(-normal_ang, 4, 'Z')
        for v in res['verts']:
            p = Vector((v.co.x * 0.055 * scale + sgn * 0.045 * scale, v.co.y * 0.018 * scale, v.co.z * 0.032 * scale))
            v.co = center + (rot @ p)
            for f in v.link_faces:
                f.material_index = mat_idx
                f.smooth = True


def bake_ao_and_export(bm, name, mat_defs, out_dir):
    """Recalculate outward normals, bake subtle AO vertex colours ('Col'), and export GLB."""
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()
    # ensure closed/open shells face away from head centre where appropriate
    col = bm.loops.layers.color.new('Col')
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
        shade[v] = min(1.0, max(0.78, 1.0 - max(0.0, s) * 0.85))
    # 2 smoothing passes on shade
    for _ in range(2):
        nxt = {}
        for v, val in shade.items():
            nbs = [shade[e.other_vert(v)] for e in v.link_edges if e.other_vert(v) in shade]
            nxt[v] = (val + sum(nbs)) / (1 + len(nbs)) if nbs else val
        shade = nxt
    for f in bm.faces:
        for lp in f.loops:
            k = shade[lp.vert]
            lp[col] = (k, k, k, 1.0)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for poly in me.polygons:
        poly.use_smooth = True
    me.color_attributes.active_color = me.color_attributes['Col']
    me.color_attributes.render_color_index = 0
    for mname, rgba in mat_defs:
        m = bpy.data.materials.new(mname)
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get('Principled BSDF')
        if bsdf:
            bsdf.inputs['Base Color'].default_value = rgba
            bsdf.inputs['Roughness'].default_value = 1.0
        m.diffuse_color = rgba
        me.materials.append(m)
    ob = bpy.data.objects.new('pieza', me)
    bpy.context.scene.collection.objects.link(ob)
    ob.select_set(True)
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, f'{name}.glb')
    bpy.ops.export_scene.gltf(
        filepath=out, export_format='GLB', use_selection=True, export_apply=True,
        export_materials='EXPORT', export_vertex_color='ACTIVE',
        export_all_vertex_colors=False, export_active_vertex_color_when_no_material=True,
    )
    vs = [v.co for v in me.vertices]
    tris = sum(max(0, len(p.vertices) - 2) for p in me.polygons)
    print(f'SOMBRERO {name:22s} {tris:4d} tris  surfs={len(mat_defs)}  '
          f'x {min(v.x for v in vs):.2f}..{max(v.x for v in vs):.2f}  '
          f'front {-max(v.y for v in vs):.2f}..{-min(v.y for v in vs):.2f}  '
          f'up {min(v.z for v in vs):.2f}..{max(v.z for v in vs):.2f}')


# ---------------- Individual hat builders ----------------

def build_parpusa():
    """4 · Parpusa (classic Madrileña/Manchega flat cap): rounded forward-leaning crown + short curved peak."""
    bm = bmesh.new()
    n_u = 28
    # 1. Rounded flat-cap crown sloping gently forward over the peak
    profile = [
        (0.00, 1.56, 1.00, 0.00),
        (0.18, 1.63, 1.04, -0.02),
        (0.40, 1.72, 1.06, -0.05),
        (0.62, 1.81, 0.98, -0.05),
        (0.80, 1.88, 0.78, -0.02),
        (0.93, 1.92, 0.44, 0.00),
        (1.00, 1.93, 0.14, 0.00),
    ]
    rings = []
    for t, z, r_mul, fwd in profile:
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            base_r = max(0.50, head_r_at(min(z, 1.66), a, pad=0.026, over_hair=True))
            # forward overhang on the crown (front = -Y, cos(a) > 0)
            front_k = max(0.0, math.cos(a)) ** 1.4
            rr = base_r * r_mul + 0.045 * front_k * smoothstep(0.0, 0.55, t) * (1.0 - smoothstep(0.55, 1.0, t))
            q = Vector((math.sin(a) * rr, -math.cos(a) * rr + fwd, z))
            q = push_outside_head(q, pad=0.022, over_hair=True)
            ring.append(q)
        rings.append(ring)
    add_lathe(bm, rings, mat_idx=0, closed_top=True, closed_bottom=True)

    # 2. Short, neatly curved peak/visor tucked cleanly under the front
    n_va = 12
    n_vr = 4
    top_g, bot_g = [], []
    for i in range(n_vr + 1):
        u = i / n_vr
        tr, br = [], []
        for j in range(n_va + 1):
            s = -1.0 + 2.0 * j / n_va
            ang = s * 0.92
            arch = max(0.0, 1.0 - s * s) ** 0.7
            r0 = head_r_at(1.57, ang, pad=0.024, over_hair=False)
            reach = 0.21 * arch
            rr = r0 + u * reach
            droop = -0.045 * (u ** 1.35) - 0.022 * (s * s) * u
            z_mid = 1.595 + droop
            th = 0.015 * (1.0 - 0.35 * u)
            tr.append(bm.verts.new(push_outside_head(Vector((math.sin(ang) * rr, -math.cos(ang) * rr, z_mid + th)), pad=0.012, over_hair=False)))
            br.append(bm.verts.new(push_outside_head(Vector((math.sin(ang) * rr, -math.cos(ang) * rr, z_mid - th)), pad=0.012, over_hair=False)))
        top_g.append(tr)
        bot_g.append(br)
    for i in range(n_vr):
        for j in range(n_va):
            bm.faces.new((top_g[i][j], top_g[i][j + 1], top_g[i + 1][j + 1], top_g[i + 1][j])).smooth = True
            bm.faces.new((bot_g[i][j + 1], bot_g[i][j], bot_g[i + 1][j], bot_g[i + 1][j + 1])).smooth = True
    for j in range(n_va):
        bm.faces.new((top_g[n_vr][j], top_g[n_vr][j + 1], bot_g[n_vr][j + 1], bot_g[n_vr][j])).smooth = True
    for i in range(n_vr):
        bm.faces.new((bot_g[i][0], top_g[i][0], top_g[i + 1][0], bot_g[i + 1][0])).smooth = True
        bm.faces.new((top_g[i][n_va], bot_g[i][n_va], bot_g[i + 1][n_va], top_g[i + 1][n_va])).smooth = True

    add_button(bm, Vector((0.0, 0.0, 1.938)), 0.036, mat_idx=0)
    return bm, [('parpusa', (0.2, 0.55, 0.3, 1.0))]


def build_fedora():
    """5 · Sombrero de ala (Fedora): pinched creased crown, snap brim, dark hatband."""
    bm = bmesh.new()
    n_u = 32

    def crown_r(z, a):
        t = max(0.0, min(1.0, (z - 1.60) / 0.48))
        r0 = head_r_at(1.60, a, pad=0.025, over_hair=True)
        # gently tapered crown with subtle front side-pinches
        taper = 1.0 - 0.16 * (t ** 1.15)
        front_pinch = math.exp(-((abs(a) - 0.55) / 0.35) ** 2) * 0.042 * smoothstep(0.25, 0.85, t)
        return max(0.32, r0 * taper - front_pinch)

    # Brim (underside -> outer rounded edge -> topside -> crown wall -> creased crown top)
    rings = []
    # Brim profile: (radial_extra, z_offset_base, dip_front, lift_back)
    brim_pts = [
        (0.00, 1.595, 0.00, 0.00),
        (0.11, 1.588, -0.025, 0.020),
        (0.19, 1.586, -0.048, 0.048),
        (0.20, 1.600, -0.048, 0.052),
        (0.11, 1.608, -0.022, 0.022),
        (0.00, 1.615, 0.00, 0.00),
    ]
    for dr, zb, dip_f, lift_b in brim_pts:
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            r0 = head_r_at(1.60, a, pad=0.025, over_hair=True)
            # slightly wider brim front/back than sides
            brim_oval = 1.0 + 0.12 * (math.cos(a) ** 2)
            rr = r0 + dr * brim_oval
            cf = math.cos(a)
            dz = dip_f * max(0.0, cf) ** 1.3 + lift_b * max(0.0, -cf) ** 1.4
            ring.append(Vector((math.sin(a) * rr, -math.cos(a) * rr, zb + dz)))
        rings.append(ring)

    # Crown wall + classic center-creased top
    for t in (0.14, 0.34, 0.56, 0.78, 0.92, 1.00):
        z = 1.615 + t * 0.465
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            rr = crown_r(z, a) * (1.0 if t < 0.85 else (0.94 if t < 0.96 else 0.62))
            x = math.sin(a) * rr
            y = -math.cos(a) * rr
            # classic center canyon crease along top
            crease = -0.052 * math.exp(-(x / 0.16) ** 2) * smoothstep(0.75, 1.0, t)
            q = push_outside_head(Vector((x, y, z + crease)), pad=0.022, over_hair=True)
            ring.append(q)
        rings.append(ring)

    add_lathe(bm, rings, mat_idx=0, closed_top=True, closed_bottom=False)
    add_ribbon(bm, 1.622, 1.710, crown_r, n_u=n_u, mat_idx=1, thick=0.016)
    side_r = crown_r(1.665, math.pi / 2) + 0.018
    add_bow(bm, Vector((side_r, 0.0, 1.665)), math.pi / 2, mat_idx=1, scale=0.85)
    return bm, [('fedora', (0.2, 0.55, 0.3, 1.0)), ('cinta', (0.025, 0.025, 0.032, 1.0))]


def build_bombin():
    """6 · Bombín (Bowler hat): pure tall spherical dome, dark hatband, narrow curled-up brim."""
    bm = bmesh.new()
    n_u = 32

    def dome_r(z, a):
        t = max(0.0, min(1.0, (z - 1.60) / 0.52))
        r0 = head_r_at(1.60, a, pad=0.024, over_hair=True)
        return r0 * math.sqrt(max(0.02, 1.0 - (t ** 2.15) * 0.96))

    rings = []
    # Narrow curled-up bowler brim (curls neatly upward without hiding the hatband)
    brim_pts = [
        (0.00, 1.595, 0.000),
        (0.08, 1.596, 0.008),
        (0.14, 1.622, 0.024),
        (0.145, 1.640, 0.028),
        (0.12, 1.642, 0.026),
        (0.06, 1.615, 0.008),
        (0.00, 1.615, 0.000),
    ]
    for dr, zb, curl in brim_pts:
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            r0 = head_r_at(1.60, a, pad=0.024, over_hair=True)
            side_boost = 1.0 + 0.25 * (math.sin(a) ** 2)
            rr = r0 + dr * (0.92 + 0.10 * (math.cos(a) ** 2))
            ring.append(Vector((math.sin(a) * rr, -math.cos(a) * rr, zb + curl * side_boost)))
        rings.append(ring)

    # Pure smooth bowler dome up to z = 2.13
    for t in (0.16, 0.34, 0.52, 0.70, 0.84, 0.94, 0.99):
        z = 1.615 + t * 0.515
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            rr = dome_r(z, a)
            q = push_outside_head(Vector((math.sin(a) * rr, -math.cos(a) * rr, z)), pad=0.022, over_hair=True)
            ring.append(q)
        rings.append(ring)

    add_lathe(bm, rings, mat_idx=0, closed_top=True, closed_bottom=False)
    add_ribbon(bm, 1.640, 1.735, dome_r, n_u=n_u, mat_idx=1, thick=0.018)
    return bm, [('bombin', (0.2, 0.55, 0.3, 1.0)), ('cinta', (0.025, 0.025, 0.032, 1.0))]


def build_pamela():
    """7 · Pamela (Wide-brim sun hat): smooth rounded crown, wide graceful floppy brim, cream ribbon."""
    bm = bmesh.new()
    n_u = 32

    def crown_r(z, a):
        t = max(0.0, min(1.0, (z - 1.60) / 0.44))
        r0 = head_r_at(1.60, a, pad=0.024, over_hair=True)
        return r0 * math.sqrt(max(0.03, 1.0 - (t ** 2.2) * 0.95))

    rings = []
    # Wide graceful gently drooping floppy brim
    brim_pts = [
        (0.00, 1.596, 0.000),
        (0.14, 1.592, -0.014),
        (0.27, 1.578, -0.038),
        (0.37, 1.556, -0.068),
        (0.375, 1.572, -0.068),
        (0.27, 1.595, -0.038),
        (0.14, 1.608, -0.014),
        (0.00, 1.615, 0.000),
    ]
    for dr, zb, droop in brim_pts:
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            r0 = head_r_at(1.60, a, pad=0.024, over_hair=True)
            rr = r0 + dr
            # soft feminine wave around the outer brim
            wave = 0.022 * math.cos(2.0 * a) * ((dr / 0.375) ** 1.5)
            ring.append(Vector((math.sin(a) * rr, -math.cos(a) * rr, zb + droop + wave)))
        rings.append(ring)

    # Smooth rounded sun-hat dome
    for t in (0.18, 0.38, 0.58, 0.76, 0.90, 0.98):
        z = 1.615 + t * 0.435
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            rr = crown_r(z, a)
            q = push_outside_head(Vector((math.sin(a) * rr, -math.cos(a) * rr, z)), pad=0.022, over_hair=True)
            ring.append(q)
        rings.append(ring)

    add_lathe(bm, rings, mat_idx=0, closed_top=True, closed_bottom=False)
    add_ribbon(bm, 1.618, 1.698, crown_r, n_u=n_u, mat_idx=1, thick=0.013)
    back_r = crown_r(1.658, math.pi) + 0.015
    add_bow(bm, Vector((0.0, back_r, 1.658)), math.pi, mat_idx=1, scale=1.05)
    return bm, [('pamela', (0.2, 0.55, 0.3, 1.0)), ('cinta', (0.95, 0.91, 0.82, 1.0))]


def build_vaquero():
    """12 · Sombrero vaquero (Cowboy hat): tall cattleman-creased crown, leather band, upturned taco brim."""
    bm = bmesh.new()
    n_u = 32

    def crown_r(z, a):
        t = max(0.0, min(1.0, (z - 1.60) / 0.54))
        r0 = head_r_at(1.60, a, pad=0.024, over_hair=True)
        taper = 1.0 - 0.14 * (t ** 1.1)
        pinch = math.exp(-((abs(a) - 0.58) / 0.34) ** 2) * 0.055 * smoothstep(0.28, 0.88, t)
        return max(0.32, r0 * taper - pinch)

    rings = []
    # Iconic Western brim: curls dramatically UP on sides, dips smoothly down front & back
    brim_pts = [
        (0.00, 1.594, 0.000, 0.000),
        (0.12, 1.590, 0.032, -0.016),
        (0.24, 1.592, 0.095, -0.042),
        (0.30, 1.604, 0.148, -0.058),
        (0.305, 1.622, 0.152, -0.054),
        (0.23, 1.612, 0.092, -0.038),
        (0.11, 1.610, 0.030, -0.012),
        (0.00, 1.615, 0.000, 0.000),
    ]
    for dr, zb, side_up, fb_down in brim_pts:
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            r0 = head_r_at(1.60, a, pad=0.024, over_hair=True)
            s2 = math.sin(a) ** 2
            c2 = math.cos(a) ** 2
            # slightly narrower side reach because it curls upward steeply
            rr = r0 + dr * (0.94 + 0.12 * c2)
            dz = side_up * (s2 ** 1.25) + fb_down * (c2 ** 1.35)
            ring.append(Vector((math.sin(a) * rr, -math.cos(a) * rr, zb + dz)))
        rings.append(ring)

    # Tall cattleman-creased crown
    for t in (0.14, 0.34, 0.56, 0.78, 0.92, 1.00):
        z = 1.615 + t * 0.535
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            rr = crown_r(z, a) * (1.0 if t < 0.85 else (0.94 if t < 0.96 else 0.64))
            x = math.sin(a) * rr
            y = -math.cos(a) * rr
            crease = -0.082 * math.exp(-(x / 0.17) ** 2) * smoothstep(0.68, 1.0, t)
            q = push_outside_head(Vector((x, y, z + crease)), pad=0.022, over_hair=True)
            ring.append(q)
        rings.append(ring)

    add_lathe(bm, rings, mat_idx=0, closed_top=True, closed_bottom=False)
    add_ribbon(bm, 1.622, 1.705, crown_r, n_u=n_u, mat_idx=1, thick=0.016)
    return bm, [('vaquero', (0.2, 0.55, 0.3, 1.0)), ('cuero', (0.11, 0.045, 0.02, 1.0))]


def build_panoleta():
    """8 · Pañoleta (traditional Manchega headscarf): triangular folded kerchief framing the cheeks,
    tied in a small knot under the chin, with a smooth triangular drape down the nape."""
    bm = bmesh.new()
    n_lat = 18
    n_lon = 28
    out_g, in_g = [], []
    # Spherical coords around C (face = -Y): alpha = angle from front (-Y), theta = 0 top, ±pi/2 cheeks, pi chin
    for i in range(n_lat + 1):
        u = i / n_lat  # 0 = face-framing front fold, 1 = back centre
        og, ig = [], []
        for j in range(n_lon):
            theta = j * math.tau / n_lon
            ct = math.cos(theta)
            st = math.sin(theta)
            # Face opening: gentle arched peak at forehead, wider framing cheeks, converging neatly to chin knot
            alpha0 = math.radians(52.0 + 9.0 * (st * st) - 5.0 * max(0.0, ct) + 3.0 * max(0.0, -ct))
            alpha1 = math.radians(174.0)
            alpha = alpha0 + (alpha1 - alpha0) * u
            dx = math.sin(alpha) * st
            dy = -math.cos(alpha)
            dz = math.sin(alpha) * ct
            d = Vector((dx, dy, dz))

            # Traditional folded headscarf silhouette:
            # 1) Soft triangular kerchief peak at top of forehead (not round swim cap)
            top_peak = 0.055 * (max(0.0, ct) ** 2.6) * (1.0 - smoothstep(0.0, 0.55, u))
            # 2) Flared diagonal cheek folds standing slightly off the cheeks (straight kerchief fall toward chin)
            cheek_flare = 0.068 * (abs(st) ** 1.4) * smoothstep(-0.2, 0.65, -ct + 0.35) * (1.0 - smoothstep(0.0, 0.72, u))
            # 3) Back drape: falls cleanly down over the nape like a folded triangle rather than hugging under the skull
            back_k = smoothstep(0.25, 0.85, u)
            back_fall = 0.075 * back_k * smoothstep(0.0, 0.85, max(0.0, -dz))

            r_tot = R + 0.026 + top_peak + cheek_flare + back_fall
            p_out = C + d * r_tot
            # Pull the nape/back edge down into a classic triangular scarf point (center back drops to z ~ 0.78)
            if p_out.z < 1.18:
                low_t = smoothstep(1.18, 0.86, p_out.z)
                # center back (y > 0, x ~ 0) hangs lowest like a folded triangular handkerchief
                back_pt = max(0.0, p_out.y / max(0.1, math.hypot(p_out.x, p_out.y))) ** 1.6
                drop = 0.14 * back_pt * low_t
                # keep back cloth slightly outward over upper back so it clears the torso cleanly
                if p_out.y > 0.05:
                    p_out.y += 0.045 * low_t * back_pt
                p_out.z -= drop
            # Under-chin convergence: draw the lower front fold cleanly toward the chin knot
            if p_out.z < 0.96 and p_out.y < 0.0:
                chin_t = smoothstep(0.96, 0.84, p_out.z)
                p_out.x *= (1.0 - 0.38 * chin_t)
                p_out.z = max(0.86, p_out.z)
            # Clear torso cone below neck (y = +Z back in Blender -> check against body_r)
            if p_out.z < 1.00:
                br = 0.44 - (max(p_out.z, 0.25) - 0.245) * 0.18667
                xy = Vector((p_out.x, p_out.y))
                if xy.length < br + 0.032 and xy.length > 1e-5:
                    xy = xy.normalized() * (br + 0.032)
                    p_out.x, p_out.y = xy.x, xy.y
            p_out = push_outside_head(p_out, pad=0.024, over_hair=True)

            # Inner folded rim
            th = 0.022 if u < 0.18 else 0.014
            v_rad = p_out - C
            p_in = C + v_rad.normalized() * max(R + 0.010, v_rad.length - th)
            og.append(bm.verts.new(p_out))
            ig.append(bm.verts.new(p_in))
        out_g.append(og)
        in_g.append(ig)

    for i in range(n_lat):
        for j in range(n_lon):
            jn = (j + 1) % n_lon
            bm.faces.new((out_g[i][j], out_g[i][jn], out_g[i + 1][jn], out_g[i + 1][j])).smooth = True
            bm.faces.new((in_g[i][jn], in_g[i][j], in_g[i + 1][j], in_g[i + 1][jn])).smooth = True
    for j in range(n_lon):
        jn = (j + 1) % n_lon
        bm.faces.new((in_g[0][j], in_g[0][jn], out_g[0][jn], out_g[0][j])).smooth = True
    bc_out = sum((v.co for v in out_g[-1]), Vector()) / n_lon
    bc_in = sum((v.co for v in in_g[-1]), Vector()) / n_lon
    vo = bm.verts.new(bc_out)
    vi = bm.verts.new(bc_in)
    for j in range(n_lon):
        jn = (j + 1) % n_lon
        bm.faces.new((out_g[-1][j], out_g[-1][jn], vo)).smooth = True
        bm.faces.new((in_g[-1][jn], in_g[-1][j], vi)).smooth = True

    # Small neat tied knot + two short tucked scarf tails right under the chin
    knot_pos = Vector((0.0, -0.345, 0.905))
    res = bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=1.0)
    for v in res['verts']:
        v.co = knot_pos + Vector((v.co.x * 0.068, v.co.y * 0.048, v.co.z * 0.045))
        for f in v.link_faces:
            f.smooth = True
    for sgn in (-1.0, 1.0):
        res2 = bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=5, radius=1.0)
        rot = Matrix.Rotation(sgn * 0.42, 4, 'Y')
        for v in res2['verts']:
            p = Vector((v.co.x * 0.036, v.co.y * 0.022, v.co.z * 0.085))
            v.co = knot_pos + Vector((sgn * 0.045, -0.008, -0.055)) + (rot @ p)
            for f in v.link_faces:
                f.smooth = True

    return bm, [('panoleta', (0.2, 0.55, 0.3, 1.0))]


def build_diadema():
    """9 · Cinta (Headband): smooth clean athletic/retro headband sitting cleanly above the eyebrows."""
    bm = bmesh.new()
    n_u = 32
    # Positive front elevation (z_front = 1.625 above brows, sloping gently back to z_back = 1.505)
    sec = [
        (-0.046, 0.000),
        (-0.042, 0.022),
        (-0.018, 0.028),
        (0.018, 0.028),
        (0.042, 0.022),
        (0.046, 0.000),
    ]
    rings = []
    for dz_loc, dr in sec:
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            # a=0 is front (-Y, high on forehead); a=pi is back (+Y, slightly lower at nape)
            z_center = 1.575 + 0.055 * math.cos(a)
            z = z_center + dz_loc
            rr = head_r_at(z, a, pad=0.026, over_hair=True) + dr
            q = push_outside_head(Vector((math.sin(a) * rr, -math.cos(a) * rr, z)), pad=0.022, over_hair=True)
            ring.append(q)
        rings.append(ring)
    v_rings = [[bm.verts.new(p) for p in ring] for ring in rings]
    v_rings.append(v_rings[0])
    for i in range(len(v_rings) - 1):
        r0, r1 = v_rings[i], v_rings[i + 1]
        for j in range(n_u):
            jn = (j + 1) % n_u
            bm.faces.new((r0[j], r0[jn], r1[jn], r1[j])).smooth = True
    return bm, [('cinta', (0.2, 0.55, 0.3, 1.0))]


def build_beisbol(backwards=False):
    """10/11 · Gorra de béisbol / Gorra pa' trás: smooth 6-panel dome, curved sporty visor, dark back strap."""
    bm = bmesh.new()
    n_u = 32
    # 1. Smooth dome with clean back cutout arch above the strap (a near pi)
    rings = []
    for i in range(9):
        t = i / 8.0
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            # Back keyhole arch rises gently at a ~ pi (back of head)
            back_d = abs(math.atan2(math.sin(a - math.pi), math.cos(a - math.pi)))
            arch = 0.095 * math.exp(-(back_d / 0.42) ** 2) * (1.0 - smoothstep(0.0, 0.45, t))
            z0 = 1.545 + arch
            z = z0 + t * (1.975 - z0)
            r0 = head_r_at(min(z, 1.62), a, pad=0.028, over_hair=True)
            rr = r0 * math.sqrt(max(0.015, 1.0 - (t ** 2.05) * 0.96))
            q = push_outside_head(Vector((math.sin(a) * rr, -math.cos(a) * rr, z)), pad=0.024, over_hair=True)
            ring.append(q)
        rings.append(ring)
    add_lathe(bm, rings, mat_idx=0, closed_top=True, closed_bottom=False)
    add_button(bm, Vector((0.0, 0.0, 1.982)), 0.038, mat_idx=0)

    # 2. Curved sporty visor (Surface 1: dark charcoal)
    n_va = 14
    n_vr = 5
    top_g, bot_g = [], []
    for i in range(n_vr + 1):
        u = i / n_vr
        tr, br = [], []
        for j in range(n_va + 1):
            s = -1.0 + 2.0 * j / n_va
            ang = s * 0.86
            arch = max(0.0, 1.0 - s * s) ** 0.65
            r0 = head_r_at(1.55, ang, pad=0.024, over_hair=True)
            reach = 0.28 * arch
            rr = r0 + u * reach
            # Athletic curved visor: gentle downward curve across width + subtle forward slope
            z_mid = 1.592 - 0.030 * (u ** 1.2) - 0.046 * (s * s) * (0.35 + 0.65 * u)
            th = 0.015 * (1.0 - 0.30 * u)
            tr.append(bm.verts.new(Vector((math.sin(ang) * rr, -math.cos(ang) * rr, z_mid + th))))
            br.append(bm.verts.new(Vector((math.sin(ang) * rr, -math.cos(ang) * rr, z_mid - th))))
        top_g.append(tr)
        bot_g.append(br)
    for i in range(n_vr):
        for j in range(n_va):
            f1 = bm.faces.new((top_g[i][j], top_g[i][j + 1], top_g[i + 1][j + 1], top_g[i + 1][j]))
            f2 = bm.faces.new((bot_g[i][j + 1], bot_g[i][j], bot_g[i + 1][j], bot_g[i + 1][j + 1]))
            f1.material_index = f2.material_index = 1
            f1.smooth = f2.smooth = True
    for j in range(n_va):
        f = bm.faces.new((top_g[n_vr][j], top_g[n_vr][j + 1], bot_g[n_vr][j + 1], bot_g[n_vr][j]))
        f.material_index = 1
        f.smooth = True
    for i in range(n_vr):
        for fa in (
            bm.faces.new((bot_g[i][0], top_g[i][0], top_g[i + 1][0], bot_g[i + 1][0])),
            bm.faces.new((top_g[i][n_va], bot_g[i][n_va], bot_g[i + 1][n_va], top_g[i + 1][n_va])),
        ):
            fa.material_index = 1
            fa.smooth = True

    # 3. Adjustable back strap across the keyhole arch (Surface 1)
    n_st = 10
    s_rings = []
    for z, dr in ((1.545, 0.0), (1.545, 0.016), (1.588, 0.016), (1.588, 0.0)):
        r = []
        for j in range(n_st + 1):
            a = math.pi - 0.56 + 1.12 * (j / n_st)
            rr = head_r_at(z, a, pad=0.026, over_hair=True) + dr
            r.append(bm.verts.new(Vector((math.sin(a) * rr, -math.cos(a) * rr, z))))
        s_rings.append(r)
    for i in range(3):
        for j in range(n_st):
            f = bm.faces.new((s_rings[i][j], s_rings[i][j + 1], s_rings[i + 1][j + 1], s_rings[i + 1][j]))
            f.material_index = 1
            f.smooth = True

    if backwards:
        # Rotate 180° around head centre + subtle jaunty tilt, then enforce hair clearance on back
        rot = Matrix.Rotation(math.pi, 4, 'Z') @ Matrix.Rotation(math.radians(5.0), 4, 'X')
        for v in bm.verts:
            q = C + (rot @ (v.co - C))
            v.co = push_outside_head(q, pad=0.022, over_hair=True)

    return bm, [('gorra', (0.2, 0.55, 0.3, 1.0)), ('visera', (0.030, 0.030, 0.038, 1.0))]


BUILDERS = {
    'gorro_parpusa': build_parpusa,
    'gorro_fedora': build_fedora,
    'gorro_bombin': build_bombin,
    'gorro_pamela': build_pamela,
    'gorro_panoleta': build_panoleta,
    'gorro_diadema': build_diadema,
    'gorro_beisbol': lambda: build_beisbol(False),
    'gorro_beisbol_atras': lambda: build_beisbol(True),
    'gorro_vaquero': build_vaquero,
}


def main():
    args = sys.argv[sys.argv.index('--') + 1:]
    out_dir = args[0]
    only = set(args[1:]) if len(args) > 1 else set(BUILDERS.keys())
    for name, fn in BUILDERS.items():
        if name not in only:
            continue
        bm, mats = fn()
        bake_ao_and_export(bm, name, mats, out_dir)


if __name__ == '__main__':
    main()
