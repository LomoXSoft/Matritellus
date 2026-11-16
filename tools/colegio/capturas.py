"""The Street View pictures the old school of the Avenida de Juan Carlos I ("el viejo colegio", the user's words) was
measured from. Fetches them (they are Google's: NOT kept in the repository, only this list) and writes views.json
beside them.

    python tools/colegio/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, the point of the map it looks at, pitch (up +), horizontal field of view.
Every camera round it: python tools/molino/panos.py cerca nqFJDD-6qHoodVtdivBnnA -408 122 52.
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

MID = (-409.0, 110.0)       # the middle of the building
TOWER = (-424.0, 118.0)     # its south-west corner
EAST = (-392.0, 110.0)      # the end of its east wing
YARD = (-405.0, 128.0)      # the court before it
JA = ('41ugvVZeyz6FnHoiqrrR1w', -435.22, 156.01)     # the Avenida de Juan Carlos I, west to east
JB = ('nOd4Cnp722SeEYuYvCVw1g', -425.30, 153.72)
JC = ('-AD5_Ik3FFcKccHw64nf1A', -413.78, 153.26)
JD = ('nqFJDD-6qHoodVtdivBnnA', -403.63, 146.98)
JE = ('35nr4J6pV1-ZJUkXj36g-w', -393.76, 145.37)
JF = ('ny6Grc9ti1nOvpUveTTYPA', -383.36, 143.97)
JG = ('B-5g4cJu0BhJcA1CTCw7cA', -373.19, 142.54)
PA = ('BRPJt1JJGd20eHnU9j6PhQ', -426.69, 139.29)     # the Calle del Peso, south to north
PB = ('TM_ZewncPIbjD597vlos7A', -429.15, 128.98)
PC = ('OhnXwDZzF-a7oZcJPKG-Bg', -432.55, 119.41)
PD = ('4qZzhIchkDGRe1QgUP5XNQ', -435.81, 110.97)
PE = ('HunZ4RQmngS_4PXutUbrOg', -446.43, 103.61)
SA = ('Bdmg3WSDc90CrA_2RBun4A', -380.72, 132.17)     # the Calle de Santa Clara, south to north
SB = ('T8-O9pVNrbXGVZHIgGtinA', -382.00, 122.92)
SC = ('z1v5y_XT_OQqGN69zK-CZg', -383.61, 112.93)
SD = ('WH2P-k7gMRvoWXeIkLKzOg', -385.49, 102.84)
SE = ('xFdIz24tMXGKgNn5PJtfUw', -387.79, 92.79)
SF = ('A3_S3r3VW3-aGU0QAT3klg', -390.30, 82.96)
J13B = ('pp-LSLplLRjwp097_6ZaIA', -425.30, 153.72)       # March 2013 from the avenue
J13C = ('U19TDBF8W-v2Y512Mrxtzw', -413.78, 153.26)
J13D = ('q00OBA_FowMJPtiE-RYo8w', -403.63, 146.98)
J13E = ('vgskYnP2KxZVtmJB29bvYw', -393.76, 145.37)
SHOTS = [      # November 2024
    ('ja', JA, TOWER, 10, 60), ('jb', JB, MID, 10, 80), ('jb_torre', JB, TOWER, 16, 50), ('jc', JC, MID, 10, 90), ('jc_torre', JC, TOWER, 18, 45), ('jc_este', JC, EAST, 10, 50),
    ('jd', JD, MID, 10, 95), ('jd_alto', JD, MID, 28, 80), ('jd_torre', JD, TOWER, 16, 40), ('jd_centro', JD, (-411.0, 115.0), 8, 45), ('jd_este', JD, EAST, 12, 45), ('jd_verja', JD, (-405.0, 138.0), -6, 100),
    ('je', JE, MID, 10, 90), ('je_este', JE, EAST, 14, 55), ('je_torre', JE, TOWER, 12, 40), ('jf', JF, (-405.0, 115.0), 10, 75), ('jg', JG, (-400.0, 118.0), 8, 55),
    ('pa', PA, TOWER, 18, 70), ('pa_patio', PA, YARD, 4, 90), ('pa_fondo', PA, MID, 10, 60), ('pb', PB, (-427.0, 115.0), 22, 100), ('pb_patio', PB, (-405.0, 120.0), 6, 90), ('pb_alto', PB, (-425.0, 117.0), 45, 90),
    ('pc', PC, (-428.0, 114.0), 25, 110), ('pc_norte', PC, (-431.0, 100.0), 12, 90), ('pc_sur', PC, (-425.0, 126.0), 10, 90), ('pd', PD, (-428.0, 113.0), 22, 100), ('pd_norte', PD, (-424.0, 100.0), 14, 90), ('pe', PE, (-428.0, 113.0), 12, 60),
    ('sa', SA, EAST, 14, 70), ('sa_patio', SA, YARD, 4, 90), ('sa_fondo', SA, MID, 10, 60), ('sb', SB, (-391.0, 110.0), 20, 100), ('sb_frente', SB, (-410.0, 115.0), 10, 80), ('sb_alto', SB, (-391.0, 108.0), 42, 90),
    ('sc', SC, (-390.0, 103.0), 25, 110), ('sc_sur', SC, (-392.0, 116.0), 12, 90), ('sd', SD, (-391.0, 100.0), 25, 110), ('sd_alto', SD, (-391.0, 100.0), 45, 100), ('se', SE, (-393.0, 98.0), 25, 110), ('se_sur', SE, (-389.5, 108.0), 14, 80),
    ('sf', SF, (-394.0, 93.0), 16, 80),
    # the same spots before: October 2019, March 2013, October 2012, May 2009
    ('jd19', ('pTN-bFh6-GSX-ehwHW5Vug', -403.63, 146.98), MID, 10, 95), ('jd13', ('q00OBA_FowMJPtiE-RYo8w', -403.63, 146.98), MID, 10, 95), ('jd12', ('eu8cKs6CIw_uT0qBy70X4w', -403.63, 146.98), MID, 10, 95),
    ('jd09', ('SwWtS0yAXAV1SHQXC5gWqQ', -403.63, 146.98), MID, 10, 95), ('jb13', ('pp-LSLplLRjwp097_6ZaIA', -425.30, 153.72), MID, 10, 80), ('je13', ('vgskYnP2KxZVtmJB29bvYw', -393.76, 145.37), MID, 10, 90),
    # March 2013, the trees bare: the south front whole (what the openings were measured on)
    ('jd13_centro', J13D, (-411.0, 115.0), 8, 45), ('jd13_torre', J13D, TOWER, 16, 40), ('jd13_este', J13D, EAST, 12, 45), ('jd13_alto', J13D, MID, 28, 80), ('jd13_puerta', J13D, (-408.0, 114.9), 6, 22),
    ('jc13', J13C, MID, 10, 90), ('jc13_torre', J13C, TOWER, 18, 45), ('jc13_centro', J13C, (-408.0, 114.9), 8, 45), ('je13_este', J13E, EAST, 14, 55), ('je13_torre', J13E, TOWER, 12, 40), ('je13_centro', J13E, (-408.0, 114.9), 8, 45),
    ('jb13_torre', J13B, TOWER, 16, 50), ('jf13', ('Za4L8JsutKBIgabMP2RUcg', -383.36, 143.97), (-405.0, 115.0), 10, 75),
    ('pb09', ('Hawm_QuHxHwql9QpKIVhPw', -429.15, 128.98), (-427.0, 115.0), 22, 100), ('sb19', ('BxSbLdP0WubZn_cn1SHQpA', -382.00, 122.92), (-391.0, 110.0), 20, 100), ('sb09', ('dbmCrhORj2uavB6W_TlC8A', -382.00, 122.92), (-391.0, 110.0), 20, 100),
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
