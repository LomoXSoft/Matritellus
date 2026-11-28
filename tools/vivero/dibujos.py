"""The pictures of the Vivero de Empresas (godot/assets/vivero/), drawn here. The business incubator of the Avenida de
la Reina Sofía (the user, 27 November 2026: "Ponte ahora con el Vivero de empresas. Que se pueda pasar y tenga
horario"): the old health centre wrapped in a lattice of pale brick, a blue gate with its name cut big. Its words:
VIVERO and the town's name on the gate, as the real one; no telephone, address or web.

    python tools/vivero/dibujos.py [where]      (where: another folder to draw into, to look at them first)

celosia.png          the lattice of the front, as most of it is: pale brick laid with small holes, row upon row, each
                     row half a hole along from the one under it (a tile of 0.52 x 0.52 m; the holes see-through)
celosia_abierta.png  the lattice where it lets more through (the band over the gate and before the way in): every other
                     brick left out, a chequer (the same tile)
puerta.png           the blue gate: a perforated sheet, VIVE over RO in tall letters and the town's name up its right
                     edge (2.0 x 2.05 m; the holes see-through)
placas.png           the two white plates by the gate: the name, and its hours
minusvalidos.png     the sign of the bay for disabled drivers before it (the wheelchair, white on blue)
rotulo.png           inside, over the reception: the name on the wall
carteles.png         inside, the little signs by the doors (eight rows of a picture: see LABELS)
tablon.png           inside, the cork board with its notes and leaflets
pantalla.png         inside, the meeting room's screen (a slide of a business plan)
After adding or changing them: Godot --headless --path godot --import.
"""
import os
import random
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', 'godot', 'assets', 'vivero')
os.makedirs(OUT, exist_ok=True)

NAVY = (26, 40, 140)
BRICK = (250, 214, 184)
LABELS = ['RECEPCIÓN', 'DESPACHO 1', 'DESPACHO 2', 'COWORKING', 'SALA DE REUNIONES', 'OFFICE', 'ASEOS', 'PATIO']


def font(name, size, variation=None):
    try:
        f = ImageFont.truetype(name, size)
        if variation:
            f.set_variation_by_name(variation)
        return f
    except Exception:
        return ImageFont.truetype('arialbd.ttf', size)


def fitted(text, fnt, fill, w, h):
    """the words on a sheet of their own, cropped to them and stretched to w x h"""
    big = Image.new('RGBA', (4000, 1200), (0, 0, 0, 0))
    ImageDraw.Draw(big).text((60, 60), text, font=fnt, fill=fill)
    big = big.crop(big.getbbox())
    return big.resize((w, h), Image.LANCZOS)


def lattice(open_):
    """a tile 0.4 m wide and 0.3 m high (256 x 192 px: 6.4 px a centimetre both ways), courses of 7.5 cm (48 px) of
    bricks 20 cm long (128 px) with their joints. Measured on the user's photograph (27 Nov 2026, 76.8 px a metre):
    a hole every 40 cm along a row, the rows 15 cm apart, each row half a hole along from the last. The close one: holes
    of 15.5 by 8.5 cm, not holes at all but bricks set back under one that juts out: painted, in their shade (no alpha).
    The open one (before the porch and the windows behind): holes
    of 12.5 by 12 cm, a chequer."""
    w, h = 256, 192
    rng = random.Random(14 if open_ else 15)
    im = Image.new('RGBA', (w, h), (246, 230, 214, 255))              # (the mortar, a shade lighter and greyer)
    d = ImageDraw.Draw(im)
    course = 48
    for row in range(h // course):
        y0 = row * course
        x = -((row % 2) * 64)
        while x < w:
            k = rng.randint(-10, 8)                   # (each brick a little lighter or darker, its hue the same)
            c = (BRICK[0] + k, BRICK[1] + k, BRICK[2] + k - rng.randint(0, 4))
            d.rectangle((x + 3, y0 + 3, x + 124, y0 + course - 4), fill=c + (255,))
            x += 128
        d.line((0, y0, w, y0), fill=(246, 232, 216, 255), width=3)
    holes = []
    for r in range(2):
        if open_:
            x0, y0 = 15 + r * 128, r * 96 + 8
            holes.append((x0, y0, x0 + 80, y0 + 77))
        else:
            x0, y0 = 8 + r * 128, r * 96 + 4
            holes.append((x0, y0, x0 + 100, y0 + 54))
    for (x0, y0, x1, y1) in holes:
        # the brick over it, lit on top; its shadow down the hole's left side; a lighter sill under it
        d.rectangle((x0 - 4, y0 - 6, x1 + 2, y0 - 2), fill=(255, 238, 220, 255))
        d.rectangle((x0 - 7, y0 - 2, x0 - 1, y1 + 3), fill=(188, 150, 126, 255))
        d.rectangle((x0, y1, x1, y1 + 4), fill=(220, 186, 160, 255))
    if not open_:
        for (x0, y0, x1, y1) in holes:                # (the brick set back: dark under the one over it, lighter down to its sill)
            for y in range(y0, y1):
                k = (y - y0) / float(y1 - y0)
                c = tuple(int(a + (b - a) * min(1.0, k * 1.2)) for a, b in zip((108, 76, 60), (182, 142, 116)))
                d.line((x0, y, x1 - 1, y), fill=c + (255,))
        return im
    alpha = im.getchannel('A')
    ad = ImageDraw.Draw(alpha)
    for (x0, y0, x1, y1) in holes:
        for dx in (-w, 0, w):                         # (a hole crossing the tile's edge comes back on the other side)
            ad.rectangle((x0 + dx, y0, x1 - 1 + dx, y1 - 1), fill=0)
    im.putalpha(alpha)
    return im


def line(text, fnt, fill, h):
    """the words at h high, as wide as their own shape makes them"""
    big = Image.new('RGBA', (4000, 1200), (0, 0, 0, 0))
    ImageDraw.Draw(big).text((60, 60), text, font=fnt, fill=fill)
    big = big.crop(big.getbbox())
    return big.resize((max(1, int(big.width * h / big.height)), h), Image.LANCZOS)


def puerta():
    """the gate: a blue perforated sheet in a frame, VIVE over RO filling most of it, the town's name reading up its
    right edge; the letters solid, the sheet round them see-through in fine holes"""
    w, h = 512, 525                                                  # (2.0 x 2.05 m)
    blue = (36, 54, 168, 255)
    dark = (22, 32, 120, 255)
    im = Image.new('RGBA', (w, h), blue)
    a = Image.new('L', (w, h), 255)
    ad = ImageDraw.Draw(a)
    for y in range(14, h - 14, 9):                                   # the perforations: holes of 4 px every 9
        for x in range(14 + (4 if (y // 9) % 2 else 0), w - 14, 9):
            ad.rectangle((x, y, x + 3, y + 3), fill=0)
    f = font('bahnschrift.ttf', 400, 'Bold Condensed')
    letters = Image.new('L', (w, h), 0)
    top = fitted('VIVE', f, (255, 255, 255, 255), 370, 236).getchannel('A')
    bot = fitted('RO', f, (255, 255, 255, 255), 236, 236).getchannel('A')
    letters.paste(top, (24, 20), top)
    letters.paste(bot, (90, 270), bot)
    side = fitted('MADRIDEJOS', font('bahnschrift.ttf', 300, 'SemiBold Condensed'), (255, 255, 255, 255), 470, 78).getchannel('A').rotate(90, expand=True)
    letters.paste(side, (w - side.size[0] - 18, (h - side.size[1]) // 2), side)
    a = Image.composite(Image.new('L', (w, h), 255), a, letters)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, w - 1, h - 1), outline=dark, width=12)
    im.putalpha(a)
    lay = Image.new('RGBA', (w, h), dark)
    lay.putalpha(letters.point(lambda v: v * 0.55))
    im = Image.alpha_composite(im, lay)
    im.putalpha(a)
    ImageDraw.Draw(a).rectangle((0, 0, w - 1, h - 1), outline=255, width=12)
    im.putalpha(a)
    return im


def placas():
    """the two plates by the gate, one over the other in the picture: the name; its hours"""
    w, h = 512, 512
    im = Image.new('RGB', (w, h), (240, 240, 236))
    d = ImageDraw.Draw(im)
    for y0 in (0, 256):
        d.rectangle((6, y0 + 6, w - 7, y0 + 249), outline=(150, 150, 150), width=4)
    f = font('bahnschrift.ttf', 200, 'Bold')
    im.paste(fitted('VIVERO', f, NAVY, 400, 86), (56, 40), fitted('VIVERO', f, NAVY, 400, 86))
    t = fitted('DE EMPRESAS', f, NAVY, 400, 60)
    im.paste(t, (56, 148), t)
    t = fitted('LUNES A VIERNES', font('bahnschrift.ttf', 200, 'SemiBold'), (40, 40, 44), 400, 52)
    im.paste(t, (56, 296), t)
    t = fitted('9:00 – 14:00', f, NAVY, 400, 96)
    im.paste(t, (56, 374), t)
    return im


def minusvalidos():
    """the wheelchair, white on blue, as on every such sign"""
    n = 256
    im = Image.new('RGB', (n, n), (28, 74, 160))
    d = ImageDraw.Draw(im)
    d.rectangle((6, 6, n - 7, n - 7), outline=(240, 240, 240), width=6)
    wht = (245, 245, 245)
    d.ellipse((104, 30, 140, 66), fill=wht)                          # the head
    d.line((120, 76, 112, 146), fill=wht, width=22)                  # the back
    d.line((112, 140, 168, 140), fill=wht, width=18)                 # the seat
    d.line((168, 140, 196, 196), fill=wht, width=16)                 # the leg
    d.line((118, 102, 162, 102), fill=wht, width=14)                 # the arm
    d.arc((52, 112, 168, 228), 110, 400, fill=wht, width=16)         # the wheel
    return im


def rotulo():
    """inside, over the reception: the name, navy on the white wall, a strip of the lattice's holes under it"""
    w, h = 1024, 300
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    f = font('bahnschrift.ttf', 260, 'Bold')
    t = fitted('VIVERO DE EMPRESAS', f, NAVY, 960, 120)
    im.paste(t, (32, 30), t)
    t = fitted('MADRIDEJOS', font('bahnschrift.ttf', 200, 'SemiLight'), (60, 60, 70), 420, 52)
    im.paste(t, (32, 176), t)
    d = ImageDraw.Draw(im)
    for k in range(14):
        x = 500 + k * 36
        d.rectangle((x, 186 + (k % 2) * 22, x + 24, 200 + (k % 2) * 22), fill=NAVY)
    return im


def carteles():
    """eight little signs, one a row: white plates with navy words"""
    w, h = 512, 512
    im = Image.new('RGB', (w, h), (244, 244, 240))
    d = ImageDraw.Draw(im)
    f = font('bahnschrift.ttf', 200, 'SemiBold')
    for i, t in enumerate(LABELS):
        y0 = i * 64
        d.rectangle((0, y0, w - 1, y0 + 63), outline=(190, 190, 196), width=3)
        d.rectangle((14, y0 + 16, 26, y0 + 48), fill=NAVY)
        s = line(t, f, NAVY, 34)
        if s.width > 450:
            s = s.resize((450, 34), Image.LANCZOS)
        im.paste(s, (44, y0 + 15), s)
    return im


def tablon():
    """a cork board with notes and leaflets pinned to it (scribbles, not words)"""
    w, h = 512, 320
    rng = random.Random(9)
    im = Image.new('RGB', (w, h), (168, 122, 78))
    d = ImageDraw.Draw(im)
    for _ in range(3000):
        x, y = rng.randrange(w), rng.randrange(h)
        c = rng.randint(-26, 22)
        d.point((x, y), fill=(168 + c, 122 + c, 78 + c))
    d.rectangle((0, 0, w - 1, h - 1), outline=(120, 120, 124), width=10)
    colours = [(250, 246, 200), (255, 255, 255), (200, 230, 250), (250, 210, 210), (210, 245, 210), (255, 255, 255)]
    for k in range(9):
        pw, ph = rng.randint(70, 120), rng.randint(80, 130)
        x, y = rng.randint(20, w - pw - 20), rng.randint(20, h - ph - 20)
        c = colours[k % len(colours)]
        d.rectangle((x + 3, y + 3, x + pw + 3, y + ph + 3), fill=(110, 80, 52))
        d.rectangle((x, y, x + pw, y + ph), fill=c)
        if k % 3 == 0:
            d.rectangle((x + 8, y + 8, x + pw - 8, y + 30), fill=NAVY)
        for ly in range(y + 40, y + ph - 10, 12):
            d.line((x + 8, ly, x + rng.randint(pw // 2, pw - 8), ly), fill=(90, 90, 100), width=3)
        d.ellipse((x + pw // 2 - 5, y - 2, x + pw // 2 + 5, y + 8), fill=(200, 30, 40))
    return im


def pantalla():
    """the meeting room's screen: a slide with a title bar and a chart of bars going up"""
    w, h = 640, 360
    im = Image.new('RGB', (w, h), (248, 248, 250))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, w, 64), fill=NAVY)
    t = fitted('PLAN DE EMPRESA', font('bahnschrift.ttf', 200, 'Bold'), (255, 255, 255), 330, 36)
    im.paste(t, (28, 14), t)
    d.line((70, 320, 600, 320), fill=(60, 60, 70), width=4)
    d.line((70, 100, 70, 320), fill=(60, 60, 70), width=4)
    for k, v in enumerate([60, 90, 80, 130, 170, 200]):
        x = 100 + k * 82
        d.rectangle((x, 320 - v, x + 52, 318), fill=[(60, 120, 200), (230, 140, 40)][k % 2])
    d.line((126, 250, 208, 222, 290, 230, 372, 180, 454, 140, 536, 112), fill=(200, 40, 50), width=5)
    return im


lattice(False).save(os.path.join(OUT, 'celosia.png'))
lattice(True).save(os.path.join(OUT, 'celosia_abierta.png'))
puerta().save(os.path.join(OUT, 'puerta.png'))
placas().save(os.path.join(OUT, 'placas.png'))
minusvalidos().save(os.path.join(OUT, 'minusvalidos.png'))
rotulo().save(os.path.join(OUT, 'rotulo.png'))
carteles().save(os.path.join(OUT, 'carteles.png'))
tablon().save(os.path.join(OUT, 'tablon.png'))
pantalla().save(os.path.join(OUT, 'pantalla.png'))
print('drawn in', os.path.abspath(OUT))
