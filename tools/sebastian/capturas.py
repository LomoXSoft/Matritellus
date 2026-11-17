"""The Street View pictures the hermitage of San Sebastián and its park are built from (the user, 18 November 2026:
"La hermita de san Sebastián y el parque que la rodea"). They are Google's: NOT kept in the repository, only this list.
Writes views.json beside them.

    python tools/sebastian/capturas.py OUT_FOLDER [name ...]

Google's car went up the Calle del Santo past the hermitage's front and side, and round the park by the loop of the
Calle del Santo, in November 2024 (2021 and 2009 at the same spots); north of it, by the Calle de los Huertos, in
October 2019 (and 2013). Every camera round it: python tools/molino/panos.py cerca 66oDLjcEYPvMnzX6fP9JSg -95 -450 45
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

# the Calle del Santo, east of the hermitage and past its front (2024; then 2021 and 2009 at the same spots)
C = {'c1': ('58B4_26_LvVYOJih1dYFNQ', -81.14, -446.93), 'c2': ('zVKTPwKnVavqIJoIaowxzg', -75.44, -455.36), 'c3': ('o3C8s_ezXX9iJLH4Pb_B7A', -69.75, -463.78),
     'c4': ('BMo0ijN6niMVBxxyR2MA3w', -64.12, -472.18), 'c0': ('YZyFhsAlTrpMlzpXXM5nZw', -83.15, -436.33), 'cm': ('LQgd9M4sOv90hLHk_0LSlA', -89.45, -430.94),
     'cn': ('ZiOmVRmP97EaJmaWxc7o4Q', -94.47, -422.91), 'co': ('cw9fBL5OFI_5e_IOspkZQA', -99.75, -414.59), 'cd': ('cfdxJAcqmCjliFK5dmt93w', -72.95, -432.19)}
C21 = {'d1': ('ToCneeqinuGSX3k7ZJt2yg',) + C['c1'][1:], 'd2': ('q1rKwCZIWz8i7H2ABxGFKQ',) + C['c2'][1:], 'd3': ('Y4HtqQXg7bQoo7KaB7gohw',) + C['c3'][1:],
       'd4': ('VFIa7QJwriBXa_DK86k6LQ',) + C['c4'][1:], 'dm': ('jhw2u3Lbcoae7vTfL5wuFw',) + C['cm'][1:]}
C09 = {'e1': ('xsRJtvO58wpVwzzPPEtEGg',) + C['c1'][1:], 'e2': ('u6uyBeMMEFe--YGqg6fS1Q',) + C['c2'][1:], 'e3': ('Eqzc4kMrSNIXa7Q3boeUCA',) + C['c3'][1:],
       'e0': ('meIWHBa2FP5iWSOChCDa2g',) + C['c0'][1:]}
# round the park by the loop of the Calle del Santo (2024; 2009 at the same spots)
P = {'p1': ('xex1VdQmpUC-3mSjtq0wwA', -130.03, -472.33), 'p2': ('8AeCMxcv0riStLo2lK3NsQ', -136.70, -459.35), 'p3': ('5GNkNYTUKWq73BpS72j4Lg', -138.81, -440.34),
     'p4': ('G4CYIhmpvVVhnqBsI2OGUA', -131.26, -434.41), 'p5': ('peXL2LpC7J_9loLaaM7KEg', -122.70, -429.07), 'p6': ('nwupvq-e1QQdNN-JCxv55g', -113.67, -423.41)}
P09 = {'q1': ('78QGctBXEKWiwTrrfIo9aA',) + P['p1'][1:], 'q2': ('g6jrZ_nDGP1sFmZuNWe1-g',) + P['p2'][1:], 'q3': ('xZhxs0rFV86N47Hib1FHmQ',) + P['p3'][1:],
       'q5': ('EYq7ZSRNckPjXRCfgmjZOw',) + P['p5'][1:], 'q6': ('1GROLHBNh5i1CXY662mpfQ',) + P['p6'][1:]}
# north of it (2019, and 2013)
N = {'n1': ('K5BD-0t8hPJy_N4u7ZTd6A', -89.55, -490.74), 'n0': ('37ywldr9smPLwAagDH0rjg', -89.55, -490.74)}

ERMITA = (-88.0, -468.0)                         # (the hermitage's middle, about)
PLAZA = (-112.0, -451.0)                         # (the round square in the park)

SHOTS = []
for k, c in list(C.items()) + list(C21.items()) + list(C09.items()):
    SHOTS.append((k, c, ERMITA, 8, 90))
for k in ('c1', 'c2', 'c3', 'c4', 'c0'):
    SHOTS.append((k + '_up', C[k], ERMITA, 28, 90))
    SHOTS.append((k + '_pq', C[k], PLAZA, 5, 90))
for k, c in list(P.items()) + list(P09.items()):
    SHOTS.append((k, c, PLAZA, 5, 90))
    SHOTS.append((k + '_er', c, ERMITA, 6, 80))
for k, c in N.items():
    SHOTS.append((k, c, (-88.0, -460.0), 6, 90))
    SHOTS.append((k + '_pq', c, PLAZA, 4, 90))
# along the hermitage's side on the Calle del Santo, and its front from the Calle del Descanso
SHOTS += [('c4_s', C['c4'], (-85.0, -440.0), 6, 80), ('c1_n', C['c1'], (-70.0, -480.0), 6, 80), ('cd_er', C['cd'], ERMITA, 8, 80),
          ('cd_up', C['cd'], ERMITA, 25, 80), ('cn_er', C['cn'], ERMITA, 8, 80), ('co_er', C['co'], (-100.0, -440.0), 6, 90)]

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
