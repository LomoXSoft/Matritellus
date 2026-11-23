"""Custom low-poly stylized footwear for Matritellus, sculpted from scratch in Blender for the game's
chunky Animal Crossing feet (each foot node sits at y = 0.13, z = 0.05; so in shoe-local Blender coords:
+Z up, -Y forward/toe, ground = z -0.13, torso bottom = z +0.115, shoe width ~0.26 m, length ~0.39 m).

    blender.exe -b --python tools/creador/calzado.py -- OUT_DIR [name1 name2 ...]

Exports each shoe as godot/assets/creador/pelo/<name>.glb with smooth outward normals, subtle baked
vertex-color shading ('Col'), and 1..3 materials (surface 0 takes the creator's shoe colour; surfaces 1+
keep their own contrasting sole/lace/trim/wood colours).
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector, Matrix

GROUND_Z = -0.13


def smoothstep(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def foot_contour(ang, half_w=0.125, len_fwd=0.22, len_back=0.16, toe_point=0.0, heel_narrow=0.16):
    """2D rounded shoe footprint point (x, y) for angle ang (0 = toe -Y, pi = heel +Y)."""
    ca = math.cos(ang)
    sa = math.sin(ang)
    # forward/back length
    ly = len_fwd if ca >= 0.0 else len_back
    # slight narrowing at heel, optional tapering toward pointed toe
    w = half_w * (1.0 - heel_narrow * max(0.0, -ca) ** 1.4)
    if toe_point > 0.0 and ca > 0.0:
        w *= (1.0 - toe_point * (ca ** 2.2))
    # slight fuller ball of foot just behind toes
    w *= (1.0 + 0.06 * math.exp(-((ca - 0.35) / 0.35) ** 2))
    x = sa * w
    y = -ca * ly
    return x, y


def add_lathe_rings(bm, rings, mat_idx=0, cap_bot=True, cap_top=True):
    """Build a closed-ring lathe mesh from a list of rings of Vector."""
    n_u = len(rings[0])
    vr = [[bm.verts.new(p) for p in ring] for ring in rings]
    for i in range(len(vr) - 1):
        r0, r1 = vr[i], vr[i + 1]
        for j in range(n_u):
            jn = (j + 1) % n_u
            f = bm.faces.new((r0[j], r0[jn], r1[jn], r1[j]))
            f.material_index = mat_idx
            f.smooth = True
    if cap_bot:
        bc = sum((v.co for v in vr[0]), Vector()) / n_u
        bv = bm.verts.new(bc)
        for j in range(n_u):
            jn = (j + 1) % n_u
            f = bm.faces.new((vr[0][jn], vr[0][j], bv))
            f.material_index = mat_idx
            f.smooth = True
    if cap_top:
        tc = sum((v.co for v in vr[-1]), Vector()) / n_u
        tv = bm.verts.new(tc)
        for j in range(n_u):
            jn = (j + 1) % n_u
            f = bm.faces.new((vr[-1][j], vr[-1][jn], tv))
            f.material_index = mat_idx
            f.smooth = True
    return vr


def add_sole(bm, z0, z1, mat_idx=1, n_u=24, half_w=0.130, len_fwd=0.225, len_back=0.165,
             toe_point=0.0, heel_narrow=0.16, toe_lift=0.0, arch_lift=0.0, heel_extra=0.0):
    """Rounded contoured sole slab with optional toe spring, arch cutout, and heel lift."""
    rings = []
    for t, r_mul in ((0.0, 0.96), (0.25, 1.0), (0.75, 1.0), (1.0, 0.97)):
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            x, y = foot_contour(a, half_w * r_mul, len_fwd * r_mul, len_back * r_mul, toe_point, heel_narrow)
            ca = math.cos(a)
            # toe spring lifts front tip slightly
            dz_toe = toe_lift * (max(0.0, ca) ** 3.0)
            # arch lift raises middle underside (between heel and ball)
            dz_arch = arch_lift * math.exp(-((y - 0.01) / 0.06) ** 2) * (1.0 - t)
            # heel block drops lower at back when heel_extra > 0
            dz_heel = -heel_extra * smoothstep(0.03, 0.08, y) * (1.0 - t)
            z = z0 + t * (z1 - z0) + dz_toe + dz_arch + dz_heel
            ring.append(Vector((x, y, z)))
        rings.append(ring)
    add_lathe_rings(bm, rings, mat_idx=mat_idx, cap_bot=True, cap_top=True)


def add_upper_shell(bm, z0, z_top, mat_idx=0, n_u=24, half_w=0.125, len_fwd=0.22, len_back=0.16,
                    toe_point=0.0, heel_narrow=0.16, shaft_z=None, collar_r=0.095, toe_bulb=0.0):
    """Smooth rounded shoe vamp (+ optional boot shaft rising to shaft_z)."""
    rings = []
    # Lower vamp: smooth rounded dome over toes & instep, rising to ankle opening at back
    levels = [
        (0.00, 1.00, 1.00),
        (0.25, 0.99, 0.99),
        (0.55, 0.91, 0.92),
        (0.80, 0.76, 0.78),
        (0.95, 0.54, 0.56),
    ]
    for t, rx, ry in levels:
        ring = []
        for j in range(n_u):
            a = j * math.tau / n_u
            ca = math.cos(a)
            # Toe box is lower/rounder in front, taller toward ankle/instep at back
            h_local = z_top - z0
            if ca > 0.0:
                h_local *= (0.72 + 0.28 * (1.0 - ca ** 1.5)) + toe_bulb * (ca ** 1.5)
            z = z0 + t * h_local
            x, y = foot_contour(a, half_w * rx, len_fwd * ry, len_back * ry, toe_point, heel_narrow)
            # shift upper rings slightly back toward ankle centre (y = +0.04)
            y = y + 0.045 * (t ** 1.4) * (1.0 - max(0.0, -ca) * 0.5)
            ring.append(Vector((x, y, z)))
        rings.append(ring)
    add_lathe_rings(bm, rings, mat_idx=mat_idx, cap_bot=True, cap_top=True)

    if shaft_z is not None and shaft_z > z_top:
        # Smooth boot shaft rising cleanly from ankle up under torso hem
        s_rings = []
        for i in range(5):
            t = i / 4.0
            z = (z_top - 0.03) + t * (shaft_z - (z_top - 0.03))
            r_x = collar_r * (0.96 + 0.08 * t)
            r_y = collar_r * (1.06 + 0.06 * t)
            ring = []
            for j in range(n_u):
                a = j * math.tau / n_u
                ring.append(Vector((math.sin(a) * r_x, 0.045 - math.cos(a) * r_y, z)))
            s_rings.append(ring)
        add_lathe_rings(bm, s_rings, mat_idx=mat_idx, cap_bot=False, cap_top=True)


def add_curved_strap(bm, y_pos, z_base, z_apex, half_w, width_y, thick, mat_idx=0, n_s=12, tilt_y=0.0):
    """Smooth arched strap over the foot/instep."""
    sec = [(-width_y * 0.5, 0.0), (width_y * 0.5, 0.0), (width_y * 0.45, thick), (-width_y * 0.45, thick)]
    rings = []
    for i in range(n_s + 1):
        u = -1.0 + 2.0 * i / n_s
        ang = u * (math.pi * 0.5)
        cx = math.sin(ang) * half_w
        cz = z_base + math.cos(ang) * (z_apex - z_base)
        cy = y_pos + tilt_y * math.cos(ang)
        nx = math.sin(ang)
        nz = math.cos(ang)
        ring = []
        for dy, dn in sec:
            ring.append(bm.verts.new(Vector((cx + nx * dn, cy + dy, cz + nz * dn))))
        rings.append(ring)
    for i in range(n_s):
        r0, r1 = rings[i], rings[i + 1]
        for k in range(4):
            kn = (k + 1) % 4
            f = bm.faces.new((r0[k], r0[kn], r1[kn], r1[k]))
            f.material_index = mat_idx
            f.smooth = True
    # Cap ends
    for end_r, rev in ((rings[0], True), (rings[-1], False)):
        f = bm.faces.new(tuple(reversed(end_r)) if rev else tuple(end_r))
        f.material_index = mat_idx


def add_tube(bm, pts, radius, mat_idx=1, n_seg=8, rx_mul=1.0, rz_mul=1.0):
    """Smooth rounded tube along 3D polyline pts."""
    rings = []
    for idx, p in enumerate(pts):
        if idx == 0:
            t = (pts[1] - pts[0]).normalized()
        elif idx == len(pts) - 1:
            t = (pts[-1] - pts[-2]).normalized()
        else:
            t = (pts[idx + 1] - pts[idx - 1]).normalized()
        up = Vector((0.0, 0.0, 1.0)) if abs(t.z) < 0.9 else Vector((1.0, 0.0, 0.0))
        u = t.cross(up).normalized()
        v = t.cross(u).normalized()
        ring = []
        for k in range(n_seg):
            a = k * math.tau / n_seg
            off = u * (math.cos(a) * radius * rx_mul) + v * (math.sin(a) * radius * rz_mul)
            ring.append(p + off)
        rings.append(ring)
    add_lathe_rings(bm, rings, mat_idx=mat_idx, cap_bot=True, cap_top=True)


def add_ellipsoid(bm, pos, scl, mat_idx=1, u_seg=10, v_seg=6, rot_euler=None):
    res = bmesh.ops.create_uvsphere(bm, u_segments=u_seg, v_segments=v_seg, radius=1.0)
    rot = Matrix.Identity(4)
    if rot_euler:
        rot = Matrix.Rotation(rot_euler[2], 4, 'Z') @ Matrix.Rotation(rot_euler[1], 4, 'Y') @ Matrix.Rotation(rot_euler[0], 4, 'X')
    for v in res['verts']:
        p = Vector((v.co.x * scl[0], v.co.y * scl[1], v.co.z * scl[2]))
        v.co = pos + (rot @ p)
        for f in v.link_faces:
            f.material_index = mat_idx
            f.smooth = True


def bake_and_export(bm, name, mat_defs, out_dir):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()
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
        shade[v] = min(1.0, max(0.80, 1.0 - max(0.0, s) * 0.75))
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
    print(f'CALZADO {name:24s} {tris:4d} tris  surfs={len(mat_defs)}  '
          f'W={max(v.x for v in vs)-min(v.x for v in vs):.2f}  '
          f'L={max(v.y for v in vs)-min(v.y for v in vs):.2f}  '
          f'Z={min(v.z for v in vs):.2f}..{max(v.z for v in vs):.2f}')


# ---------------- Palette constants (linear RGB for Blender Principled BSDF) ----------------
COL_MAIN = (0.14, 0.08, 0.04, 1.0)
COL_WHITE = (0.88, 0.85, 0.78, 1.0)
COL_CREAM = (0.90, 0.85, 0.72, 1.0)
COL_DARK = (0.032, 0.032, 0.038, 1.0)
COL_JUTE = (0.62, 0.42, 0.14, 1.0)
COL_WOOD = (0.20, 0.09, 0.035, 1.0)
COL_TAN = (0.46, 0.27, 0.12, 1.0)
COL_GOLD = (0.76, 0.56, 0.12, 1.0)


# ---------------- Individual shoe builders ----------------

def build_lona():
    """0 · Zapatillas (classic Converse-style canvas sneakers): white rounded sole, white toe cap & laces."""
    bm = bmesh.new()
    add_sole(bm, GROUND_Z, GROUND_Z + 0.048, mat_idx=1, half_w=0.130, len_fwd=0.220, len_back=0.160, toe_lift=0.008)
    add_upper_shell(bm, GROUND_Z + 0.042, 0.095, mat_idx=0, half_w=0.124, len_fwd=0.212, len_back=0.155)
    # Iconic rounded white rubber toe cap
    add_ellipsoid(bm, Vector((0.0, -0.155, -0.048)), (0.098, 0.072, 0.056), mat_idx=1, u_seg=12, v_seg=7)
    # 3 crisp white laces across the vamp
    for ly, lz, w in ((-0.095, 0.025, 0.068), (-0.050, 0.052, 0.068), (-0.005, 0.074, 0.064)):
        add_tube(bm, [Vector((-w, ly, lz - 0.008)), Vector((0.0, ly - 0.008, lz + 0.006)), Vector((w, ly, lz - 0.008))],
                 radius=0.010, mat_idx=1, n_seg=6)
    return bm, [('lona', COL_MAIN), ('blanco', COL_WHITE)]


def build_botas():
    """1 · Botas (classic chunky ankle boots): thick dark lug sole + rounded leather vamp & shaft."""
    bm = bmesh.new()
    add_sole(bm, GROUND_Z, GROUND_Z + 0.055, mat_idx=1, half_w=0.132, len_fwd=0.222, len_back=0.165, arch_lift=0.012)
    add_upper_shell(bm, GROUND_Z + 0.048, 0.105, mat_idx=0, half_w=0.126, len_fwd=0.214, len_back=0.158,
                    shaft_z=0.18, collar_r=0.098)
    # Subtle dark laces up the front
    for ly, lz in ((-0.075, 0.042), (-0.042, 0.075), (-0.015, 0.108)):
        add_tube(bm, [Vector((-0.055, ly, lz - 0.005)), Vector((0.0, ly - 0.010, lz + 0.005)), Vector((0.055, ly, lz - 0.005))],
                 radius=0.009, mat_idx=1, n_seg=6)
    return bm, [('bota', COL_MAIN), ('suela', COL_DARK)]


def build_alpargatas():
    """2 · Alpargatas (traditional Spanish espadrilles): chunky jute rope sole, canvas upper & criss-cross ties."""
    bm = bmesh.new()
    # Chunky braided jute/esparto rope sole (two stacked subtle rope bands)
    add_sole(bm, GROUND_Z, GROUND_Z + 0.034, mat_idx=1, half_w=0.130, len_fwd=0.218, len_back=0.160)
    add_sole(bm, GROUND_Z + 0.030, GROUND_Z + 0.062, mat_idx=1, half_w=0.128, len_fwd=0.215, len_back=0.158)
    # Canvas espadrille upper (sleeker, lower than sneakers)
    add_upper_shell(bm, GROUND_Z + 0.056, 0.065, mat_idx=0, half_w=0.122, len_fwd=0.208, len_back=0.152)
    # Visible criss-cross espadrille ribbons wrapping low across instep/ankle (below torso hem z=0.115!)
    for sgn in (-1.0, 1.0):
        pts = [
            Vector((sgn * 0.105, 0.04, 0.01)),
            Vector((sgn * 0.055, -0.045, 0.045)),
            Vector((-sgn * 0.055, -0.015, 0.078)),
            Vector((-sgn * 0.095, 0.06, 0.095)),
        ]
        add_tube(bm, pts, radius=0.012, mat_idx=1, n_seg=6, rz_mul=0.65)
    return bm, [('lona', COL_MAIN), ('esparto', COL_JUTE)]


def build_chanclas():
    """3 · Chanclas (beach flip-flops): contoured anatomical sole + visible front toe-post Y-strap over bare foot."""
    bm = bmesh.new()
    # Thin dark outsole + main colored contoured footbed
    add_sole(bm, GROUND_Z, GROUND_Z + 0.022, mat_idx=1, half_w=0.126, len_fwd=0.222, len_back=0.162)
    add_sole(bm, GROUND_Z + 0.020, GROUND_Z + 0.042, mat_idx=0, half_w=0.124, len_fwd=0.219, len_back=0.160)
    # Visible front toe-post in front of the bare foot ball (foot front reaches y = -0.175) + arched Y-straps
    post_bot = Vector((0.0, -0.184, -0.090))
    post_top = Vector((0.0, -0.178, 0.008))
    add_tube(bm, [post_bot, post_top], radius=0.013, mat_idx=0, n_seg=7)
    for sgn in (-1.0, 1.0):
        pts = [
            post_top,
            Vector((sgn * 0.058, -0.115, 0.046)),
            Vector((sgn * 0.114, -0.032, 0.028)),
            Vector((sgn * 0.118, 0.035, -0.088)),
        ]
        add_tube(bm, pts, radius=0.014, mat_idx=0, n_seg=7, rz_mul=0.62)
    return bm, [('chancla', COL_MAIN), ('suela', COL_DARK)]


def build_deportivas():
    """5 · Deportivas (sporty running shoes): thick sculpted white midsole, dark outsole, white side stripes & laces."""
    bm = bmesh.new()
    # Thin dark rubber outsole + chunky sculpted white athletic midsole (springy toe!)
    add_sole(bm, GROUND_Z, GROUND_Z + 0.018, mat_idx=2, half_w=0.130, len_fwd=0.228, len_back=0.168, toe_lift=0.022)
    add_sole(bm, GROUND_Z + 0.015, GROUND_Z + 0.058, mat_idx=1, half_w=0.132, len_fwd=0.226, len_back=0.166, toe_lift=0.020)
    # Sporty upper
    add_upper_shell(bm, GROUND_Z + 0.052, 0.098, mat_idx=0, half_w=0.122, len_fwd=0.214, len_back=0.156, toe_point=0.10)
    # Two sporty white diagonal stripes on EACH side (makes them unmistakably running shoes!)
    for side in (-1.0, 1.0):
        for off_y in (-0.035, 0.018):
            pts = [
                Vector((side * 0.122, off_y - 0.025, -0.068)),
                Vector((side * 0.116, off_y + 0.005, -0.012)),
                Vector((side * 0.095, off_y + 0.032, 0.042)),
            ]
            add_tube(bm, pts, radius=0.011, mat_idx=1, n_seg=6, rx_mul=0.55)
    # Crisp white athletic laces
    for ly, lz in ((-0.085, 0.032), (-0.045, 0.056), (-0.005, 0.076)):
        add_tube(bm, [Vector((-0.058, ly, lz - 0.006)), Vector((0.0, ly - 0.008, lz + 0.006)), Vector((0.058, ly, lz - 0.006))],
                 radius=0.010, mat_idx=1, n_seg=6)
    return bm, [('deportiva', COL_MAIN), ('blanco', COL_WHITE), ('suela', COL_DARK)]


def build_botas_faena():
    """6 · Botas de faena (heavy-duty work boots): rugged dark lug sole, steel toe cap, padded collar & laces."""
    bm = bmesh.new()
    # Extra chunky dark treaded work sole
    add_sole(bm, GROUND_Z, GROUND_Z + 0.060, mat_idx=1, half_w=0.136, len_fwd=0.228, len_back=0.168, arch_lift=0.016)
    add_upper_shell(bm, GROUND_Z + 0.052, 0.112, mat_idx=0, half_w=0.128, len_fwd=0.218, len_back=0.160,
                    shaft_z=0.18, collar_r=0.104, toe_bulb=0.012)
    # Reinforced dark steel toe bumper cap
    add_ellipsoid(bm, Vector((0.0, -0.155, -0.032)), (0.108, 0.078, 0.062), mat_idx=1, u_seg=12, v_seg=7)
    # Contrasting tan/yellow work-boot laces
    for ly, lz in ((-0.080, 0.045), (-0.045, 0.078), (-0.015, 0.106)):
        add_tube(bm, [Vector((-0.060, ly, lz - 0.006)), Vector((0.0, ly - 0.010, lz + 0.006)), Vector((0.060, ly, lz - 0.006))],
                 radius=0.010, mat_idx=2, n_seg=6)
    return bm, [('faena', COL_MAIN), ('goma', COL_DARK), ('cordones', COL_JUTE)]


def build_botas_agua():
    """7 · Botas de agua (rain wellies): smooth rounded wellington boot + contrasting cream rubber sole & top trim."""
    bm = bmesh.new()
    # Chunky contrasting off-white/cream rubber rain sole (distinguishes wellies immediately!)
    add_sole(bm, GROUND_Z, GROUND_Z + 0.050, mat_idx=1, half_w=0.132, len_fwd=0.224, len_back=0.164, arch_lift=0.010)
    add_upper_shell(bm, GROUND_Z + 0.044, 0.095, mat_idx=0, half_w=0.125, len_fwd=0.214, len_back=0.156,
                    shaft_z=0.19, collar_r=0.102)
    # Crisp contrasting rubber stripe/collar band just visible below torso hem + heel kick tab
    add_sole(bm, 0.075, 0.105, mat_idx=1, half_w=0.106, len_fwd=0.065, len_back=0.152)
    add_ellipsoid(bm, Vector((0.0, -0.195, -0.088)), (0.082, 0.035, 0.025), mat_idx=1, u_seg=10, v_seg=5)
    return bm, [('agua', COL_MAIN), ('goma', COL_WHITE)]


def build_sandalias():
    """8 · Sandalias (summer strappy sandals): tan footbed, thin dark outsole, 2 clean curved straps + gold buckle."""
    bm = bmesh.new()
    add_sole(bm, GROUND_Z, GROUND_Z + 0.022, mat_idx=2, half_w=0.125, len_fwd=0.214, len_back=0.162)
    add_sole(bm, GROUND_Z + 0.020, GROUND_Z + 0.042, mat_idx=1, half_w=0.123, len_fwd=0.210, len_back=0.160)
    # Two clean smooth arched straps hugging the bare/sock ball foot with zero clipping
    add_curved_strap(bm, y_pos=-0.095, z_base=-0.088, z_apex=0.044, half_w=0.120, width_y=0.046, thick=0.014, mat_idx=0)
    add_curved_strap(bm, y_pos=0.010, z_base=-0.088, z_apex=0.064, half_w=0.122, width_y=0.044, thick=0.014, mat_idx=0)
    # Tiny neat gold buckle on the outer side of the instep strap
    add_ellipsoid(bm, Vector((-0.122, 0.010, -0.015)), (0.014, 0.022, 0.022), mat_idx=3, u_seg=8, v_seg=5)
    return bm, [('sandalia', COL_MAIN), ('plantilla', COL_TAN), ('suela', COL_DARK), ('hebilla', COL_GOLD)]


def build_bailarinas():
    """9 · Bailarinas (ballet flats): sleek low-cut rounded flat shoe with deep open instep + cute front bow."""
    bm = bmesh.new()
    n_u = 28
    # Thin dark flat outsole
    add_sole(bm, GROUND_Z, GROUND_Z + 0.024, mat_idx=1, half_w=0.124, len_fwd=0.214, len_back=0.160, toe_point=0.08)
    # Low-cut hollowed ballet flat rim (wraps cleanly around toes and heel, open on top so the foot/instep shows!)
    out_r, in_r = [], []
    levels = [
        (0.00, 1.00, -0.106),
        (0.35, 1.02, -0.065),
        (0.75, 0.96, -0.022),
        (1.00, 0.88, 0.004),
    ]
    for t, rm, z_base in levels:
        og, ig = [], []
        for j in range(n_u):
            a = j * math.tau / n_u
            ca = math.cos(a)
            # slightly higher at toe cap and heel counter, scooped low along sides
            scoop = 0.024 * (max(0.0, ca) ** 2.0) + 0.032 * (max(0.0, -ca) ** 2.0)
            z = z_base + scoop * t
            x, y = foot_contour(a, 0.124 * rm, 0.212 * rm, 0.158 * rm, toe_point=0.08)
            og.append(bm.verts.new(Vector((x, y, z))))
            ig.append(bm.verts.new(Vector((x * 0.86, y * 0.88, z))))
        out_r.append(og)
        in_r.append(ig)
    for i in range(len(levels) - 1):
        for j in range(n_u):
            jn = (j + 1) % n_u
            f1 = bm.faces.new((out_r[i][j], out_r[i][jn], out_r[i + 1][jn], out_r[i + 1][j]))
            f2 = bm.faces.new((in_r[i][jn], in_r[i][j], in_r[i + 1][j], in_r[i + 1][jn]))
            f1.smooth = f2.smooth = True
    for j in range(n_u):
        jn = (j + 1) % n_u
        bm.faces.new((out_r[-1][j], out_r[-1][jn], in_r[-1][jn], in_r[-1][j])).smooth = True
    # Cute little bow right on the front rim
    for sgn in (-1.0, 1.0):
        add_ellipsoid(bm, Vector((sgn * 0.032, -0.145, 0.024)), (0.032, 0.016, 0.018), mat_idx=0, u_seg=8, v_seg=5,
                      rot_euler=(0.0, sgn * 0.2, -sgn * 0.25))
    add_ellipsoid(bm, Vector((0.0, -0.150, 0.024)), (0.016, 0.016, 0.016), mat_idx=1, u_seg=8, v_seg=5)
    return bm, [('bailarina', COL_MAIN), ('suela', COL_DARK)]


def build_camperas():
    """10 · Camperas (Western cowboy boots): tapered almond toe, stacked wood Cuban heel & Western toe/heel accents."""
    bm = bmesh.new()
    # Stacked wood-brown Western sole + distinct Cuban heel block
    add_sole(bm, GROUND_Z + 0.018, GROUND_Z + 0.052, mat_idx=1, half_w=0.126, len_fwd=0.232, len_back=0.156,
             toe_point=0.22, toe_lift=0.018, arch_lift=0.026, heel_extra=0.018)
    # Chunky stacked wooden Cuban heel under back
    add_ellipsoid(bm, Vector((0.0, 0.108, GROUND_Z + 0.030)), (0.088, 0.068, 0.034), mat_idx=1, u_seg=12, v_seg=6)
    # Tapered cowboy boot vamp & shaft
    add_upper_shell(bm, GROUND_Z + 0.046, 0.102, mat_idx=0, half_w=0.120, len_fwd=0.224, len_back=0.150,
                    toe_point=0.22, shaft_z=0.18, collar_r=0.094)
    # Contrasting warm-tan Western toe tip & heel overlay
    add_ellipsoid(bm, Vector((0.0, -0.172, -0.048)), (0.078, 0.065, 0.048), mat_idx=2, u_seg=12, v_seg=6)
    add_ellipsoid(bm, Vector((0.0, 0.118, -0.032)), (0.092, 0.056, 0.058), mat_idx=2, u_seg=10, v_seg=6)
    return bm, [('campera', COL_MAIN), ('madera', COL_WOOD), ('adorno', COL_TAN)]


def build_zapatillas_casa():
    """11 · Zapatillas de casa (cozy house slippers): plush rounded slipper + thick cream sherpa fleece cuff."""
    bm = bmesh.new()
    # Soft thin flexible sole
    add_sole(bm, GROUND_Z, GROUND_Z + 0.028, mat_idx=2, half_w=0.128, len_fwd=0.216, len_back=0.160)
    # Soft plush rounded slipper body
    add_upper_shell(bm, GROUND_Z + 0.024, 0.072, mat_idx=0, half_w=0.126, len_fwd=0.212, len_back=0.158, toe_bulb=0.012)
    # Thick pillowy cream sherpa cuff wrapping smoothly around the ankle opening
    n_u = 24
    cuff_pts = [Vector((math.sin(j * math.tau / n_u) * 0.108, 0.035 - math.cos(j * math.tau / n_u) * 0.118, 0.048 + 0.014 * math.cos(j * math.tau / n_u)))
                for j in range(n_u + 1)]
    add_tube(bm, cuff_pts, radius=0.034, mat_idx=1, n_seg=8, rz_mul=0.90)
    return bm, [('casa', COL_MAIN), ('borrego', COL_CREAM), ('suela', COL_DARK)]


def build_tacones():
    """12 · Tacones (heeled pumps): sculpted pump + real heel + lifted arch so the skin foot NEVER pokes underneath."""
    bm = bmesh.new()
    n_u = 28
    # Contoured arched dark sole (drops at front ball to ground, rises sharply under arch, connects to heel!)
    add_sole(bm, GROUND_Z, GROUND_Z + 0.024, mat_idx=1, half_w=0.116, len_fwd=0.218, len_back=0.140,
             toe_point=0.18, arch_lift=0.056)
    # Real sculpted stiletto/block heel at the back (from ground -0.13 up to -0.025)
    h_rings = []
    for t, rx, ry in ((0.0, 0.036, 0.038), (0.45, 0.044, 0.048), (1.0, 0.072, 0.062)):
        z = GROUND_Z + t * 0.108
        h_rings.append([Vector((math.sin(j * math.tau / 14) * rx, 0.105 - math.cos(j * math.tau / 14) * ry, z)) for j in range(14)])
    add_lathe_rings(bm, h_rings, mat_idx=0, cap_bot=True, cap_top=True)
    # Heel tip dark cap on ground
    add_ellipsoid(bm, Vector((0.0, 0.105, GROUND_Z + 0.008)), (0.038, 0.040, 0.010), mat_idx=1, u_seg=10, v_seg=4)

    # Sleek sculpted open-top pump shell sitting cleanly on the arched sole
    out_r, in_r = [], []
    levels = [
        (0.00, 1.00, 0.00),
        (0.45, 0.98, 0.042),
        (0.85, 0.92, 0.076),
        (1.00, 0.84, 0.092),
    ]
    for t, rm, dz_l in levels:
        og, ig = [], []
        for j in range(n_u):
            a = j * math.tau / n_u
            ca = math.cos(a)
            x, y = foot_contour(a, 0.118 * rm, 0.214 * rm, 0.145 * rm, toe_point=0.18)
            # base follows the arched heel slope (higher at heel, on ground at toe)
            z_arch = GROUND_Z + 0.022 + 0.078 * smoothstep(-0.08, 0.11, y)
            scoop = 0.018 * (max(0.0, ca) ** 2.0) + 0.038 * (max(0.0, -ca) ** 2.0)
            z = z_arch + dz_l + scoop * t
            og.append(bm.verts.new(Vector((x, y, z))))
            ig.append(bm.verts.new(Vector((x * 0.86, y * 0.88, z))))
        out_r.append(og)
        in_r.append(ig)
    for i in range(len(levels) - 1):
        for j in range(n_u):
            jn = (j + 1) % n_u
            f1 = bm.faces.new((out_r[i][j], out_r[i][jn], out_r[i + 1][jn], out_r[i + 1][j]))
            f2 = bm.faces.new((in_r[i][jn], in_r[i][j], in_r[i + 1][j], in_r[i + 1][jn]))
            f1.smooth = f2.smooth = True
    for j in range(n_u):
        jn = (j + 1) % n_u
        bm.faces.new((out_r[-1][j], out_r[-1][jn], in_r[-1][jn], in_r[-1][j])).smooth = True
    return bm, [('tacon', COL_MAIN), ('suela', COL_DARK)]


def build_misa():
    """13 · Zapatos de misa (classic dress penny loafers / mocasines): dark dress sole + low heel + penny strap."""
    bm = bmesh.new()
    # Sleek dark polished dress sole with subtle low heel
    add_sole(bm, GROUND_Z + 0.008, GROUND_Z + 0.042, mat_idx=1, half_w=0.124, len_fwd=0.226, len_back=0.162,
             toe_point=0.14, arch_lift=0.012, heel_extra=0.008)
    add_ellipsoid(bm, Vector((0.0, 0.105, GROUND_Z + 0.018)), (0.095, 0.062, 0.020), mat_idx=1, u_seg=12, v_seg=5)
    # Sleek low dress loafer body
    add_upper_shell(bm, GROUND_Z + 0.036, 0.082, mat_idx=0, half_w=0.118, len_fwd=0.218, len_back=0.156, toe_point=0.14)
    # Iconic penny-loafer strap across the vamp (in darker contrasting leather + tiny gold penny detail!)
    add_curved_strap(bm, y_pos=-0.048, z_base=-0.075, z_apex=0.056, half_w=0.116, width_y=0.054, thick=0.012, mat_idx=1)
    add_ellipsoid(bm, Vector((0.0, -0.048, 0.064)), (0.024, 0.012, 0.008), mat_idx=2, u_seg=8, v_seg=4)
    # Classic moccasin U-shaped apron seam ridge around the toe box
    u_pts = [Vector((math.sin(a) * 0.088, -0.055 - math.cos(a) * 0.125, -0.010 + 0.042 * (1.0 - max(0.0, math.cos(a)))))
             for a in [-1.35 + 2.70 * i / 12.0 for i in range(13)]]
    add_tube(bm, u_pts, radius=0.009, mat_idx=1, n_seg=6)
    return bm, [('mocasin', COL_MAIN), ('suela', COL_DARK), ('detalle', COL_GOLD)]


def build_zuecos():
    """14 · Zapatos feos (chunky Crocs-style clogs!): oversized bulbous perforated toe box + chunky sole + heel strap."""
    bm = bmesh.new()
    # Oversized chunky rounded comfort sole
    add_sole(bm, GROUND_Z, GROUND_Z + 0.052, mat_idx=0, half_w=0.144, len_fwd=0.228, len_back=0.162, heel_narrow=0.10, toe_lift=0.010)
    # Subtle contrasting sole stripe all around
    add_sole(bm, GROUND_Z + 0.016, GROUND_Z + 0.030, mat_idx=1, half_w=0.147, len_fwd=0.231, len_back=0.165, heel_narrow=0.10, toe_lift=0.010)
    # Iconic wide bulbous oversized clog vamp (extra wide & rounded at the front!)
    add_upper_shell(bm, GROUND_Z + 0.046, 0.095, mat_idx=0, half_w=0.140, len_fwd=0.222, len_back=0.145,
                    heel_narrow=0.14, toe_bulb=0.028)
    # Iconic dark Crocs ventilation holes on top of the bulbous toe box + 3 side ports on each side!
    for hx, hy, hz in (
        (-0.048, -0.148, 0.014), (0.0, -0.162, 0.010), (0.048, -0.148, 0.014),
        (-0.058, -0.098, 0.042), (0.0, -0.112, 0.042), (0.058, -0.098, 0.042),
        (-0.042, -0.052, 0.062), (0.042, -0.052, 0.062),
    ):
        add_ellipsoid(bm, Vector((hx, hy, hz)), (0.017, 0.017, 0.010), mat_idx=2, u_seg=8, v_seg=4)
    for side in (-1.0, 1.0):
        for py in (-0.125, -0.075, -0.025):
            add_ellipsoid(bm, Vector((side * 0.136, py, -0.052)), (0.010, 0.015, 0.012), mat_idx=2, u_seg=6, v_seg=4)
    # Iconic pivoting clog heel strap + dark side rivets!
    strap_pts = [
        Vector((-0.128, 0.015, 0.010)),
        Vector((-0.118, 0.095, 0.035)),
        Vector((0.0, 0.172, 0.042)),
        Vector((0.118, 0.095, 0.035)),
        Vector((0.128, 0.015, 0.010)),
    ]
    add_tube(bm, strap_pts, radius=0.019, mat_idx=0, n_seg=7, rz_mul=1.1)
    for side in (-1.0, 1.0):
        add_ellipsoid(bm, Vector((side * 0.134, 0.015, 0.010)), (0.012, 0.020, 0.020), mat_idx=2, u_seg=8, v_seg=5)
    return bm, [('zueco', COL_MAIN), ('banda', COL_WHITE), ('agujeros', COL_DARK)]


BUILDERS = {
    'calzado_lona': build_lona,
    'calzado_botas': build_botas,
    'calzado_alpargatas': build_alpargatas,
    'calzado_chanclas': build_chanclas,
    'calzado_zapatillas': build_deportivas,
    'calzado_botas_faena': build_botas_faena,
    'calzado_botas_agua': build_botas_agua,
    'calzado_sandalias': build_sandalias,
    'calzado_bailarinas': build_bailarinas,
    'calzado_camperas': build_camperas,
    'calzado_zapatillas_casa': build_zapatillas_casa,
    'calzado_tacones': build_tacones,
    'calzado_misa': build_misa,
    'calzado_zuecos': build_zuecos,
}


def main():
    args = sys.argv[sys.argv.index('--') + 1:]
    out_dir = args[0]
    only = set(args[1:]) if len(args) > 1 else set(BUILDERS.keys())
    for name, fn in BUILDERS.items():
        if name not in only:
            continue
        bm, mats = fn()
        bake_and_export(bm, name, mats, out_dir)


if __name__ == '__main__':
    main()
