"""Street View panoramas: what Google says of one (where it is on the game's map, its date, which way the car was
going, how high) and of the ones it names beside it (its neighbours along the streets, and the older ones taken at the
same spot), and pictures from one.

    python tools/molino/panos.py info ID [ID ...]                    this one and all it names
    python tools/molino/panos.py foto ID OUT.jpg heading pitch [fov]   a picture from it (up to 1024 x 640)
    python tools/molino/panos.py cerca ID x z [radius]               walks from ID, neighbour by neighbour, to the panorama
                                                                     nearest to (x, z) on the game's map, then lists every
                                                                     one within `radius` (60 m) of it, with the older ones
                                                                     taken at each spot: all the cameras round a place

The id of a first panorama comes from the address bar of Google Maps in Street View (the 22 letters after "!1s").
Pitch is up-positive, as on screen. Positions are Google's: good to a metre or two in a street, worse in a square
(tools/plaza/LEEME.md) -- fix each against something known before measuring from it. (The old search by place,
GeoPhotoService.SingleImageSearch, was turned off in 2026.)
"""
import json, math, sys, urllib.request

LAT0, LON0 = 39.4690, -3.5335
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0
UA = {'User-Agent': 'Mozilla/5.0 (map-tool)'}
PB = ('!1m4!1smaps_sv.tactile!11m2!2m1!1b1!2m2!1sen!2sus!3m3!1m2!1e2!2s%s!4m57!1e1!1e2!1e3!1e4!1e5!1e6!1e8!1e12!2m1!1e1!4m1!1i48!5m1!1e1!5m1!1e2!6m1!1e1!6m1!1e2'
      '!9m36!1m3!1e2!2b1!3e2!1m3!1e2!2b0!3e3!1m3!1e3!2b1!3e2!1m3!1e3!2b0!3e3!1m3!1e8!2b0!3e3!1m3!1e1!2b0!3e3!1m3!1e4!2b0!3e3!1m3!1e10!2b1!3e2!1m3!1e10!2b0!3e3')


def place(e):
    """[[null, null, lat, lon], [height, ...], [heading, tilt, roll]] -> x, z, heading, height"""
    la, lo = e[0][2], e[0][3]
    return round((lo - LON0) * KX, 2), round(-(la - LAT0) * KZ, 2), (round(e[2][0], 1) if len(e) > 2 and e[2] else None), (round(e[1][0], 2) if len(e) > 1 and e[1] else None)


def when(d):
    """[year, month] (Google sometimes gives the year alone, or more) -> '2024-11'"""
    d = list(d) if isinstance(d, (list, tuple)) else [d]
    return '%d-%02d' % (int(d[0]), int(d[1])) if len(d) >= 2 else '%d' % int(d[0])


def info(pid):
    url = 'https://www.google.com/maps/photometa/v1?authuser=0&hl=en&gl=us&pb=' + PB % pid
    t = urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40).read().decode('utf8', 'replace')
    p = json.loads(t[t.index('['):])[1][0]
    loc = p[5][0]
    here = {'id': pid, 'date': when(p[6][7]), 'at': place(loc[1])}
    others = []
    named = loc[3][0] if len(loc) > 3 and loc[3] else []
    old = {h[0]: when(h[1]) for h in (loc[8] if len(loc) > 8 and loc[8] else [])}
    for i, e in enumerate(named):
        if e[0][1] == pid:
            continue
        others.append({'id': e[0][1], 'at': place(e[2]), 'date': old.get(i, '')})
    return here, others


def near(pid, target, radius=60.0):
    """Every panorama within `radius` of `target`, reached from `pid` along the streets: [(here, [older ones at that spot])]."""
    here, others = info(pid)
    seen = {pid}
    for _ in range(80):                 # first, walk to the one nearest to the target
        best = min((o for o in others if not o['date'] and o['id'] not in seen), key=lambda o: math.dist(o['at'][:2], target), default=None)
        if best is None or math.dist(best['at'][:2], target) >= math.dist(here['at'][:2], target) - 0.5:
            break
        seen.add(best['id'])
        here, others = info(best['id'])
    out, todo, done = [], [(here, others)], {here['id']}
    while todo:
        here, others = todo.pop(0)
        out.append((here, [o for o in others if o['date'] and math.dist(o['at'][:2], here['at'][:2]) < 8.0]))
        for o in others:
            if not o['date'] and o['id'] not in done and math.dist(o['at'][:2], target) <= radius:
                done.add(o['id'])
                todo.append(info(o['id']))
    return out


if __name__ == '__main__':
    if sys.argv[1] == 'cerca':
        target = (float(sys.argv[3]), float(sys.argv[4]))
        for here, old in sorted(near(sys.argv[2], target, float(sys.argv[5]) if len(sys.argv) > 5 else 60.0), key=lambda q: (round(q[0]['at'][1] / 15.0), q[0]['at'][0])):
            print('%s  %s  x %8.2f  z %8.2f   %s' % (here['id'], here['date'], here['at'][0], here['at'][1], '  '.join('%s %s' % (o['date'], o['id']) for o in sorted(old, key=lambda o: o['date']))))
    elif sys.argv[1] == 'foto':
        pid, out, h, pitch = sys.argv[2], sys.argv[3], float(sys.argv[4]), float(sys.argv[5])
        fov = float(sys.argv[6]) if len(sys.argv) > 6 else 90
        url = 'https://streetviewpixels-pa.googleapis.com/v1/thumbnail?panoid=%s&cb_client=maps_sv.tactile&w=1600&h=1000&yaw=%g&pitch=%g&thumbfov=%g' % (pid, h % 360, -pitch, fov)
        open(out, 'wb').write(urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40).read())
        print(out)
    else:
        seen = set()
        for pid in sys.argv[2:]:
            here, others = info(pid)
            print('%s  %s  x %8.2f  z %8.2f  heading %s  height %s' % (here['id'], here['date'], here['at'][0], here['at'][1], here['at'][2], here['at'][3]))
            for o in sorted(others, key=lambda o: math.dist(o['at'][:2], here['at'][:2])):
                if o['id'] in seen:
                    continue
                seen.add(o['id'])
                print('   %s  %-7s  x %8.2f  z %8.2f  heading %s  height %s   (%.0f m off)' % (o['id'], o['date'] or 'now', o['at'][0], o['at'][1], o['at'][2], o['at'][3], math.dist(o['at'][:2], here['at'][:2])))
