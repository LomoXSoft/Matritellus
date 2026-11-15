"""The Street View pictures the old bullring was measured from: before its restoration (May 2009), just after (March
2013) and now (November 2024). Fetches them (they are Google's: NOT kept in the repository, only this list) and writes
views.json beside them.

    python tools/toros/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, heading, pitch (up +), horizontal field of view. Places are Google's (tools/molino/panos.py info).
"""
import json, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

PANO = {
    # Calle Vista Alegre, south of the square in front of the ring
    'S09': ('JulqMviwA2wMutv6yqIQsQ', 480.75, 612.43),     # May 2009: before
    'S13': ('0B69vWCKq1SIV8AU1QSttw', 478.35, 611.49),     # March 2013: the works just over
    'S':   ('81fruKYED6R-etf1CQDAbg', 478.35, 611.49),     # November 2024
    'SE09': ('QLQK8jinaB4rdVZoDNGArg', 487.88, 617.27),
    'SW09': ('DVtWuXbulNZOXuoc04ZFMQ', 466.35, 605.41),
    'SO09': ('KDrZJ3EcFL6TFtd1ZwXujA', 458.95, 615.15),
    'E09': ('oc6i15MGfdDFdTV-xPSPkw', 506.18, 599.71),
    'SW':  ('I7TY2nkPxEGAgBv9jZRDCg', 460.86, 597.16),
    'SW13': ('jOfPgSdNxa74yreqpCJ_zQ', 463.08, 600.85),
    'SE':  ('v6v_EllsB9HYjltTQrsC_w', 505.33, 593.39),
    # Calle de la Prensa, to the west
    'W1':  ('XzIagNaaAb8Zez8IEwX46g', 436.42, 555.90),
    'W13': ('ma5br10eX6a-0rC0y7JVKg', 435.23, 558.01),
    'W2':  ('CepbYd6Qef6n6f1SBm6uuw', 439.98, 546.48),
    'W3':  ('SnMY-K1UjUptKrYw7lfUGA', 446.72, 526.84),
    'W0':  ('X_xF8STpdOEVanfKeDI34A', 435.77, 580.78),
    # Calle de San Agustín, to the east
    'E1':  ('XRqLZGl2FWeV-xLLgv5CDw', 519.56, 555.62),
    'E13': ('bqWOUVZobZlxftSCNmurTQ', 522.47, 556.15),
    'E2':  ('5X5sheVaviILq9qVNfLDeA', 513.16, 574.74),
    'E3':  ('nnXn0kCtn6pwzS34fum5yQ', 525.77, 536.38),
}
SHOTS = [
    ('S09_n', 'S09', 355, 6, 60), ('S09_nw', 'S09', 320, 5, 90), ('S09_ne', 'S09', 30, 5, 90),
    ('SE09_n', 'SE09', 345, 6, 75), ('SW09_n', 'SW09', 10, 6, 75), ('SO09_ne', 'SO09', 20, 6, 75), ('E09_nw', 'E09', 320, 6, 75),
    ('S13_n', 'S13', 355, 6, 60), ('SW13_n', 'SW13', 15, 8, 75), ('W13_e', 'W13', 80, 10, 90), ('E13_w', 'E13', 265, 10, 90),
    ('S_n', 'S', 355, 6, 60), ('S_nw', 'S', 320, 5, 90), ('S_ne', 'S', 30, 5, 90),
    ('SW_n', 'SW', 15, 8, 75), ('SE_nw', 'SE', 325, 8, 75),
    ('W1_e', 'W1', 80, 10, 90), ('W2_e', 'W2', 95, 12, 90), ('W3_se', 'W3', 125, 10, 90), ('W0_ne', 'W0', 50, 8, 75),
    ('E1_w', 'E1', 265, 10, 90), ('E2_nw', 'E2', 300, 10, 90), ('E3_sw', 'E3', 245, 10, 90),
]

if __name__ == '__main__':
    out = sys.argv[1]
    only = set(sys.argv[2:])
    os.makedirs(out, exist_ok=True)
    path = os.path.join(out, 'views.json')
    views = json.load(open(path)) if os.path.exists(path) else {}
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
