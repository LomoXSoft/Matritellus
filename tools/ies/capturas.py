"""The Street View pictures the IES Valdeacero (the user's name for the IES Valdehierro, 17 November 2026) was measured
from: all from the avenue on its east side (its other sides give on to fields). Fetches them (they are Google's: NOT
kept in the repository, only this list) and writes views.json beside them.

    python tools/ies/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, the point of the map it looks at, pitch (up +), horizontal field of view.
Every camera along it: python tools/molino/panos.py cerca pnsPdFB5AYQuHAs8DICWMQ -60 -1220 110.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

C = {   # November 2024, along the avenue from the north
    'a': ('habx2_KVAe9GyTq1FNcL5g', -38.35, -1268.38), 'b': ('5H1B18vv86yC8iZ8yUfCUw', -40.03, -1258.44),
    'c': ('FJ1U02OrefZ5MqtTPoYtjQ', -41.84, -1248.52), 'd': ('1s0H_iaSoNKxjidjh8xAJQ', -43.76, -1238.40),
    'e': ('4HQqCmikVjqdP3NegRyE5Q', -45.74, -1228.31), 'f': ('pnsPdFB5AYQuHAs8DICWMQ', -47.72, -1218.18),
    'g': ('u4V7ifsppSSbwp-GKBs8tw', -49.54, -1207.81), 'h': ('aFn9WyNYwE89el-FaPg4IA', -51.23, -1197.31),
    'i': ('Z9fbXcMese05HUzkQUe2ug', -53.17, -1186.41), 'j': ('J4Vpisb0i6EXc8mqWYed5g', -55.40, -1174.68),
    'k': ('Ldu9GWAK6CXdprfH9fAUCw', -57.94, -1161.51), 'l': ('nxNyuiqO1yG1Q0rW227Y_g', -59.63, -1152.60),
    'm': ('aNgr8jlFP3JNGpS9Kcouhw', -61.26, -1143.32), 'n': ('K6srAwtYOlpdtNfcg4IbMg', -63.03, -1133.58),
    'o': ('GE2-_R63CfcmpsKcry743w', -64.71, -1123.79),
}
SHOTS = [
    ('a_fp', C['a'], (-125.0, -1255.0), 4, 60), ('b_aparca', C['b'], (-110.0, -1250.0), 4, 90), ('c_puerta', C['c'], (-70.0, -1245.0), 4, 70),
    ('d_gimnasio', C['d'], (-90.0, -1225.0), 6, 90), ('e_gimnasio', C['e'], (-80.0, -1218.0), 6, 90), ('f_gimnasio', C['f'], (-75.0, -1215.0), 8, 100),
    ('g_sur_gim', C['g'], (-85.0, -1198.0), 6, 90), ('h_arboles', C['h'], (-90.0, -1192.0), 4, 90), ('i_esquina', C['i'], (-100.0, -1180.0), 4, 90),
    ('j_pistas', C['j'], (-110.0, -1168.0), 4, 90), ('k_pistas', C['k'], (-120.0, -1160.0), 4, 90), ('l_peine', C['l'], (-135.0, -1150.0), 4, 70),
    ('m_peine', C['m'], (-140.0, -1145.0), 4, 60), ('n_sur', C['n'], (-120.0, -1140.0), 4, 70), ('o_sur', C['o'], (-130.0, -1140.0), 3, 50),
    ('i_cerca', C['i'], (-80.0, -1183.0), 4, 90), ('d_esquina', C['d'], (-75.0, -1240.0), 6, 80), ('j_porche', C['j'], (-122.0, -1178.0), 4, 40),
    # the way in, closer: its board, its gates, the porter's lodge, the flags behind
    ('h_entrada', C['h'], (-76.0, -1181.0), 6, 45), ('i_entrada', C['i'], (-76.0, -1181.0), 6, 45), ('j_entrada', C['j'], (-76.0, -1181.0), 6, 45),
    ('k_entrada', C['k'], (-76.0, -1181.0), 6, 45), ('i_banderas', C['i'], (-84.0, -1181.0), 20, 45), ('j_banderas', C['j'], (-84.0, -1181.0), 20, 45),
]
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
