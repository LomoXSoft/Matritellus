"""The Street View pictures the nursery school of the Calle del Palo ("S. José de Calasanz" in the game) was measured
from. The user's word: the pictures of May 2009 come first (the yard was more colourful then, with more to play on);
those of March 2013, with the trees bare, show the front itself. Fetches them (they are Google's: NOT kept in the
repository, only this list) and writes views.json beside them.

    python tools/calasanz/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, heading, pitch (up +), horizontal field of view. Places are Google's (tools/molino/panos.py info).
"""
import json, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

PANO = {
    # Calle del Palo, going down it from the crossroads with the Arroyuelo (the school is on the left, to the north-east)
    'A09': ('LKpi3YsNTLAs2fbm9lGJsw', -113.41, -207.55),     # May 2009
    'B09': ('Uftn-XVyvBPQ7eNUXy6h5Q', -108.83, -203.65),
    'C09': ('tvR8ip_eHAOH-bpECGEBuw', -97.92, -193.77),
    'D09': ('hJ_QY1maOiwGF5f2yTijOg', -94.40, -190.47),
    'X09': ('iNNpKCcghLbmQftOQTCPwg', -123.97, -214.29),     # at the crossroads
    'N09': ('P1CEVXt8t99y1fYDXOiBpg', -121.87, -226.11),     # Calle del Arroyuelo Alto, round the corner
    'A13': ('1z4hVlN2LUzRli9eLalu3w', -118.55, -206.61),     # March 2013: the trees bare
    'B13': ('wHhW_dTCKzho9Kj6Y9kt-w', -109.10, -198.86),
    'C13': ('eKLfiHcC0SJN6X9W-fWP6A', -100.50, -192.17),
    'D13': ('Y1RprrTOkcptAEiLfWngsw', -93.61, -186.85),
    'B24': ('mxTiJa0obKp3464g_JOw2A', -109.49, -201.28),     # November 2024
    'C24': ('Gw3wVxan3CXUKN-8Q5d_aQ', -102.01, -194.57),
}
SHOTS = [
    ('A09_ne', 'A09', 45, 6, 90), ('A09_e', 'A09', 80, 4, 90), ('A09_n', 'A09', 5, 6, 90),
    ('B09_ne', 'B09', 45, 6, 90), ('B09_e', 'B09', 90, 4, 90), ('B09_n', 'B09', 0, 6, 90),
    ('C09_ne', 'C09', 45, 6, 90), ('C09_n', 'C09', 0, 6, 90), ('C09_nw', 'C09', 320, 4, 90), ('C09_e', 'C09', 90, 4, 90),
    ('D09_n', 'D09', 0, 6, 90), ('D09_nw', 'D09', 320, 4, 75), ('D09_ne', 'D09', 45, 6, 90),
    ('X09_e', 'X09', 95, 5, 90), ('X09_ne', 'X09', 60, 6, 75), ('N09_e', 'N09', 100, 5, 90), ('N09_se', 'N09', 140, 5, 90),
    ('A13_ne', 'A13', 45, 8, 90), ('A13_e', 'A13', 85, 6, 90),
    ('B13_ne', 'B13', 45, 10, 90), ('B13_n', 'B13', 0, 8, 90), ('B13_e', 'B13', 90, 8, 90),
    ('C13_ne', 'C13', 45, 10, 90), ('C13_n', 'C13', 0, 10, 90), ('C13_nw', 'C13', 315, 8, 90),
    ('D13_n', 'D13', 0, 8, 90), ('D13_nw', 'D13', 315, 8, 90), ('D13_ne', 'D13', 45, 8, 90),
    ('B24_ne', 'B24', 45, 8, 90), ('C24_n', 'C24', 0, 8, 90),
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
