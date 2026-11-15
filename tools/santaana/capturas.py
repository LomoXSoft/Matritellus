"""The Street View pictures the convent of Santa Ana (the Poor Clares', on the corner of the Calle de las Monjas and the
Calle de Santiago Apóstol) was measured from. Fetches them (they are Google's: NOT kept in the repository, only this
list) and writes views.json beside them.

    python tools/santaana/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, heading, pitch (up +), horizontal field of view. Places are Google's (tools/molino/panos.py cerca
HunZ4RQmngS_4PXutUbrOg -495 -58 75 lists every camera round the convent, with the older ones at each spot).
"""
import json, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

SQM = 284.6         # the heading that looks square at the convent's front on the Calle de las Monjas (it faces east)
SQS = 184.0         # ...and at its side on the Calle de Santiago Apóstol (it faces north)
PANO = {
    # Calle de las Monjas, November 2024, from south to north (the convent is on the west side)
    'M1': ('TJFDrk9NW5FSWsDtXlnMCA', -506.61, -4.61), 'M2': ('opBkmySaKr9tTExV0G-itw', -503.24, -14.89), 'M3': ('Xw9GRVJVvF3fUwmwMMyQ_w', -499.54, -25.84),
    'M4': ('45wx1b5IJ3hmiiaxDZwFWg', -496.52, -35.02), 'M5': ('WHguMaK9-qFtadU-8cJN9A', -493.10, -48.47), 'M6': ('VNruzd1DmNlg0zv-9CSIVA', -490.99, -58.21),
    'M7': ('MmpdrpBk5uToSc5Mtmz12Q', -489.05, -68.03), 'M8': ('Go2PAqzTx7e90DPlw-2F1A', -487.84, -78.85), 'M9': ('Gvo1Leii4Of4pefrZiPBGA', -487.78, -90.23),
    'M10': ('yg0GmczuLrEqYRqu4aKk_A', -488.30, -102.33),
    # the same street in March 2021, March 2013 and May 2009
    'M5_21': ('M18tODOkItA12szjhVltTw', -493.10, -48.47), 'M6_21': ('2EafPvipeYWUZwlgqJno7A', -490.99, -58.21), 'M7_21': ('5HsrxcJ9g7MiktE6NEbnvQ', -489.05, -68.03),
    'M5_13': ('IWzitwqpdaQ1zED6zRKlww', -493.10, -48.47), 'M7_13': ('DmXWlYYLueCtcO2yUlyz4g', -489.05, -68.03), 'M6_09': ('RefTQG_-VyiI4KWBkaTSEQ', -490.99, -58.21),
    # Calle de Santiago Apóstol, November 2024, from east to west (the convent is on the south side)
    'S1': ('NN9z01c8dmXsLDqz7iN4Jw', -503.13, -84.49), 'S2': ('DFlm05ChthIeKaEQE25tQQ', -513.77, -85.07), 'S3': ('6ipu7jHzjR0TGLC2i2Q8MA', -524.00, -84.67),
    'S4': ('313euw2J7gMQEq1wTBdyjg', -534.30, -84.46), 'S5': ('1GJ7nfpAaIpeYnJCTElpJw', -544.17, -86.12), 'S2_09': ('UOWxsVrDX6EnomWkSnBg_Q', -513.77, -85.07),
    # Calle de la Amargura, across the crossroads: the church's end from afar
    'A1': ('FIKcqv2kKm2TXiBv5tDVwA', -480.02, -90.28), 'A2': ('Z_HHtFV2ZeubLMQwZtxANg', -470.82, -90.72),
}
SHOTS = [(k + '_f', k, SQM, 14, 100) for k in ('M3', 'M4', 'M5', 'M6', 'M7', 'M8')] + [(k + '_alto', k, SQM, 40, 100) for k in ('M4', 'M5', 'M6', 'M7', 'M8')] + [
    ('M1_n', 'M1', 10, 12, 80), ('M2_n', 'M2', 5, 14, 90), ('M3_nw', 'M3', 330, 16, 100), ('M5_nw', 'M5', 325, 22, 100), ('M5_sw', 'M5', 235, 16, 100),
    ('M7_sw', 'M7', 230, 22, 100), ('M7_nw', 'M7', 320, 22, 100), ('M9_sw', 'M9', 225, 20, 100), ('M9_w', 'M9', 265, 16, 100), ('M10_sw', 'M10', 205, 16, 90),
    ('M5_21_f', 'M5_21', SQM, 14, 100), ('M6_21_f', 'M6_21', SQM, 14, 100), ('M7_21_f', 'M7_21', SQM, 14, 100), ('M5_13_f', 'M5_13', SQM, 14, 100), ('M7_13_f', 'M7_13', SQM, 14, 100), ('M6_09_f', 'M6_09', SQM, 14, 100),
    ('S1_f', 'S1', SQS, 16, 100), ('S2_f', 'S2', SQS, 16, 100), ('S3_f', 'S3', SQS, 16, 100), ('S4_f', 'S4', SQS, 16, 100), ('S5_f', 'S5', SQS, 14, 100),
    ('S1_alto', 'S1', SQS, 42, 100), ('S2_alto', 'S2', SQS, 42, 100), ('S1_e', 'S1', 95, 12, 90), ('S3_e', 'S3', 100, 14, 90), ('S5_e', 'S5', 95, 12, 80), ('S2_09_f', 'S2_09', SQS, 16, 100),
    ('A1_w', 'A1', 250, 18, 90), ('A2_w', 'A2', 262, 14, 70),
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
