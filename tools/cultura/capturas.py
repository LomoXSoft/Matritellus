"""The Street View pictures the block of the Casa Grande, the public library and the school of music and dance
is measured from (the user, 17 November 2026: "son varios edificios públicos pegados que ocupan una manzana entera ...
Tiene bastantes detalles así que tómatelo con calma"). They are Google's: NOT kept in the repository, only this list.
Writes views.json beside them.

    python tools/cultura/capturas.py OUT_FOLDER [name ...]

Google's car went up the Calle de los Arcos and along the Calle de Argentina in November 2024 (and 2021, 2019, 2013 at
the same spots); along the Callejón Pando, south of the block, in October 2019 and March 2013. Every camera round it:
python tools/molino/panos.py cerca wAvXPKVYISE48bviztDmuQ 150 130 50
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

# the Calle de los Arcos (west front), 2024
A = {'a1': ('V3gP39k6auimdB5ety6qRA', 114.55, 110.04), 'a2': ('gw9PBuF8Xf4ktoRtVq0epA', 114.50, 118.86), 'a3': ('7C0xOk9Fm-2QI42kBTVIoQ', 114.45, 129.18),
     'a4': ('wAvXPKVYISE48bviztDmuQ', 113.99, 139.62), 'a5': ('wFnN54ZqwIxpzNiFEzMqHA', 114.54, 149.35), 'a0': ('fH7IvgkZYsJCy2X8xkJ9SQ', 112.53, 101.64)}
# the Calle de Argentina (north front), 2024
N = {'n1': ('RSeloxQHHDLXEooBgjZ3Rw', 121.21, 106.65), 'n2': ('7J0Zg8keRRUczN91JzRBXA', 131.49, 109.09), 'n3': ('0P-oTjohdd8ccQE22g7ATw', 141.79, 111.50),
     'n4': ('rCfj3W8UFWc1GJTyT-4djA', 151.94, 114.23), 'n5': ('7wKmn_QEYiTNJ5yskWPB5A', 161.74, 116.95), 'n6': ('qdcZgH2WEfFj3WA5NgsTFw', 171.42, 119.58),
     'n7': ('6UAYDRh1649STJbgyrzCMg', 180.66, 122.27), 'n8': ('N_VBL96WSmEj1tYcljiZFw', 190.18, 126.30)}
# the Callejón Pando (south front), 2019
S = {'s1': ('enpGM7ZYZcp3H73y6y0slw', 132.51, 143.39), 's2': ('JEeMXWLr-H3q_dRD5QvVHQ', 141.67, 145.48), 's3': ('jtWMstGjHL17bAH8H0FpMg', 150.89, 147.98),
     's4': ('EelayRBvMUVkGbmMoRzD4Q', 165.22, 152.13), 's5': ('L_6fCNQop4xqhXusKHIB7g', 174.78, 155.43), 's6': ('OdcLf0evUW8kw845Cai4vg', 184.35, 158.52)}
# ...and the same spots in 2013
S13 = {'t1': ('vNUrLcI3G_RE-Iia3QE1Gw',) + S['s1'][1:], 't2': ('uEJGpKsF8TBFJdcR9e9IMg',) + S['s2'][1:], 't3': ('WinfFNgK5-H7A00iCWYdjQ',) + S['s3'][1:],
       't4': ('2odFcywH6_f_V_WZ-7F-9Q',) + S['s4'][1:], 't5': ('-gqw7SXjdsq47VWwhrWBog',) + S['s5'][1:], 't6': ('0PyXmTtFVGuflFakWDJlng',) + S['s6'][1:]}

SHOTS = []
for k, c in A.items():                          # the Arcos front: square on, a little up; and looking along it
    SHOTS.append((k, c, (118.0, c[2]), 8, 90))
    SHOTS.append((k + '_up', c, (118.0, c[2]), 30, 90))
SHOTS += [('a0_esq', A['a0'], (122.0, 112.0), 8, 90), ('a5_esq', A['a5'], (122.0, 140.0), 6, 90)]
for k, c in N.items():                          # the Argentina front: square on (the block south of the street), a little up
    SHOTS.append((k, c, (c[1] + 1.0, c[2] + 9.0), 8, 90))
    SHOTS.append((k + '_up', c, (c[1] + 1.0, c[2] + 9.0), 30, 90))
SHOTS += [('n8_este', N['n8'], (176.0, 138.0), 6, 90), ('n7_este', N['n7'], (176.0, 140.0), 6, 90), ('n8_lejos', N['n8'], (150.0, 125.0), 6, 70)]
for k, c in S.items():                          # the Pando front (2019): square on to the north, a little up
    SHOTS.append((k, c, (c[1] - 1.5, c[2] - 8.0), 8, 90))
    SHOTS.append((k + '_up', c, (c[1] - 1.5, c[2] - 8.0), 30, 90))
SHOTS += [('s6_este', S['s6'], (176.0, 142.0), 6, 90), ('s6_aparc', S['s6'], (180.0, 132.0), 4, 90), ('s5_este', S['s5'], (174.0, 142.0), 10, 90)]
for k, c in S13.items():
    SHOTS.append((k, c, (c[1] - 1.5, c[2] - 8.0), 8, 90))
# looking along each front, to count its openings
SHOTS += [('a5_n', A['a5'], (118.6, 122.0), 6, 90), ('a0_s', A['a0'], (118.6, 126.0), 6, 80), ('a3_n', A['a3'], (118.6, 112.0), 6, 90),
          ('a3_s', A['a3'], (118.0, 138.0), 6, 90), ('n1_e', N['n1'], (150.0, 116.0), 8, 80), ('n3_e', N['n3'], (165.0, 121.0), 8, 80),
          ('n5_w', N['n5'], (135.0, 112.0), 8, 80), ('n8_w', N['n8'], (150.0, 118.0), 8, 70), ('s1_e', S['s1'], (160.0, 149.0), 8, 80),
          ('s5_w', S['s5'], (135.0, 141.0), 8, 80), ('s3_w', S['s3'], (125.0, 139.0), 8, 80), ('s3_e', S['s3'], (168.0, 148.0), 8, 80)]

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
