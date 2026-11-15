"""The Street View pictures the mill was measured from: which panorama, which way, how wide. Fetches them (they are
Google's: they are NOT kept in the repository, only this list) and writes views.json beside them, with each picture's
camera as tools/molino/foto.py wants it.

    python tools/molino/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, heading, pitch (up +), horizontal field of view. The panoramas' places are Google's, from
`panos.py info`; PLACE holds the ones that were fixed against the aerial photograph since.
"""
import json, os, sys
import panos

# panorama -> (x, z) on the game's map, and the height of its camera over the square's own floor when known
PANO = {
    'O':  ('wZH_1TM6TyH0MNJDa5lzHQ', -293.88, -725.94),   # in the street, right in front of the mill (2024-11)
    'O13': ('Czy1ZiINtgQlbyjNG1CCZg', -293.09, -729.87),  # the same spot in 2013
    'O09': ('xYWGTvpBl-GPRGiIs_AQnQ', -294.39, -726.47),  # ...and in 2009
    'S1': ('ccy-tkwsfSLNxQg3nyWAtA', -296.02, -716.20),   # down the street (south), 10 m apart
    'S2': ('-N5y7yIRQzk1X88eQZ9-Vg', -298.80, -706.58),
    'S3': ('oNnn3GmU6t2zdDhQr74a_A', -301.46, -696.95),
    'S4': ('lIimX_OQPEijwEKo6VpTuA', -303.17, -687.09),
    'S6': ('pcTw3-LOadcXDMETsP4B7Q', -305.71, -667.00),
    'N1': ('KxdSxHIYF5ZMThEAYvvW_w', -292.34, -735.90),   # up the street (north)
    'N2': ('ASZ_65UgDIGG12FpcQr0dw', -290.79, -745.98),
    'N3': ('dGKn5I1TAImDi_1UqzaXYA', -289.33, -756.03),
    'N4': ('eUqFV6EdZ2EWC4US5kuvoQ', -287.94, -766.02),
    'N6': ('09FuQ5zx_SAv7vxFG2sZ8g', -283.30, -784.71),
    'W1': ('XJkMbMM-A7nWSHNnEaoe-w', -330.08, -743.44),   # the track to the west
    'W2': ('zIpvexo1mMf8yMZa-ZkrtA', -328.70, -753.38),
    'W4': ('1MWH1vjcr-Mhfh-hydF8LA', -321.40, -771.32),
    'E1': ('Y0F17ri2-CDobuO-9ND4uQ', -225.42, -707.80),   # the track to the east, across the field
    'E2': ('jYS3-an9GucJrElmz_34MQ', -222.68, -718.20),
    'E3': ('sUVcAC3TsEAqwxbl6mIiWQ', -219.99, -727.85),
    'E4': ('smGct0rngmLNOjC_iQIs4g', -216.06, -740.95),
    'E5': ('qyJh3XAlg1Z9n5aMhPMu8A', -214.26, -750.72),
    'NN': ('SkRwiDpojZUnvD9PTbVIOw', -274.28, -816.47),   # the track to the north
}
SHOTS = [
    # the mill over its wall, from the street
    ('O_e', 'O', 90, 18, 90), ('O_ne', 'O', 45, 10, 90), ('O_se', 'O', 135, 10, 90), ('O_molino', 'O', 82, 28, 50),
    ('O13_e', 'O13', 90, 18, 90), ('O09_e', 'O09', 90, 18, 90),
    ('S1_ne', 'S1', 50, 15, 90), ('S1_e', 'S1', 95, 8, 90), ('S1_se', 'S1', 140, 8, 90),
    ('S2_ne', 'S2', 40, 12, 90), ('S2_e', 'S2', 90, 8, 90), ('S2_se', 'S2', 135, 8, 90),
    ('S3_ne', 'S3', 35, 12, 90), ('S3_e', 'S3', 85, 8, 90),
    ('S4_ne', 'S4', 30, 10, 75), ('S6_n', 'S6', 22, 8, 50),
    ('N1_e', 'N1', 90, 12, 90), ('N1_se', 'N1', 135, 15, 90), ('N1_ne', 'N1', 45, 8, 90),
    ('N2_e', 'N2', 90, 8, 90), ('N2_se', 'N2', 140, 14, 90), ('N2_ne', 'N2', 45, 8, 90),
    ('N3_se', 'N3', 150, 12, 90), ('N3_e', 'N3', 95, 8, 90), ('N4_s', 'N4', 165, 10, 75), ('N6_s', 'N6', 172, 6, 40),
    # from far off: the whole of it
    ('W1_molino', 'W1', 105, 8, 40), ('W2_molino', 'W2', 115, 8, 40), ('W4_molino', 'W4', 135, 7, 35),
    ('E1_molino', 'E1', 248, 6, 40), ('E2_molino', 'E2', 259, 6, 40), ('E3_molino', 'E3', 269, 6, 40), ('E4_molino', 'E4', 281, 6, 40), ('E5_molino', 'E5', 289, 6, 40),
    ('E3_ancho', 'E3', 269, 6, 90), ('NN_s', 'NN', 182, 5, 35),
]

if __name__ == '__main__':
    out = sys.argv[1]
    only = set(sys.argv[2:])
    os.makedirs(out, exist_ok=True)
    views = {}
    path = os.path.join(out, 'views.json')
    if os.path.exists(path):
        views = json.load(open(path))
    import urllib.request
    for name, key, h, p, fov in SHOTS:
        if only and name not in only:
            continue
        pid, x, z = PANO[key]
        f = os.path.join(out, name + '.jpg')
        if not os.path.exists(f):
            url = 'https://streetviewpixels-pa.googleapis.com/v1/thumbnail?panoid=%s&cb_client=maps_sv.tactile&w=1600&h=1000&yaw=%g&pitch=%g&thumbfov=%g' % (pid, h % 360, -p, fov)
            open(f, 'wb').write(urllib.request.urlopen(urllib.request.Request(url, headers=panos.UA), timeout=40).read())
        views[name] = {'pano': key, 'x': x, 'z': z, 'heading': h, 'pitch': p, 'hfov': fov}
    json.dump(views, open(path, 'w'), indent=0)
    print(len(views), 'views in', out)
