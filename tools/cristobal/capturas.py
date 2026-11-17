"""The Street View pictures the little hermitage of San Cristóbal is built from (the user, 17 November 2026: "Ahora la
hermita de san Cristóbal. Una pequeña hermita hecha por ciudadanos del pueblo que hace esquina con Ortega y Gasset y
Carretera antigua Madrid Cádiz"). They are Google's: NOT kept in the repository, only this list. Writes views.json.

    python tools/cristobal/capturas.py OUT_FOLDER [name ...]

Google's car went up the old road (the N-IVa) in November 2024, March 2021, October 2019, September 2015, March 2013,
September 2012 and May 2009 at the same spots; along the Calle de Ortega y Gasset, past its front, in March 2013 and
May 2009. Every camera round it: python tools/molino/panos.py cerca C9_kb9AtgaA2vqN-rYUgbw 432 -980 45
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

# the old road, east of it: 2024, 2021, 2015, 2009 at each spot
R = {'r1': ('NV6DNym8mEx_rfcjtW9pWQ', 461.18, -982.65), 'r1_21': ('EMFdFdy_lDwEQGjo1wHcbQ', 461.18, -982.65), 'r1_15': ('37G1POEJmkIqSzduZnMemw', 461.18, -982.65),
     'r1_09': ('DaQ9qAIK2s86nSSNF49p8A', 461.18, -982.65),
     'r2': ('p6Zyxz1LZl25rQIr6HiH_Q', 457.31, -991.76), 'r2_21': ('Phy7oyxwY2-FTmENpIbPnQ', 457.31, -991.76), 'r2_09': ('2pYnehHcGKDWBp6Yy_Sy1A', 457.31, -991.76),
     'r3': ('C9_kb9AtgaA2vqN-rYUgbw', 465.25, -973.34), 'r3_21': ('mUXB9Da4AjlGJk72jdCNog', 465.25, -973.34),
     'r4': ('jZg6KzHJ1DgW1HBZzboByA', 452.95, -1001.54), 'r4_21': ('xTFOi3XSB3V56sXXxkpViA', 452.95, -1001.54)}
# the Calle de Ortega y Gasset, past its front (2013, and 2009)
O = {'o1': ('OVX37Y9PHDlCNm1DU2XwHQ', 431.01, -973.15), 'o1_09': ('abtFsNyY1iQKemynt0qc8Q', 431.01, -973.15),
     'o2': ('UHpoAcNJk6xvlehu6BlpyA', 442.50, -978.96), 'o2_09': ('_1utGBDCiVdAKBIg0ghtJg', 442.50, -978.96),
     'o3': ('bTdvxxT9qqCB8wuN5lgQMg', 422.79, -968.77), 'o3_09': ('544s3ywI7bBE04RrY_dggQ', 422.79, -968.77),
     'o4': ('ikR1xPHhQXd0fgJjrp4uEg', 414.50, -964.27), 'o5': ('rgNvWz0UOjCL9JK4n4NRXA', 453.73, -983.18)}

ERMITA = (430.3, -983.9)                         # (its middle, about: Catastro's building)

SHOTS = []
for k, c in list(R.items()) + list(O.items()):
    SHOTS.append((k, c, ERMITA, 4, 70))
for k in ('r1', 'r1_21', 'r2', 'o1', 'o2', 'o3', 'o5'):
    SHOTS.append((k + '_z', (R.get(k) or O.get(k)), ERMITA, 6, 35))
SHOTS += [('o1_ancho', O['o1'], ERMITA, 5, 110), ('r1_ancho', R['r1'], (440.0, -985.0), 3, 110)]

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
