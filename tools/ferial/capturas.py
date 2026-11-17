"""The Street View pictures the fairground and market ("Recinto ferial y mercadillo"; the user, 17 November 2026: "Son
una entrada con fuente, una entrada con columnas con enredaderas, y tres caminos asfaltados con aceras amplias") is
measured from. They are Google's: NOT kept in the repository, only this list. Writes views.json beside them.

    python tools/ferial/capturas.py OUT_FOLDER [name ...]

Google's car went in along its paths in March 2013; in November 2024 only round it (the road on its east, the street on
its north). Every camera round it: python tools/molino/panos.py cerca YmBTdwUn0TAT6W6cEsHEXw 160 600 90
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

C = {
    # 2024, round it
    'e1': ('ue7FhcFvJ0vYxCSQbZtB5Q', 205.80, 570.85), 'e2': ('LKqMsZWGoscA0tCp0epnlA', 202.63, 580.33), 'e3': ('3HIlUsaYjrchUc05i_NX0Q', 199.43, 589.79),
    'e4': ('vI5WPSPDIlrK-CgydW9DPA', 196.27, 599.20), 'e5': ('-SCuegeMnENvO6iUKOzduw', 193.22, 609.38), 'e6': ('Lg0KAJ5VVgggz4m-8pW2kg', 191.02, 618.83),
    'e0': ('WcW0aFCGdBue9fjIMeclhg', 209.07, 560.81), 'n1': ('qrFkRpCvmi0IrhjhDwYUfw', 127.31, 527.82), 'n0': ('jfCswC32R-0FEJQ9mbadFw', 115.35, 530.63),
    'ne': ('eZdHUaBm49e-Ifl9DTNCxQ', 213.12, 545.53),
    # 2013, inside
    'f1': ('khxrxSkjKEZkAq7_72z13w', 158.47, 586.17), 'f2': ('vIplOLk2d3w_BMlLdSByZA', 152.01, 593.17), 'f3': ('GBijdSjXL1R5iTpgp7zOQg', 166.94, 587.99),
    'f4': ('Rka2EKTnWTYaDNpPTsMFKg', 151.81, 605.13), 'nn': ('l_6HacjdGWQcZrzMWBN4tQ', 172.62, 568.21), 'nn2': ('0TNpzaPOOIK2TJBCu_7K5Q', 175.00, 559.09),
    'w1': ('jdFXzfyWH9ub5r5ZrP9Eqg', 130.05, 605.65), 'w3': ('j8EeFMhjZ6YjjbkVvdTtIA', 119.26, 634.09), 'w5': ('enLZpS2NqydlYi3o-xH81g', 106.69, 661.58),
    'm2': ('3BLeSDJilFQ3OYbItYqTrg', 145.17, 627.58), 'm4': ('86pwt7ACoGuMXegdXe2NLw', 129.23, 666.86), 'x2': ('SpGJwWSijqQpbb2D9XO_hg', 170.79, 633.53),
    'x4': ('K61KhodwNiJSXEka2eQUbA', 151.92, 680.59), 'o2': ('CHC9JemikEjwqvAWz7aCyw', 184.46, 641.16), 'o4': ('KyDDpPyCoIXFY2W92dDLzw', 170.73, 687.10),
    'g1': ('-M1VHm8R6s8x5E4g6bB8xg', 141.26, 589.01), 'g2': ('RE2yN24ncKWaDq2b-GqxgQ', 134.30, 595.91),
}
FOUNTAIN = (155.3, 595.0)

SHOTS = [
    # the east road, 2024: looking in
    ('e1', C['e1'], (180.0, 575.0), 6, 100), ('e2', C['e2'], (176.0, 585.0), 6, 100), ('e3', C['e3'], (172.0, 592.0), 6, 100),
    ('e4', C['e4'], (170.0, 600.0), 6, 100), ('e5', C['e5'], (168.0, 612.0), 6, 100), ('e6', C['e6'], (160.0, 630.0), 6, 100),
    ('e0', C['e0'], (180.0, 555.0), 6, 100), ('ne', C['ne'], (180.0, 560.0), 4, 90),
    ('n1', C['n1'], (140.0, 560.0), 6, 100), ('n0', C['n0'], (125.0, 560.0), 6, 100),
    # inside, 2013
    ('f1', C['f1'], FOUNTAIN, -4, 90), ('f2', C['f2'], FOUNTAIN, -4, 90), ('f3', C['f3'], FOUNTAIN, -4, 90), ('f4', C['f4'], FOUNTAIN, -4, 90),
    ('f1_n', C['f1'], (175.0, 545.0), 4, 100), ('nn', C['nn'], (180.0, 540.0), 6, 100), ('nn_s', C['nn'], FOUNTAIN, 0, 90), ('nn2', C['nn2'], (182.0, 540.0), 6, 100),
    ('w1', C['w1'], (110.0, 660.0), 2, 90), ('w3', C['w3'], (100.0, 690.0), 2, 90), ('w5', C['w5'], (120.0, 710.0), 2, 90),
    ('m2', C['m2'], (120.0, 700.0), 2, 90), ('m4', C['m4'], (155.0, 600.0), 2, 90), ('x2', C['x2'], (150.0, 690.0), 2, 90),
    ('x4', C['x4'], (175.0, 610.0), 2, 90), ('o2', C['o2'], (200.0, 620.0), 4, 100), ('o4', C['o4'], (185.0, 640.0), 4, 90),
    ('g1', C['g1'], (125.0, 570.0), 4, 100), ('g2', C['g2'], (110.0, 600.0), 4, 100), ('w1_e', C['w1'], (160.0, 615.0), 2, 100),
    # the arches of ivy at the north end: from the street north of it (2013), from inside, close
    ('a1', ('FjHs-kKRBiMA07HLQHZHVw', 174.06, 537.75), (178.0, 556.0), 6, 100), ('a2', ('hQ0WfprNZRFsQ5QbSJ2XWg', 186.75, 543.83), (180.0, 560.0), 6, 100),
    ('a3', ('dlB8CL1d_lfC1BlYzwfP8A', 163.08, 536.18), (178.0, 552.0), 6, 100), ('a4', ('mKNMEKhvjzycZIgR8gvygg', 197.38, 547.16), (180.0, 556.0), 6, 100),
    ('a5', ('fqWTjULqiLuPooSgxw4BpA', 178.21, 549.60), (195.0, 552.0), 8, 100), ('a6', ('fqWTjULqiLuPooSgxw4BpA', 178.21, 549.60), (162.0, 548.0), 8, 100),
    ('a7', C['nn2'], (182.0, 545.0), 10, 60), ('p1', C['nn'], (195.0, 580.0), 10, 100), ('p2', C['e3'], (180.0, 588.0), 14, 100),
    # the park north of it, from the Paseo del Cristo and the Calle de la Huerta (2024; the user, 17 Nov: "te faltaría la
    # parte que se ve desde Paseo de Cristo")
    ('q1', ('e8s9Jq3BuvN0VcgJZs4jvw', 179.50, 469.78), (185.0, 495.0), 6, 100), ('q2', ('NArBlnjMzN_ydF7e4b3zdA', 188.69, 473.87), (195.0, 495.0), 6, 100),
    ('q3', ('_0jcrnfj8Qjodr_3RWZLVw', 197.84, 478.05), (197.0, 500.0), 8, 110), ('q4', ('11qM1hV4m3K4UKw2OxO-qg', 206.79, 481.78), (198.0, 500.0), 6, 100),
    ('q5', ('IG3vMqeaKX51bTLK5b29wQ', 216.00, 485.63), (200.0, 500.0), 6, 100), ('q3_f', ('_0jcrnfj8Qjodr_3RWZLVw', 197.84, 478.05), (197.0, 489.0), -8, 70),
    ('h1', ('wffpdT-gF2ohXHsfhopMXA', 229.73, 496.74), (205.0, 505.0), 6, 100), ('h2', ('3uRHyhSw2AgzGhUZWrn40Q', 226.80, 507.56), (205.0, 515.0), 6, 100),
    ('h3', ('SbxAI3gLQdOw14laa0F1og', 223.34, 517.47), (200.0, 525.0), 6, 100), ('q1_w', ('e8s9Jq3BuvN0VcgJZs4jvw', 179.50, 469.78), (165.0, 500.0), 6, 100),
    ('q3_13', ('JVJqMXYK_URvdugGfWVZbA', 197.84, 478.05), (197.0, 500.0), 8, 110), ('q5_13', ('qYzXk1wVl43U1ySGUeZong', 216.00, 485.63), (200.0, 500.0), 6, 100),
    # the park from the fairground's street, south of it (2013), looking north
    ('s1', C['nn2'] if False else ('dlB8CL1d_lfC1BlYzwfP8A', 163.08, 536.18), (175.0, 515.0), 8, 100), ('s2', ('FjHs-kKRBiMA07HLQHZHVw', 174.06, 537.75), (185.0, 515.0), 8, 100),
    ('s3', ('hQ0WfprNZRFsQ5QbSJ2XWg', 186.75, 543.83), (195.0, 520.0), 8, 100), ('s4', ('mKNMEKhvjzycZIgR8gvygg', 197.38, 547.16), (200.0, 520.0), 8, 100),
    ('s5', ('eZdHUaBm49e-Ifl9DTNCxQ', 213.12, 545.53), (195.0, 530.0), 8, 100),
    # the public toilets north of the auditorium and the auditorium itself (the user, 17 Nov 2026: "el auditorio (en verde) y
    # los baños públicos (en rojo)")
    ('w1t', ('dlB8CL1d_lfC1BlYzwfP8A', 163.08, 536.18), (149.0, 529.0), 8, 90), ('w2t', ('FjHs-kKRBiMA07HLQHZHVw', 174.06, 537.75), (151.0, 530.0), 6, 70),
    ('w3t', ('qrFkRpCvmi0IrhjhDwYUfw', 127.31, 527.82), (150.0, 530.0), 6, 70), ('w4t', ('jfCswC32R-0FEJQ9mbadFw', 115.35, 530.63), (148.0, 531.0), 4, 55),
    ('w5t', ('dlB8CL1d_lfC1BlYzwfP8A', 163.08, 536.18), (155.0, 531.0), 6, 60),
    ('u1', ('-M1VHm8R6s8x5E4g6bB8xg', 141.26, 589.01), (145.0, 560.0), 6, 100), ('u2', ('RE2yN24ncKWaDq2b-GqxgQ', 134.30, 595.91), (140.0, 560.0), 6, 100),
    ('u3', ('jdFXzfyWH9ub5r5ZrP9Eqg', 130.05, 605.65), (138.0, 570.0), 6, 90), ('u4', ('Rka2EKTnWTYaDNpPTsMFKg', 151.81, 605.13), (145.0, 572.0), 6, 90),
    ('u5', ('l_6HacjdGWQcZrzMWBN4tQ', 172.62, 568.21), (150.0, 560.0), 6, 100), ('u6', ('dlB8CL1d_lfC1BlYzwfP8A', 163.08, 536.18), (158.0, 560.0), 6, 100),
    ('u7', ('0TNpzaPOOIK2TJBCu_7K5Q', 175.00, 559.09), (150.0, 566.0), 6, 100), ('u8', ('GBijdSjXL1R5iTpgp7zOQg', 166.94, 587.99), (148.0, 570.0), 6, 100),
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
