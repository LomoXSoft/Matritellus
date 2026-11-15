"""The Street View pictures the supermarket by the old Madrid-Cádiz road ("Mercamona" in the game) and its car park were
measured from. Fetches them (they are Google's: NOT kept in the repository, only this list) and writes views.json.

    python tools/mercamona/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, heading, pitch (up +), horizontal field of view. Every camera round it, with its older passes:
python tools/molino/panos.py cerca 0kuTvD40S4ObcE2J8Y1McQ 930 335 125. All are of November 2024 unless named otherwise.
There are none inside the car park (it is private ground), and no private 360 pictures either (looked for at four spots).
"""
import json, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

SQW = 100.6         # the heading that looks square at the shop's long west side, from the old road
PANO = {
    # the old Madrid-Cádiz road, west of the shop, from north to south
    'W0': ('fvSxWi44J1YvnYYpZe697w', 885.15, 273.81), 'W1': ('egdhvhxrx6kPjfpnCrJULg', 887.80, 294.10), 'W2': ('SYIF_iam5lnx5xn0c5J5mw', 886.04, 303.90),
    'W3': ('hYH_aXsxmEqXLG2WaSp5dw', 882.36, 323.86), 'W4': ('0kuTvD40S4ObcE2J8Y1McQ', 878.60, 343.68), 'W5': ('SqmLD7tqS_tcOCSe6sJMdQ', 874.95, 363.57),
    'W6': ('ItkM4lLBzM_4SfkOePmjtQ', 872.43, 383.61), 'W7': ('3qj7lNMj-xhfFG2xrugN8w', 867.87, 402.94),
    # the street north of it, by the roundabout
    'N1': ('f9MMn3i5t_PfTpguPQ5jGQ', 913.65, 266.08), 'N2': ('xH-80HUM6HEoAFng_h0dEw', 936.70, 276.11),
    # the street along the north-east side of the car park, before the terraced houses, from the shop's corner outwards
    'E0': ('FIHwnAykFeXrXjp-jsTnVQ', 935.90, 295.87), 'E1': ('ne7uTvzIWlSh3_1MF_FVow', 942.38, 302.95), 'E2': ('iTw5bR4HhNzmiNp5BG8IyA', 949.32, 309.64),
    'E3': ('ZemCwJbEUxQZ80IjQSojIg', 964.18, 321.66), 'E4': ('T3s4dRyKddPsV5_lxUjghg', 979.89, 333.22), 'E5': ('yfGalK073F6UmiJoTcHFRw', 995.68, 344.85),
    'E6': ('B19Fv1FTzNbo-NV35kiXrQ', 1011.54, 357.76),
}
SHOTS = [
    ('W1_se', 'W1', 135, 8, 100), ('W2_e', 'W2', 95, 10, 100), ('W3_f', 'W3', SQW, 10, 100), ('W4_f', 'W4', SQW, 10, 100), ('W5_f', 'W5', SQW, 10, 100), ('W6_f', 'W6', SQW, 10, 100),
    ('W7_ne', 'W7', 55, 8, 100), ('W4_ne', 'W4', 55, 8, 100), ('W4_se', 'W4', 150, 8, 100), ('W0_se', 'W0', 150, 8, 100),
    ('N1_s', 'N1', 180, 8, 100), ('N2_s', 'N2', 190, 8, 100), ('N2_sw', 'N2', 230, 8, 100),
    ('E0_s', 'E0', 185, 8, 100), ('E0_sw', 'E0', 240, 10, 100), ('E1_s', 'E1', 190, 6, 100), ('E1_sw', 'E1', 245, 10, 100), ('E2_s', 'E2', 190, 4, 100), ('E2_w', 'E2', 265, 8, 100),
    ('E3_sw', 'E3', 225, 5, 100), ('E3_w', 'E3', 275, 6, 90), ('E4_sw', 'E4', 225, 4, 100), ('E4_w', 'E4', 270, 5, 80), ('E5_w', 'E5', 255, 4, 80), ('E5_sw', 'E5', 215, 4, 100), ('E6_w', 'E6', 262, 4, 70),
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
