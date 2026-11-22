"""The Street View pictures the crossroads of the traffic lights is measured from (the user, 21 November 2026: "el
cruce de los semáforos" or "las cuatro esquinas"; first its red corner building, "Seguros Sopiss" in the game). They
are Google's: NOT kept in the repository, only this list. Writes views.json beside them.

    python tools/cruce/capturas.py OUT_FOLDER [name ...]

Google's car went through all five streets in November 2024 (and 2021, 2019, 2013, 2012, 2009 at most spots). Every
camera round it: python tools/molino/panos.py cerca MX048pEYVrMizUfLzgdf8A 111 68 34
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

# the red building (Catastro 4391002VJ5649S, part 1), on the map
NW = (96.5, 59.4)                 # where its three floors end on the Salvador
NE = (108.32, 62.26)              # its corner of the Salvador and the avenue
SE = (108.56, 70.77)              # its corner of the avenue and the Teniente Infante
SW = (103.82, 72.76)              # where it ends on the Teniente Infante
def mid(a, b, k=0.5): return (a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k)

# the cameras of November 2024 (id, x, z)
CN = ('wJrwC7OIrdwyG6Ag_tcQ8A', 112.36, 61.38)     # on the avenue, before its north corner
CS = ('MX048pEYVrMizUfLzgdf8A', 111.39, 70.68)     # on the avenue, before its south corner
CN2 = ('G6dyim3Kn23g0Cg1WW9Ekw', 112.79, 51.24)    # on the avenue, ten metres north
A1 = ('nUMs3kr4b23TmHY6NGjAiw', 123.18, 68.57)     # on Santa Ana, straight before its front
A2 = ('CBt-cHjZO6uJHbtaamEAVA', 134.59, 70.48)     # on Santa Ana, further east
S1 = ('g4GegfrqtNCWRqHR-AikzA', 99.84, 56.23)      # on the Salvador, before its north side
S2 = ('GoUKXt1VLeE5_22rpVJZww', 90.58, 52.96)      # on the Salvador, further west
T1 = ('pyEBIrwfy7y3eqEk0Mo_aw', 101.53, 75.03)     # on the Teniente Infante, before its south side
T2 = ('aDwg-sUWTDvB8J-zZGMEKQ', 90.98, 76.64)      # on the Teniente Infante, further west
R1 = ('xihL8Rs66EZLdzD8zfpNyw', 111.96, 81.79)     # on the Arcos, looking north
R2 = ('iE_CHEMBkWEj3w2fdvGjTw', 111.90, 92.14)     # on the Arcos, further south

SHOTS = [
    # (name, camera, looking at, pitch, fov)
    ('a1_frente', A1, mid(NE, SE), 12, 75), ('a1_bajo', A1, mid(NE, SE), 2, 50), ('a1_alto', A1, mid(NE, SE), 30, 75),
    ('a2_frente', A2, mid(NE, SE), 8, 50),
    ('cn_frente', CN, mid(NE, SE), 12, 100), ('cn_norte', CN, mid(NW, NE, 0.7), 12, 100), ('cn_alto', CN, mid(NE, SE, 0.3), 45, 100),
    ('cs_frente', CS, mid(NE, SE), 12, 100), ('cs_sur', CS, mid(SE, SW), 12, 100), ('cs_alto', CS, mid(NE, SE, 0.7), 45, 100),
    ('cs_bajo', CS, mid(NE, SE, 0.6), -5, 90),
    ('cn2_esquina', CN2, NE, 12, 70),
    ('s1_norte', S1, mid(NW, NE), 10, 100), ('s1_este', S1, mid(NW, NE, 0.85), 10, 90), ('s1_oeste', S1, mid(NW, NE, 0.1), 10, 90),
    ('s1_alto', S1, mid(NW, NE), 42, 100), ('s2_norte', S2, mid(NW, NE), 8, 60),
    ('t1_sur', T1, mid(SE, SW), 12, 100), ('t1_alto', T1, mid(SE, SW), 45, 100), ('t1_vecino', T1, (98.0, 71.6), 12, 100),
    ('t2_sur', T2, mid(SE, SW), 8, 50),
    ('r1_sur', R1, mid(SE, SW), 12, 70), ('r2_sur', R2, SE, 8, 40),
]

# the dental clinic (Catastro 4390018VJ5649S; the house arcos_2 of the map), on the map: "Clínica Dental" in the game
# (the user, 22 November 2026). Its pictures are the d_ ones.
D_NW = (96.54, 79.20)             # where it ends on the Calle Cervantes
D_NE = (108.48, 77.76)            # its corner of the Calle Cervantes and the Arcos (the cut's north end)
D_CH = (109.11, 78.55)            # the cut's other end
D_SE = (109.06, 86.65)            # where it ends on the Arcos
R0 = ('fH7IvgkZYsJCy2X8xkJ9SQ', 112.53, 101.64)    # on the Arcos, twenty metres south
SHOTS += [
    ('d_r1_este', R1, mid(D_CH, D_SE), 10, 100), ('d_r1_alto', R1, mid(D_CH, D_SE), 40, 100), ('d_r1_esquina', R1, D_NE, 10, 90),
    ('d_r1_sur', R1, mid(D_CH, D_SE, 0.9), 8, 90), ('d_r2_este', R2, mid(D_CH, D_SE), 12, 60), ('d_r0_este', R0, mid(D_CH, D_SE), 8, 35),
    ('d_cs_esquina', CS, D_NE, 10, 80), ('d_cs_norte', CS, mid(D_NW, D_NE, 0.6), 10, 80), ('d_cs_alto', CS, D_NE, 32, 80),
    ('d_t1_norte', T1, mid(D_NW, D_NE), 10, 100), ('d_t1_este', T1, mid(D_NW, D_NE, 0.85), 10, 90), ('d_t1_oeste', T1, mid(D_NW, D_NE, 0.15), 10, 90),
    ('d_t1_alto', T1, mid(D_NW, D_NE), 42, 100), ('d_t2_norte', T2, mid(D_NW, D_NE), 8, 60),
    ('d_a1_esquina', A1, D_NE, 8, 45),
]

# the white house with blue frames, Calle de Santa Ana 2 (Catastro 4690001VJ5649S; the house constitucion_a1 of the
# map), on the map (the user, 22 November 2026). Its pictures are the e_ ones.
E_NW = (116.70, 74.14)            # its corner of Santa Ana and the Arcos
E_NE = (131.66, 73.67)            # where it ends on Santa Ana
E_SW = (116.49, 78.83)            # where it ends on the Arcos
SHOTS += [
    ('e_a1_frente', A1, mid(E_NW, E_NE), 10, 110), ('e_a1_oeste', A1, mid(E_NW, E_NE, 0.2), 10, 90), ('e_a1_este', A1, mid(E_NW, E_NE, 0.8), 10, 90),
    ('e_a1_alto', A1, mid(E_NW, E_NE), 38, 110), ('e_a2_oeste', A2, mid(E_NW, E_NE, 0.6), 8, 70),
    ('e_cs_esquina', CS, E_NW, 10, 70), ('e_cs_norte', CS, mid(E_NW, E_NE, 0.4), 10, 80),
    ('e_r1_oeste', R1, mid(E_NW, E_SW), 10, 80), ('e_r1_alto', R1, mid(E_NW, E_SW), 32, 80), ('e_t1_oeste', T1, mid(E_NW, E_SW), 6, 35),
    ('e_r2_oeste', R2, E_SW, 8, 45),
]

# the cream house with the bay window, on the corner of the avenue and Santa Ana (Catastro 4491809VJ5649S; the house
# constitucion_2 of the map), on the map. Its pictures are the f_ ones.
F_N = (118.50, 47.62)             # where it ends on the avenue
F_C1 = (117.97, 57.91)            # the corner's cut: its end on the avenue...
F_C2 = (120.12, 61.46)            # ...and on Santa Ana
F_E = (129.63, 63.93)             # where it ends on Santa Ana
SHOTS += [
    ('f_cn_oeste', CN, mid(F_N, F_C1, 0.6), 10, 100), ('f_cn_esquina', CN, mid(F_C1, F_C2), 10, 90), ('f_cn_alto', CN, mid(F_C1, F_C2), 36, 100),
    ('f_cn2_oeste', CN2, mid(F_N, F_C1), 10, 100), ('f_cs_esquina', CS, mid(F_C1, F_C2), 10, 70), ('f_cs_alto', CS, mid(F_C1, F_C2), 28, 70),
    ('f_a1_sur', A1, mid(F_C2, F_E), 10, 100), ('f_a1_esquina', A1, F_C2, 10, 80), ('f_a1_alto', A1, mid(F_C2, F_E), 38, 100),
    ('f_a2_sur', A2, mid(F_C2, F_E, 0.7), 8, 70), ('f_s1_esquina', S1, mid(F_C1, F_C2), 6, 35),
]

# the two-storey house north of the Salvador, the north-west corner (Catastro 4391110VJ5649S; the house salvador_c3 of
# the map), on the map. Its pictures are the g_ ones.
G_W = (88.66, 49.82)              # where it ends on the Salvador
G_SE = (107.84, 56.33)            # its corner of the Salvador and the avenue
G_NE = (109.16, 43.81)            # where it ends on the avenue
CN3 = ('MAKn_U1qXv0tbXDqggHOaQ', 113.55, 41.13)    # on the avenue, twenty metres north
CN4 = ('m-K8uuoyF-a-3Rbm9NZInw', 113.99, 31.09)    # on the avenue, thirty metres north: the empty plot's far end
SHOTS += [
    ('g_s1_norte', S1, mid(G_W, G_SE, 0.58), 10, 110), ('g_s1_oeste', S1, mid(G_W, G_SE, 0.25), 10, 90), ('g_s1_este', S1, mid(G_W, G_SE, 0.9), 10, 90),
    ('g_s1_alto', S1, mid(G_W, G_SE, 0.58), 40, 110), ('g_s2_norte', S2, mid(G_W, G_SE, 0.15), 10, 110), ('g_s2_este', S2, mid(G_W, G_SE, 0.7), 8, 70),
    ('g_cn_esquina', CN, G_SE, 10, 80), ('g_cn_alto', CN, G_SE, 34, 80),
    ('g_cn2_oeste', CN2, mid(G_SE, G_NE), 10, 110), ('g_cn2_alto', CN2, mid(G_SE, G_NE), 38, 110), ('g_cn2_sur', CN2, mid(G_SE, G_NE, 0.15), 10, 90),
    ('g_cn3_oeste', CN3, mid(G_SE, G_NE, 0.75), 10, 100), ('g_cn3_norte', CN3, (107.0, 43.7), 10, 80), ('g_cn3_sur', CN3, G_SE, 8, 60),
    ('g_cs_lejos', CS, G_SE, 8, 45), ('g_a1_lejos', A1, G_SE, 6, 40),
    ('g_cn4_sur', CN4, (109.6, 38.0), 8, 100), ('g_cn4_oeste', CN4, (107.0, 31.5), 8, 100),
]

# the traffic lights, the mirror and the signs of the crossroads (the user, 22 November 2026: "Pasamos a semáforos"):
# all round from the cameras in it and beside it, and what a driver sees coming up each street. The x_ pictures.
def ring(tag, cam, n, pitch=6, fov=90):
    out = []
    for i in range(n):
        h = math.radians(360.0 * i / n)
        out.append(('x_%s_%03d' % (tag, round(360.0 * i / n)), cam, (cam[1] + 10.0 * math.sin(h), cam[2] - 10.0 * math.cos(h)), pitch, fov))
    return out

X_MID = (113.1, 68.0)             # the middle of the crossroads
SHOTS += ring('cs', CS, 8) + ring('cn', CN, 8) + ring('r1', R1, 4, 6, 100) + ring('t1', T1, 4, 6, 100) + ring('a1', A1, 4, 6, 100) + ring('s1', S1, 4, 6, 100)
SHOTS += [
    ('x_r2_norte', R2, (113.0, 74.1), 5, 45), ('x_a2_oeste', A2, (113.1, 68.9), 5, 45), ('x_s2_este', S2, (113.4, 60.6), 5, 45),
    ('x_cn2_sur', CN2, X_MID, 6, 70), ('x_cn3_sur', CN3, X_MID, 5, 40), ('x_t2_este', T2, (113.0, 74.1), 5, 45),
    ('x_cs_alto_n', CS, (CS[1], CS[2] - 10.0), 30, 90), ('x_cs_alto_e', CS, (CS[1] + 10.0, CS[2]), 30, 90),
    ('x_cn_alto_s', CN, (CN[1], CN[2] + 10.0), 30, 90), ('x_cn_alto_e', CN, (CN[1] + 10.0, CN[2]), 30, 90),
]

if __name__ == '__main__':
    out = sys.argv[1]
    only = set(sys.argv[2:])
    os.makedirs(out, exist_ok=True)
    path = os.path.join(out, 'views.json')
    views = json.load(open(path)) if os.path.exists(path) else {}
    for name, (pid, x, z), at, p, fov in SHOTS:
        if only and name not in only:
            continue
        h = math.degrees(math.atan2(at[0] - x, -(at[1] - z))) % 360
        f = os.path.join(out, name + '.jpg')
        if not os.path.exists(f):
            url = 'https://streetviewpixels-pa.googleapis.com/v1/thumbnail?panoid=%s&cb_client=maps_sv.tactile&w=1600&h=1000&yaw=%g&pitch=%g&thumbfov=%g' % (pid, h, -p, fov)
            try:
                open(f, 'wb').write(urllib.request.urlopen(urllib.request.Request(url, headers=panos.UA), timeout=40).read())
            except Exception as e:
                print('  could not fetch', name, e); continue
        views[name] = {'pano': pid, 'x': x, 'z': z, 'heading': round(h, 1), 'pitch': p, 'hfov': fov}
    json.dump(views, open(path, 'w'), indent=0)
    print(len(views), 'views in', out)
