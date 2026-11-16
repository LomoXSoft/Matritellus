"""The Street View pictures the corner shop between the Calle de San José and the Calle de Santo Domingo ("los chinos
del Arroyuelo", the user's words) was measured from. Fetches them (they are Google's: NOT kept in the repository, only
this list) and writes views.json beside them.

    python tools/chinos/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, the point of the map it looks at, pitch (up +), horizontal field of view.
Every camera round it: python tools/molino/panos.py cerca u-oBM2ipqzDkSoTgh0sUdw -290 9 48.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

POINT = (-282.4, 9.8)       # the middle of its narrow end, where the two streets part
E = ('gvHEsB6MR7ucganC4GuM1A', -269.78, 7.80)        # in front of the point, where the streets are still one
EE = ('m8PeTuuDMsAOH1MAnzXUpg', -259.73, 9.80)
NE = ('u-oBM2ipqzDkSoTgh0sUdw', -279.90, 4.91)       # the Calle de San José (its north side), from the point westwards
NA = ('Ft2sFQuP_UnOWLveRoC7kQ', -290.12, 2.56)
NB = ('Go-bYP4P7xLQmnZVy2GQzw', -300.31, 0.61)
NO = ('Ff67cJes8o0X2cRQHdBrag', -310.07, -1.44)
SE = ('iSeVEtAKaceYCysDc8anlA', -283.90, 13.50)      # the Calle de Santo Domingo (its south side)
SA = ('3ajAuCiPz8GAMMvDR-OCOQ', -293.71, 16.16)
SB = ('yWqlTsSPAzm_uHgUbZfYOw', -303.73, 18.01)
SO = ('dxlispXs1K8UDuYuf6dgeA', -313.76, 20.10)
SHOTS = [      # November 2024
    ('e24', E, POINT, 9, 60), ('e24_alto', E, POINT, 24, 60), ('e24_zoom', E, POINT, 3, 30), ('e24_ancho', E, POINT, 12, 100), ('ee24', EE, POINT, 6, 40),
    ('ne24_punta', NE, POINT, 16, 100), ('ne24_lado', NE, (-290.0, 6.4), 12, 90), ('ne24_bajo', NE, (-284.5, 7.8), -2, 70),
    ('n24', NA, (-290.6, 6.3), 12, 110), ('n24_alto', NA, (-290.6, 6.3), 38, 100), ('n24_izq', NA, (-284.0, 7.8), 8, 75), ('n24_der', NA, (-298.0, 4.6), 8, 75),
    ('nb24', NB, (-300.0, 4.2), 12, 110), ('nb24_largo', NB, (-290.0, 6.4), 8, 70), ('no24', NO, (-300.0, 5.0), 8, 60),
    ('se24_punta', SE, POINT, 16, 100), ('se24_lado', SE, (-290.0, 12.4), 12, 90), ('se24_bajo', SE, (-283.2, 11.2), -2, 70),
    ('s24', SA, (-293.5, 12.8), 12, 110), ('s24_alto', SA, (-293.5, 12.8), 38, 100), ('s24_izq', SA, (-300.0, 14.0), 8, 75), ('s24_der', SA, (-286.0, 11.9), 8, 75),
    ('sb24', SB, (-300.5, 14.0), 12, 100), ('sb24_largo', SB, (-290.0, 12.4), 8, 70), ('so24', SO, (-300.0, 13.0), 8, 60),
    # each long side whole, from either end: both of its ends in the picture (tools/chinos/medir.py fits the camera to them)
    ('cal_n_e', NE, (-298.0, 13.4), 10, 80), ('cal_n_o', NB, (-292.8, 19.15), 10, 105), ('cal_s_o', SB, (-288.87, 4.63), 10, 75),
    ('cal_s_e1', SE, (-301.2, 3.5), 10, 100), ('cal_s_e2', SE, (-287.37, -6.2), 10, 100),
    # the same spots before: October 2019, March 2013, May 2009
    ('e19', ('Bg4UAuhCeGRG9wPBkwSCFw', -269.78, 7.80), POINT, 9, 60), ('e13', ('-Lkytof6xJQs-rz3K5Wb_g', -269.78, 7.80), POINT, 9, 60), ('e09', ('KvfhXEFNAfNQDT3xN0qWrg', -269.78, 7.80), POINT, 9, 60),
    ('n19', ('S95SjOPhmcUydKtOnnOtPg', -290.12, 2.56), (-290.6, 6.3), 12, 110), ('s09', ('4sqt8oRPNZQ7v1Vm2dJIxg', -293.71, 16.16), (-293.5, 12.8), 12, 110),
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
