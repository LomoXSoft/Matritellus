"""The Street View pictures the long paved park of the Paseo del Cristo is built from (the user, 21 November 2026, after
the Residencia: "Podemos continuar con el parque largo empedrado que hay al lado del paseo del cristo (tiene su propia
linea en street view, sin nombre)"). The park runs ~180 m from the Calle de las Viñas / Calle de los Arcos corner to the
little square before the hermitage, between the Paseo (south) and the white walls and the lane (north). The pictures are
Google's: NOT kept in the repository, only this list. Writes views.json beside them.

    python tools/paseo/capturas.py OUT_FOLDER [name ...]

Every camera: python tools/molino/panos.py cerca CIArmJTqQDSoqJ2P2fhg-w 215 472 110
  - the park's own line (the footway, no name) is March 2013 only, Google's cameras ~3 m north of the map's footway;
  - the Paseo's (the car, on the south carriageway) is November 2024, with 2009-2021 behind each.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

# the Paseo, November 2024: name -> (panorama, x, z)
CAR = {
    'c01': ('u-l7g7mkRTpJUOPCIMVm3w', 111.82, 440.82), 'c02': ('140qwoUuY3RsJRMMmC9AtA', 121.41, 446.41),
    'c03': ('CNbxLm_ntt0eO6ETKwiXyQ', 130.85, 452.16), 'c04': ('M6Xw_3IoX4RSJ1ZDihAbxQ', 141.13, 455.56),
    'c05': ('zT0DZUF6QUl6xehtEvNO7A', 150.92, 459.02), 'c06': ('samV7pK2Gp6YxmFtTcXURA', 160.50, 462.81),
    'c07': ('3RFZNVMGKevbpFStDYFeZw', 170.01, 466.45), 'c08': ('e8s9Jq3BuvN0VcgJZs4jvw', 179.50, 469.78),
    'c09': ('NArBlnjMzN_ydF7e4b3zdA', 188.69, 473.87), 'c10': ('_0jcrnfj8Qjodr_3RWZLVw', 197.84, 478.05),
    'c11': ('11qM1hV4m3K4UKw2OxO-qg', 206.79, 481.78), 'c12': ('IG3vMqeaKX51bTLK5b29wQ', 216.00, 485.63),
    'c13': ('briJxJRe5ES99wJKMoO8VQ', 224.78, 489.30), 'c14': ('AHN0VC2fNHK73tjvXPSD5A', 239.79, 495.81),
    'c15': ('_d1czvBfIbVTaaQMdxKq4A', 245.32, 497.51), 'c16': ('FE9kNBt3_iuYmbUHIBmMPQ', 255.40, 501.30),
    'c17': ('OgE5F5zRrZHV4KGtFHaA1A', 265.00, 505.11), 'c18': ('rPqWgh_PR3rcQqPixKmOCw', 274.41, 508.95),
    'c19': ('s2MSczvzfrgUAeDjdfur3Q', 283.76, 512.81), 'c20': ('H8trUMQZZCwoiRsxDUl32w', 293.01, 516.80),
}
# the park's own line, March 2013
WALK = {
    'p01': ('9e-igsJ1saav-CIw1Ykhww', 131.68, 441.80), 'p02': ('5EzB-OVuJmNRZdKlq88Udg', 141.90, 440.69),
    'p03': ('O4KeNk9G_WZalnTa4DEWSQ', 153.39, 445.29), 'p04': ('G-uGIlTZk02lfSL7XlAQKw', 162.51, 448.80),
    'p05': ('pJRjYD5Gdr8m66F-qUjnyg', 171.63, 452.25), 'p06': ('pn30DX_vsl1x9zxRrQsd9g', 180.79, 455.78),
    'p07': ('Rb22K6_Agf2CMQUyqS8xYA', 190.08, 459.54), 'p08': ('sBxPBRPGvpHKv7HnEjgXkw', 199.74, 463.45),
    'p09': ('9xXhOLuf4aI_dVhdRxSYiw', 209.46, 467.20), 'p10': ('3xLfKbI5-3s8TrxIM2YbFw', 219.04, 470.46),
    'p11': ('lIGI54o-BrTGqFb3b_VlQQ', 228.35, 474.04), 'p12': ('YgeLJcXjcui4tLzObQs0AA', 242.63, 479.65),
    'p13': ('z-nBXSUpekFN-l4OtFXTLA', 247.56, 481.69), 'p14': ('-n5-SLCZXUDzPds-xwBASA', 256.83, 485.25),
    'p15': ('CIArmJTqQDSoqJ2P2fhg-w', 265.78, 488.85), 'p16': ('FhyIVFZOkbslh0znRv4yFA', 277.01, 494.11),
}
ALONG = 110.5                       # (the park's heading eastwards; westwards is +180, its north side -90)
SHOTS = []                          # (name, (panorama, x, z, heading, pitch, fov))
for k, (pid, x, z) in CAR.items():
    SHOTS.append((k + '_n', (pid, x, z, ALONG - 75, 3, 90)))
for k in ('c02', 'c03', 'c08', 'c13', 'c17'):
    pid, x, z = CAR[k]
    SHOTS.append((k + '_e', (pid, x, z, ALONG - 25, 3, 90)))
for k, (pid, x, z) in WALK.items():
    SHOTS.append((k + '_e', (pid, x, z, ALONG, 3, 90)))
    SHOTS.append((k + '_n', (pid, x, z, ALONG - 90, 3, 90)))
    SHOTS.append((k + '_s', (pid, x, z, ALONG + 90, 3, 90)))
    SHOTS.append((k + '_d', (pid, x, z, ALONG + 30, -35, 90)))      # (the paving, at the feet)
for k in ('p03', 'p08', 'p13', 'p16'):
    pid, x, z = WALK[k]
    SHOTS.append((k + '_w', (pid, x, z, ALONG + 180, 3, 90)))

if __name__ == '__main__':
    out = sys.argv[1]
    only = set(sys.argv[2:])
    os.makedirs(out, exist_ok=True)
    path = os.path.join(out, 'views.json')
    views = json.load(open(path)) if os.path.exists(path) else {}
    for name, (pid, x, z, h, p, fov) in SHOTS:
        if only and name not in only and name.split('_')[0] not in only:
            continue
        h = h % 360
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
