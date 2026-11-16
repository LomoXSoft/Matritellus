"""The Street View pictures the roundabout of the Tricornios (the user, 17 November 2026: the one before their barracks,
where the Avenida de la Constitución, the Avenida de Martín Descalzo, the Calle del Santo and the Calle de Víctor
Pradera meet; its giant flag and the monolith to the Tricornios) was measured from. Fetches them (they are Google's:
NOT kept in the repository, only this list) and writes views.json beside them.

    python tools/rotonda/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, the point of the map it looks at, pitch (up +), horizontal field of view.
Every camera round it: python tools/molino/panos.py cerca IuhvN2zroz7Q7PoCVTUD9A 25.5 -566 28.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

MID = (25.3, -566.0)        # the middle of the island (the orthophoto)
CAMS = {                    # November 2024, round the ring
    'n': ('vM2OScsxTIj4__BXc4djww', 22.33, -585.76), 'ne': ('FulCTR8gaTyM9vYx76PzJw', 33.86, -581.09),
    'nn': ('fejKJS6Oa8VoBbjeB3Z2QQ', 18.37, -573.66), 'nne': ('2LaFPD6KouxGcvBlcBeusg', 28.39, -574.86),
    'e': ('Td3uRVyOVpaTCxYT8HRE3A', 34.14, -567.18), 'se': ('3UxAajot0yU6ObBN2F5Lxg', 29.69, -558.54),
    's': ('fMoZOBnHcZphj-KV3sRyoQ', 19.99, -557.79), 'sw': ('JwPybn0cXEw4RdnGGUcZ-w', 15.02, -559.94),
    'w': ('leylh5p9d7SupUWNtTMCbg', 8.81, -570.26), 'ww': ('8vgC6_SM8Z02-AlQPosXBw', -0.15, -565.64),
    'ss': ('bvSzKa_jtZxpYLbeWU0-JA', 33.08, -548.19),
}
SHOTS = []
for k, cam in CAMS.items():
    near = math.hypot(cam[1] - MID[0], cam[2] - MID[1]) < 14
    SHOTS.append((k, cam, MID, 8 if near else 4, 100 if near else 60))
    SHOTS.append((k + '_alto', cam, MID, 40 if near else 22, 100 if near else 70))
SHOTS += [('e_cerca', CAMS['e'], MID, 0, 40), ('s_cerca', CAMS['s'], MID, 0, 40), ('w_cerca', CAMS['w'], MID, 0, 40), ('nne_cerca', CAMS['nne'], MID, 0, 40)]
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
