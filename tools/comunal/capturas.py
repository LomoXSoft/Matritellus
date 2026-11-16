"""The Street View pictures the people's university of the Calle de los Arcos ("Universidad Comunal" in the game) and
the stationer's beside it ("Papelería Rocas") were measured from. Fetches them (they are Google's: NOT kept in the
repository, only this list) and writes views.json beside them.

    python tools/comunal/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, the point of the map it looks at, pitch (up +), horizontal field of view.
Every camera round them: python tools/molino/panos.py cerca wAvXPKVYISE48bviztDmuQ 113 135 45.
SPHERE: a private 360 picture taken in the street before the gate (not the car's): its own address, by yaw.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

UP = (105.0, 135.0)         # the middle of the university's front
GATE = (108.0, 140.5)       # its porch and gate, on the street
SHOP = (108.9, 146.2)       # the stationer's front
A = ('gw9PBuF8Xf4ktoRtVq0epA', 114.50, 118.86)      # the Calle de los Arcos, north to south
B = ('7C0xOk9Fm-2QI42kBTVIoQ', 114.45, 129.18)
C = ('wAvXPKVYISE48bviztDmuQ', 113.99, 139.62)
D = ('wFnN54ZqwIxpzNiFEzMqHA', 114.54, 149.35)
E = ('yqUDq4-Hiu6ONtmBdfr2hA', 114.70, 164.80)
P = ('enpGM7ZYZcp3H73y6y0slw', 132.51, 143.39)      # the Callejón Pando, which meets the street before the gate (October 2019)
V1 = ('gm2zVd9BRwjQkej_k-8yTw', 78.28, 119.88)      # the Calle Cervantes, behind (October 2019)
V2 = ('H7tDQl008YG1DRwU1Gtb9A', 78.52, 133.09)
V3 = ('e-ozD4ymamaPuNnhqwJbLQ', 77.81, 142.88)
SHOTS = [      # November 2024
    ('a', A, UP, 8, 70), ('a_tapia', A, (108.0, 127.0), 6, 90), ('a_norte', A, (105.0, 124.8), 10, 80),
    ('b', B, (105.0, 131.0), 8, 100), ('b_sur', B, (105.0, 139.0), 8, 90), ('b_alto', B, (105.0, 131.0), 26, 90), ('b_porche', B, GATE, 10, 70), ('b_norte', B, (106.5, 125.0), 8, 90),
    ('c', C, (105.0, 138.0), 8, 100), ('c_norte', C, (105.0, 130.0), 8, 90), ('c_porche', C, GATE, 12, 90), ('c_alto', C, GATE, 30, 90), ('c_tienda', C, SHOP, 16, 90), ('c_placa', C, (105.0, 134.0), 10, 40),
    ('d', D, SHOP, 18, 100), ('d_alto', D, SHOP, 42, 90), ('d_bajo', D, SHOP, 2, 80), ('d_norte', D, GATE, 10, 80), ('d_sur', D, (109.3, 153.0), 14, 90), ('d_lejos', D, UP, 8, 60),
    ('e', E, SHOP, 10, 50), ('e_ancho', E, (109.2, 152.0), 12, 80),
    ('p', P, GATE, 6, 45), ('p_zoom', P, (105.0, 137.0), 5, 25), ('p_tienda', P, SHOP, 8, 30),
    ('v1', V1, (79.6, 144.5), 12, 50), ('v2', V2, (79.6, 144.5), 16, 80), ('v3', V3, (79.5, 146.0), 24, 110), ('v3_alto', V3, (79.5, 146.0), 48, 100),
    # the same spots before: October 2019, March 2013, May 2009
    ('b19', ('zhZWIyqA6V-tkwDA-DOmaQ', 114.45, 129.18), (105.0, 131.0), 8, 100), ('c19', ('VrmU5HyoUGLJm7MsrX-8Yw', 113.99, 139.62), (105.0, 138.0), 8, 100),
    ('d19', ('zCdUjhV8wWELDw3W_sX5wA', 114.54, 149.35), SHOP, 18, 100), ('c13', ('_DuRbR0cnrSBKBiQbc_Tcg', 113.99, 139.62), (105.0, 138.0), 8, 100),
    ('b09', ('iQzt-8N92ZKajSMbYDRtpA', 114.45, 129.18), (105.0, 131.0), 8, 100), ('d09', ('73Bgh8yD7IPcq96fTmix-Q', 114.54, 149.35), SHOP, 18, 100),
]
SPHERE = 'https://lh3.googleusercontent.com/gpms-cs-s/AM4Q-U-lEOhuEe50mVp4jfpcsslBW_o4Pkk0G4rzg0LX3xAHCtvUOpci3qcScFhtua7jWGJAh_Z_qYWQIT0AbqnXIUsYXnLVPoesjf1ptAFBI_sZ1xi7IPvUKDrJ4EyQhr9ltfPHZk3VFg'

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
    for yaw in range(0, 360, 45):                   # the private 360 picture, all round
        f = os.path.join(out, 'esfera_%03d.jpg' % yaw)
        if (not only or 'esfera' in only) and not os.path.exists(f):
            try:
                open(f, 'wb').write(urllib.request.urlopen(urllib.request.Request('%s=w1024-h640-k-no-pi-5-ya%d-ro0-fo80' % (SPHERE, yaw), headers=panos.UA), timeout=40).read())
            except Exception as e:
                print('  could not fetch the sphere at', yaw, e)
    json.dump(views, open(path, 'w'), indent=0)
    print(len(views), 'views in', out)
