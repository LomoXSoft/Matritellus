"""The Street View pictures the hermitage of the Cristo del Prado is built from (the user, 21 November 2026: "Siguiente
proyecto la Ermita del Cristo del Prado (junto a la residencia, en la misma manzana)"). They are Google's: NOT kept in
the repository, only this list. Writes views.json beside them.

    python tools/cristoprado/capturas.py OUT_FOLDER [name ...]

Google's car went round it in November 2024, April 2021, October 2019, March 2013 and May 2009 (the square before its main
front only in 2013, from the street to the north-west). Every camera:
python tools/molino/panos.py cerca dnrAgAc_jet-TXZgpUcydg 318 505 45
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

C = {'s1': ('dnrAgAc_jet-TXZgpUcydg', 311.44, 525.03), 's1_09': ('5TfE1cmLF4LFf7euGRh3mg', 311.44, 525.03), 's1_19': ('A2Ghh6rXS1OR8PkAN_Wo_g', 311.44, 525.03),
     's2': ('8rsKtMbDWaX0ColhfBuYrg', 320.03, 528.90), 's2_13': ('tJdoqT5JD0xjZhg_wYjbpA', 320.03, 528.90),
     's3': ('0VcrKaToAOZI2CTz3pUxOw', 328.25, 532.95), 's4': ('H8trUMQZZCwoiRsxDUl32w', 293.01, 516.80), 's5': ('o0B4cB2MjpDy2E5jUWUy5g', 302.24, 520.90),
     'e1': ('5pQ62GihKL9-mm3bpRG1BQ', 340.98, 506.86), 'e2': ('L2KqhU6ee9kGjAvxkPatGQ', 344.05, 516.44), 'e3': ('nudJWr_JJKWKsfScznC2fQ', 338.33, 496.64),
     'e4': ('KiEP0wmXn1VWFet62qZLWA', 335.65, 486.78), 'w1': ('s2MSczvzfrgUAeDjdfur3Q', 283.76, 512.81), 'w2': ('rPqWgh_PR3rcQqPixKmOCw', 274.41, 508.95),
     'f1': ('Vx1Z_b-a_VOy_f1PqQIrTQ', 341.66, 538.56), 'f2': ('4wRRZrsGwnVyluep9tj-3A', 335.00, 543.37),
     'p1': ('FhyIVFZOkbslh0znRv4yFA', 277.01, 494.11), 'p2': ('X3JgsFznit14x6ju4yl9ig', 285.54, 478.98), 'p3': ('9hBJj2p2fa3EZW-ZzFth4g', 288.82, 472.25)}
AT = (318.0, 506.0)                              # (the middle of the hermitage, on the map)
FRONT = (301.3, 499.1)                           # (the middle of its main front, to the west, on the square)

SHOTS = []
for k, c in C.items():
    SHOTS.append((k, c, AT, 12, 90))
for k in ('s1', 's2', 's3', 'e1', 'e2', 'f1'):
    SHOTS.append((k + '_up', C[k], AT, 32, 80))
for k in ('p1', 'p2', 'p3', 'w1', 'w2', 's4', 's5'):           # (the main front, on the square to the west)
    SHOTS.append((k + '_f', C[k], FRONT, 14, 75))

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
