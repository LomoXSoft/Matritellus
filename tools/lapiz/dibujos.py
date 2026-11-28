"""The pictures of the Taller Lápiz and of Dulces San Paquito (godot/assets/lapiz/), drawn here: the game's own signs
for the car electrician's of the Avenida de Martín Descalzo and the sweet maker's next door (the user, 27 November
2026: "Taller López (que llamaremos taller Lápiz) y dulces san Francisco (que llamaremos dulces san Paquito)"). The
real names, telephone numbers and web address are left out; what the scroll lists is our own wording.

    python tools/lapiz/dibujos.py

rotulo.png          the board on the parapet (7.1 x 0.65 m): TALLER LÁPIZ in tall red letters, faded, on white
letras.png          the trade painted along the top of its front (14 x 0.62 m): ELECTRICIDAD DEL AUTOMÓVIL in blue,
                    on nothing (alpha: the wall's own white behind)
dulces.png          the painted panel on the white pier (1.7 x 1.2 m): DULCES SAN PAQUITO, a friar's plain silhouette
                    (as on the real one), a scroll of what they make
baldosa_gris.png    the workshop's foot: grey tiles with a white lattice (4 x 4 tiles of 20 cm)
baldosa_salmon.png  the white house's foot: salmon tiles (4 x 2 tiles of 25 x 20 cm)
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'lapiz')
os.makedirs(OUT, exist_ok=True)


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


TALL = ['impact.ttf', 'arialbd.ttf']
BLACK = ['ariblk.ttf', 'arialbd.ttf']
SERIF = ['times.ttf', 'georgia.ttf']
SCRIPT = ['segoesc.ttf', 'Gabriola.ttf', 'georgiai.ttf']


def stains(im, rng, cell, col, alpha, cut=0.55):
    """cloudy stains of weather over a picture (noise blown up soft): dirt, or paint gone"""
    w, h = im.size
    small = Image.new('L', (max(2, w // cell), max(2, h // cell)))
    small.putdata([int(rng.uniform(0, 255)) for _ in range(small.size[0] * small.size[1])])
    big = small.resize((w, h), Image.BICUBIC).filter(ImageFilter.GaussianBlur(cell / 3.0))
    lo = int(255 * cut)
    a = big.point(lambda v: 0 if v < lo else min(255, int((v - lo) * 255 / max(1, 255 - lo) * alpha / 255.0)))
    lay = Image.new('RGBA', (w, h), col + (255,))
    lay.putalpha(a)
    return Image.alpha_composite(im, lay)


def flecks(size, rng, cell, cut):
    """where paint has come away: an irregular mask (255 = gone)"""
    w, h = size
    small = Image.new('L', (max(2, w // cell), max(2, h // cell)))
    small.putdata([int(rng.uniform(0, 255)) for _ in range(small.size[0] * small.size[1])])
    big = small.resize((w, h), Image.BICUBIC)
    return big.point(lambda v: 255 if v > cut else 0)


def rotulo():
    """TALLER LÁPIZ: tall letters of a pink faded red, each with a darker edge and a shadow to its right and down (the
    real board's look: painted by hand long ago), on the parapet's white"""
    w, h = 2048, 318                  # (the board: 7.0 by 1.08 m)
    rng = random.Random(27)
    im = Image.new('RGBA', (w, h), (236, 234, 226, 255))
    im = stains(im, rng, 24, (196, 190, 176), 110)
    text = 'TALLER LÁPIZ'
    f = font(TALL, 300)
    # drawn on a sheet of its own, then stretched to fill the board as the real letters do (Street View 2024: the
    # two words from end to end of it, nearly its whole height)
    big = Image.new('RGBA', (2600, 420), (0, 0, 0, 0))
    bd = ImageDraw.Draw(big)
    bd.text((24, 10), text, font=f, fill=(96, 92, 104, 210))                        # the shadow, grey-blue
    bd.text((10, 0), text, font=f, fill=(196, 92, 84, 255), stroke_width=7, stroke_fill=(150, 46, 40, 255))
    bd.text((10, 0), text, font=f, fill=(214, 128, 116, 255))                      # the faded face
    big = big.crop(big.getbbox())
    tw, th = int(w * 0.95), int(h * 0.86)
    sheet = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    sheet.paste(big.resize((tw, th), Image.LANCZOS), ((w - tw) // 2, (h - th) // 2))
    a = sheet.split()[3]
    gone = flecks((w, h), rng, 22, 234)
    a = Image.composite(Image.new('L', (w, h), 0), a, gone)
    sheet.putalpha(a)
    sheet = stains(sheet, rng, 14, (236, 226, 216), 120, 0.6)
    sheet.putalpha(a)
    im = Image.alpha_composite(im, sheet)
    # dirt running down from the top
    lay = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lay)
    for _ in range(70):
        x = rng.uniform(0, w)
        ld.line([x, 0, x + rng.uniform(-3, 3), rng.uniform(20, 120)], fill=(120, 112, 96, int(rng.uniform(20, 60))), width=int(rng.uniform(2, 6)))
    im = Image.alpha_composite(im, lay.filter(ImageFilter.GaussianBlur(2)))
    im.convert('RGB').save(os.path.join(OUT, 'rotulo.png'))


def letras():
    """ELECTRICIDAD DEL AUTOMÓVIL: heavy blue letters painted on the wall, "DEL" smaller, worn here and there"""
    w, h = 4096, 272                  # (the band: 13.9 by 0.92 m)
    rng = random.Random(9)
    # drawn on a sheet of its own, then stretched across the whole front as the real letters are (Street View 2024:
    # from the corner by the salmon house to the blue bay, tall and a little narrow)
    sheet = Image.new('RGBA', (5200, 220), (0, 0, 0, 0))
    d = ImageDraw.Draw(sheet)
    big = font(BLACK, 150)
    small = font(BLACK, 92)
    parts = [('ELECTRICIDAD ', big), ('DEL ', small), ('AUTOMÓVIL', big)]
    x = 10
    for t, f in parts:
        y = 8 if f is big else 62
        d.text((x, y), t, font=f, fill=(34, 48, 112, 255))
        x += d.textlength(t, font=f)
    sheet = sheet.crop(sheet.getbbox())
    tw, th = int(w * 0.97), int(h * 0.86)
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    im.paste(sheet.resize((tw, th), Image.LANCZOS), ((w - tw) // 2, (h - th) // 2))
    a = im.split()[3]
    gone = flecks((w, h), rng, 12, 238)
    a = Image.composite(Image.new('L', (w, h), 0), a, gone)
    im.putalpha(a)
    im.save(os.path.join(OUT, 'letras.png'))


def friar(d, cx, foot, hgt, col):
    """a friar standing, seen from the side, his hood up, a rope at his waist, holding out a tray of sweets: a plain
    dark silhouette, as on the real panel"""
    s = hgt / 100.0
    d.polygon([(cx - 15 * s, foot), (cx + 17 * s, foot), (cx + 11 * s, foot - 62 * s), (cx + 9 * s, foot - 80 * s),
               (cx - 7 * s, foot - 82 * s), (cx - 12 * s, foot - 60 * s)], fill=col)                         # the habit
    d.ellipse([cx - 8 * s, foot - 98 * s, cx + 9 * s, foot - 79 * s], fill=col)                             # the hooded head
    d.polygon([(cx - 9 * s, foot - 92 * s), (cx - 13 * s, foot - 78 * s), (cx - 4 * s, foot - 80 * s)], fill=col)
    d.polygon([(cx + 6 * s, foot - 74 * s), (cx + 28 * s, foot - 62 * s), (cx + 27 * s, foot - 57 * s), (cx + 4 * s, foot - 64 * s)], fill=col)   # the arm, out
    d.rectangle([cx + 20 * s, foot - 66 * s, cx + 40 * s, foot - 63 * s], fill=col)                       # the tray
    for k in range(3):
        d.ellipse([cx + (22 + 6 * k) * s, foot - 71 * s, cx + (27 + 6 * k) * s, foot - 66 * s], fill=col)    # on it
    d.line([(cx - 11 * s, foot - 56 * s), (cx + 11 * s, foot - 56 * s)], fill=(236, 232, 222), width=max(1, int(1.6 * s)))   # the rope
    d.line([(cx + 2 * s, foot - 56 * s), (cx + 4 * s, foot - 30 * s)], fill=(236, 232, 222), width=max(1, int(1.4 * s)))
    d.ellipse([cx + 2 * s, foot - 31 * s, cx + 6 * s, foot - 27 * s], outline=(236, 232, 222), width=max(1, int(1.2 * s)))


def scroll(d, x0, y0, x1, y1):
    """a scroll of parchment, rolled at its top and its foot"""
    paper = (236, 222, 186)
    roll = (214, 194, 146)
    line = (90, 70, 40)
    d.rectangle([x0 + 22, y0 + 10, x1 - 22, y1 - 10], fill=paper, outline=line, width=3)
    for yy in (y0, y1):
        d.rounded_rectangle([x0 + 6, yy - 16, x1 - 6, yy + 16], radius=16, fill=roll, outline=line, width=3)
        d.line([x0 + 20, yy - 4, x1 - 20, yy - 4], fill=(236, 220, 176), width=4)
        for xx in (x0 + 6, x1 - 6):
            d.ellipse([xx - 12, yy - 16, xx + 12, yy + 16], fill=(190, 168, 120), outline=line, width=3)


def dulces():
    """the white panel on the pier: DULCES SAN PAQUITO across the top, the friar at the left, the scroll at the right"""
    w, h = 1024, 724
    rng = random.Random(16)
    im = Image.new('RGBA', (w, h), (240, 238, 230, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([10, 10, w - 11, h - 11], outline=(70, 66, 60, 255), width=5)
    f = font(SERIF, 92)
    t = 'DULCES SAN PAQUITO'
    tw = d.textlength(t, font=f)
    d.text(((w - tw) / 2, 34), t, font=f, fill=(34, 32, 30, 255))
    friar(d, 190, 650, 470, (40, 30, 24, 255))
    scroll(d, 380, 176, 970, 640)
    fs = font(SCRIPT, 46)
    lines = ['Obrador artesano', 'Rosquillas de anís', 'Mantecados', 'Mazapanes', 'Bizcochos', 'Flores de sartén']
    y = 214
    for ln in lines:
        lw = d.textlength(ln, font=fs)
        d.text((675 - lw / 2, y), ln, font=fs, fill=(70, 50, 30, 255))
        y += 66
    im = stains(im, rng, 30, (196, 190, 176), 90)
    lay = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lay)
    for _ in range(40):
        x = rng.uniform(0, w)
        ld.line([x, h * 0.6, x + rng.uniform(-4, 4), h], fill=(120, 110, 90, int(rng.uniform(20, 50))), width=int(rng.uniform(3, 8)))
    im = Image.alpha_composite(im, lay.filter(ImageFilter.GaussianBlur(3)))
    im.convert('RGB').save(os.path.join(OUT, 'dulces.png'))


def baldosa_gris():
    """grey tiles, each with a white lattice of diamonds (the workshop's foot, Street View 2024)"""
    n, px = 4, 64
    im = Image.new('RGB', (n * px, n * px), (150, 154, 160))
    d = ImageDraw.Draw(im)
    rng = random.Random(3)
    for i in range(n):
        for j in range(n):
            x0, y0 = i * px, j * px
            g = int(rng.uniform(-8, 8))
            d.rectangle([x0, y0, x0 + px - 1, y0 + px - 1], fill=(146 + g, 150 + g, 158 + g))
            c = px / 2
            for k in (0.18, 0.34):
                r = px * k
                d.polygon([(x0 + c, y0 + c - r), (x0 + c + r, y0 + c), (x0 + c, y0 + c + r), (x0 + c - r, y0 + c)], outline=(226, 228, 230), width=3)
            for cx, cy in ((0, 0), (px, 0), (0, px), (px, px)):
                d.polygon([(x0 + cx, y0 + cy - 9), (x0 + cx + 9, y0 + cy), (x0 + cx, y0 + cy + 9), (x0 + cx - 9, y0 + cy)], fill=(222, 224, 226))
            d.rectangle([x0, y0, x0 + px - 1, y0 + px - 1], outline=(196, 196, 192), width=2)        # the joints
    im.save(os.path.join(OUT, 'baldosa_gris.png'))


def baldosa_salmon():
    """salmon tiles of 25 x 20 cm, a little uneven in colour, pale joints (the white house's foot)"""
    nx, ny, pw, ph = 4, 2, 80, 64
    im = Image.new('RGB', (nx * pw, ny * ph), (226, 216, 204))
    d = ImageDraw.Draw(im)
    rng = random.Random(5)
    for i in range(nx):
        for j in range(ny):
            g = int(rng.uniform(-10, 10))
            d.rectangle([i * pw + 2, j * ph + 2, i * pw + pw - 3, j * ph + ph - 3], fill=(222 + g, 150 + g, 120 + g))
    im.save(os.path.join(OUT, 'baldosa_salmon.png'))


if __name__ == '__main__':
    rotulo()
    letras()
    dulces()
    baldosa_gris()
    baldosa_salmon()
    print('drawn in', os.path.normpath(OUT))
