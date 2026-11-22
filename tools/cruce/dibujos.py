"""The pictures of "Seguros Sopiss" (godot/assets/sopiss/), drawn here: the red corner building of the crossroads of
the traffic lights, the real Soliss Seguros office (the user, 21 November 2026: "el edificio de soliss seguros ... que
llamaremos seguros sopiss"). All of them the game's own: no real name, logo or slogan.

    python tools/cruce/dibujos.py

rotulo.png        the name on the magenta fascia: SOPISS, "Seguros de toda la vida" under it
cartel_coche.png  the poster in the big windows: a car, "TU COCHE BIEN SEGURO DESDE 145 EUR"
cartel_casa.png   the poster in the side windows: a house, "TU CASA BIEN SEGURA DESDE 82 EUR"
mutua.png         the white panel on the pier beside the door: SOPISS, "La mutua de La Mancha"
lista.png         the words on the glass beside the door: hogar, motos, empresas, autonomos, vida, salud
salamanquesa.png  the script name between the top floor's balconies (the real one is another business's name), in
                  white: sopiss.gd colours it, blue by day and a yellow neon by night (the user, 22 November 2026)
placa_avenida.png, placa_cervantes.png   the street's tiles on the fronts
valla.png         the old hoarding on the roof, sun-bleached
logo_pared.png    the name on the office's back wall
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'sopiss')
os.makedirs(OUT, exist_ok=True)
PINK = (204, 28, 112)
WHITE = (255, 255, 255)
EURO = '€'
DOT = '·'


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


BLACK = ['ariblk.ttf', 'arialbd.ttf']
BOLD = ['arialbd.ttf']
SCRIPT = ['segoescb.ttf', 'segoesc.ttf', 'ariali.ttf']
SERIF = ['georgiab.ttf', 'timesbd.ttf']


def wide(text, f, fill, stretch=1.35, gap=10, cut=None):
    """text set wide: each letter drawn, stretched sideways and spaced; `cut`: a thin line cut through the letters (the
    name was first drawn with one; it read as a fault, so it has none now)"""
    parts = []
    for ch in text:
        if ch == ' ':
            parts.append(Image.new('RGBA', (int(f.size * 0.35 * stretch), 4), (0, 0, 0, 0)))
            continue
        b = f.getbbox(ch)
        t = Image.new('RGBA', (b[2] - b[0] + 8, b[3] + 8), (0, 0, 0, 0))
        ImageDraw.Draw(t).text((4 - b[0], 0), ch, font=f, fill=fill)
        t = t.resize((int(t.size[0] * stretch), t.size[1]), Image.LANCZOS)
        parts.append(t)
    w = sum(p.size[0] for p in parts) + gap * (len(parts) - 1)
    h = max(p.size[1] for p in parts)
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    x = 0
    for p in parts:
        im.alpha_composite(p, (x, 0))
        x += p.size[0] + gap
    im = im.crop(im.getbbox())
    if cut:
        d = ImageDraw.Draw(im)
        y = int(im.size[1] * cut)
        d.rectangle([0, y, im.size[0], y + max(2, im.size[1] // 22)], fill=(0, 0, 0, 0))
    return im


def centre(im, piece, y):
    im.alpha_composite(piece, ((im.size[0] - piece.size[0]) // 2, y))


def fit(piece, w, h):
    k = min(w / piece.size[0], h / piece.size[1])
    return piece.resize((int(piece.size[0] * k), int(piece.size[1] * k)), Image.LANCZOS)


def rotulo():
    im = Image.new('RGBA', (1024, 256), (0, 0, 0, 0))
    centre(im, fit(wide('SOPISS', font(BLACK, 150), WHITE, 1.45, 14), 880, 130), 30)
    d = ImageDraw.Draw(im)
    f = font(BOLD, 40)
    t = 'Seguros de toda la vida'
    d.text(((1024 - d.textlength(t, font=f)) / 2, 178), t, font=f, fill=WHITE)
    im.save(os.path.join(OUT, 'rotulo.png'))


def car(d, x, y, s, col):
    """a little car seen side on: body, cabin, wheels (s: its length)"""
    d.rounded_rectangle([x, y + s * 0.2, x + s, y + s * 0.42], radius=s * 0.07, fill=col)
    d.polygon([(x + s * 0.2, y + s * 0.22), (x + s * 0.32, y + s * 0.04), (x + s * 0.68, y + s * 0.04), (x + s * 0.84, y + s * 0.22)], fill=col)
    d.polygon([(x + s * 0.27, y + s * 0.2), (x + s * 0.35, y + s * 0.08), (x + s * 0.49, y + s * 0.08), (x + s * 0.49, y + s * 0.2)], fill=(60, 70, 86))
    d.polygon([(x + s * 0.53, y + s * 0.2), (x + s * 0.53, y + s * 0.08), (x + s * 0.66, y + s * 0.08), (x + s * 0.76, y + s * 0.2)], fill=(60, 70, 86))
    for cx in (0.22, 0.78):
        d.ellipse([x + s * (cx - 0.1), y + s * 0.3, x + s * (cx + 0.1), y + s * 0.5], fill=(34, 34, 38))
        d.ellipse([x + s * (cx - 0.05), y + s * 0.35, x + s * (cx + 0.05), y + s * 0.45], fill=(190, 190, 196))
    d.rectangle([x + s * 0.93, y + s * 0.26, x + s * 0.99, y + s * 0.31], fill=(250, 230, 150))


def house(d, x, y, s, col):
    d.polygon([(x - s * 0.06, y + s * 0.42), (x + s * 0.5, y), (x + s * 1.06, y + s * 0.42)], fill=(54, 54, 60))
    d.rectangle([x + s * 0.06, y + s * 0.4, x + s * 0.94, y + s * 0.95], fill=col)
    d.rectangle([x + s * 0.7, y + s * 0.06, x + s * 0.82, y + s * 0.3], fill=(54, 54, 60))
    d.rectangle([x + s * 0.42, y + s * 0.62, x + s * 0.58, y + s * 0.95], fill=(120, 80, 60))
    for wx in (0.16, 0.68):
        d.rectangle([x + s * wx, y + s * 0.52, x + s * (wx + 0.17), y + s * 0.72], fill=(120, 170, 210))


def cartel(name, lines, price, what):
    w, h = 384, 512
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([6, 6, w - 6, h - 150], radius=30, fill=PINK + (255,))
    d.text((34, 28), 'COMPROMISO SOPISS', font=font(BOLD, 22), fill=WHITE)
    f1 = font(BOLD, 44)
    y = 68
    for ln in lines:
        d.text((34, y), ln, font=f1, fill=WHITE)
        y += 50
    fp = font(BLACK, 104)
    d.text((40, y - 6), price, font=fp, fill=WHITE)
    d.text((48 + d.textlength(price, font=fp), y + 22), EURO, font=font(BLACK, 64), fill=WHITE)
    if what == 'car':
        car(d, 40, h - 190, 300, (246, 246, 248))
    else:
        house(d, 100, h - 200, 190, (246, 244, 236))
    im.save(os.path.join(OUT, name))


def mutua():
    w, h = 256, 640
    im = Image.new('RGBA', (w, h), (236, 236, 232, 255))
    im.alpha_composite(fit(wide('SOPISS', font(BLACK, 60), (70, 70, 76), 1.4, 5), 190, 60), (30, 60))
    d = ImageDraw.Draw(im)
    f = font(BOLD, 34)
    y = 250
    for ln in ('La mutua', 'de', 'La Mancha'):
        d.text((30, y), ln, font=f, fill=PINK)
        y += 42
    im.save(os.path.join(OUT, 'mutua.png'))


def lista():
    w, h = 320, 512
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    f = font(BOLD, 44)
    y = 40
    for ln in ('hogar', 'motos', 'empresas', 'autónomos', 'vida', 'salud'):
        d.ellipse([18, y + 20, 34, y + 36], fill=PINK + (255,))
        d.text((54, y), ln, font=f, fill=PINK + (255,))
        y += 72
    im.save(os.path.join(OUT, 'lista.png'))


def salamanquesa():
    w, h = 1024, 300
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    f = font(SCRIPT, 112)
    t = 'Salamanquesa'
    layer = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    tw = d.textlength(t, font=f)
    x = (w - tw) / 2
    d.text((x + 4, 62 + 5), t, font=f, fill=(112, 112, 112, 255), stroke_width=7, stroke_fill=(112, 112, 112, 255))             # (the letters' depth: a darker edge under them)
    d.text((x, 62), t, font=f, fill=(255, 255, 255, 255), stroke_width=7, stroke_fill=(255, 255, 255, 255))
    d.line([(x + 40, 228), (x + tw - 30, 228)], fill=(255, 255, 255, 255), width=10)  # (the stroke under the name)
    layer = layer.rotate(5, resample=Image.BICUBIC, center=(w / 2, h / 2))
    im.alpha_composite(layer)
    box = im.getbbox()                                   # (cut to its letters, then set in a 4 : 1 picture: sopiss.gd's NEON_W x NEON_W / 4)
    im = im.crop((box[0] - 6, box[1] - 6, box[2] + 6, box[3] + 6))
    k = min(1024 / im.size[0], 256 / im.size[1])
    im = im.resize((int(im.size[0] * k), int(im.size[1] * k)), Image.LANCZOS)
    out = Image.new('RGBA', (1024, 256), (0, 0, 0, 0))
    out.alpha_composite(im, ((1024 - im.size[0]) // 2, (256 - im.size[1]) // 2))
    out.save(os.path.join(OUT, 'salamanquesa.png'))


def placa(name, top, bottom):
    w, h = 360, 280
    im = Image.new('RGBA', (w, h), (244, 242, 234, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([5, 5, w - 6, h - 6], outline=(40, 60, 120), width=5)
    d.rectangle([14, 14, w - 15, h - 15], outline=(40, 60, 120), width=2)
    cx, cy = w // 2, 62                                  # a little shield of the game's own: a saffron flower
    d.polygon([(cx - 26, cy - 30), (cx + 26, cy - 30), (cx + 26, cy + 8), (cx, cy + 32), (cx - 26, cy + 8)], fill=(250, 248, 240), outline=(40, 60, 120))
    for a in range(6):
        ang = math.radians(a * 60 + 30)
        px, py = cx + 13 * math.cos(ang), cy - 4 + 13 * math.sin(ang)
        d.ellipse([px - 8, py - 8, px + 8, py + 8], fill=(150, 100, 190))
    d.ellipse([cx - 5, cy - 9, cx + 5, cy + 1], fill=(230, 120, 30))
    f = font(SERIF, 52)
    for i, ln in enumerate((top, bottom)):
        g = f
        while d.textlength(ln, font=g) > w - 44:
            g = font(SERIF, g.size - 2)
        d.text(((w - d.textlength(ln, font=g)) / 2, 112 + i * 70), ln, font=g, fill=(24, 30, 52))
    im.save(os.path.join(OUT, name))


def valla():
    w, h = 1024, 256
    im = Image.new('RGBA', (w, h), (226, 214, 160, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=(70, 96, 150), width=14)
    centre(im, fit(wide('SEGUROS SOPISS', font(BLACK, 110), (176, 70, 120), 1.2, 6), 900, 110), 44)
    f = font(BOLD, 40)
    t = 'DE TODA LA VIDA %s EN LAS CUATRO ESQUINAS' % DOT
    d.text(((w - d.textlength(t, font=f)) / 2, 180), t, font=f, fill=(70, 96, 150))
    px = im.load()                                       # (sun-bleached: streaks of rust and washed patches)
    rng = random.Random(7)
    for _ in range(26):
        x0 = rng.randrange(20, w - 20); y0 = rng.randrange(0, h // 2); ln = rng.randrange(40, 200)
        for y in range(y0, min(h, y0 + ln)):
            for x in range(x0, x0 + rng.randrange(1, 4)):
                r, g, b, a = px[x, y]
                px[x, y] = (int(r * 0.86), int(g * 0.8), int(b * 0.74), a)
    im = Image.blend(im, Image.new('RGBA', (w, h), (232, 226, 200, 255)), 0.28)
    im.save(os.path.join(OUT, 'valla.png'))


def logo_pared():
    im = Image.new('RGBA', (768, 256), (0, 0, 0, 0))
    centre(im, fit(wide('SOPISS', font(BLACK, 150), PINK + (255,), 1.45, 14), 700, 120), 30)
    d = ImageDraw.Draw(im)
    f = font(BOLD, 40)
    t = 'Seguros de toda la vida'
    d.text(((768 - d.textlength(t, font=f)) / 2, 176), t, font=f, fill=(90, 90, 96))
    im.save(os.path.join(OUT, 'logo_pared.png'))


if __name__ == '__main__':
    rotulo()
    cartel('cartel_coche.png', ('TU COCHE', 'BIEN SEGURO', 'DESDE'), '145', 'car')
    cartel('cartel_casa.png', ('TU CASA', 'BIEN SEGURA', 'DESDE'), '82', 'house')
    mutua(); lista(); salamanquesa()
    placa('placa_avenida.png', 'Avenida', 'Constitución')
    placa('placa_cervantes.png', 'Calle', 'Cervantes')
    valla(); logo_pared()
    print(sorted(os.listdir(OUT)))
