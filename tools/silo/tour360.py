"""The 360 photos of the virtual tour of the Silo del Tío Colorao (38 of them, September 2019, 8192 x 4096), from one of
them: where each stands on the game's map (as its maker placed it: good to a metre or two), which way its middle looks,
which others it names, and the key its picture is served under.

    python tools/silo/tour360.py OUT_FOLDER ID [ID ...]      -> OUT_FOLDER/tour.json (and Google's answer for each)

A first ID comes from tools/silo/cerca360.py (the 360 nearest a point). Then tools/silo/baja360.py fetches the pictures
and tools/silo/hojas360.py draws the plan and the sheets. The pictures and Google's answers (which carry the names of
whoever uploaded them) are NOT kept in the repository: give a folder outside it.
"""
import sys, os, json, re, math, urllib.request
OUT = sys.argv[1]
PB = ('!1m4!1smaps_sv.tactile!11m2!2m1!1b1!2m2!1sen!2sus!3m3!1m2!1e10!2s%s!4m61!1e1!1e2!1e3!1e4!1e5!1e6!1e8!1e12!1e17!2m1!1e1!4m1!1i48!5m1!1e1!5m1!1e2!6m1!1e1!6m1!1e2'
      '!9m36!1m3!1e2!2b1!3e2!1m3!1e2!2b0!3e3!1m3!1e3!2b1!3e2!1m3!1e3!2b0!3e3!1m3!1e8!2b0!3e3!1m3!1e1!2b0!3e3!1m3!1e4!2b0!3e3!1m3!1e10!2b1!3e2!1m3!1e10!2b0!3e3!11m2!3m1!4b1')
LAT0, LON0 = 39.4690, -3.5335
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0
todo, seen = list(sys.argv[2:]), {}
while todo and len(seen) < 80:
    pid = todo.pop(0)
    if pid in seen: continue
    f = os.path.join(OUT, pid + '.json')
    if os.path.exists(f):
        t = open(f, encoding='utf8').read()
    else:
        url = 'https://www.google.com/maps/photometa/v1?authuser=0&hl=en&gl=us&pb=' + PB % pid
        try:
            t = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (map-tool)'}), timeout=40).read().decode('utf8', 'replace')
        except Exception as e:
            print(pid, 'fail', e); seen[pid] = None; continue
        open(f, 'w', encoding='utf8').write(t)
    p = json.loads(t[t.index('['):])[1][0]
    kind = p[2][:3] if len(p) > 2 and p[2] else None            # [10, sub, [h, w]]
    loc = None
    try:
        e = p[5][0][1]
        loc = (e[0][2], e[0][3], (e[2][0] if len(e) > 2 and e[2] else None), (e[1][0] if len(e) > 1 and e[1] else None))
    except Exception:
        pass
    date = None
    try: date = p[6][7]
    except Exception: pass
    names = []
    for m in re.finditer(r'\[10, "([\w-]{15,})"\]', json.dumps(p)):
        if m.group(1) not in names: names.append(m.group(1))
    tok = re.search(r'gpms-cs-s/([\w-]+)', t)
    seen[pid] = {'kind': kind, 'loc': loc, 'date': date, 'links': [n for n in names if n != pid], 'img': tok.group(1) if tok else None}
    for n in names:
        if n not in seen and n not in todo: todo.append(n)
rows = {}
for pid, v in seen.items():
    if not v: continue
    la, lo, hd, hh = v['loc'] if v['loc'] else (None, None, None, None)
    rows[pid] = {'kind': v['kind'], 'date': v['date'], 'x': round((lo - LON0) * KX, 2) if lo else None, 'z': round(-(la - LAT0) * KZ, 2) if la else None, 'heading': hd, 'height': hh, 'links': v['links'], 'img': v['img']}
    print(pid, rows[pid]['x'], rows[pid]['z'], round(hd or 0, 1), len(v['links']), 'img' if v['img'] else 'NO IMG')
json.dump(rows, open(os.path.join(OUT, 'tour.json'), 'w'), indent=1)
print(len(rows), 'photos')
