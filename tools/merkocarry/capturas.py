"""The Street View pictures the Merkocarry (the user's name for the Merkocash of Madridejos, 17 November 2026) is
measured from, along its four streets: the Calle de Santa Ana (its narrow front), the Calle del Cristo (the warehouse
of 2020 and the shop's side), the Calle del Suspiro (the long side and the car park's gate) and the Calle de Magallanes
(the end of the car park and its shelter). They are Google's: NOT kept in the repository, only this list. Writes
views.json beside them.

    python tools/merkocarry/capturas.py OUT_FOLDER [name ...]

Each: name, panorama, where it stood on the map (Google's word for it), the point of the map it looks at, pitch (up +),
horizontal field of view. Every camera round it: python tools/molino/panos.py cerca bFJAVCn9O-iVi3jA0khWJg 452 150 40
(and from Zii0OFqXF3uCwsu75gEDvw on the Cristo, 6GEyCAYQVd9WzgSj6HrjwQ on the Suspiro, p_szQTPad6o7NpH0BNcxzg on Magallanes).
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

C = {   # November 2024 (and 2019 at some spots)
    'sa1': ('bYnc558jiqHsNT8eHBy7aA', 440.49, 143.75), 'sa2': ('bFJAVCn9O-iVi3jA0khWJg', 450.50, 145.54),
    'sa3': ('DVlTjlBNP9qwJXa7QlZ0dQ', 459.84, 147.65), 'sa4': ('eaKTGw5bZLB8l0nOj-vZ7w', 470.13, 149.70),
    'cr0': ('loNLbQRf70i7Zrh5OlYD-Q', 409.49, 171.41), 'cr1': ('-B1iW6ptDxqYHD1fE9pV_g', 405.48, 180.75),
    'cr2': ('SFnnBq8O60oxOK91dMEhbA', 401.25, 189.77), 'cr3': ('qU2xY6btFXqECbrXN_4jGg', 396.55, 198.63),
    'cr4': ('aveOb2G-b9mxxkd8vohyBA', 391.93, 207.24), 'cr5': ('Kde2-5N1dYxz4al5MNwOCg', 387.26, 216.23),
    'su0': ('6GEyCAYQVd9WzgSj6HrjwQ', 470.91, 181.07), 'su1': ('Cth7cGyUNNZPNvI18sIwgw', 466.08, 189.40),
    'su2': ('1hU-_iRO6VSFgtJw1b1CLg', 461.14, 198.02), 'su3': ('dSNFp-UwpPsJQD_lpVQfbA', 456.26, 206.67),
    'su4': ('CR1EO8VfEBkw3w9NSUz7_Q', 451.36, 215.56), 'su5': ('gywL-bUiWI22C_eHmtEflQ', 446.45, 224.66),
    'su6': ('KJT2-UFEjZ-PQDs7SBlRNA', 441.53, 233.65), 'su7': ('IltAhJbirn20-6mQLCdxOQ', 436.62, 242.33),
    'ma0': ('g54tZ1VQ6TNrDfVdmjgL4A', 385.39, 249.63), 'ma1': ('p4RqYpW-jwQYJoqp833nXQ', 404.27, 254.49),
    'ma2': ('z6fao6zF2J-pbHa-s139fA', 414.69, 256.62), 'ma3': ('fdyBmHl3sme2vkvl9F8Fdg', 426.57, 260.32),
    'ma4': ('p_szQTPad6o7NpH0BNcxzg', 431.66, 251.15),
    'sa2_19': ('XiMEMQJumq_vxMeG5V5xkg', 450.50, 145.54), 'su4_19': ('m6kUjmGPXCZ3cuFROwgIbg', 451.36, 215.56),
}
CR_IN = (0.9, 0.43)       # from the Cristo's middle into the block
SU_IN = (-0.874, -0.486)  # from the Suspiro's
MA_IN = (0.25, -0.97)     # from Magallanes'

def on(c, d, k=6.0):
    return (C[c][1] + d[0] * k, C[c][2] + d[1] * k)

SHOTS = [
    ('sa1', C['sa1'], (453.0, 156.0), 10, 80), ('sa2', C['sa2'], (452.0, 157.0), 14, 100), ('sa3', C['sa3'], (452.0, 156.0), 10, 80),
    ('sa4', C['sa4'], (452.0, 156.0), 8, 70), ('sa2_alto', C['sa2'], (452.0, 157.0), 30, 90), ('sa2_19', C['sa2_19'], (452.0, 157.0), 14, 100),
    ('cr0', C['cr0'], on('cr0', CR_IN), 12, 100), ('cr1', C['cr1'], on('cr1', CR_IN), 12, 100), ('cr2', C['cr2'], on('cr2', CR_IN), 12, 100),
    ('cr3', C['cr3'], on('cr3', CR_IN), 12, 100), ('cr4', C['cr4'], on('cr4', CR_IN), 12, 100), ('cr0_lejos', C['cr0'], (398.0, 205.0), 6, 70),
    ('cr5_lejos', C['cr5'], (410.0, 178.0), 6, 70),
    # wide and square on (the Cristo is narrow: from its middle the wall is three or four metres off)
    ('cr0_w', C['cr0'], on('cr0', CR_IN), 18, 120), ('cr1_w', C['cr1'], on('cr1', CR_IN), 18, 120), ('cr2_w', C['cr2'], on('cr2', CR_IN), 18, 120),
    ('cr3_w', C['cr3'], on('cr3', CR_IN), 18, 120), ('cr4_w', C['cr4'], on('cr4', CR_IN), 18, 120), ('cr5_w', C['cr5'], on('cr5', CR_IN), 18, 120),
    ('su1', C['su1'], on('su1', SU_IN), 12, 100), ('su2', C['su2'], on('su2', SU_IN), 12, 100), ('su3', C['su3'], on('su3', SU_IN), 12, 100),
    ('su4', C['su4'], on('su4', SU_IN), 12, 100), ('su5', C['su5'], on('su5', SU_IN), 12, 100), ('su6', C['su6'], on('su6', SU_IN), 12, 100),
    ('su7', C['su7'], on('su7', SU_IN), 12, 100), ('su0_lejos', C['su0'], (445.0, 225.0), 5, 70), ('su7_lejos', C['su7'], (462.0, 195.0), 5, 70),
    ('su4_19', C['su4_19'], on('su4', SU_IN), 12, 100),
    ('ma1', C['ma1'], on('ma1', MA_IN), 12, 100), ('ma2', C['ma2'], on('ma2', MA_IN), 12, 100), ('ma3', C['ma3'], on('ma3', MA_IN), 12, 100),
    ('ma4', C['ma4'], (418.0, 238.0), 8, 90), ('ma0_lejos', C['ma0'], (425.0, 252.0), 5, 70),
    # the nave of the Mayordomía beside it on the Cristo (4790711, of 2020: the user, 17 Nov, "es otro edificio distinto")
    ('my_frente', C['cr0'], (413.5, 174.2), 15, 110), ('my_alto', C['cr0'], (413.5, 174.2), 40, 100),
    ('my_norte', ('Zii0OFqXF3uCwsu75gEDvw', 416.86, 151.89), (412.4, 174.2), 8, 60), ('my_sur', C['cr1'], (413.0, 172.0), 10, 70),
    ('my_sur2', C['cr2'], (413.0, 172.0), 8, 55), ('my_puerta', C['cr0'], (412.2, 176.0), 6, 70),
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
