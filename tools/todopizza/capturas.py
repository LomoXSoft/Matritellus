"""The Street View pictures the pizza house beside the supermarket ("Todopizza" in the game) was measured from. Fetches
them (they are Google's: NOT kept in the repository, only this list) and writes views.json beside them.

    python tools/todopizza/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, pitch (up +), horizontal field of view, and how far off the house's
middle it looks (degrees, to the right +). The heading is worked out: towards the middle of the house, map (911.5, 294.5).
All of November 2024 but the last two (March 2013, May 2009). Every camera round it: python tools/molino/panos.py cerca
0kuTvD40S4ObcE2J8Y1McQ 912 294 45.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

MID = (911.5, 294.5)
SHOTS = [
    ('o1', 'egdhvhxrx6kPjfpnCrJULg', 887.80, 294.10, 8, 75, 0), ('o1_zoom', 'egdhvhxrx6kPjfpnCrJULg', 887.80, 294.10, 6, 40, 0), ('o0', 'fvSxWi44J1YvnYYpZe697w', 885.15, 273.81, 6, 60, 0),
    ('o2', 'SYIF_iam5lnx5xn0c5J5mw', 886.04, 303.90, 8, 70, 0), ('n0', 'uwo5HGgW-m1YxdNOkvkP8w', 903.79, 264.99, 6, 60, 0), ('n1', 'f9MMn3i5t_PfTpguPQ5jGQ', 913.65, 266.08, 6, 60, 0),
    ('n1_zoom', 'f9MMn3i5t_PfTpguPQ5jGQ', 913.65, 266.08, 5, 34, 0), ('n2', 'kJ8t-cs9EgZju8ZDC5EX3w', 922.65, 270.26, 6, 60, 0), ('e0', 'GC7ssFBT0OHiQgqdle5ECw', 937.01, 282.26, 6, 60, 0),
    ('e1', 'FIHwnAykFeXrXjp-jsTnVQ', 935.90, 295.87, 8, 70, 0), ('e1_zoom', 'FIHwnAykFeXrXjp-jsTnVQ', 935.90, 295.87, 6, 40, 0), ('cartel', 'f9MMn3i5t_PfTpguPQ5jGQ', 913.65, 266.08, 10, 40, -38),
    ('o1_2013', 'YR5Aep9i5M0YJ26qHYMI', 887.80, 294.10, 8, 75, 0), ('o1_2009', '4ySsdZUgfogEG5SIWA2gzA', 887.80, 294.10, 8, 75, 0),
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
