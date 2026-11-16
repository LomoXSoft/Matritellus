"""The Street View pictures the corner house of the bank and the copy shop (the user's "Banco Cantabria" and "Copistería
Sancho Panza", 17 November 2026) was measured from: along the Calle del Teniente Infante and the Calle de San Francisco.
Fetches them (they are Google's: NOT kept in the repository, only this list) and writes views.json beside them.

    python tools/bancosancho/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, the point of the map it looks at, pitch (up +), horizontal field of view.
Every camera round it: python tools/molino/panos.py cerca AOkd_HSZRzCeB7BZVgfZQw -108 108 45
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

C = {   # November 2024: the Teniente Infante from the west, then the San Francisco from the north
    'a': ('lZp23MzMdr_kz25cx2xiMw', -128.90, 106.70), 'b': ('DUNVaPD1XGkjmmH-77X0Cw', -118.70, 105.60),
    'c': ('3xktbtbAIiSrAnesWldXPw', -108.57, 104.62), 'd': ('HN30PnnPMZsm9QPZ00hdwg', -98.06, 103.44),
    'e': ('Ac_DZHB5ODsgWVbSy5mLsQ', -87.33, 102.21), 'f': ('s4XHHydXVdb2R1pkVNebSQ', -77.14, 100.61),
    's1': ('a4vXgms2w_pEGW2EjBuzrQ', -88.76, 115.43), 's2': ('JLUqLAFjEiccSPpOdY_rqg', -90.14, 125.03),
    'c19': ('jaTuiKKpO3PxlzaMNJWUsw', -108.57, 104.62), 'd19': ('2uwzBI6vD5-o64J2rc_i3Q', -98.06, 103.44),
}
SHOTS = [
    ('a_lejos', C['a'], (-110.0, 110.0), 8, 70), ('b_frente', C['b'], (-118.0, 114.0), 10, 80), ('c_frente', C['c'], (-108.0, 113.0), 10, 80),
    ('d_frente', C['d'], (-98.0, 112.0), 10, 80), ('e_esquina', C['e'], (-95.0, 112.0), 10, 90), ('f_lejos', C['f'], (-100.0, 112.0), 8, 70),
    ('s1_lado', C['s1'], (-96.0, 117.0), 10, 90), ('s2_lado', C['s2'], (-95.0, 115.0), 8, 80),
    ('c_bajo', C['c'], (-108.0, 113.0), 0, 60), ('d_bajo', C['d'], (-98.0, 112.0), 0, 60), ('b_bajo', C['b'], (-118.0, 114.0), 0, 60),
    ('c19_frente', C['c19'], (-108.0, 113.0), 10, 80), ('d19_frente', C['d19'], (-98.0, 112.0), 10, 80),
    # square on to the front of the Teniente Infante (its normal is about 173 degrees), wide: the ground floor and the first
    ('a_recto', C['a'], (-128.9 + 0.12 * 8, 106.7 + 0.99 * 8), 14, 110), ('b_recto', C['b'], (-118.7 + 0.12 * 8, 105.6 + 0.99 * 8), 14, 110),
    ('c_recto', C['c'], (-108.57 + 0.12 * 8, 104.62 + 0.99 * 8), 14, 110), ('d_recto', C['d'], (-98.06 + 0.12 * 8, 103.44 + 0.99 * 8), 14, 110),
    ('e_recto', C['e'], (-95.0, 112.0), 14, 110), ('s1_recto', C['s1'], (-96.0, 115.6), 14, 110), ('s2_recto', C['s2'], (-96.0, 124.8), 14, 110),
    # the copy shop's stretch of brick (the user's picture: its three openings, the wooden door, the glass door, the window)
    ('c_ladrillo', C['c'], (-112.0, 111.0), 4, 70), ('b_ladrillo', C['b'], (-113.5, 111.0), 4, 70),
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
