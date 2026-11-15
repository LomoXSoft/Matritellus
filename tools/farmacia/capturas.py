"""The Street View pictures the pharmacy of the Calle Real and its neighbours (the chemist's-and-perfume shop on the corner
of the Calle de Colón, the narrow house between them, the brick house to the north) were measured from. Fetches them
(they are Google's: NOT kept in the repository, only this list) and writes views.json beside them.

    python tools/farmacia/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, heading, pitch (up +), horizontal field of view. Places are Google's (tools/molino/panos.py info),
a metre or two off: medir.py corrects them against Catastro's party walls.
"""
import json, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

SQ = 100.6          # the heading that looks square at the fronts of the Calle Real (they face west-south-west)
SQC = 27.5          # ...and at the chemist's side on the Calle de Colón (it faces south-south-west)
PANO = {
    # Calle Real, November 2024, from the crossroads with Colón and Palma northwards
    'X24': ('80y8myrODlJDq3tnllHNrg', -70.12, -59.11),
    'A24': ('YE5saENHfTggimx6HE0ksA', -70.11, -68.50),
    'N24': ('79dD5HZMsr4Qq80cLBfKTg', -67.90, -81.57),
    'M24': ('Fakoho7RotLJb084A8szSg', -65.87, -91.29),
    'A19': ('O2N8hZLYePI25-J078PY0w', -69.21, -69.72),       # October 2019
    'N19': ('zer0tO2K-vq1MoRJTd5Frg', -65.58, -82.38),
    'A09': ('y0MuwaEzow9cAYvIGTeZNA', -73.55, -70.00),       # May 2009
    'X13': ('CJIN7IXhiJ5CDpCRtGTo-w', -73.10, -61.55),       # March 2013
    # Calle de Colón, along the chemist's long side
    'C24': ('Unz-azlMy1IT2VRuOBNP0A', -59.22, -51.53),
}
SHOTS = [
    ('X24_f', 'X24', SQ, 15, 110), ('X24_alto', 'X24', SQ, 38, 100), ('X24_ne', 'X24', 60, 12, 100), ('X24_esq', 'X24', 70, 20, 110),
    ('A24_f', 'A24', SQ, 15, 110), ('A24_alto', 'A24', SQ, 38, 100), ('A24_sur', 'A24', 150, 10, 90), ('A24_norte', 'A24', 50, 12, 90),
    ('N24_f', 'N24', SQ, 15, 110), ('N24_alto', 'N24', SQ, 38, 100), ('N24_se', 'N24', 150, 10, 90), ('N24_ne', 'N24', 70, 12, 100),
    ('M24_f', 'M24', SQ, 15, 110), ('M24_se', 'M24', 140, 12, 100),
    ('A19_f', 'A19', SQ, 15, 110), ('N19_f', 'N19', SQ, 15, 110), ('A09_f', 'A09', SQ, 15, 110), ('X13_ne', 'X13', 70, 15, 100),
    ('A24_n70', 'A24', 70, 6, 90), ('N24_s130', 'N24', 130, 6, 90),      # the pharmacy's shop front, from both ends
    ('C24_f', 'C24', SQC, 15, 110), ('C24_alto', 'C24', SQC, 38, 100), ('C24_o', 'C24', 300, 12, 100), ('C24_e', 'C24', 80, 12, 100),
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
