"""The Street View pictures the Noche (the user's name for the Dia of the Calle del Teniente Infante, 17 November 2026)
was measured from: all from that street, before it. Fetches them (they are Google's: NOT kept in the repository, only
this list) and writes views.json beside them.

    python tools/noche/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, the point of the map it looks at, pitch (up +), horizontal field of view.
Every camera along it: python tools/molino/panos.py cerca hOlBlXoqRGJcy5CXm_aN3A -14 96 35
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

C = {   # November 2024, along the street from the west
    'a': ('NgAzi0v7HUt_MAQ0YBsBSQ', -44.52, 95.75), 'b': ('Fg04feoxAVScdrVL5uGyJg', -34.57, 94.13),
    'c': ('AOkd_HSZRzCeB7BZVgfZQw', -24.62, 92.71), 'd': ('hOlBlXoqRGJcy5CXm_aN3A', -14.40, 91.27),
    'e': ('7i3goaZGmUp_Wcv0qOPdgA', -3.75, 89.94), 'f': ('1abUf44Pb38w1IAe-z3wtg', 7.31, 88.59),
    # the same spot in front, older
    'd19': ('wfTpqebO-QASsVGKMWR_kw', -14.40, 91.27), 'd13': ('uAwS8YoZF9aKfZrLOfPclw', -14.40, 91.27),
}
SHOTS = [
    ('d_frente', C['d'], (-14.4, 102.0), 12, 80), ('d_bajo', C['d'], (-14.4, 102.0), -2, 60), ('d_puerta', C['d'], (-12.5, 101.0), 0, 30),
    ('d_rotulo', C['d'], (-12.5, 101.0), 14, 30), ('d_balcones', C['d'], (-14.4, 102.0), 30, 60), ('d_arco', C['d'], (-16.8, 101.0), 0, 30),
    ('c_frente', C['c'], (-14.0, 101.0), 10, 80), ('e_frente', C['e'], (-14.0, 101.0), 10, 80),
    ('b_lejos', C['b'], (-14.0, 101.0), 8, 60), ('f_lejos', C['f'], (-14.0, 101.0), 8, 60),
    ('c_lado', C['c'], (-18.0, 103.0), 4, 60), ('e_lado', C['e'], (-10.5, 102.0), 4, 60),
    ('d19_frente', C['d19'], (-14.4, 102.0), 12, 80), ('d13_frente', C['d13'], (-14.4, 102.0), 12, 80),
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
