"""The Street View pictures the Pizzería Toti is measured from (the pizzeria of the Calle de Ramón y Cajal, the house
cajal_3 of the map; the user, 17 November 2026: "Tu siguiente objetivo es la pizzería ... Con su terraza y todo", and "La
llamaremos Pizzeria Toti"). They are Google's: NOT kept in the repository, only this list. Writes views.json beside
them.

    python tools/toti/capturas.py OUT_FOLDER [name ...]

Google's car went up the street in November 2024, April 2021, October 2019 and March 2013 (the older ones at the same
spots as those of 2024, give or take a metre or two). Every camera round it:
python tools/molino/panos.py cerca 019M-P8TLnCz90aaTtOmOA -152 22 40
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

# the four spots up the street, south of the corner with the Calle del Salvador: [2024, 2021, 2019, 2013]
SPOTS = {
    'a': ((-153.31, 11.06), ['ah6U8IbIwTPcwbGVpfZ_RA', 'Pt1ukoaVSMV0BuI70OkLUQ', 'ndj_4_Lvnl1wJTu5w1OxOw', 'auPda3eabY1fiFDmHQaX2Q']),
    'b': ((-155.71, 21.94), ['gJTbFo3bTOOqUxYq1Lnjzw', '_liy0KoTb-f0kav1UuWHww', 'RJnDiGiJMu85wZ5bhv3bqw', 'nkK0gDMtEHM_felPnjdJ3g']),
    'c': ((-157.75, 31.86), ['AN97XgO6Ung9oe6Ir81cgQ', 'UWs_SdILJLO144fqllZqEw', 'A4hulvBkkvqn-yK5GihJ4Q', '7L2XYWU0HIlqYyFNNoUZBg']),
    'd': ((-159.11, 41.68), ['qVJdV32KKPFrjku599WkpQ', 'lIUGRsEYSyR_rdZ8zXYWGQ', 'KaPYRqgFnVkGj85hoKV7Aw', 'I69bBRG2erkUXBG37Is8Fw']),
    'e': ((-146.50, -8.60), ['x8e6rv8Jb0cS5BoNxSrFgg', None, None, 'iqx1rFpNG3f9_L0IZyM74Q']),
}
YEARS = ['24', '21', '19', '13']
FRONT = (-150.42, 22.96)          # the middle of the house's front (cajal_3: (-148.7, 14.9) + 16.48 m south)
PIZZA = (-149.6, 19.2)            # the pizzeria's middle (0.03..0.62 of the front)
TERRACE = (-153.0, 19.5)          # where a terrace in the street would be

SHOTS = []
for k, (at, ids) in SPOTS.items():
    for y, pid in zip(YEARS, ids):
        if pid is None:
            continue
        SHOTS.append(('%s%s' % (k, y), (pid, at[0], at[1]), PIZZA if k != 'e' else FRONT, 6, 90))
SHOTS += [
    ('b24_cerca', (SPOTS['b'][1][0],) + SPOTS['b'][0], PIZZA, 8, 60), ('b24_toldo', (SPOTS['b'][1][0],) + SPOTS['b'][0], (-149.0, 17.0), 18, 50),
    ('b24_arriba', (SPOTS['b'][1][0],) + SPOTS['b'][0], FRONT, 30, 90), ('b24_calle', (SPOTS['b'][1][0],) + SPOTS['b'][0], TERRACE, -10, 100),
    ('a24_sur', (SPOTS['a'][1][0],) + SPOTS['a'][0], (-152.0, 30.0), 4, 90), ('c24_norte', (SPOTS['c'][1][0],) + SPOTS['c'][0], (-150.0, 12.0), 4, 90),
    ('b24_resto', (SPOTS['b'][1][0],) + SPOTS['b'][0], (-151.6, 28.0), 6, 70),
    # the south end of the house and the next one, square on (where the grocer's yellow awning is)
    ('c24_frente', (SPOTS['c'][1][0],) + SPOTS['c'][0], (-151.9, 30.0), 8, 90), ('d24_frente', (SPOTS['d'][1][0],) + SPOTS['d'][0], (-153.0, 40.0), 8, 90),
    ('c21_frente', (SPOTS['c'][1][1],) + SPOTS['c'][0], (-151.9, 30.0), 8, 90), ('c13_frente', (SPOTS['c'][1][3],) + SPOTS['c'][0], (-151.9, 30.0), 8, 90),
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
