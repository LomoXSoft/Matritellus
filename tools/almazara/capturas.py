"""The Street View pictures the almazara "González de la Ruz" (the user's name, 21 November 2026, for Aceites García de
la Cruz) is measured from, along its two streets: the road to Villacañas (Catastro's Calle Reyes Católicos: its front,
the way in, the long wall and the tall nave) and the Calle del Triunfo (its back). They are Google's: NOT kept in the
repository, only this list. Writes views.json beside them.

    python tools/almazara/capturas.py OUT_FOLDER [name ...]

Each shot: name, camera, heading (compass), pitch (up +), horizontal field of view. Every camera round the place:
tools/molino/panos.py cerca gBqVpv-1hKNIh8TxYJ7Ofg 290 -575 110. Where each stood is Google's word for it.
"""
import json, os, sys, urllib.request

UA = {'User-Agent': 'Mozilla/5.0 (map-tool)'}
C = {   # November 2024
    # the road to Villacañas, south-west to north-east (the car's heading 228: it came down it)
    'c03': ('9xMnPJwE84KtxHhHAYTg_Q', 259.94, -499.57), 'c04': ('ec4ZFf7tLhTqonfr9xURlA', 265.11, -508.24),
    'c05': ('gBqVpv-1hKNIh8TxYJ7Ofg', 271.48, -515.64), 'c06': ('s9yfCdoXWwap52JWb9httg', 278.30, -522.74),
    'c07': ('zyi9sDPoDmWPYTJQfGKFjA', 285.53, -529.38), 'c08': ('SDYLEyOB85eMzq1ZUNcCkg', 292.59, -536.29),
    'c09': ('pSiCZ30qy9GJTU2fwLdZ2w', 300.18, -542.55), 'c10': ('2Am06WZ12-kI3i8VUB5qTw', 307.73, -549.13),
    'c11': ('h35FvUZ3ZatCUvOCpqNGgg', 315.29, -555.95), 'c12': ('vcr4m_LqB-RAdZDl6EBORA', 322.75, -562.86),
    'c13': ('UUwaRest3rQeN5PzjYI6pg', 330.16, -569.74), 'c14': ('aHE9BXKWqmZmMTPZGkFiSQ', 337.73, -576.55),
    'c15': ('2YxgNrKYt1qB037Gmb6Wew', 345.19, -583.17), 'c16': ('5keA9CL3THksRcauIrkQ9w', 352.55, -589.71),
    'c17': ('WTI2elPLZU_oEBze3DvR8A', 360.02, -596.19), 'c18': ('C35_V2vv-Bk_yEJxLxVLjA', 367.63, -602.83),
    'c19': ('ZwePo3A92jL_DHKMLFJp4g', 375.21, -609.51), 'c20': ('r1iGaIp6erJXwKoxrORlkw', 382.78, -616.28),
    'c21': ('--x2DPr-eMCAZo6zjIgT_A', 390.24, -623.41), 'c22': ('UMlMTt1fz5qSxUBzZSVyYw', 397.87, -630.00),
    'c23': ('KvZ6-JTz1uX2qgIfOKRJiA', 405.37, -636.81), 'c24': ('frzRyAqHZ6_bROlKLv2HVg', 412.75, -643.49),
    'c25': ('wRrT8vjIbhEmsdDOuJh-3g', 420.07, -650.10),
    # the Calle del Triunfo, south-west to north-east
    't00': ('ah1vckL0xO9WHDsFtMJ0CA', 208.22, -536.61), 't01': ('XYSI16EJgeLjsMiR4H6y1g', 214.44, -544.89),
    't02': ('h-0qjIv8kT2DA-5o31jzxg', 220.58, -552.94), 't03': ('PJZRC_Vo92LXvrithbt-5g', 226.68, -561.33),
    't04': ('vhYApdhXOqDkIUnm41m2JA', 232.80, -569.80), 't05': ('9ie04-DWaG_PtD2JYnq3MQ', 238.87, -578.17),
    't06': ('TWaYYc3-Xe-Hq6hovAVA1g', 243.96, -588.11), 't07': ('wdkfXjcqh6oNPaBy5kzW8Q', 249.65, -596.36),
    't08': ('8meDRAooiNWHkVEF26Y4Qg', 255.42, -604.80), 't09': ('EDRYU8nOe_SjDXJRF11Ckw', 261.18, -613.38),
    't10': ('SGFrOyyOwLhPdAsDHV1LTQ', 266.16, -622.40), 't11': ('xnydtAxwM2NKdJp_-s-dZQ', 270.82, -631.82),
    't12': ('bpQX8ldpenP7fFwfe52Iyg', 278.68, -640.69),
}
ROAD, BACK = 317.5, 126.5      # looking square on to the front from the road, and to the back from the Triunfo
SHOTS = [(n, n, ROAD, 12, 110) for n in sorted(C) if n[0] == 'c']
SHOTS += [(n, n, BACK if n < 't09' else 113.5, 22, 120) for n in sorted(C) if n[0] == 't']
SHOTS += [
    # the tall nave to its top, and the mural
    ('c16_alto', 'c16', ROAD, 32, 100), ('c18_alto', 'c18', ROAD, 32, 100), ('c20_alto', 'c20', ROAD, 32, 100), ('c22_alto', 'c22', ROAD, 32, 100),
    ('c06_mural', 'c06', 310, 14, 90), ('c05_esquina', 'c05', 300, 14, 90),
    # into the yard through the way in
    ('c07_patio', 'c07', 300, 6, 90), ('c08_patio', 'c08', 285, 6, 90), ('c08_patio2', 'c08', 320, 6, 80), ('c07_fondo', 'c07', 330, 5, 50),
    ('c08_tienda', 'c08', 270, 5, 50), ('c09_patio', 'c09', 265, 5, 70),
    # along the road, both ways
    ('c04_largo', 'c04', 20, 8, 90), ('c12_largo_sw', 'c12', 250, 8, 90), ('c12_largo_ne', 'c12', 20, 12, 90), ('c25_largo', 'c25', 255, 12, 90),
    ('c23_fin', 'c23', ROAD, 20, 110), ('c24_fin', 'c24', 300, 15, 100),
    # the Triunfo: its ends, and along it
    ('t00_largo', 't00', 60, 12, 90), ('t12_largo', 't12', 215, 12, 90), ('t12_puerta', 't12', 150, 10, 100), ('t01_esquina', 't01', 100, 15, 100),
    ('t02_alto', 't02', BACK, 40, 110), ('t05_alto', 't05', BACK, 40, 110), ('t08_alto', 't08', BACK, 40, 110),
]


def foto(pid, path, heading, pitch, fov):
    url = 'https://streetviewpixels-pa.googleapis.com/v1/thumbnail?panoid=%s&cb_client=maps_sv.tactile&w=1600&h=1000&yaw=%g&pitch=%g&thumbfov=%g' % (pid, heading % 360, -pitch, fov)
    open(path, 'wb').write(urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40).read())


if __name__ == '__main__':
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    want = set(sys.argv[2:])
    views = {}
    for name, cam, heading, pitch, fov in SHOTS:
        pid, x, z = C[cam]
        views[name] = {'id': pid, 'x': x, 'z': z, 'heading': heading, 'pitch': pitch, 'hfov': fov}
        path = os.path.join(out, name + '.jpg')
        if (want and name not in want) or (not want and os.path.exists(path)):
            continue
        foto(pid, path, heading, pitch, fov)
        print(name)
    json.dump(views, open(os.path.join(out, 'views.json'), 'w'), indent=1)
