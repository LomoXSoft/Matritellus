"""Tokken 9 (godot/scripts/tokken.gd): the fighters, their portraits and the stages, cut out of the user's GIFs.

    python -I tools/make_tokken.py [--debug DIR]

Reads referencias/recress/Tokken9_*.gif (the user's, 13 November 2026: two fighters on a stage, eight frames each) and
writes, in godot/assets/tokken/:

    <fighter>.png     the fighter's eight poses in a row, all facing right, each in a cell of the same size
    cara_<fighter>.png  the portrait from the GIF's own life bar
    fondo_<n>.png     the stage of GIF n with nobody on it (what the fighters hid is filled in from beside it)

and godot/scripts/tokken_datos.gd: for each fighter, the size of a cell and where the feet are in it; for each stage,
its size and where the floor is.

Each fighter is cut out of each frame with OpenCV's GrabCut, started from a box round the fighter read off the frame by
eye (BOXES below) and, where that was not enough, a few strokes saying "this is fighter" or "this is background".
With --debug, sheets of the cut-outs on magenta are left in DIR to look at.
"""
import os
import sys

import cv2
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'referencias', 'recress')
OUT = os.path.join(ROOT, 'godot', 'assets', 'tokken')

# fighter -> the GIF it is in, which side of it (0 left, 1 right), where the floor line under its feet is, and for
# each frame the box round it (x0, y0, x1, y1). "bg" / "fg": per frame, strokes that are surely background or surely
# fighter: ("rect", x0, y0, x1, y1) or ("disc", x, y, r).
FIGHTERS = {
    'cleopatra': {'gif': 1, 'side': 0, 'floor': 380, 'boxes': {
        0: (34, 190, 186, 382), 1: (36, 200, 196, 382), 2: (32, 198, 212, 382), 3: (36, 202, 212, 382),
        4: (36, 196, 186, 382), 5: (20, 212, 150, 382), 6: (36, 196, 178, 382), 7: (32, 190, 180, 382)},
        # (her skirt is white with a pale edge: no ink round it, so the whole box starts as "maybe her")
        'loose': True, 'bg': {2: [('disc', 234, 262, 26)], 3: [('rect', 178, 236, 215, 290)]}},
    'raptor': {'gif': 1, 'side': 1, 'floor': 382, 'boxes': {
        0: (228, 224, 439, 384), 1: (224, 226, 439, 384), 2: (264, 226, 439, 384), 3: (262, 200, 439, 384),
        4: (200, 210, 439, 384), 5: (192, 226, 439, 384), 6: (222, 220, 439, 384), 7: (230, 222, 439, 384)},
        'bg': {0: [('rect', 396, 150, 439, 262)], 1: [('rect', 396, 150, 439, 262)], 2: [('rect', 396, 150, 439, 262)],
               3: [('rect', 396, 150, 439, 262)], 4: [('rect', 306, 150, 439, 262)], 5: [('rect', 396, 150, 439, 258)],
               6: [('rect', 396, 150, 439, 262)], 7: [('rect', 396, 150, 439, 262)]}},
    'napoleon': {'gif': 2, 'side': 0, 'floor': 382, 'boxes': {
        0: (26, 178, 176, 384), 1: (28, 184, 192, 384), 2: (28, 188, 248, 384), 3: (28, 190, 224, 384),
        4: (26, 188, 176, 384), 5: (30, 184, 160, 384), 6: (24, 196, 172, 384), 7: (24, 176, 174, 384)},
        'bg': {5: [('rect', 156, 150, 200, 332)], 6: [('rect', 104, 150, 200, 236)]}},
    'samurai': {'gif': 2, 'side': 1, 'floor': 382, 'boxes': {
        0: (262, 176, 430, 384), 1: (262, 174, 432, 384), 2: (262, 176, 432, 384), 3: (240, 196, 432, 384),
        4: (182, 196, 439, 384), 5: (196, 186, 434, 384), 6: (192, 190, 428, 384), 7: (258, 174, 432, 384)}},
    'dracula': {'gif': 3, 'side': 0, 'floor': 382, 'boxes': {
        0: (4, 190, 186, 384), 1: (18, 200, 206, 384), 2: (22, 202, 246, 384), 3: (24, 206, 196, 384),
        4: (22, 194, 206, 384), 5: (34, 194, 206, 384), 6: (12, 198, 202, 384), 7: (18, 188, 198, 384)}},
    'monstruo': {'gif': 3, 'side': 1, 'floor': 382, 'boxes': {
        0: (266, 184, 430, 384), 1: (264, 184, 430, 384), 2: (266, 184, 432, 384), 3: (262, 188, 432, 384),
        4: (252, 180, 426, 384), 5: (236, 158, 426, 384), 6: (262, 184, 428, 384), 7: (268, 181, 432, 384)}},
}
ORDER = ['cleopatra', 'raptor', 'napoleon', 'samurai', 'dracula', 'monstruo']
# the portraits in each GIF's life bar: (x0, y0, x1, y1) for the left one and the right one
PORTRAITS = {1: [(14, 14, 88, 82), (350, 14, 430, 82)], 2: [(12, 12, 82, 76), (358, 12, 430, 76)], 3: [(12, 12, 82, 76), (358, 12, 430, 76)]}
MARGIN = 6
# the fights' own flashes, which are no part of the stage: gif -> frame -> where they are (not looked at there)
FLASHES = {1: {2: [('disc', 236, 262, 34)], 3: [('rect', 170, 205, 300, 300)]}}
# bits that are in too many frames to go by themselves: painted over from round about
MEND = {}


def frames_of(gif: int) -> list:
    im = Image.open(os.path.join(SRC, 'Tokken9_%d.gif' % gif))
    out = []
    for i in range(im.n_frames):
        im.seek(i)
        out.append(np.asarray(im.convert('RGB')).copy())
    return out


def stroke(mask: np.ndarray, shape: tuple, value: int) -> None:
    if shape[0] == 'rect':
        cv2.rectangle(mask, (shape[1], shape[2]), (shape[3], shape[4]), int(value), -1)
    else:
        cv2.circle(mask, (shape[1], shape[2]), shape[3], int(value), -1)


def big_blobs(m: np.ndarray, keep: float) -> np.ndarray:
    n, lab, stats, _ = cv2.connectedComponentsWithStats(m.astype(np.uint8), 8)
    if n <= 1:
        return m
    top = stats[1:, cv2.CC_STAT_AREA].max()
    out = np.zeros_like(m)
    for k in range(1, n):
        if stats[k, cv2.CC_STAT_AREA] >= top * keep:
            out |= lab == k
    return out


def fill_holes(m: np.ndarray, biggest: int) -> np.ndarray:
    """holes of up to `biggest` pixels inside the fighter are fighter (a pale eye, a highlight)"""
    inv = (~m).astype(np.uint8)
    n, lab, stats, _ = cv2.connectedComponentsWithStats(inv, 4)
    out = m.copy()
    h, w = m.shape
    for k in range(1, n):
        x, y, bw, bh, area = stats[k]
        if area <= biggest and x > 0 and y > 0 and x + bw < w and y + bh < h:
            out |= lab == k
    return out


def inked(img: np.ndarray, box: tuple, dark: int) -> np.ndarray:
    """What the fighter's own outline encloses. They are drawn with a line that is nearly black, and the stages have
    next to nothing that dark: so, inside the box, whatever cannot be reached from its edge without crossing ink."""
    h, w = img.shape[:2]
    x0, y0, x1, y1 = box
    x1 = min(x1, w - 1)
    ink = np.zeros((h, w), np.uint8)
    ink[y0:y1, x0:x1 + 1] = (img[y0:y1, x0:x1 + 1].max(axis=2) < dark)
    shut = cv2.dilate(ink, np.ones((3, 3), np.uint8))                # (a gap of a pixel or two in the line is closed)
    sea = np.zeros((h + 2, w + 2), np.uint8)
    room = (shut == 0).astype(np.uint8)
    pad = np.zeros((h, w), np.uint8)
    pad[max(0, y0 - 2):y1 + 2, max(0, x0 - 2):min(w, x1 + 3)] = 1    # the box and a ring round it to pour the sea into
    room &= pad
    flood = room.copy()
    for (sx, sy) in [(max(0, x0 - 2), max(0, y0 - 2)), (min(w - 1, x1 + 2), max(0, y0 - 2)), (max(0, x0 - 2), y1 + 1), (min(w - 1, x1 + 2), y1 + 1)]:
        if flood[sy, sx] == 1:
            cv2.floodFill(flood, sea, (sx, sy), 2)
    inside = ((flood != 2) & (pad == 1)).astype(np.uint8)
    inside[:y0] = 0
    inside[y1:] = 0
    inside[:, :x0] = 0
    inside[:, x1 + 1:] = 0
    inside = cv2.erode(inside, np.ones((3, 3), np.uint8)) | ink      # (the line itself was fattened to shut it: back to size)
    return big_blobs(inside.astype(bool), 0.05)


def cut(img: np.ndarray, box: tuple, bg: list, fg: list, dark: int, loose: bool) -> np.ndarray:
    h, w = img.shape[:2]
    x0, y0, x1, y1 = box
    x1 = min(x1, w - 1)
    body = inked(img, box, dark)
    core = cv2.erode(body.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0
    mask = np.full((h, w), cv2.GC_BGD, np.uint8)
    mask[y0:y1, x0:x1 + 1] = cv2.GC_PR_FGD if loose else cv2.GC_PR_BGD
    mask[body] = cv2.GC_PR_FGD
    mask[core] = cv2.GC_FGD
    for s in bg:
        stroke(mask, s, cv2.GC_BGD)
    for s in fg:
        stroke(mask, s, cv2.GC_FGD)
    bgr = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
    bm = np.zeros((1, 65), np.float64)
    fm = np.zeros((1, 65), np.float64)
    cv2.grabCut(bgr, mask, None, bm, fm, 5, cv2.GC_INIT_WITH_MASK)
    m = (mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD)
    m = big_blobs(m, 0.03)
    return fill_holes(m, 60)


VIEW_H = 360          # the stage as the game shows it: this many rows, up from the bottom of the GIF


def stage(frames: list, covered: list, floor: int, mend: list) -> tuple:
    """The stage with nobody on it, and wide. Each pixel is the middle value of the frames in which no fighter is over
    it; where one always is, the strip of stage between the two fighters is laid over it again and again, there and
    back (the railings and the floor carry on). Then the whole of it mirrored to either side: three times as wide."""
    stack = np.stack(frames).astype(np.float32)
    cover = np.stack(covered)
    h, w = cover.shape[1:]
    clear = (~cover).sum(axis=0)
    data = np.ma.array(stack, mask=np.repeat(cover[..., None], 3, axis=3))
    plate = np.ma.median(data, axis=0).filled(0).astype(np.uint8)
    hole = clear < 3
    hole[:88] = False                                    # (the life bars: not ours to mend, the game's own go over them)
    hole[floor - 16:floor + 14] |= hole[floor - 16:floor + 14].any(axis=0)[None, :]     # the strip of floor they stand on: all of it,
    edge = np.nonzero(hole[floor - 16:floor + 14].any(axis=0))[0]                        # and out to the ends of the picture
    if len(edge):
        if edge.min() < 60:
            hole[floor - 16:floor + 14, :edge.min()] = True
        if edge.max() > w - 60:
            hole[floor - 16:floor + 14, edge.max():] = True
    mid = w // 2
    ys, xs = np.nonzero(hole)
    left_edge = int(xs[xs < mid].max()) + 1 if (xs < mid).any() else mid - 20       # the clear strip in the middle
    right_edge = int(xs[xs >= mid].min()) if (xs >= mid).any() else mid + 20
    if right_edge - left_edge < 16:
        left_edge, right_edge = mid - 8, mid + 8
    span = right_edge - left_edge
    out = plate.copy()
    # On the floor the joints between the slabs run to a point up on the horizon: what is laid there is taken from
    # the strip along those lines, not straight across (straight across, a joint in the strip came out as a row of
    # dark posts). `u` is which of those lines a pixel is on.
    floor_top = floor - 46
    vanish = floor - 112.0
    cx = (left_edge + right_edge) / 2.0
    reach = (span / 2.0) / (h - 1 - vanish)
    for y, x in zip(ys, xs):
        if y >= floor_top:
            u = abs(x - cx) / (y - vanish)
            j = u % (2 * reach)
            j = j if j < reach else 2 * reach - j
            src = cx + (1.0 if x >= cx else -1.0) * j * (y - vanish)
            out[y, x] = plate[y, int(min(max(round(src), left_edge), right_edge - 1))]
            continue
        d = (left_edge - 1 - x) if x < mid else (x - right_edge)
        j = d % (2 * span)
        j = j if j < span else 2 * span - 1 - j
        out[y, x] = plate[y, left_edge + j] if x < mid else plate[y, right_edge - 1 - j]
    if mend:
        spots = np.zeros((h, w), np.uint8)
        for m in mend:
            stroke(spots, m, 255)
        out = cv2.cvtColor(cv2.inpaint(cv2.cvtColor(out, cv2.COLOR_RGB2BGR), spots, 4, cv2.INPAINT_TELEA), cv2.COLOR_BGR2RGB)
    out = out[h - VIEW_H:]
    wide = np.concatenate([out[:, ::-1], out, out[:, ::-1]], axis=1)
    return wide, floor - (h - VIEW_H)


def main() -> None:
    debug = sys.argv[sys.argv.index('--debug') + 1] if '--debug' in sys.argv else ''
    os.makedirs(OUT, exist_ok=True)
    gifs = {}
    masks = {}
    meta = {'fighters': {}, 'stages': {}}
    for name in ORDER:
        f = FIGHTERS[name]
        if f['gif'] not in gifs:
            gifs[f['gif']] = frames_of(f['gif'])
        fr = gifs[f['gif']]
        cuts = []
        covered = masks.setdefault(f['gif'], [np.zeros(fr[0].shape[:2], bool) for _ in range(8)])
        for i in range(8):
            m = cut(fr[i], f['boxes'][i], f.get('bg', {}).get(i, []), f.get('fg', {}).get(i, []), f.get('dark', 50), f.get('loose', False))
            ys, xs = np.nonzero(m)
            x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
            covered[i] |= cv2.dilate(m.astype(np.uint8), np.ones((9, 9), np.uint8)) > 0
            covered[i][f['floor'] - 16:f['floor'] + 14, max(0, x0 - 12):x1 + 12] = True      # (and the shadow at the feet)
            rgba = np.dstack([fr[i][y0:y1, x0:x1], (m[y0:y1, x0:x1] * 255).astype(np.uint8)])
            low = ys > ys.max() - max(6, (ys.max() - ys.min()) // 6)           # the feet: the lowest sixth of it
            feet = (xs[low].min() + xs[low].max()) / 2.0 - x0
            if f['side'] == 1:                                                    # (everybody faces right)
                rgba = rgba[:, ::-1]
                feet = (x1 - x0) - feet
            cuts.append({'img': rgba, 'feet': feet, 'drop': f['floor'] - y1})      # drop: how far its lowest pixel is above the floor
        left = int(np.ceil(max(c['feet'] for c in cuts))) + MARGIN
        right = int(np.ceil(max(c['img'].shape[1] - c['feet'] for c in cuts))) + MARGIN
        tall = max(c['img'].shape[0] + max(0, c['drop']) for c in cuts) + MARGIN * 2
        cw, ch = left + right, tall
        sheet = np.zeros((ch, cw * 8, 4), np.uint8)
        poses = []
        for i, c in enumerate(cuts):
            ih, iw = c['img'].shape[:2]
            px = i * cw + left - int(round(c['feet']))
            py = ch - MARGIN - max(0, c['drop']) - ih
            sheet[py:py + ih, px:px + iw] = c['img']
            poses.append({'box': [int(px - i * cw), int(py), int(iw), int(ih)]})
        Image.fromarray(sheet, 'RGBA').save(os.path.join(OUT, name + '.png'), optimize=True)
        meta['fighters'][name] = {'cell': [int(cw), int(ch)], 'feet': [int(left), int(ch - MARGIN)], 'poses': poses}
        px0, py0, px1, py1 = PORTRAITS[f['gif']][f['side']]
        face = Image.fromarray(fr[0][py0:py1, px0:px1])
        if f['side'] == 1:
            face = face.transpose(Image.FLIP_LEFT_RIGHT)
        face.save(os.path.join(OUT, 'cara_' + name + '.png'))
        print('%-10s cell %dx%d' % (name, cw, ch))
        if debug:
            os.makedirs(debug, exist_ok=True)
            bgc = np.zeros((ch, cw * 8, 3), np.uint8)
            bgc[:] = (255, 0, 255)
            a = sheet[:, :, 3:4] / 255.0
            comp = (sheet[:, :, :3] * a + bgc * (1 - a)).astype(np.uint8)
            Image.fromarray(comp).resize((comp.shape[1] * 2, comp.shape[0] * 2), Image.NEAREST).save(os.path.join(debug, 'cut_' + name + '.png'))
    for gif in sorted(gifs):
        for i, strokes in FLASHES.get(gif, {}).items():
            spots = np.zeros(gifs[gif][0].shape[:2], np.uint8)
            for st in strokes:
                stroke(spots, st, 1)
            masks[gif][i] |= spots > 0
        floor = max(FIGHTERS[n]['floor'] for n in ORDER if FIGHTERS[n]['gif'] == gif)
        img, floor_y = stage(gifs[gif], masks[gif], floor, MEND.get(gif, []))
        Image.fromarray(img).save(os.path.join(OUT, 'fondo_%d.png' % gif), optimize=True)
        meta['stages'][str(gif)] = {'size': [int(img.shape[1]), int(img.shape[0])], 'floor': int(floor_y)}
        print('fondo_%d  %dx%d  floor %d' % (gif, img.shape[1], img.shape[0], floor_y))
    # the sizes go into a script of the game's own (a .json beside the pictures would be left out of the installers)
    lines = ['extends RefCounted',
             '## Tokken 9: the sizes of the pictures in assets/tokken/. Written by tools/make_tokken.py: do not edit by hand.',
             '## For each fighter: the cell of one pose in its strip, and where the feet are in a cell. For each stage: its',
             '## size, and how far down the floor is.',
             '',
             'const FIGHTERS := {']
    for name in ORDER:
        m = meta['fighters'][name]
        lines.append('\t"%s": {"cell": Vector2(%d, %d), "foot": Vector2(%d, %d)},' % (name, m['cell'][0], m['cell'][1], m['feet'][0], m['feet'][1]))
    lines.append('}')
    lines.append('const STAGES := {')
    for gif in sorted(meta['stages']):
        m = meta['stages'][gif]
        lines.append('\t%s: {"size": Vector2(%d, %d), "floor": %d.0},' % (gif, m['size'][0], m['size'][1], m['floor']))
    lines.append('}')
    with open(os.path.join(ROOT, 'godot', 'scripts', 'tokken_datos.gd'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write('\n'.join(lines) + '\n')
    print('tokken_datos.gd')


if __name__ == '__main__':
    main()
