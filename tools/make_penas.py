"""The peñas' logos, ready to be sprayed on the walls of the town: godot/assets/penas/<id>.png, 512 px at most, with a
real transparent background.

    python tools/make_penas.py

The originals (referencias/penas/*.webp, made by Luis) came with the grey-and-white chequerboard that stands for
"transparent" painted into the picture itself. It is taken out here: every grey pixel (no colour in it) that can be
reached from the edge of the picture without crossing anything else is background; so are grey islands shut in by the
drawing that still show the chequerboard's two greys; and the grey fringe left round the edges. The logos are all drawn
with a dark outline round the letters, which is what keeps the flood out of the white letters themselves.

Needs Pillow and numpy.
"""
import os
from collections import deque
import warnings
import numpy as np
warnings.filterwarnings("ignore", category=RuntimeWarning)          # (nan means of tiny islands: handled)
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, 'referencias', 'penas')
OUT = os.path.join(ROOT, 'godot', 'assets', 'penas')
WORK = 768                          # the size it is cleaned at
FINAL = 512                         # and the size it is kept at
PENAS = ['nietos', 'croquetilla', 'bordillo', 'centradito', 'costrola', 'al_prao']      # (Creator.PENAS order)


def grey_mask(rgb, sat_max=26, lum_min=108):
    mx = rgb.max(axis=2).astype(np.int16)
    mn = rgb.min(axis=2).astype(np.int16)
    lum = rgb.mean(axis=2)
    return ((mx - mn) <= sat_max) & (lum >= lum_min), lum


def components(mask):
    """labels of the 4-connected regions of mask (0 = not in mask), and how many there are"""
    h, w = mask.shape
    lab = np.zeros((h, w), np.int32)
    n = 0
    for y0 in range(h):
        row = mask[y0]
        for x0 in np.nonzero(row & (lab[y0] == 0))[0]:
            if lab[y0, x0]:
                continue
            n += 1
            lab[y0, x0] = n
            q = deque([(y0, x0)])
            while q:
                y, x = q.popleft()
                for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                    if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] and not lab[yy, xx]:
                        lab[yy, xx] = n
                        q.append((yy, xx))
    return lab, n


def step_diff(lum, mask, lag, axis):
    """how different, on average, a pixel of `mask` is from the one `lag` pixels further on (nan if too few pairs)"""
    if axis == 1:
        a, b, m = lum[:, :-lag], lum[:, lag:], mask[:, :-lag] & mask[:, lag:]
    else:
        a, b, m = lum[:-lag], lum[lag:], mask[:-lag] & mask[lag:]
    if m.sum() < 20:
        return float('nan')
    return float(np.abs(a - b)[m].mean())


def rhythm(lum, mask, s):
    """[difference one square away, two squares away], across and down: a chequerboard of squares of s pixels differs a
    lot one square away and little two squares away; a white letter with grey grime on it differs about the same"""
    d1 = np.nanmean([step_diff(lum, mask, s, 1), step_diff(lum, mask, s, 0)])
    d2 = np.nanmean([step_diff(lum, mask, 2 * s, 1), step_diff(lum, mask, 2 * s, 0)])
    return d1, d2


def clean(name):
    full = Image.open(os.path.join(SRC, name + '.webp')).convert('RGB')
    flum = np.asarray(full).astype(np.float32).mean(axis=2)
    k = WORK / max(full.size)
    im = full.resize((round(full.width * k), round(full.height * k)), Image.LANCZOS)
    rgb = np.asarray(im).copy()
    grey, lum = grey_mask(rgb)
    lab, n = components(grey)
    h, w = grey.shape
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(edge))
    up = lambda m: np.asarray(Image.fromarray((m * 255).astype(np.uint8)).resize(full.size, Image.NEAREST)) > 0
    # the size of the chequerboard's squares, from the background round the outside
    big_bg = up(bg)
    s = 2 + int(np.nanargmax([step_diff(flum, big_bg, lag, 1) for lag in range(2, 26)]))
    contrast = step_diff(flum, big_bg, s, 1)
    # Grey islands shut in by the drawing: background too, but only if they have the chequerboard's rhythm (white
    # letters have grey grime on them, and must stay).
    sizes = np.bincount(lab.ravel(), minlength=n + 1)
    light = np.bincount(lab.ravel(), weights=(lum > 232).ravel(), minlength=n + 1)
    dark = np.bincount(lab.ravel(), weights=((lum > 135) & (lum < 212)).ravel(), minlength=n + 1)
    islands = 0
    for i in range(1, n + 1):
        if i in edge or sizes[i] < 40 or light[i] / sizes[i] < 0.2 or dark[i] / sizes[i] < 0.2:
            continue
        d1, d2 = rhythm(flum, up(lab == i), s)
        if np.isnan(d1):
            continue
        if np.isnan(d2):                         # too small to see two squares: strong contrast and both greys well mixed
            yes = d1 >= max(55.0, contrast * 0.85) and dark[i] / sizes[i] >= 0.33 and light[i] / sizes[i] >= 0.25
        else:
            yes = (d1 + 1.0) / (d2 + 1.0) >= 1.5 and d1 >= min(40.0, contrast * 0.8)
        if yes:
            bg |= lab == i
            islands += 1
    # the grey fringe round the edges (a pixel half chequerboard, half outline)
    for _ in range(2):
        near = np.zeros_like(bg)
        near[1:, :] |= bg[:-1, :]; near[:-1, :] |= bg[1:, :]; near[:, 1:] |= bg[:, :-1]; near[:, :-1] |= bg[:, 1:]
        fringe, _ = grey_mask(rgb, sat_max=40, lum_min=90)
        bg |= near & fringe & ~bg
    alpha = np.where(bg, 0, 255).astype(np.uint8)
    a = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.7))
    a = Image.fromarray(np.clip((np.asarray(a).astype(np.int32) - 40) * 255 // 175, 0, 255).astype(np.uint8))
    out = Image.fromarray(rgb).convert('RGBA')
    out.putalpha(a)
    box = out.getbbox()
    if box:
        m = 6
        out = out.crop((max(0, box[0] - m), max(0, box[1] - m), min(out.width, box[2] + m), min(out.height, box[3] + m)))
    k = FINAL / max(out.size)
    out = out.resize((round(out.width * k), round(out.height * k)), Image.LANCZOS)
    os.makedirs(OUT, exist_ok=True)
    out.save(os.path.join(OUT, name + '.png'))
    print('%-12s %dx%d  (%d islands of chequerboard inside)' % (name, out.width, out.height, islands))
    return out


def wear(size=256, seed=7):
    """desgaste.png: what years of sun and rain do to paint on a wall, as two tileable noises the graffiti shader
    reads (props.gd): red, broad blotches where it has faded; green, fine specks where it has flaked off"""
    rng = np.random.default_rng(seed)
    fy = np.fft.fftfreq(size)[:, None]
    fx = np.fft.fftfreq(size)[None, :]
    f = np.sqrt(fx * fx + fy * fy)

    def noise(cut):
        white = rng.standard_normal((size, size))
        smooth = np.real(np.fft.ifft2(np.fft.fft2(white) * np.exp(-(f / cut) ** 2)))     # (filtered in the frequency domain: it wraps round)
        smooth -= smooth.min()
        return smooth / max(1e-6, smooth.max())

    blotch = 0.65 * noise(0.012) + 0.35 * noise(0.03)
    speck = 0.6 * noise(0.11) + 0.4 * noise(0.22)
    img = np.stack([blotch, speck, np.zeros_like(blotch)], axis=2)
    Image.fromarray((img * 255).astype(np.uint8)).save(os.path.join(OUT, 'desgaste.png'))
    print('desgaste.png %dx%d' % (size, size))


if __name__ == '__main__':
    for p in PENAS:
        clean(p)
    wear()
