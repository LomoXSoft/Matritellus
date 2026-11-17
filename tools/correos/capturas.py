"""The Street View pictures the post office of the Calle de Zaragoza (number 1, by the Plaza del Ayuntamiento; the user,
17 November 2026: "Vamos con la oficina de correos") is measured from. They are Google's: NOT kept in the repository,
only this list. Writes views.json beside them.

    python tools/correos/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map (Google's word for it), the point of the map it looks at, pitch (up +),
horizontal field of view. Every camera round it: python tools/molino/panos.py cerca iNNpKCcghLbmQftOQTCPwg -124 -76 30.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

C = {   # November 2024 (and 2013, 2019 where Google has them)
    'n': ('9hjj_J3VGECZEO0uhhJIXg', -123.14, -73.89), 's': ('ejgqJZS_XKH0kDtjUDUgRg', -121.01, -78.46),
    'ss': ('7LySxfUeZ9Rdjg28OTYA3Q', -114.79, -91.96), 'nn': ('bP9NZaWhJRT-RCGLZn0hwg', -130.67, -56.60),
    'nnn': ('019M-P8TLnCz90aaTtOmOA', -134.15, -47.82), 'sss': ('t_0gGPWQjl1qAjwAcChDtg', -118.77, -104.40),
    'n13': ('YNcFuMsh8kLKBotnYAr9aw', -123.14, -73.89), 's13': ('AEbNV_UqVoqVtOwK6ric6Q', -121.01, -78.46),
}
FRONT = ((-130.12, -66.22), (-122.17, -83.17))      # its front on the Zaragoza (Catastro), south end to north end
IN = (-0.9055, -0.4247)                              # from the street into it

def on(c, k=6.0):
    return (C[c][1] + IN[0] * k, C[c][2] + IN[1] * k)

SHOTS = [
    ('n_frente', C['n'], on('n'), 14, 110), ('s_frente', C['s'], on('s'), 14, 110), ('n_alto', C['n'], on('n'), 35, 100), ('s_alto', C['s'], on('s'), 35, 100),
    ('n13_frente', C['n13'], on('n13'), 14, 110), ('s13_frente', C['s13'], on('s13'), 14, 110),
    ('ss_lejos', C['ss'], (-126.0, -75.0), 8, 70), ('sss_lejos', C['sss'], (-126.0, -76.0), 6, 55),
    ('nn_lejos', C['nn'], (-126.0, -78.0), 8, 75), ('nnn_lejos', C['nnn'], (-126.0, -78.0), 6, 55),
    ('n_entrada', C['n'], (-129.0, -70.5), 6, 80), ('s_arco', C['s'], (-125.5, -80.0), 6, 80),
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
