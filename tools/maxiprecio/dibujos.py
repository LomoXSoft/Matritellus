"""The pictures of the clothes shop "MaxiPrecio" (godot/assets/maxiprecio/), drawn here: the game's own signs for the
Hiper Textil of the Calle de los Arcos (the user, 23 November 2026: "Vamos con el HiperTextil Miniprecio (que llamaremos
MaxiPrecio). Necesitará tener un interior (hay fotos en maps) y su horario comercial"). The real shop's badge is two
cherries with "Mini Precio" across them; ours is two peaches with "Maxi Precio" (the user, the same day: "Como el
logo original son dos cerezas que el nuestro sean dos melocotones", with a picture of the badge drawn so). No
telephone, no address, no social network.

    python tools/maxiprecio/dibujos.py

rotulo.png    the boards over the door, under the bay (2.9 x 1.0 m each): blue and white stripes, "Hiper Textil", the
              peaches with "Maxi Precio" across them
rayas.png     the white wall's blue stripes, slanting up to the right: one tile, 0.9 m across and 1.8 m high (it repeats)
mural.png     what is painted on the white walls of the Calle de Granada and the Calle del Molino over the stripes:
              "Hiper Textil" and the big peaches (2.6 x 2.4 m, see-through round them)
horario.png   the card of its hours on the door's glass (the real shop's, from Google Maps on 23 Nov 2026: Monday to
              Friday 9:30-14:00 and 17:00-21:00, Saturday 9:30-14:00, Sunday shut)
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'maxiprecio')
os.makedirs(OUT, exist_ok=True)
BLUE = (10, 40, 146)
WHITE = (250, 250, 248)
RED = (222, 52, 72)
RED_DARK = (168, 30, 50)
GREEN = (52, 128, 66)
GREEN_DARK = (30, 84, 44)
INK = (26, 30, 40)


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


SCRIPT = ['segoescb.ttf', 'segoesc.ttf', 'ariali.ttf']
BOLD = ['arialbd.ttf', 'DejaVuSans-Bold.ttf']


def stripes(img, period, slope, width, colour, shift=0.0):
    """blue bands slanting up to the right across a white picture: `period` px apart along x, rising `slope` px a px"""
    w, h = img.size
    d = ImageDraw.Draw(img)
    k = -int(h / slope / period) - 2
    while True:
        x0 = shift + k * period                       # where the band's left edge meets the bottom
        if x0 > w + period:
            break
        top = x0 + h / slope
        d.polygon([(x0, h), (x0 + width, h), (top + width, 0), (top, 0)], fill=colour)
        k += 1


PEACH_TOP = (212, 38, 34)        # the peaches: red over the top...
PEACH_MID = (236, 88, 34)
PEACH_LOW = (248, 170, 40)       # ...yellow-orange underneath
PEACH_DARK = (150, 24, 22)
LEAF = (52, 138, 50)
LEAF_LIGHT = (122, 188, 72)
LEAF_DARK = (26, 84, 32)
STEM = (112, 66, 38)
STEM_DARK = (68, 38, 22)


def _bezier(a, c, b, n=24):
    return [((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * c[0] + t * t * b[0], (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * c[1] + t * t * b[1]) for t in (k / n for k in range(n + 1))]


def _peach(W, H, c, r, yellow, light, crease):
    """one peach on a see-through layer: red over the top going to yellow-orange towards `yellow` (a direction),
    darker round its edge, a soft light at `light` (in its own radii), its crease (three points, in its radii)"""
    import numpy as np
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    u = (xx - c[0]) / r[0]
    v = (yy - c[1]) / r[1]
    d2 = u * u + v * v
    t = np.clip(((u * yellow[0] + v * yellow[1]) * 0.5 + 0.5 - 0.22) / 0.78, 0.0, 1.0) ** 1.15
    top, mid, low = (np.array(q, np.float32) for q in (PEACH_TOP, PEACH_MID, PEACH_LOW))
    t3 = t[..., None]
    col = np.where(t3 < 0.5, top + (mid - top) * (t3 * 2.0), mid + (low - mid) * ((t3 - 0.5) * 2.0))
    edge = (np.clip((d2 - 0.55) / 0.45, 0.0, 1.0) ** 2)[..., None] * 0.38
    col = col + (np.array(PEACH_DARK, np.float32) - col) * edge
    hl = np.exp(-(((u - light[0]) / 0.42) ** 2 + ((v - light[1]) / 0.36) ** 2) * 1.6)[..., None] * 0.34
    col = col + (np.array((255, 214, 170), np.float32) - col) * hl
    alpha = (d2 <= 1.0).astype(np.uint8) * 255
    img = np.dstack([np.clip(col, 0, 255).astype(np.uint8), alpha])
    lay = Image.fromarray(img, 'RGBA')
    # its crease and the dimple of its stalk: dark, soft, inside it only
    marks = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(marks)
    pts = [(c[0] + q[0] * r[0], c[1] + q[1] * r[1]) for q in crease]
    d.line(_bezier(pts[0], pts[1], pts[2]), fill=PEACH_DARK + (150,), width=max(2, int(W * 0.011)), joint='curve')
    dm = pts[0]
    d.ellipse([dm[0] - r[0] * 0.12, dm[1] - r[1] * 0.06, dm[0] + r[0] * 0.12, dm[1] + r[1] * 0.08], fill=PEACH_DARK + (170,))
    marks = marks.filter(ImageFilter.GaussianBlur(W * 0.006))
    marks.putalpha(ImageChops.multiply(marks.getchannel('A'), lay.getchannel('A')))
    lay.alpha_composite(marks)
    return lay


def _leaf(d, base, tip, wide, W):
    """a leaf from its base to its tip: green, one half lighter, its midrib and veins darker"""
    bx, by = base
    tx, ty = tip
    ln = math.hypot(tx - bx, ty - by)
    ux, uy = (tx - bx) / ln, (ty - by) / ln
    nx, ny = -uy, ux
    side_a, side_b, mid = [], [], []
    for k in range(25):
        s = k / 24
        w = wide * math.sin(math.pi * s) ** 0.75 * (1.0 - 0.35 * s)
        bend = ln * 0.06 * math.sin(math.pi * s)
        cx, cy = bx + (tx - bx) * s + nx * bend, by + (ty - by) * s + ny * bend
        side_a.append((cx + nx * w, cy + ny * w))
        side_b.append((cx - nx * w, cy - ny * w))
        mid.append((cx, cy))
    d.polygon(side_a + side_b[::-1], fill=LEAF)
    d.polygon(side_a + mid[::-1], fill=LEAF_LIGHT if ny < 0 else LEAF)
    d.polygon(side_b + mid[::-1], fill=LEAF_LIGHT if ny >= 0 else LEAF)
    d.line(mid, fill=LEAF_DARK, width=max(2, int(W * 0.007)))
    for k in range(3, 21, 4):
        p = mid[k]
        for q in (side_a[min(24, k + 3)], side_b[min(24, k + 3)]):
            d.line([p, (p[0] + (q[0] - p[0]) * 0.8, p[1] + (q[1] - p[1]) * 0.8)], fill=LEAF_DARK, width=max(1, int(W * 0.003)))


def peaches(size, words=True):
    """the badge: two peaches side by side, the right one in front, a stalk with two leaves over them, a white edge
    round them, "Maxi" and "Precio" written across them (see-through round it all). The real shop's badge is two
    cherries; ours are peaches (the user, 23 Nov 2026: "Como el logo original son dos cerezas que el nuestro sean dos
    melocotones", with a picture). size: (w, h) in px"""
    w, h = size
    s = 4                                              # (drawn four times bigger, then made smaller: smooth edges)
    W, H = w * s, h * s
    big = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    c1, r1 = (W * 0.29, H * 0.6), (W * 0.24, H * 0.33)          # the left peach, behind...
    c2, r2 = (W * 0.665, H * 0.6), (W * 0.285, H * 0.37)        # ...and the right one, in front
    halo = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    e = W * 0.022
    for c, r in ((c1, r1), (c2, r2)):
        hd.ellipse([c[0] - r[0] - e, c[1] - r[1] - e, c[0] + r[0] + e, c[1] + r[1] + e], fill=WHITE + (255,))
    big.alpha_composite(halo)
    big.alpha_composite(_peach(W, H, c1, r1, (-0.55, 0.85), (0.2, -0.45), [(0.25, -0.9), (-0.55, -0.7), (-0.62, 0.35)]))
    big.alpha_composite(_peach(W, H, c2, r2, (0.45, 0.9), (-0.25, -0.4), [(-0.1, -0.93), (0.55, -0.8), (0.72, 0.15)]))
    d = ImageDraw.Draw(big)
    # the stalk: from the top down to the left peach, a branch to the right one
    top = (W * 0.56, H * 0.03)
    fork = (W * 0.5, H * 0.15)
    left_end = (c1[0] + r1[0] * 0.25, c1[1] - r1[1] * 0.88)
    right_end = (c2[0] - r2[0] * 0.1, c2[1] - r2[1] * 0.9)
    for a, b, wd in ((top, left_end, 0.022), (fork, right_end, 0.017)):
        d.line([a, b], fill=STEM, width=int(W * wd))
        d.line([(a[0] + W * 0.004, a[1]), (b[0] + W * 0.004, b[1])], fill=STEM_DARK, width=max(1, int(W * wd * 0.3)))
    d.ellipse([top[0] - W * 0.011, top[1] - W * 0.011, top[0] + W * 0.011, top[1] + W * 0.011], fill=STEM)
    _leaf(d, (W * 0.47, H * 0.2), (W * 0.06, H * 0.27), H * 0.075, W)
    _leaf(d, (W * 0.53, H * 0.2), (W * 0.9, H * 0.19), H * 0.06, W)
    if words:
        for word, c, r, tilt, wide, shift in (('Maxi', c1, r1, 14, 0.27, -0.2), ('Precio', c2, r2, 14, 0.42, 0.08)):
            f = font(SCRIPT, 100)
            f = font(SCRIPT, int(100 * W * wide / d.textlength(word, font=f)))     # (each word as wide as the part of its peach that shows)
            tw = d.textlength(word, font=f)
            lay = Image.new('RGBA', (int(tw + H * 0.12), int(r[1] * 1.3)), (0, 0, 0, 0))
            ld = ImageDraw.Draw(lay)
            ld.text((H * 0.06, r[1] * 0.08), word, font=f, fill=WHITE, stroke_width=max(1, int(f.size * 0.035)), stroke_fill=WHITE)      # (thick, as if by brush)
            y_line = r[1] * 0.08 + f.size * 1.18                  # the swoosh under it, rising to the right
            ld.line(_bezier((H * 0.07 + tw * 0.15, y_line + f.size * 0.08), (H * 0.06 + tw * 0.5, y_line + f.size * 0.04), (H * 0.06 + tw * 0.98, y_line - f.size * 0.18)),
                    fill=WHITE, width=max(2, int(f.size * 0.07)), joint='curve')
            lay = lay.rotate(tilt, expand=True, resample=Image.BICUBIC)
            big.alpha_composite(lay, (int(c[0] - lay.width / 2 + r[0] * shift), int(c[1] - lay.height / 2 + r[1] * 0.12)))
    return big.resize((w, h), Image.LANCZOS)


def rotulo():
    w, h = 1160, 400
    img = Image.new('RGBA', (w, h), WHITE + (255,))
    stripes(img, 120, 1.6, 34, BLUE)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w - 1, h - 1], outline=(214, 216, 220), width=6)
    badge = peaches((520, 360))
    plate = Image.new('RGBA', (560, 380), (0, 0, 0, 0))                # (a white ground behind the badge, so it reads)
    ImageDraw.Draw(plate).ellipse([0, 10, 559, 379], fill=WHITE + (235,))
    img.alpha_composite(plate, (w // 2 - 280, 14))
    img.alpha_composite(badge, (w // 2 - 260, 34))
    f = font(SCRIPT, 62)
    t = 'Hiper Textil'
    tw = d.textlength(t, font=f)
    d.text(((w - tw) / 2, 2), t, font=f, fill=BLUE, stroke_width=3, stroke_fill=WHITE)
    img.convert('RGB').save(os.path.join(OUT, 'rotulo.png'))


def rayas():
    w, h = 180, 360                                    # (0.9 x 1.8 m: 200 px a metre)
    img = Image.new('RGB', (w, h), WHITE)
    stripes(img, w, h / w, 30, BLUE)                   # (one band a tile, so that it carries on into the next)
    img.save(os.path.join(OUT, 'rayas.png'))


def mural():
    w, h = 780, 720                                    # (2.6 x 2.4 m: 300 px a metre)
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    badge = peaches((700, 600))
    img.alpha_composite(badge, (40, 120))
    d = ImageDraw.Draw(img)
    f = font(SCRIPT, 96)
    d.text((40, 0), 'Hiper Textil', font=f, fill=BLUE, stroke_width=4, stroke_fill=WHITE)
    img.save(os.path.join(OUT, 'mural.png'))


def horario():
    w, h = 300, 400
    img = Image.new('RGB', (w, h), WHITE)
    d = ImageDraw.Draw(img)
    stripes(img, 60, 1.6, 12, BLUE)
    d.rectangle([14, 14, w - 15, h - 15], fill=WHITE)
    badge = peaches((150, 110), False)
    img.paste(badge, (75, 22), badge)
    fb = font(BOLD, 30)
    fs = font(BOLD, 22)
    t = 'HORARIO'
    d.text(((w - d.textlength(t, font=fb)) / 2, 140), t, font=fb, fill=BLUE)
    rows = [('Lunes a viernes', ''), ('9:30 - 14:00', ''), ('17:00 - 21:00', ''), ('Sábado', ''), ('9:30 - 14:00', ''), ('Domingo cerrado', '')]
    y = 186
    for i, (a, _) in enumerate(rows):
        colour = INK if a[0].isdigit() else BLUE
        d.text(((w - d.textlength(a, font=fs)) / 2, y), a, font=fs, fill=colour)
        y += 32 if i not in (2, 4) else 40
    img.save(os.path.join(OUT, 'horario.png'))


if __name__ == '__main__':
    rotulo()
    rayas()
    mural()
    horario()
    print('ok', os.path.abspath(OUT))
