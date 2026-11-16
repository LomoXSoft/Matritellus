"""The Street View pictures the Guardia Civil's barracks of the Avenida de la Constitución (the "Tricornios'" in the
game) was measured from. Fetches them (they are Google's: NOT kept in the repository, only this list) and writes
views.json beside them.

    python tools/cuartel/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, the point of the map it looks at, pitch (up +), horizontal field of view.
Every camera round it: python tools/molino/panos.py cerca l497FompEAUE4gSNDdP4-g 70 -520 62.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

GAP = (65.5, -535.0)        # between its two north blocks
VA = ('IuhvN2zroz7Q7PoCVTUD9A', 42.47, -538.50)     # the Calle de Víctor Pradera (its north side), west to east
VB = ('oZigwnrSOywURHqQHBiUWg', 53.42, -540.49)
VC = ('l497FompEAUE4gSNDdP4-g', 63.43, -542.12)
VD = ('9w-eQnj_hypUp5jFfocomw', 73.48, -543.71)
VE = ('J8DgCI5tTH58jQvbPcyjmA', 83.58, -545.40)
VF = ('jtMn1Um4YLj_rv0gvNwSUA', 93.69, -547.04)
VG = ('aPWSXmHVyaOh6cRjODZo6A', 103.88, -548.75)
AN = ('bvSzKa_jtZxpYLbeWU0-JA', 33.08, -548.19)     # the Avenida de la Constitución (its west side), north to south
AA = ('K2YpX8ilw6XtEs3ckC_a6w', 30.05, -536.22)
AB = ('nvpJ6qgLOeEhnfpLpBHxOQ', 32.19, -526.43)
AC = ('pEgpX4wXkxdTGFMYVcyB0Q', 32.26, -516.39)
AD = ('66oDLjcEYPvMnzX6fP9JSg', 30.00, -506.41)
AE = ('vhQGP0aQ72pcZbokjpTRBQ', 39.10, -501.15)
SV = ('F8IcLXelfxLvEuAT6MBe5A', 41.25, -510.15)     # the service road beside the avenue, by its west side
NA = ('juZlxME3A7xL_o_q0t1_KA', 49.27, -493.72)     # the Calle Nueva (south of it), west to east
NB = ('V60GqIde74aKk5nfZVQuFg', 59.95, -493.00)
NC = ('fyIJs5vfjhS6nyhhSlJoeQ', 69.80, -489.37)
ND = ('YGHlJO_3JthmA0KwqpVDKA', 79.43, -485.75)
NE = ('8yp6R6jV70clGnF7mM1I0g', 88.86, -482.13)
SHOTS = [      # November 2024
    ('va', VA, (50.0, -534.0), 14, 80), ('va_largo', VA, (75.0, -539.0), 8, 60), ('vb', VB, (54.8, -535.8), 20, 105), ('vb_alto', VB, (54.8, -535.8), 42, 95), ('vb_este', VB, GAP, 10, 70),
    ('vc', VC, GAP, 12, 100), ('vc_alto', VC, GAP, 36, 95), ('vc_puerta', VC, (65.5, -533.5), 6, 50), ('vc_oeste', VC, (56.0, -535.9), 14, 90), ('vc_este', VC, (76.0, -539.3), 14, 90),
    ('vd', VD, (75.0, -539.2), 20, 105), ('vd_alto', VD, (75.0, -539.2), 42, 95), ('vd_puerta', VD, (65.5, -533.5), 8, 60), ('ve', VE, (84.0, -540.7), 20, 105), ('ve_oeste', VE, (68.0, -536.0), 8, 70),
    ('vf', VF, (90.0, -541.6), 20, 105), ('vf_largo', VF, (72.0, -538.7), 8, 60), ('vg', VG, (94.0, -540.0), 12, 70),
    ('an', AN, (50.0, -534.0), 10, 55), ('aa', AA, (48.2, -531.0), 12, 70), ('ab', AB, (49.0, -527.0), 14, 85), ('ab_sur', AB, (52.0, -512.0), 10, 80), ('ac', AC, (51.5, -517.0), 14, 90),
    ('ad', AD, (52.0, -509.0), 14, 85), ('ad_norte', AD, (49.0, -527.0), 10, 80), ('ae', AE, (55.0, -503.0), 14, 90),
    ('sv', SV, (51.5, -509.5), 22, 110), ('sv_alto', SV, (51.5, -509.5), 45, 95), ('sv_norte', SV, (49.0, -526.0), 16, 95), ('sv_centro', SV, (52.0, -517.0), 14, 90), ('sv_sur', SV, (55.0, -500.0), 12, 90),
    ('na', NA, (58.0, -500.6), 14, 95), ('nb', NB, (61.0, -500.6), 16, 105), ('nb_patio', NB, (70.0, -520.0), 10, 60), ('nc', NC, (72.0, -503.0), 14, 95), ('nc_oeste', NC, (60.0, -500.6), 12, 80),
    ('nd', ND, (81.0, -504.0), 14, 90), ('ne', NE, (86.0, -505.0), 12, 75),
    # the same spots before: October 2019, March 2013
    ('vc19', ('Cyl7Mx4kpNJyEa7UnOLQqA', 63.43, -542.12), GAP, 12, 100), ('vc13', ('ExymnWpvWX9gRnRdiVu9wQ', 63.43, -542.12), GAP, 12, 100),
    ('vd13', ('_I6ZlWvz5jCDfkTs3I3sGQ', 73.48, -543.71), (75.0, -539.2), 20, 105), ('sv13', ('s1UHwU9TJwP4lcXHrhuNdA', 41.25, -510.15), (51.5, -509.5), 22, 110),
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
