"""Where the openings of the corner shop's long walls are, worked out from several Street View pictures at once.

    python tools/chinos/ajuste.py FOLDER n|s

Google's place for a camera is a metre or two out, and a street this narrow has no room for that: so each camera's place
(along the wall, out from it) and a small turn of its compass are unknowns here, and so is each thing seen on the wall.
What ties it down: the two ends of the wall (Catastro's corners), and that a thing seen from two cameras is in one place.
OBS: picture -> [(thing, px, py), ...] in the 1024 x 640 pictures (read off tools/chinos/rejilla.py's grids). A thing
is an upright edge on the wall's plane; "end0" and "endL" are the wall's ends. Each reading counts for less the more
metres one pixel is worth there (far away, along the wall, a pixel is a metre).
The ruler: ('band', px, top, bottom) is the course of bricks stood on end between the floors, seen at that column from
that row to that row. A brick is 24 cm long, so that course is 24 cm high wherever it is seen: that gives how far
each camera stood from the wall.
"""
import json, math, os, sys
import medir

OBS = {
    'n': {      # the Calle de San José: 0 at the point, 19.77 at the neighbour's wall
        'nb24': [('band', 400, 320, 345), ('endL', 598, 40), ('endL', 608, 300), ('endL', 623, 627), ('g2R', 587, 420), ('g2R', 593, 620), ('g2L', 360, 430), ('g2L', 360, 600),
                 ('g1R', 337, 430), ('g1R', 337, 600), ('g1L', 167, 417), ('g1L', 137, 630), ('u5L', 270, 241), ('u5R', 447, 225),
                 ('archL', 95, 250), ('archR', 160, 250), ('ventR', 45, 395)],
        'cal_n_o': [('endL', 748, 200), ('endL', 776, 500), ('g2R', 727, 450), ('g2L', 477, 480), ('g1R', 456, 480), ('g1L', 318, 470),
                    ('ventL', 203, 388), ('ventR', 232, 388), ('G3L', 146, 465), ('G3R', 192, 465), ('archL', 262, 250), ('archR', 300, 250)],
        'n24': [('band', 450, 267, 300), ('G2R', 293, 480), ('G3L', 585, 500), ('G3R', 825, 520), ('u2L', 123, 110), ('u2R', 347, 110), ('u3L', 567, 100), ('u3R', 757, 100),
                ('acL', 800, 200), ('acR', 940, 200), ('ventL', 845, 353), ('ventR', 1000, 353), ('archL', 995, 60)],
        'cal_n_e': [('G1L', 415, 480), ('G1R', 590, 480), ('G2L', 697, 500), ('G2R', 760, 500), ('G3L', 787, 465), ('G3R', 815, 465), ('g1L', 833, 455),
                    ('endL', 865, 400), ('ventL', 803, 393), ('ventR', 819, 393)],
        'ne24_punta': [('end0', 470, 400), ('end0', 468, 550), ('G1L', 763, 520), ('band', 700, 238.5, 273), ('band', 900, 269, 300)],
    },
    's': {      # the Calle de Santo Domingo: 0 at the neighbour's wall, 19.97 at the point
        'cal_s_o': [('end0', 88, 100), ('end0', 72, 500), ('sgL', 120, 520), ('sgR', 351, 520), ('d1L', 370, 520), ('d1R', 423, 520), ('bdL', 519, 500), ('bdR', 572, 500),
                    ('a1L', 627, 500), ('a1R', 657, 500), ('a2L', 665, 500), ('a2R', 691, 500), ('w3L', 708, 505), ('w3R', 749, 505), ('endL', 819, 460), ('band', 200, 319, 360)],
        'sb24': [('end0', 333, 120), ('end0', 313, 567), ('sgL', 343, 520), ('sgR', 480, 520), ('d1L', 492, 520), ('d1R', 523, 520), ('bdL', 589, 500), ('bdR', 630, 500),
                 ('a1L', 662, 490), ('a1R', 685, 490), ('a2L', 690, 490), ('a2R', 710, 490), ('w3L', 721, 480), ('w3R', 753, 480), ('endL', 803, 450), ('band', 400, 340, 365)],
        's24': [('bdL', 23, 480), ('bdR', 223, 480), ('a1L', 377, 490), ('a1R', 453, 490), ('a2L', 530, 490), ('a2R', 593, 490), ('w3L', 707, 500), ('w3R', 873, 500),
                ('w4L', 950, 500), ('band', 400, 293, 327)],
        'cal_s_e1': [('w5L', 680, 520), ('w5R', 797, 520), ('w4L', 510, 500), ('w4R', 575, 500), ('w3L', 370, 480), ('w3R', 440, 480), ('a2L', 327, 460), ('a2R', 349, 460),
                     ('a1L', 308, 455), ('a1R', 327, 455), ('end0', 267, 400), ('band', 667, 177, 220)],
        'cal_s_e2': [('w4R', 100, 500), ('w5L', 257, 500), ('w5R', 370, 500), ('SGL', 617, 500), ('band', 300, 190.4, 228.8)],
        'se24_punta': [('SGL', 333, 500), ('SGR', 657, 520), ('endL', 710, 480), ('endL', 707, 560), ('band', 600, 287, 320)],
    },
}
CAMS = {'nb24': 'NB', 'cal_n_o': 'NB', 'n24': 'NA', 'cal_n_e': 'NE', 'ne24_lado': 'NE', 'ne24_punta': 'NE',
        'sb24': 'SB', 'cal_s_o': 'SB', 's24': 'SA', 'cal_s_e1': 'SE', 'cal_s_e2': 'SE', 'se24_lado': 'SE', 'se24_punta': 'SE'}


def s_of(v, cam, px, py, wall):
    w = dict(v)
    w['heading'] = v['heading'] + cam[2]
    return medir.at(w, px, py, wall, (cam[0], cam[1]))[0]


def cost(par, names, views, wall, ln, tell=False):
    cams = {n: par[3 * i:3 * i + 3] for i, n in enumerate(names)}
    things = {}
    bands = []
    for pic, obs in OBS[wall].items():
        v = views[pic]
        cam = cams[CAMS[pic]]
        for ob in obs:
            if ob[0] == 'band':
                w = dict(v)
                w['heading'] = v['heading'] + cam[2]
                try:
                    high = medir.at(w, ob[1], ob[2], wall, (cam[0], cam[1]))[1] - medir.at(w, ob[1], ob[3], wall, (cam[0], cam[1]))[1]
                except ZeroDivisionError:
                    return 1e9
                bands.append((pic, high))
                continue
            name, px, py = ob
            try:
                s = s_of(v, cam, px, py, wall)
                wide = abs(s_of(v, cam, px + 2, py, wall) - s) + 0.03
            except ZeroDivisionError:
                return 1e9
            things.setdefault(name, []).append((s, 1.0 / wide ** 2, pic))
    e = 0.0
    out = {}
    for name, got in things.items():
        if name == 'end0':
            mid = 0.0
        elif name == 'endL':
            mid = ln
        else:
            mid = sum(s * w for s, w, _ in got) / sum(w for _, w, _ in got)
        out[name] = (mid, got)
        e += sum(w * (s - mid) ** 2 for s, w, _ in got)
    e += sum(((high - 0.24) / 0.012) ** 2 for _, high in bands)
    for i, n in enumerate(names):          # Google is not far wrong: a weak pull towards its place and its compass
        c0 = medir.local(START[n], wall)
        e += 0.5 * ((par[3 * i] - c0[0]) ** 2 + (par[3 * i + 1] - c0[1]) ** 2) + 0.3 * par[3 * i + 2] ** 2
    return (e, out, bands) if tell else e


if __name__ == '__main__':
    folder, wall = sys.argv[1], sys.argv[2]
    views = json.load(open(os.path.join(folder, 'views.json')))
    ln = medir.frame(wall)[3]
    names = sorted({CAMS[p] for p in OBS[wall]})
    START = {CAMS[p]: (views[p]['x'], views[p]['z']) for p in OBS[wall]}
    par = []
    for n in names:
        par += list(medir.local(START[n], wall)) + [0.0]
    step = [0.5, 0.5, 2.0] * len(names)
    best = cost(par, names, views, wall, ln)
    for _ in range(400):                    # a plain search, one unknown at a time, the stride halving when nothing helps
        moved = False
        for i in range(len(par)):
            for d in (step[i], -step[i]):
                q = list(par)
                q[i] += d
                if i % 3 == 1 and q[i] < 1.0:
                    continue
                c = cost(q, names, views, wall, ln)
                if c < best - 1e-9:
                    par, best, moved = q, c, True
                    break
        if not moved:
            step = [x * 0.5 for x in step]
            if max(step) < 0.002:
                break
    e, out, bands = cost(par, names, views, wall, ln, True)
    for i, n in enumerate(names):
        c0 = medir.local(START[n], wall)
        print('camera %s: Google along %.2f out %.2f   fitted along %.2f out %.2f, turned %.1f deg' % (n, c0[0], c0[1], par[3 * i], par[3 * i + 1], par[3 * i + 2]))
    print('cost %.2f' % e, '  the band, cm:', '  '.join('%s %.1f' % (pic, high * 100) for pic, high in bands))
    for name, (mid, got) in sorted(out.items(), key=lambda kv: kv[1][0]):
        print('%-7s %6.2f   %s' % (name, mid, '  '.join('%s %.2f' % (pic, s) for s, _, pic in got)))
