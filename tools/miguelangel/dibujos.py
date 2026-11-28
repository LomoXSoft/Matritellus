"""The pictures of the Pizzeria Miguel Ángel (godot/assets/miguelangel/), drawn here: the game's own box sign for the
pizzeria of the Calle de Tembleque (the user, 27 November 2026: "Pizzería Michelangelo (que llamaremos Pizzeria Miguel
Ángel)"; and "En el cartel que ponga Burger Pizzería Miguel Ángel"). The real sign reads PIZZERIA BURGUER over the
name in a pale blue script; here the words are the user's. No telephone, address or web.

    python tools/miguelangel/dibujos.py [where]      (where: another folder to draw into, to look at them first)

letrero.png     the two faces of the box sign (1.0 x 0.7 m), in the real one's style: BURGER / PIZZERÍA in tall narrow
                crimson letters with serifs, Miguel Ángel in a pale blue script under them, on blue-black in a frame of
                aluminium
baldosa.png     the foot of the front: terracotta tiles with a cream diamond lattice (2 x 2 tiles of 20 cm)
cortina.png     the striped curtain in the doorway of the flats (cream, brown, green and red stripes, as in Catastro's
                photograph)
After adding or changing them: Godot --headless --path godot --import.
"""
import os
import random
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', 'godot', 'assets', 'miguelangel')
os.makedirs(OUT, exist_ok=True)


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


SERIF_B = ['cambriab.ttf', 'georgiab.ttf', 'timesbd.ttf']
SCRIPT = ['segoescb.ttf', 'segoesc.ttf', 'Gabriola.ttf', 'georgiai.ttf']


def fitted(text, fnt, fill, stroke, stroke_fill, w, h):
    """the words drawn on a sheet of their own, cropped to them and stretched to w x h"""
    big = Image.new('RGBA', (3000, 700), (0, 0, 0, 0))
    bd = ImageDraw.Draw(big)
    bd.text((40, 40), text, font=fnt, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)
    big = big.crop(big.getbbox())
    return big.resize((w, h), Image.LANCZOS)


def caps_line(text, fnt, fill, stroke, stroke_fill, w, cap_h):
    """a line of capitals stretched to w wide with its capitals cap_h high, whatever accents rise over them; and how far
    down the picture its capitals begin"""
    plain = text.translate(str.maketrans('ÁÉÍÓÚÑ', 'AEIOUN'))
    big = Image.new('RGBA', (3000, 900), (0, 0, 0, 0))
    bd = ImageDraw.Draw(big)
    bd.text((40, 200), text, font=fnt, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)
    probe = Image.new('L', (3000, 900), 0)
    ImageDraw.Draw(probe).text((40, 200), plain, font=fnt, fill=255, stroke_width=stroke)
    full = big.getbbox()
    caps = probe.getbbox()
    big = big.crop(full)
    ky = cap_h / float(caps[3] - caps[1])
    out = big.resize((w, max(1, int(round(big.size[1] * ky)))), Image.LANCZOS)
    return out, int(round((caps[1] - full[1]) * ky))


def letrero():
    """as the real one (the user's photograph, 27 Nov 2026: "Que se parezca más en estilo al original"): a face of
    blue-black inside a broad frame of aluminium; two words in tall narrow letters with serifs, of a crimson that
    glows a little, filling the face; the name under them in a bold slanting script of pale blue"""
    w, h = 1024, 720                  # (the panel: 1.0 by 0.7 m, its frame included)
    rng = random.Random(27)
    im = Image.new('RGBA', (w, h), (16, 16, 34, 255))
    # a little light from inside, stronger in the middle (a lit box sign)
    glow = Image.new('L', (w, h), 0)
    ImageDraw.Draw(glow).ellipse((-w // 5, -h // 6, w + w // 5, h + h // 6), fill=40)
    glow = glow.filter(ImageFilter.GaussianBlur(140))
    lay = Image.new('RGBA', (w, h), (44, 40, 78, 255))
    lay.putalpha(glow)
    im = Image.alpha_composite(im, lay)
    d = ImageDraw.Draw(im)
    # the frame of aluminium: broad and pale, a darker line where it meets the face, its light on the top and the left
    fr = 44
    d.rectangle((0, 0, w - 1, h - 1), fill=None, outline=(176, 180, 186, 255), width=fr)
    d.line((0, 2, w, 2), fill=(222, 226, 230, 255), width=6)
    d.line((2, 0, 2, h), fill=(214, 218, 222, 255), width=6)
    d.line((0, h - 3, w, h - 3), fill=(120, 124, 130, 255), width=6)
    d.rectangle((fr - 4, fr - 4, w - fr + 3, h - fr + 3), outline=(70, 72, 80, 255), width=5)
    crimson = (176, 28, 70, 255)
    edge = (108, 14, 44, 255)
    f = font(SERIF_B, 300)
    # (the user, 27 Nov 2026: "En el cartel que ponga Burger Pizzería Miguel Ángel": the two words in that order, the
    # accent of PIZZERÍA rising into the gap between the lines)
    for text, top in (('BURGER', 72), ('PIZZERÍA', 334)):
        sheet, cap = caps_line(text, f, crimson, 3, edge, int(w * 0.78), 196)       # (narrow: drawn and squeezed)
        halo = sheet.filter(ImageFilter.GaussianBlur(9))
        halo.putalpha(halo.getchannel('A').point(lambda v: v * 0.45))
        at = ((w - sheet.size[0]) // 2, top - cap)
        im.alpha_composite(halo, at)
        im.alpha_composite(sheet, at)
    s = font(SCRIPT, 220)
    blue = (150, 184, 246, 255)
    name = fitted('Miguel Ángel', s, blue, 5, blue, int(w * 0.6), 112)
    k = 0.32                          # (slanting like the real one's: a shear to the right)
    name = name.transform((name.size[0] + int(k * name.size[1]), name.size[1]), Image.AFFINE,
                          (1, k, -k * name.size[1], 0, 1, 0), Image.BICUBIC)
    halo = name.filter(ImageFilter.GaussianBlur(7))
    halo.putalpha(halo.getchannel('A').point(lambda v: v * 0.5))
    nx = (w - name.size[0]) // 2 + 20
    im.alpha_composite(halo, (nx, 556))
    im.alpha_composite(name, (nx, 556))
    # dust of years on its face
    noise = Image.new('L', (w // 16, h // 16))
    noise.putdata([int(rng.uniform(0, 255)) for _ in range(noise.size[0] * noise.size[1])])
    noise = noise.resize((w, h), Image.BICUBIC).point(lambda v: max(0, v - 190) // 4)
    dust = Image.new('RGBA', (w, h), (150, 140, 120, 255))
    dust.putalpha(noise)
    im = Image.alpha_composite(im, dust)
    im.convert('RGB').save(os.path.join(OUT, 'letrero.png'))


def baldosa():
    """two by two tiles: each a terracotta square with a cream diamond set in it, so that together they make the
    lattice of the photographs"""
    n = 256
    t = n // 2
    rng = random.Random(8)
    im = Image.new('RGB', (n, n), (168, 86, 54))
    d = ImageDraw.Draw(im)
    for i in range(2):
        for j in range(2):
            x0, y0 = i * t, j * t
            base = tuple(max(0, min(255, c + rng.randint(-10, 10))) for c in (170, 88, 56))
            d.rectangle((x0, y0, x0 + t - 1, y0 + t - 1), fill=base)
            m = t // 2
            pts = [(x0 + m, y0 + 6), (x0 + t - 6, y0 + m), (x0 + m, y0 + t - 6), (x0 + 6, y0 + m)]
            d.polygon(pts, outline=(232, 214, 180), width=9)
            d.polygon([(x0 + m, y0 + 30), (x0 + t - 30, y0 + m), (x0 + m, y0 + t - 30), (x0 + 30, y0 + m)], fill=(150, 72, 44))
            d.rectangle((x0, y0, x0 + t - 1, y0 + t - 1), outline=(206, 190, 160), width=3)       # (the grout)
    im = im.filter(ImageFilter.GaussianBlur(0.8))
    im.save(os.path.join(OUT, 'baldosa.png'))


def cortina():
    w, h = 256, 512
    im = Image.new('RGB', (w, h), (226, 214, 186))
    d = ImageDraw.Draw(im)
    cols = [(226, 214, 186), (122, 84, 54), (226, 214, 186), (84, 112, 70), (236, 228, 208), (168, 52, 44), (226, 214, 186), (122, 84, 54)]
    x = 0
    k = 0
    widths = [30, 14, 22, 18, 26, 10, 24, 16]
    while x < w:
        ww = widths[k % len(widths)]
        d.rectangle((x, 0, x + ww - 1, h), fill=cols[k % len(cols)])
        x += ww
        k += 1
    # its folds: soft upright shading
    for i in range(0, w, 32):
        d.rectangle((i, 0, i + 10, h), fill=None)
    shade = Image.new('L', (w, h), 0)
    sd = ImageDraw.Draw(shade)
    for i in range(0, w, 32):
        sd.rectangle((i + 18, 0, i + 30, h), fill=70)
    shade = shade.filter(ImageFilter.GaussianBlur(6))
    dark = Image.new('RGB', (w, h), (40, 30, 24))
    im = Image.composite(dark, im, shade)
    im.save(os.path.join(OUT, 'cortina.png'))


letrero()
baldosa()
cortina()
print('drawn in', os.path.abspath(OUT))
