"""The pictures of the shoe shop "Pisacastaña" (godot/assets/pisacastana/), drawn here: the game's own signs for the
shoe shop of the corner of the Calle de los Arcos and the Calle Argentina (the real Pisamorena; the user, 23 November
2026: "Ahora la zapatería. Usaremos Pisamorena (que llamaremos Pisacastaña). Mismo tratamiento que las otras dos
tiendas pero solo con zapatos"). The real boards are white, the name in thin grey capitals between art-deco lines; the
frosted glass by the door is pale turquoise with white lines in diamonds. Ours are drawn anew with our own name. No
telephone, no address, no social network.

    python tools/pisacastana/dibujos.py

rotulo.png    the board over the Calle Argentina's first window (1.45 x 0.62 m): a white panel in a thin dark frame, a
              board in it with "PISACASTAÑA" in thin grey capitals between art-deco lines
friso.png     the Arcos's: the window's top light over the awning (1.9 x 0.62 m), frosted pale blue with white
              diamond lines, the same board in its middle
cristal.png   the frosted window by the door (1.6 x 2.0 m): pale turquoise, white lines in diamonds over its top two
              thirds, the board with the name in them
estrecho.png  the narrow pane at the corner (0.45 x 2.0 m): the same frosted glass, a notice card on it
horario.png   the card of its hours on that glass (Google Maps, 23 Nov 2026): Monday to Friday 10:00-13:30 and
              17:00-20:00, Saturday 10:30-14:00, Sunday shut
placa.png     the street's name plate on the corner ("Calle Argentina", Street View 2024)
mural.png     the inside's back wall: the name big, "zapatería" under it, in a dark grey to read on the turquoise wall
              (see-through round it)
electro.png   the board of the shut appliance shop next door on the Arcos (no brand: "Electrodomésticos")
vende.png     the "se vende" card in that shop's window (no telephone)
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'pisacastana')
os.makedirs(OUT, exist_ok=True)
WHITE = (250, 250, 248)
GREY = (112, 110, 112)           # the name and the lines (Street View 2024: a thin mid grey on the white)
GREY_LIGHT = (176, 174, 176)
FRAME = (52, 52, 56)
FROST = (176, 220, 214)          # the turquoise frosted glass
FROST_BLUE = (196, 214, 224)     # the Arcos's top light: paler, bluer
INK = (40, 40, 44)
RED = (200, 36, 36)
GREEN = (46, 150, 70)


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


THIN = ['segoeuil.ttf', 'segoeuisl.ttf', 'corbell.ttf', 'arial.ttf']
SERIF = ['constan.ttf', 'georgia.ttf', 'times.ttf']
BOLD = ['arialbd.ttf', 'DejaVuSans-Bold.ttf']


def spaced(d, text, f, cx, y, sp, fill):
    """the text centred on cx, its letters spaced out by sp"""
    tw = sum(d.textlength(c, font=f) for c in text) + sp * (len(text) - 1)
    x = cx - tw / 2
    for c in text:
        d.text((x, y), c, font=f, fill=fill)
        x += d.textlength(c, font=f) + sp
    return tw


def deco(d, cx, y, half, s, fill, flip=False):
    """an art-deco line: a small diamond in the middle, two thin lines out from it ending in little chevrons, a fan of
    short strokes over the diamond (under it when flip)"""
    lw = max(2, int(s * 0.012))
    r = s * 0.05
    d.polygon([(cx, y - r), (cx + r * 1.4, y), (cx, y + r), (cx - r * 1.4, y)], outline=fill, width=lw)
    for side in (-1, 1):
        x0 = cx + side * r * 1.6
        x1 = cx + side * half
        d.line([(x0, y - r * 0.28), (x1, y - r * 0.28)], fill=fill, width=lw)
        d.line([(x0, y + r * 0.28), (x1 - side * half * 0.18, y + r * 0.28)], fill=fill, width=lw)
        d.line([(x1, y - r * 0.28), (x1 - side * r, y - r * 0.9)], fill=fill, width=lw)
        d.line([(x1, y - r * 0.28), (x1 - side * r, y + r * 0.34)], fill=fill, width=lw)
    k = -1 if not flip else 1
    for a in (-0.9, -0.45, 0.0, 0.45, 0.9):
        q0 = (cx + math.sin(a) * r * 1.3, y + k * math.cos(a) * r * 1.3)
        q1 = (cx + math.sin(a) * r * 2.4, y + k * math.cos(a) * r * 2.4)
        d.line([q0, q1], fill=fill, width=lw)


def board(img, box, name_size=0.3):
    """the board with the name: white, a thin grey border, the name between two art-deco lines"""
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    d.rectangle(box, fill=WHITE, outline=GREY_LIGHT, width=max(2, int(h * 0.02)))
    d.rectangle([x0 + h * 0.06, y0 + h * 0.06, x1 - h * 0.06, y1 - h * 0.06], outline=(214, 212, 214), width=max(1, int(h * 0.01)))
    f = font(SERIF, int(h * name_size))
    cx = (x0 + x1) / 2
    tw = spaced(d, 'PISACASTAÑA', f, cx, y0 + h * 0.36, h * 0.03, GREY)
    deco(d, cx, y0 + h * 0.26, min(tw * 0.42, w * 0.4), h, GREY)
    deco(d, cx, y0 + h * 0.8, min(tw * 0.42, w * 0.4), h, GREY, True)


def diamonds(d, w, h, y0, y1, fill, step):
    """white lines in diamonds over a frosted glass, from y0 to y1"""
    lw = max(2, int(w * 0.006))
    n = int((w + (y1 - y0)) / step) + 2
    for k in range(-n, n):
        x = k * step
        d.line([(x, y0), (x + (y1 - y0), y1)], fill=fill, width=lw)
        d.line([(x + (y1 - y0), y0), (x, y1)], fill=fill, width=lw)


def rotulo():
    w, h = 1160, 496
    img = Image.new('RGB', (w, h), WHITE)
    d = ImageDraw.Draw(img)
    board(img, (int(w * 0.1), int(h * 0.12), int(w * 0.9), int(h * 0.88)), 0.25)
    d.rectangle([0, 0, w - 1, h - 1], outline=FRAME, width=8)
    img.save(os.path.join(OUT, 'rotulo.png'))


def friso():
    w, h = 1100, 360
    img = Image.new('RGB', (w, h), FROST_BLUE)
    d = ImageDraw.Draw(img)
    diamonds(d, w, h, 0, h, (240, 246, 250), 260)
    bw = int(h * 2.2)
    board(img, ((w - bw) // 2, int(h * 0.14), (w + bw) // 2, int(h * 0.86)))
    d.rectangle([0, 0, w - 1, h - 1], outline=FRAME, width=6)
    img.save(os.path.join(OUT, 'friso.png'))


def cristal():
    w, h = 640, 800
    img = Image.new('RGB', (w, h), FROST)
    d = ImageDraw.Draw(img)
    for y in range(h):                                  # (a little paler towards the foot, as frosted glass in the light)
        t = y / h
        col = tuple(int(FROST[i] + (236 - FROST[i]) * 0.25 * t) for i in range(3))
        d.line([(0, y), (w, y)], fill=col)
    diamonds(d, w, h, 0, int(h * 0.62), (246, 250, 250), 210)
    bw, bh = int(w * 0.7), int(w * 0.3)
    board(img, ((w - bw) // 2, int(h * 0.2), (w + bw) // 2, int(h * 0.2) + bh), 0.26)
    img.save(os.path.join(OUT, 'cristal.png'))


def estrecho():
    w, h = 220, 980
    img = Image.new('RGB', (w, h), FROST)
    d = ImageDraw.Draw(img)
    diamonds(d, w, h, 0, int(h * 0.36), (246, 250, 250), 150)
    d.rectangle([int(w * 0.1), int(h * 0.38), int(w * 0.9), int(h * 0.62)], fill=WHITE, outline=GREY_LIGHT, width=3)
    f = font(SERIF, 20)
    y = h * 0.4
    for line in ['Calzado', 'de señora,', 'caballero', 'y niño', '', 'Bodas,', 'comuniones', 'y diario']:
        if line:
            d.text(((w - d.textlength(line, font=f)) / 2, y), line, font=f, fill=GREY)
        y += 27
    img.save(os.path.join(OUT, 'estrecho.png'))


def horario():
    w, h = 300, 400
    img = Image.new('RGB', (w, h), WHITE)
    d = ImageDraw.Draw(img)
    d.rectangle([6, 6, w - 7, h - 7], outline=GREY, width=3)
    fn = font(SERIF, 30)
    spaced(d, 'PISACASTAÑA', fn, w / 2, 34, 1, GREY)
    deco(d, w / 2, 92, 110, 200, GREY, True)
    fb = font(BOLD, 24)
    fs = font(BOLD, 21)
    t = 'HORARIO'
    d.text(((w - d.textlength(t, font=fb)) / 2, 132), t, font=fb, fill=INK)
    rows = ['Lunes a viernes', '10:00 - 13:30', '17:00 - 20:00', 'Sábado', '10:30 - 14:00', 'Domingo cerrado']
    y = 174
    for i, a in enumerate(rows):
        colour = INK if a[0].isdigit() else GREY
        d.text(((w - d.textlength(a, font=fs)) / 2, y), a, font=fs, fill=colour)
        y += 30 if i not in (2, 4) else 40
    img.save(os.path.join(OUT, 'horario.png'))


def placa():
    w, h = 360, 200
    img = Image.new('RGB', (w, h), WHITE)
    d = ImageDraw.Draw(img)
    d.rectangle([4, 4, w - 5, h - 5], outline=INK, width=6)
    d.rectangle([14, 14, w - 15, h - 15], outline=INK, width=2)
    f = font(SERIF, 54)
    for t, y in [('Calle', 30), ('Argentina', 100)]:
        d.text(((w - d.textlength(t, font=f)) / 2, y), t, font=f, fill=INK)
    img.save(os.path.join(OUT, 'placa.png'))


def mural():
    w, h = 1024, 384
    s = 2
    W, H = w * s, h * s
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    f = font(SERIF, int(H * 0.3))
    ink = (56, 58, 62, 255)                              # (on the turquoise wall the shop's grey would not read)
    tw = spaced(d, 'PISACASTAÑA', f, W / 2, H * 0.24, H * 0.03, ink)
    deco(d, W / 2, H * 0.15, tw * 0.4, H, ink)
    deco(d, W / 2, H * 0.72, tw * 0.4, H, ink, True)
    fs = font(THIN, int(H * 0.12))
    spaced(d, 'zapatería', fs, W / 2, H * 0.8, H * 0.02, ink)
    img = img.resize((w, h), Image.LANCZOS)
    img.save(os.path.join(OUT, 'mural.png'))


def electro():
    w, h = 1400, 118                                   # (5.95 x 0.5 m)
    img = Image.new('RGB', (w, h), (244, 246, 242))
    d = ImageDraw.Draw(img)
    d.rectangle([0, h - 18, w, h], fill=GREEN)
    d.rectangle([0, 0, w, 6], fill=GREEN)
    f = font(BOLD, 70)
    t = 'ELECTRODOMÉSTICOS'
    d.text(((w - d.textlength(t, font=f)) / 2, 14), t, font=f, fill=INK)
    d.rectangle([0, 0, w - 1, h - 1], outline=(40, 44, 40), width=4)
    img.save(os.path.join(OUT, 'electro.png'))


def vende():
    w, h = 300, 140
    img = Image.new('RGB', (w, h), WHITE)
    d = ImageDraw.Draw(img)
    d.rectangle([3, 3, w - 4, h - 4], outline=RED, width=5)
    f = font(BOLD, 50)
    t = 'SE VENDE'
    d.text(((w - d.textlength(t, font=f)) / 2, 34), t, font=f, fill=RED)
    img.save(os.path.join(OUT, 'vende.png'))


if __name__ == '__main__':
    rotulo()
    friso()
    cristal()
    estrecho()
    horario()
    placa()
    mural()
    electro()
    vende()
    print('ok', os.path.abspath(OUT))
