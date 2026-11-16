"""The Street View pictures the kebab house of the Calle de Santa Ana ("Tele Dürum" in the game) was measured from.
Fetches them (they are Google's: NOT kept in the repository, only this list) and writes views.json beside them.

    python tools/teledurum/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, pitch (up +), horizontal field of view, and how far off the middle of
the house's front it looks (degrees, to the right +). The heading is worked out: towards map (361.5, 133.0).
Every camera before it: python tools/molino/panos.py cerca 3a7t9FkO19DA-Qbf5sZTpg 361.5 130 24.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

MID = (361.5, 133.0)
SHOTS = [      # November 2024, then October 2019 and March 2013 from the same spots (the street is narrow: the camera is 4 m from the front)
    ('f24', '3a7t9FkO19DA-Qbf5sZTpg', 363.57, 129.73, 10, 110, 0), ('f24_alto', '3a7t9FkO19DA-Qbf5sZTpg', 363.57, 129.73, 36, 100, 0),
    ('f24_izq', '3a7t9FkO19DA-Qbf5sZTpg', 363.57, 129.73, 4, 60, -28), ('f24_der', '3a7t9FkO19DA-Qbf5sZTpg', 363.57, 129.73, 4, 60, 30),
    ('o24', '3HSMCqeAv26ecx-58_9NYw', 353.75, 127.52, 8, 75, 0), ('o24_zoom', '3HSMCqeAv26ecx-58_9NYw', 353.75, 127.52, 3, 40, 0),
    ('e24', 'Q6si6qVmhth4gj6JcMfDiA', 373.33, 131.85, 8, 75, 0), ('e24_zoom', 'Q6si6qVmhth4gj6JcMfDiA', 373.33, 131.85, 3, 40, 0),
    ('oo24', 'ex6iOsd_PJLqN1y6a2ADFw', 343.87, 125.16, 6, 50, 0), ('ee24', 'HSfmkdTRwgtZPUSglNA3Vg', 382.90, 134.26, 6, 50, 0),
    ('f19', 'jhLzr68QQCgOjQC3-pr3BA', 363.57, 129.73, 10, 110, 0), ('o19', 'jnM2BHI88jdvgiYhJZ0tig', 353.75, 127.52, 8, 75, 0), ('f13', 'Wla7xyKPWk5aia6OjHDIdg', 363.57, 129.73, 10, 110, 0),
]

if __name__ == '__main__':
    out = sys.argv[1]
    only = set(sys.argv[2:])
    os.makedirs(out, exist_ok=True)
    path = os.path.join(out, 'views.json')
    views = json.load(open(path)) if os.path.exists(path) else {}
    for name, pid, x, z, p, fov, off in SHOTS:
        if only and name not in only:
            continue
        h = (math.degrees(math.atan2(MID[0] - x, -(MID[1] - z))) + off) % 360
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
