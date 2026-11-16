"""The Street View pictures the MasAhorro (the user's name for the supermarket of the Calle de la Noria, 17 November
2026) was measured from: from the Calle de la Noria on its east side, the Calle de las Viñas on the north (over its car
park) and the lane on the south. Fetches them (they are Google's: NOT kept in the repository, only this list) and
writes views.json beside them.

    python tools/masahorro/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map, the point of the map it looks at, pitch (up +), horizontal field of view.
Every camera round it: python tools/molino/panos.py cerca YmBTdwUn0TAT6W6cEsHEXw 35 530 75
                  and python tools/molino/panos.py cerca c-ihUBCd62tZq8WM313qMg 55 440 50
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

C = {   # November 2024
    # the Calle de la Noria, from the north
    'nb': ('9jrDHsP_t5LhMDivWBbzzg', 81.73, 462.76), 'na': ('zgHimZ1bhREe3ErwVHVbwQ', 78.21, 472.52),
    'nc': ('c-ihUBCd62tZq8WM313qMg', 74.81, 481.97), 'nd': ('FTIC0N9T38rlVe2p7YZo0Q', 71.47, 491.34),
    'ne': ('ftuO3JSvo1BefzyBijVvzw', 68.30, 500.61), 'nf': ('3cprML_geeUVL0AifJwpVQ', 64.31, 512.16),
    'ng': ('D1VjcNKdXQFgF_Dbosuc8g', 62.22, 519.92), 'nh': ('YmBTdwUn0TAT6W6cEsHEXw', 58.57, 528.77),
    'ni': ('q8UU4vO7j8EVqLh8puHKWg', 55.21, 538.09), 'nj': ('2AtgeAvne_E924e_kqOCpA', 52.66, 548.24),
    'nk': ('aWyaZQyVSUr5LahZm8ekqQ', 51.38, 552.91),
    # the branch east, opposite the shop's south end
    'ea': ('1mIMvfJlaldy57G6RfLXlA', 76.99, 518.97), 'eb': ('pZ99Q8S1Ms7O5_VyuuBiyQ', 86.67, 522.75),
    # the lane on the south, from the east
    'sa': ('VAIEwV1qsZpAhsScII3PGg', 32.82, 568.93), 'sb': ('-58pk7AQxlqAxBlU1s0jNg', 21.75, 568.79),
    'sc': ('4zEtktOTPLuUUPUY2XvA2Q', 11.41, 567.99), 'sd': ('KA9Jh_EbUCvjp70UsLIhCg', 1.53, 566.73),
    # the Calle de las Viñas, over the car park
    'va': ('6MXeaR5SEZr7iP4rxvYjAg', 43.39, 426.90), 'vb': ('vkPhPebCxyAs2SRda5Z8gQ', 61.32, 427.92),
    'vc': ('M4sjwcjonN1lCPCexgUoEA', 70.91, 430.39),
}
SHOTS = [
    # a first look all round
    ('va_aparca', C['va'], (50.0, 480.0), 2, 80), ('vb_aparca', C['vb'], (50.0, 480.0), 2, 80), ('vc_aparca', C['vc'], (45.0, 480.0), 2, 80),
    ('nb_norte', C['nb'], (40.0, 500.0), 2, 80), ('na_norte', C['na'], (40.0, 505.0), 2, 80), ('nc_norte', C['nc'], (40.0, 507.0), 3, 80),
    ('nd_entrada', C['nd'], (40.0, 507.0), 4, 80), ('ne_esquina', C['ne'], (45.0, 510.0), 4, 90),
    ('nf_este', C['nf'], (40.0, 522.0), 6, 90), ('ng_este', C['ng'], (40.0, 528.0), 6, 90), ('nh_este', C['nh'], (35.0, 535.0), 6, 90),
    ('ni_este', C['ni'], (35.0, 545.0), 6, 90), ('nj_este', C['nj'], (32.0, 555.0), 6, 90), ('nk_sur', C['nk'], (30.0, 565.0), 4, 90),
    ('ea_este', C['ea'], (40.0, 530.0), 4, 80), ('eb_este', C['eb'], (40.0, 535.0), 4, 70),
    ('sa_sur', C['sa'], (30.0, 545.0), 10, 100), ('sb_sur', C['sb'], (25.0, 545.0), 10, 100), ('sc_sur', C['sc'], (25.0, 550.0), 8, 100),
    ('sd_sur', C['sd'], (25.0, 555.0), 6, 90),
    # the front, from afar but square on (over the car park, from the Calle de las Viñas), zoomed
    ('vb_frente', C['vb'], (40.0, 513.0), 2, 30), ('vc_frente', C['vc'], (40.0, 513.0), 2, 30), ('va_frente', C['va'], (40.0, 513.0), 2, 30),
    ('vb_puerta', C['vb'], (33.0, 511.0), 3, 14), ('vc_puerta', C['vc'], (33.0, 511.0), 3, 14),
    # the way in, closer, from the Noria
    ('nc_puerta', C['nc'], (33.0, 511.0), 4, 40), ('nd_puerta', C['nd'], (33.0, 511.0), 4, 40), ('ne_puerta', C['ne'], (33.0, 511.0), 4, 40),
    ('nf_puerta', C['nf'], (40.0, 512.0), 4, 50), ('ne_rotulo', C['ne'], (38.0, 513.0), 14, 30),
    # its west end (the cream bay, the yellow pier, the grey gate) and what stands in the car park
    ('nd_oeste', C['nd'], (28.8, 509.7), 3, 16), ('nc_oeste', C['nc'], (28.8, 509.7), 3, 16), ('vc_oeste', C['vc'], (28.8, 509.7), 2, 8),
    ('vb_oeste', C['vb'], (28.8, 509.7), 2, 8), ('vc_carros', C['vc'], (48.0, 486.0), -2, 16), ('vb_carros', C['vb'], (48.0, 486.0), -2, 16),
    ('nd_bicis', C['nd'], (46.0, 514.0), -6, 30), ('vc_cargadores', C['vc'], (25.0, 480.0), 0, 30), ('na_cargadores', C['na'], (28.0, 470.0), 0, 40),
    # square on to the side wall, looking down: how far the wall is from the camera (the angle to its foot)
    ('ng_suelo', C['ng'], (62.22 - 0.949 * 10, 519.92 - 0.316 * 10), -25, 90), ('nh_suelo', C['nh'], (58.57 - 0.949 * 10, 528.77 - 0.316 * 10), -25, 90),
    ('ni_suelo', C['ni'], (55.21 - 0.949 * 10, 538.09 - 0.316 * 10), -25, 90),
    ('vb_entrada', C['vb'], (55.0, 445.0), -12, 70), ('va_entrada', C['va'], (52.0, 440.0), -10, 80), ('nb_farolas', C['nb'], (45.0, 465.0), 15, 70),
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
    for yaw in (range(0, 360, 45) if SPHERE else ()):                   # a private 360 picture, all round
        f = os.path.join(out, 'esfera_%03d.jpg' % yaw)
        if (not only or 'esfera' in only) and not os.path.exists(f):
            try:
                open(f, 'wb').write(urllib.request.urlopen(urllib.request.Request('%s=w1024-h640-k-no-pi-5-ya%d-ro0-fo80' % (SPHERE, yaw), headers=panos.UA), timeout=40).read())
            except Exception as e:
                print('  could not fetch the sphere at', yaw, e)
    json.dump(views, open(path, 'w'), indent=0)
    print(len(views), 'views in', out)
