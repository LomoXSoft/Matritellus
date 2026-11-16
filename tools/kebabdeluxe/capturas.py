"""The Street View pictures Kebab Deluxe (the user's name for the kebab house of the Avenida de Castilla-La Mancha;
"La Meseta" before it) was measured from. Fetches them (they are Google's: NOT kept in the repository, only this
list) and writes views.json beside them.

    python tools/kebabdeluxe/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, the point of the map it looks at, pitch (up +), horizontal field of view.
Every camera round it: python tools/molino/panos.py cerca 1oy_DoBxzLMvQVbRqUUHkQ 56 168 30.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

MID = (56.06, 168.62)       # the middle of its front, on the map (Catastro)
UP = (55.3, 169.3)          # a little to its left, higher: its upper floor
A = ('jY7RmSPa4PVrnlIZbcPyEQ', 41.74, 153.59)      # the avenue, from the north-west (November 2024)
B = ('g-g3Ffsq6LZ7mGqrjv077Q', 47.81, 161.35)
C = ('1oy_DoBxzLMvQVbRqUUHkQ', 54.39, 168.64)      # right in front
D = ('kLcTHpWQ-iiQjQJMUWv7BQ', 60.38, 177.10)
E = ('XGuMP0AKS2BafFLTJ2rNPw', 70.66, 188.30)
SHOTS = [
    ('a', A, MID, 6, 40), ('b', B, MID, 10, 60), ('b_ancho', B, MID, 14, 90),
    ('c', C, MID, 20, 110), ('c_alto', C, MID, 40, 110), ('c_bajo', C, MID, 0, 100),
    ('d', D, MID, 12, 70), ('d_ancho', D, MID, 16, 100), ('e', E, MID, 6, 40),
    # the same spots before: October 2019, March 2013 (La Meseta)
    ('b19', ('ds3Ha7MN8EZTkp0I7VRNBQ', 47.81, 161.35), MID, 10, 60), ('c19', ('haA61Pdoh3ieRU9I8ch2gQ', 54.39, 168.64), MID, 20, 110),
    ('d19', ('lTFETi2Fo34H1J4MdSA9CQ', 60.38, 177.10), MID, 12, 70), ('b13', ('jzGyOB3RxYLrN4395u-spA', 47.81, 161.35), MID, 10, 60),
    ('d13', ('6DzKnDnjOleOoXyvINfeDQ', 60.38, 177.10), MID, 12, 70),
]
SPHERE = ''

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
    for yaw in (range(0, 360, 45) if SPHERE else ()):                   # the private 360 picture, all round
        f = os.path.join(out, 'esfera_%03d.jpg' % yaw)
        if (not only or 'esfera' in only) and not os.path.exists(f):
            try:
                open(f, 'wb').write(urllib.request.urlopen(urllib.request.Request('%s=w1024-h640-k-no-pi-5-ya%d-ro0-fo80' % (SPHERE, yaw), headers=panos.UA), timeout=40).read())
            except Exception as e:
                print('  could not fetch the sphere at', yaw, e)
    json.dump(views, open(path, 'w'), indent=0)
    print(len(views), 'views in', out)
