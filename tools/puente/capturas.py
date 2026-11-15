"""The Street View pictures the old bridge of the Arroyuelo Medio was measured from: all of May 2009, the only time the
car passed while it stood (it could not drive under it: the pictures are from the streets round it). Fetches them (they
are Google's: NOT kept in the repository, only this list) and writes views.json beside them.

    python tools/puente/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, heading, pitch (up +), horizontal field of view. Places are Google's (tools/molino/panos.py info).
"""
import json, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

PANO = {
    # Calle de Matías Pérez, coming down to the west end of the bridge
    'MP':  ('Y_66tNcpYwFehBqO3MVJRA', -159.43, -259.64),     # five metres from its west end
    'MP2': ('4UomZsgbUmeAUjM1-y0Q5w', -168.71, -266.81),
    # where Matías Pérez, the Arroyuelo Medio, the Arroyuelo Alto and the Palo meet, south-east of it
    'J':   ('sP-mmLaX_Tn4-4QMzfn_uQ', -142.44, -246.06),
    'A':   ('dozSb9UNCaRLY1241o7nVw', -137.47, -232.57),
    'B':   ('vFPtXmujrLVyAVKbfs1Q7Q', -135.58, -223.34),
    'AA':  ('P1CEVXt8t99y1fYDXOiBpg', -121.87, -226.11),     # Calle del Arroyuelo Alto
    'P':   ('iNNpKCcghLbmQftOQTCPwg', -123.97, -214.29),     # Calle del Palo
    # Calle del Santo, at the far end of the sunk bed
    'S':   ('vu0JGi2MsCb3Vst0YHkPpQ', -171.66, -304.56),
    'S2':  ('QvxduDS0420jdPkgdhsTdw', -177.39, -294.56),
    # today (November 2024), for the houses round it: in the bed itself, which is a street now
    'H1':  ('bBFSR440n17UnFPrH773WQ', -149.91, -263.73),
    'H2':  ('jjfeB6yfytIgCTGQmu7GVg', -154.57, -272.41),
    'H0':  ('MqHQ2vJwr_Sblw-0YayYcQ', -145.26, -254.76),
}
SHOTS = [
    ('MP_e', 'MP', 77, -10, 90), ('MP_ne', 'MP', 45, -10, 90), ('MP_se', 'MP', 115, -8, 90), ('MP_e_cerca', 'MP', 80, -14, 50), ('MP_n', 'MP', 10, -6, 90),
    ('MP2_e', 'MP2', 107, -3, 60),
    ('J_350', 'J', 350, -6, 50), ('J_345', 'J', 345, -5, 25),
    ('J_nw', 'J', 330, -8, 75), ('J_nw_cerca', 'J', 328, -7, 40), ('J_w', 'J', 295, -8, 75), ('J_n', 'J', 5, -8, 75),
    ('A_nw', 'A', 335, -5, 60), ('A_nw_cerca', 'A', 335, -4, 30),
    ('B_nw', 'B', 338, -4, 45), ('AA_nw', 'AA', 320, -4, 45), ('AA_nw_cerca', 'AA', 320, -3, 25), ('P_nw', 'P', 330, -3, 40),
    ('S_se', 'S', 154, -6, 60), ('S_se_cerca', 'S', 155, -3, 25), ('S_s', 'S', 180, -10, 90), ('S2_se', 'S2', 141, -5, 45),
    ('H1_n', 'H1', 335, -2, 90), ('H1_e', 'H1', 65, 2, 90), ('H1_w', 'H1', 245, 2, 90), ('H1_s', 'H1', 155, -2, 90),
    ('H2_e', 'H2', 65, 2, 90), ('H2_w', 'H2', 245, 2, 90), ('H0_nw', 'H0', 330, -3, 90),
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
