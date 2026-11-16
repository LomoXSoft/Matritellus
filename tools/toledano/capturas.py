"""The Street View pictures the Plazuela del Toledano was measured from. Fetches them (they are Google's: NOT kept in
the repository, only this list) and writes views.json beside them.

    python tools/toledano/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, the point of the map it looks at, pitch (up +), horizontal field of view.
Every camera round it: python tools/molino/panos.py cerca CzCj5kSG7s9inuIdgT9lgA -365 -44 55.
SPHERE: a private 360 picture taken on the islet itself (not the car's): its own address, by yaw.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

MID = (-368.0, -42.0)       # the middle of the islet
TW = (-379.0, -38.0)        # its three points: west...
TS = (-361.0, -54.0)        # ...south...
TN = (-368.0, -32.0)        # ...and north
E1 = ('CzCj5kSG7s9inuIdgT9lgA', -358.61, -44.47)    # east of it (November 2024, all of these)
E2 = ('RIgTvJTn_aqq4KRpEgDo3w', -363.23, -34.89)
N1 = ('2nfdcXKps7d_Oceoeho0kw', -371.56, -31.26)    # north
N2 = ('o3jRFkXbY8LdOj6dJQ9D4g', -377.96, -35.32)
W1 = ('05M_Gm21SYnZ_nEzPe505A', -377.80, -42.86)    # along its south-west side
W2 = ('tFXarX-PkRUFyfm216quGQ', -370.96, -49.34)
S1 = ('3Lmw6TF9-cV-UIOZkBsz6g', -362.95, -55.63)    # south
S2 = ('JISQj2pjj3JSclYdI0lsNw', -354.55, -52.76)
F1 = ('r_mKnb0Onz3Q2nMkJXKxrw', -386.00, -39.29)    # further off: west, north, south
F2 = ('E9HAC6qR9Lr1_JoD3s9i-A', -364.65, -25.93)
F3 = ('L_meabBIGL27jXXxHbW4Sw', -354.65, -61.81)
SHOTS = [
    ('e1', E1, MID, 2, 100), ('e1_n', E1, TN, 4, 90), ('e1_s', E1, TS, 0, 90), ('e1_alto', E1, MID, 25, 100),
    ('e2', E2, MID, 0, 100), ('e2_s', E2, TS, 2, 80),
    ('n1', N1, MID, 0, 100), ('n1_o', N1, TW, 0, 90),
    ('n2', N2, MID, 0, 100), ('n2_s', N2, TS, 2, 70),
    ('w1', W1, MID, 0, 100), ('w1_e', W1, TS, 2, 90),
    ('w2', W2, MID, 0, 110), ('w2_n', W2, TN, 4, 90), ('w2_o', W2, TW, 2, 90),
    ('s1', S1, MID, 2, 100), ('s1_n', S1, TN, 3, 70),
    ('s2', S2, MID, 2, 90),
    ('f1', F1, MID, 4, 70), ('f2', F2, MID, 3, 70), ('f3', F3, MID, 4, 70),
    # the same spots before: March 2013, May 2009
    ('e1_13', ('eI9HKapgqS21JiBX0HAEwQ', -358.61, -44.47), MID, 2, 100), ('e1_09', ('IHE5Pay1JmOTOFqN9MuEYw', -358.61, -44.47), MID, 2, 100),
    ('w2_13', ('2PeJZiDZDZ46RRCpH1p9Lw', -370.96, -49.34), MID, 0, 110), ('n1_19', ('11PLwefvS_11TEqaazGQ7g', -371.56, -31.26), MID, 0, 100),
]
SPHERE = 'https://lh3.googleusercontent.com/gpms-cs-s/AM4Q-U9GFYPs4z9Bo7CdICLwrjoqa79yRAPiFiEl6_hn07viu0ya8aMrHoeKX86S36rQUbsCyXjnC4Qv85OjuALPX7B6ogQoRKJFUSKBZ-ieGrB9MuFzFF7ukBmNx_pzcI2J9h1yK93_OQ'

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
