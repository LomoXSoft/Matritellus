"""the 360 photos of the tour, whole (equirectangular, 2048 x 1024): python baja360.py META_FOLDER OUT_FOLDER [width]"""
import sys, os, json, urllib.request
meta, out = sys.argv[1], sys.argv[2]
w = int(sys.argv[3]) if len(sys.argv) > 3 else 2048
rows = json.load(open(os.path.join(meta, 'tour.json')))
order = sorted(rows, key=lambda k: (rows[k]['z'], rows[k]['x']))
names = {}
for i, pid in enumerate(order):
    name = 'e%02d' % (i + 1)
    names[name] = pid
    f = os.path.join(out, name + ('.jpg' if w == 2048 else '_%d.jpg' % w))
    if os.path.exists(f) or not rows[pid]['img']: continue
    url = 'https://lh3.googleusercontent.com/gpms-cs-s/%s=w%d-h%d-k-no' % (rows[pid]['img'], w, w // 2)
    try:
        d = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (map-tool)'}), timeout=60).read()
        open(f, 'wb').write(d)
    except Exception as e:
        print(name, 'fail', e)
json.dump({n: dict(rows[p], id=p) for n, p in names.items()}, open(os.path.join(out, 'nombres.json'), 'w'), indent=1)
print(len(names), 'named')
