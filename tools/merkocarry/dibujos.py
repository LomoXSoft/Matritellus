"""The pictures the Merkocarry is painted with (godot/assets/merkocarry/), all drawn here: the user's name for the
Merkocash of the Calle de Santa Ana (17 November 2026), in lettering of our own after the colours of its front (the
first syllables red on white, the middle two white in a red square, the rest green outlined in white on red), the green
strip under it, and a row of badges of no brand at all where the real one has its suppliers'.

    python tools/merkocarry/dibujos.py [OUT_FOLDER]

rotulo.png      the board over the front (15.6 x 2.5 m): the name, the strip, the badges
logo.png        the name alone, on white (the posters, the signs of the car park)
cartel_iva.png  the poster of the left window: "PRECIOS IVA INCLUIDO" and a basket of fruit
cartel_hora.png the poster of the right window: a trolley, and its hours on a red plate
entrada.png     the red band across its glass doors: "ENTRADA" twice
parking.png     the board over the gate of the Calle del Cristo: "P  ENTRADA PARKING  P"
clientes.png    the board over the gate of the Calle del Suspiro: "ENTRADA CLIENTES" and the name
p_flecha.png    the sign on the tall pier by the gate: a white P, a red arrow
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', 'godot', 'assets', 'merkocarry')
FONTS = os.path.join(os.environ.get('WINDIR', 'C:\\Windows'), 'Fonts')
BLACK = os.path.join(FONTS, 'ariblk.ttf')
BOLD = os.path.join(FONTS, 'arialbd.ttf')
RED = (222, 52, 62)
GREEN = (46, 150, 78)
WHITE = (252, 252, 250)
BLUE = (34, 74, 168)
os.makedirs(OUT, exist_ok=True)


def save(im, name):
    im.save(os.path.join(OUT, name))
    print(name, im.size)


def outlined(d, xy, s, f, fill, edge, w):
    x, y = xy
    for dx in range(-w, w + 1, max(1, w // 3)):
        for dy in range(-w, w + 1, max(1, w // 3)):
            if dx * dx + dy * dy <= w * w:
                d.text((x + dx, y + dy), s, font=f, fill=edge)
    d.text((x, y), s, font=f, fill=fill)


def name(W, H, bg=WHITE):
    """the name on its own: MER red, KO white in a red square, CARRY green edged in white on a red board"""
    im = Image.new('RGB', (W, H), bg)
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(BLACK, int(H * 0.78))
    a, b, c = 'MER', 'KO', 'CARRY'
    wa, wb, wc = d.textlength(a, font=f), d.textlength(b, font=f), d.textlength(c, font=f)
    pad = H * 0.08
    total = wa + pad + wb + pad * 3 + wc + pad * 2
    k = min(1.0, W * 0.96 / total)
    if k < 1.0:
        f = ImageFont.truetype(BLACK, int(H * 0.78 * k))
        wa, wb, wc = d.textlength(a, font=f), d.textlength(b, font=f), d.textlength(c, font=f)
        pad *= k
        total = wa + pad + wb + pad * 3 + wc + pad * 2
    x = (W - total) / 2
    top = H * 0.1
    asc = f.getbbox('M')
    ty = (H - (asc[3] - asc[1])) / 2 - asc[1]
    d.text((x, ty), a, font=f, fill=RED)
    x += wa + pad
    d.rectangle([x - pad * 0.5, top, x + wb + pad * 0.5, H - top], fill=RED)             # KO, white in its square
    d.text((x, ty), b, font=f, fill=WHITE)
    x += wb + pad * 3
    d.rectangle([x - pad, top, x + wc + pad, H - top], fill=RED)                         # CARRY on its board
    outlined(d, (x, ty), c, f, GREEN, WHITE, max(2, int(H * 0.035)))
    return im


def badges(d, x0, y0, x1, y1, n):
    """a row of little badges of no brand at all: ovals, shields and bars in suppliers' colours, with no word on them"""
    cols = [(30, 80, 170), (220, 40, 40), (250, 200, 40), (40, 140, 70), (20, 20, 20), (120, 60, 160), (0, 150, 200), (230, 120, 30)]
    step = (x1 - x0) / n
    h = y1 - y0
    for i in range(n):
        cx = x0 + step * (i + 0.5)
        c = cols[(i * 5) % len(cols)]
        c2 = cols[(i * 3 + 2) % len(cols)]
        kind = i % 4
        w = step * 0.62
        if kind == 0:
            d.ellipse([cx - w / 2, y0 + h * 0.15, cx + w / 2, y1 - h * 0.15], fill=c)
            d.ellipse([cx - w / 3.2, y0 + h * 0.32, cx + w / 3.2, y1 - h * 0.32], fill=WHITE)
        elif kind == 1:
            d.rounded_rectangle([cx - w / 2, y0 + h * 0.22, cx + w / 2, y1 - h * 0.22], radius=h * 0.12, fill=c)
            d.rectangle([cx - w / 2.6, y0 + h * 0.45, cx + w / 2.6, y0 + h * 0.55], fill=WHITE)
        elif kind == 2:
            d.polygon([(cx - w / 3, y0 + h * 0.12), (cx + w / 3, y0 + h * 0.12), (cx + w / 3, y0 + h * 0.6), (cx, y1 - h * 0.1), (cx - w / 3, y0 + h * 0.6)], fill=c)
            d.ellipse([cx - w / 8, y0 + h * 0.3, cx + w / 8, y0 + h * 0.55], fill=c2)
        else:
            d.ellipse([cx - w / 2, y0 + h * 0.2, cx + w / 2, y1 - h * 0.2], fill=c2)
            d.ellipse([cx - w / 2 + 4, y0 + h * 0.2 + 4, cx + w / 2 - 4, y1 - h * 0.2 - 4], outline=WHITE, width=3)


def rotulo():
    k = 200                                                    # px a metre
    W, H = int(15.6 * k), int(2.5 * k)
    im = Image.new('RGB', (W, H), WHITE)
    d = ImageDraw.Draw(im)
    nm = name(int(12.4 * k), int(1.5 * k))
    im.paste(nm, (int((15.6 - 12.4) / 2 * k), int(0.15 * k)))
    d.rectangle([0, int(1.72 * k), W, int(2.12 * k)], fill=GREEN)                         # the strip
    f = ImageFont.truetype(BOLD, int(0.3 * k))
    s = 'EL SÚPER DE LA FAMILIA   PARA TODOS LOS PÚBLICOS'
    d.text((int((W - d.textlength(s, font=f)) / 2), int(1.75 * k)), s, font=f, fill=WHITE)
    badges(d, int(0.3 * k), int(2.15 * k), W - int(0.3 * k), H - 4, 34)
    save(im, 'rotulo.png')


def logo():
    save(name(900, 180), 'logo.png')


def basket(d, cx, cy, s):
    d.polygon([(cx - s, cy), (cx + s, cy), (cx + s * 0.75, cy + s * 0.8), (cx - s * 0.75, cy + s * 0.8)], fill=(170, 110, 50))
    for j in range(3):
        d.line([(cx - s * 0.9 + j * 0.05 * s, cy + s * 0.25 * (j + 1)), (cx + s * 0.9 - j * 0.05 * s, cy + s * 0.25 * (j + 1))], fill=(120, 74, 30), width=max(2, int(s * 0.05)))
    for i, (dx, col) in enumerate(((-0.6, (230, 50, 40)), (-0.15, (250, 170, 30)), (0.3, (120, 180, 50)), (0.72, (230, 50, 40)), (0.05, (250, 220, 60)))):
        r = s * (0.28 if i < 4 else 0.22)
        y = cy - r * (0.5 if i < 4 else 1.4)
        d.ellipse([cx + dx * s - r, y - r, cx + dx * s + r, y + r], fill=col)
    d.arc([cx - s * 0.9, cy - s * 1.2, cx + s * 0.9, cy + s * 0.6], 190, 350, fill=(120, 74, 30), width=max(3, int(s * 0.07)))


def trolley(d, cx, cy, s, col=(220, 52, 62)):
    w = max(3, int(s * 0.08))
    d.line([(cx - s * 1.2, cy - s * 0.9), (cx - s * 0.9, cy - s * 0.9), (cx - s * 0.55, cy + s * 0.45), (cx + s * 0.85, cy + s * 0.45)], fill=(60, 60, 64), width=w)
    d.polygon([(cx - s * 0.8, cy - s * 0.6), (cx + s * 1.1, cy - s * 0.6), (cx + s * 0.85, cy + s * 0.25), (cx - s * 0.6, cy + s * 0.25)], fill=col)
    for i in range(4):
        x = cx - s * 0.6 + i * s * 0.45
        d.line([(x, cy - s * 0.6), (x - s * 0.05, cy + s * 0.25)], fill=WHITE, width=max(2, w // 2))
    for x in (cx - s * 0.4, cx + s * 0.65):
        d.ellipse([x - s * 0.13, cy + s * 0.55, x + s * 0.13, cy + s * 0.81], fill=(40, 40, 44))
    for i, c in enumerate(((120, 180, 50), (250, 170, 30), (230, 50, 40))):              # what is in it
        d.ellipse([cx - s * 0.5 + i * s * 0.45, cy - s * 0.95, cx - s * 0.1 + i * s * 0.45, cy - s * 0.55], fill=c)


def poster_frame(W, H):
    im = Image.new('RGB', (W, H), WHITE)
    d = ImageDraw.Draw(im)
    lg = name(int(W * 0.42), int(H * 0.11))
    d.rectangle([0, 0, W, int(H * 0.14)], fill=WHITE)
    im.paste(lg, (int(W * 0.04), int(H * 0.015)))
    d.rectangle([0, int(H * 0.14), W, int(H * 0.15)], fill=RED)
    return im, d


def cartel_iva():
    W, H = 900, 500                                            # 3.6 x 2.0 m
    im, d = poster_frame(W, H)
    d.rectangle([0, int(H * 0.15), W, H], fill=(236, 240, 232))
    d.rectangle([int(W * 0.03), int(H * 0.22), int(W * 0.33), int(H * 0.92)], fill=RED)
    f = ImageFont.truetype(BLACK, 46)
    for i, s in enumerate(('PRECIOS', 'IVA', 'INCLUIDO')):
        tw = d.textlength(s, font=f)
        d.text((int(W * 0.18 - tw / 2), int(H * 0.32 + i * 72)), s, font=f, fill=WHITE)
    basket(d, int(W * 0.66), int(H * 0.55), 150)
    save(im, 'cartel_iva.png')


def cartel_hora():
    W, H = 900, 500
    im, d = poster_frame(W, H)
    d.rectangle([0, int(H * 0.15), W, H], fill=(236, 238, 242))
    trolley(d, int(W * 0.36), int(H * 0.58), 130)
    x0, y0, x1, y1 = int(W * 0.66), int(H * 0.26), int(W * 0.97), int(H * 0.9)
    d.rectangle([x0, y0, x1, y1], fill=WHITE, outline=(30, 30, 30), width=4)
    f = ImageFont.truetype(BLACK, 52)
    f2 = ImageFont.truetype(BOLD, 26)
    d.text(((x0 + x1) / 2 - d.textlength('HORARIO', font=f) / 2, y0 + 14), 'HORARIO', font=f, fill=(30, 30, 30))
    d.text(((x0 + x1) / 2 - d.textlength('ININTERRUMPIDO', font=f2) / 2, y0 + 78), 'ININTERRUMPIDO', font=f2, fill=(30, 30, 30))
    d.rectangle([x0 + 14, y0 + 118, x1 - 14, y0 + 164], fill=RED)
    d.text(((x0 + x1) / 2 - d.textlength('de lunes a sábado', font=f2) / 2, y0 + 126), 'de lunes a sábado', font=f2, fill=WHITE)
    f3 = ImageFont.truetype(BLACK, 34)
    s = '9:30 a 21:00 H'
    d.text(((x0 + x1) / 2 - d.textlength(s, font=f3) / 2, y0 + 180), s, font=f3, fill=(30, 30, 30))
    save(im, 'cartel_hora.png')


def entrada():
    W, H = 1400, 80                                            # 3.5 x 0.2 m
    im = Image.new('RGB', (W, H), RED)
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(BOLD, 52)
    for cx in (W * 0.27, W * 0.73):
        d.text((cx - d.textlength('ENTRADA', font=f) / 2, 10), 'ENTRADA', font=f, fill=WHITE)
    save(im, 'entrada.png')


def parking():
    W, H = 1500, 150                                           # 7.5 x 0.75 m
    im = Image.new('RGB', (W, H), BLUE)
    d = ImageDraw.Draw(im)
    lg = name(260, 70)
    im.paste(lg, (14, 40))
    f = ImageFont.truetype(BOLD, 72)
    fp = ImageFont.truetype(BLACK, 100)
    for x in (310, W - 120):
        d.rectangle([x, 22, x + 106, 128], fill=WHITE)
        d.text((x + 53 - d.textlength('P', font=fp) / 2, 10), 'P', font=fp, fill=BLUE)
    s = 'ENTRADA PARKING'
    tx = (416 + W - 120) / 2 - d.textlength(s, font=f) / 2
    d.text((tx, 26), s, font=f, fill=WHITE)
    for ax in (tx - 70, tx + d.textlength(s, font=f) + 30):                          # the arrows down
        d.polygon([(ax, 50), (ax + 40, 50), (ax + 40, 80), (ax + 56, 80), (ax + 20, 118), (ax - 16, 80), (ax, 80)], fill=WHITE)
    save(im, 'parking.png')


def clientes():
    W, H = 900, 260                                            # 1.8 x 0.52 m
    im = Image.new('RGB', (W, H), BLUE)
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(BOLD, 84)
    s = 'ENTRADA CLIENTES'
    d.text((W / 2 - d.textlength(s, font=f) / 2, 12), s, font=f, fill=WHITE)
    lg = name(760, 120)
    im.paste(lg, (70, 124))
    save(im, 'clientes.png')


def p_flecha():
    W, H = 400, 400
    im = Image.new('RGB', (W, H), BLUE)
    d = ImageDraw.Draw(im)
    d.rectangle([12, 12, W - 12, H - 12], outline=WHITE, width=10)
    fp = ImageFont.truetype(BLACK, 250)
    d.text((W / 2 - d.textlength('P', font=fp) / 2, -10), 'P', font=fp, fill=WHITE)
    d.polygon([(60, 300), (260, 300), (260, 270), (340, 320), (260, 370), (260, 340), (60, 340)], fill=RED)
    save(im, 'p_flecha.png')


def chapa():
    """a metre of the blue sheet in ribs (it repeats), the ribs across"""
    S = 256
    im = Image.new('RGB', (S, S), (44, 90, 196))
    d = ImageDraw.Draw(im)
    for k in range(8):
        y = k * S // 8
        d.rectangle([0, y, S, y + 6], fill=(70, 120, 222))
        d.rectangle([0, y + 6, S, y + 10], fill=(28, 62, 150))
    save(im, 'chapa.png')


def malla():
    """a metre of the wire fence, the diamonds of its mesh (see-through between the wires)"""
    S = 256
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    step = S // 4
    for k in range(-4, 9):
        x = k * step
        d.line([(x, 0), (x + S, S)], fill=(150, 156, 162, 255), width=3)
        d.line([(x + S, 0), (x, S)], fill=(150, 156, 162, 255), width=3)
    save(im, 'malla.png')


def celosia():
    """a metre of the gates' lattice: blue bars in a grid, the squares between them open"""
    S = 256
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    step = S // 6
    for k in range(7):
        d.rectangle([k * step - 5, 0, k * step + 5, S], fill=(40, 96, 200, 255))
        d.rectangle([0, k * step - 5, S, k * step + 5], fill=(40, 96, 200, 255))
    save(im, 'celosia.png')


def chapa_crema():
    """a metre of the Mayordomía's sheet: pale beige in wide ribs (it repeats)"""
    S = 256
    im = Image.new('RGB', (S, S), (206, 196, 180))
    d = ImageDraw.Draw(im)
    for k in range(6):
        y = k * S // 6
        d.rectangle([0, y, S, y + 10], fill=(226, 218, 204))
        d.rectangle([0, y + 10, S, y + 15], fill=(160, 150, 136))
        d.rectangle([0, y + 15, S, y + 18], fill=(186, 176, 160))
    save(im, 'chapa_crema.png')


def placa():
    """the plate of the Mayordomía's nave: grey bronze cut like a scroll, its word in raised letters (the user's word
    for it; the rest of what the real one says is not copied)"""
    W, H = 840, 200                                            # 1.68 x 0.4 m
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    body = (128, 120, 108, 255)
    edge = [(20, 30), (60, 10), (120, 22), (W - 120, 18), (W - 60, 8), (W - 20, 28), (W - 34, 70), (W - 14, 110), (W - 30, 160),
            (W - 70, 190), (W - 140, 178), (140, 184), (70, 194), (24, 170), (36, 120), (12, 80)]
    d.polygon(edge, fill=body)
    d.line(edge + edge[:1], fill=(92, 86, 76, 255), width=6)
    f = ImageFont.truetype(BOLD, 96)
    s = 'MAYORDOMÍA'
    x = W / 2 - d.textlength(s, font=f) / 2
    d.text((x + 3, 46), s, font=f, fill=(70, 64, 56, 255))
    d.text((x, 42), s, font=f, fill=(200, 190, 170, 255))
    save(im, 'placa.png')


if __name__ == '__main__':
    rotulo(); logo(); cartel_iva(); cartel_hora(); entrada(); parking(); clientes(); p_flecha(); chapa(); malla(); celosia(); chapa_crema(); placa()
