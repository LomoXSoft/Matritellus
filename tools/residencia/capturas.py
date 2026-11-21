"""The Street View pictures the old people's home of the Cristo del Prado is built from (the user, 21 November 2026, after
the hermitage: "After these fixes we can continue with the rest of the apple"). Its block is the hermitage's, between
the two arms of the Calle del Cristo, the Travesía del Cristo and the Paseo. The pictures are Google's: NOT kept in the
repository, only this list. Writes views.json beside them.

    python tools/residencia/capturas.py OUT_FOLDER [name ...]

Every camera: python tools/molino/panos.py cerca HFTSREh-4cD5ixATO9UNJQ 305 445 45 (the west arm only in March 2013).
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

# name: (panorama, x, z, target x, target z, pitch, fov)
C = {
    # the east arm of the Calle del Cristo, from the Paseo northwards
    'e1': ('KiEP0wmXn1VWFet62qZLWA', 335.65, 486.78, 322.0, 478.0, 12, 90),
    'e2': ('3FtHVefyXwzvG6SDU-rmig', 332.88, 476.79, 320.0, 470.0, 12, 90),
    'e3': ('HFTSREh-4cD5ixATO9UNJQ', 330.15, 467.03, 318.0, 462.0, 12, 90),
    'e4': ('7tvw82odCLneq_OL2IMw3g', 328.13, 457.26, 316.0, 452.0, 12, 90),
    'e5': ('imovFldaAuKAaj1saAu8kg', 328.11, 447.38, 312.0, 444.0, 12, 90),
    'e6': ('bE-RlfSZ1meFfa6Fy8TD9g', 328.73, 436.97, 310.0, 440.0, 12, 90),
    'e3_19': ('kv6q5tUbI7QsHqTCKUiU8A', 330.15, 467.03, 318.0, 462.0, 12, 90),
    'e3_13': ('pHi0Naso9c51tjyPMDjP5g', 330.15, 467.03, 318.0, 462.0, 12, 90),
    # the north end, on the Travesía del Cristo
    'n1': ('u-cJ9CdGsglHg1uNHDEmFA', 319.51, 437.39, 305.0, 440.0, 12, 90),
    'n2': ('4henVzynQ8B_e57Nra8N7A', 314.26, 429.77, 305.0, 440.0, 12, 90),
    'n3': ('oBOasshY6HtGZHhbYWs7zQ', 300.74, 434.84, 306.0, 442.0, 12, 90),
    'n4': ('dEqHl_teQYhXHKRWM2w4UQ', 303.93, 427.46, 306.0, 440.0, 12, 90),
    # the west arm (2013)
    'w1': ('3cSKd1AAMpJ1wySLKI2Y6g', 297.45, 443.61, 306.0, 452.0, 12, 90),
    'w2': ('geiWeTCh0ZFJ4vcEDAWEiQ', 294.50, 453.33, 304.0, 460.0, 12, 90),
    'w3': ('jQLw-qPtLyA9cOk0M8keDg', 291.37, 463.07, 302.0, 470.0, 12, 90),
    'w4': ('9hBJj2p2fa3EZW-ZzFth4g', 288.82, 472.25, 298.0, 480.0, 12, 90),
    'w5': ('X3JgsFznit14x6ju4yl9ig', 285.54, 478.98, 296.0, 487.0, 12, 90),
    # the little square before the hermitage's front: the home's porch wing (2013)
    'p1': ('FhyIVFZOkbslh0znRv4yFA', 277.01, 494.11, 293.0, 483.0, 10, 90),
}
SHOTS = []
for k, c in C.items():
    SHOTS.append((k, c))
    if k in ('e2', 'e4', 'n1', 'w2', 'w4'):
        SHOTS.append((k + '_up', (c[0], c[1], c[2], c[3], c[4], 32, 80)))

if __name__ == '__main__':
    out = sys.argv[1]
    only = set(sys.argv[2:])
    os.makedirs(out, exist_ok=True)
    path = os.path.join(out, 'views.json')
    views = json.load(open(path)) if os.path.exists(path) else {}
    for name, (pid, x, z, tx, tz, p, fov) in SHOTS:
        if only and name not in only:
            continue
        h = math.degrees(math.atan2(tx - x, -(tz - z))) % 360
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
