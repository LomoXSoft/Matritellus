"""The Street View pictures the house on the corner of the Calle del Salvador and the Calle de Ramón y Cajal is
measured from ("Salvador 2", the user, 17 November 2026: "La casa pegada a toti con dos entradas que hace esquina en
la calle"; the house cajal_1 of the map, beside the Pizzería Toti). They are Google's: NOT kept in the repository,
only this list. Writes views.json beside them.

    python tools/salvador2/capturas.py OUT_FOLDER [name ...]

Google's car came down the Calle de Ramón y Cajal and through the crossroads in November 2024 (and 2021, 2019, 2013,
2009 at the same spots); along the Calle del Salvador east of the crossroads only in March 2013. Every camera round
it: python tools/molino/panos.py cerca bfGNFXwKazkvNtZbGmvLPQ -138 3 22
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

CORNER = (-146.9, 6.7)            # the corner's cut
CAJAL = (-148.1, 11.8)            # the middle of its front on Ramón y Cajal
SALVADOR = (-140.8, 6.3)          # the middle of its front on the Salvador
E = (-146.50, -8.60)              # north of the crossroads
J = (-156.46, 2.48)               # west of it, on the Calle de la Plaza
A = (-153.31, 11.06)              # on Ramón y Cajal, before the pizzeria
M = (-143.72, 1.47)               # on the Salvador, before the house (2013)
P = (-132.60, 1.47)               # on the Salvador, further east (2013)

SHOTS = [
    ('e24', ('x8e6rv8Jb0cS5BoNxSrFgg',) + E, CORNER, 10, 90), ('e24_sal', ('x8e6rv8Jb0cS5BoNxSrFgg',) + E, SALVADOR, 6, 80),
    ('e09', ('iqx1rFpNG3f9_L0IZyM74Q',) + E, CORNER, 10, 90),
    ('j24', ('bfGNFXwKazkvNtZbGmvLPQ',) + J, CORNER, 8, 90), ('j24_sal', ('bfGNFXwKazkvNtZbGmvLPQ',) + J, SALVADOR, 4, 60),
    ('j24_caj', ('bfGNFXwKazkvNtZbGmvLPQ',) + J, CAJAL, 8, 80), ('j24_arriba', ('bfGNFXwKazkvNtZbGmvLPQ',) + J, CORNER, 32, 90),
    ('j21', ('qX4K5rplmung_idLA0pnhg',) + J, CORNER, 8, 90), ('j19', ('eSeWsCMq6nkA1ekTsuqxlg',) + J, CORNER, 8, 90),
    ('j13', ('gl_9VtE-B2u9_TUU0W6xVg',) + J, CORNER, 8, 90),
    ('a24', ('ah6U8IbIwTPcwbGVpfZ_RA',) + A, CAJAL, 8, 90), ('a24_esq', ('ah6U8IbIwTPcwbGVpfZ_RA',) + A, CORNER, 10, 90),
    ('a24_arriba', ('ah6U8IbIwTPcwbGVpfZ_RA',) + A, CAJAL, 34, 90),
    ('a21', ('Pt1ukoaVSMV0BuI70OkLUQ',) + A, CAJAL, 8, 90), ('a19', ('ndj_4_Lvnl1wJTu5w1OxOw',) + A, CAJAL, 8, 90),
    ('a13', ('auPda3eabY1fiFDmHQaX2Q',) + A, CAJAL, 8, 90),
    ('m13', ('m9FWBYzuE1qea5w18xtxAw',) + M, (-143.0, 6.5), 8, 90), ('m13_w', ('m9FWBYzuE1qea5w18xtxAw',) + M, CORNER, 6, 90),
    ('m13_e', ('m9FWBYzuE1qea5w18xtxAw',) + M, (-138.0, 6.3), 6, 90), ('m13_arriba', ('m9FWBYzuE1qea5w18xtxAw',) + M, (-142.0, 6.5), 34, 90),
    ('p13', ('ps58Yzy0x1CiJTkF1WoJuA',) + P, (-140.0, 6.5), 4, 90),
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
