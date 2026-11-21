"""The pictures of the roast chicken shop "Javi" (godot/assets/asador/), drawn here: the game's own signs for the
Asador de Pollos of the Calle de los Arcos (the user, 21 November 2026: "asador de pollos juli (que llamaremos Javi)").
The real shop's name and telephone numbers are left out.

    python tools/asador/dibujos.py

rotulo.png     the board over the shop's door (2.7 x 0.7 m): the badge with the chicken and "Javi", POLLOS ASADOS (the user's
               name for the shop: "En vez de Asador de Pollos mejor llamarlo Pollos Asados"), COMIDAS PREPARADAS
banderola.png  the tall sign between the balconies (0.55 x 3.0 m): a roast chicken, POLLOS ASADOS down it
carta.png      the list on the wall inside (no prices: the game's food has its own)
reparto.png    the notice of the deliveries, Tuesdays and Sundays
horario.png    the card of its hours in the window (the user's: Tuesdays and Sundays, 7:00 to 16:00)
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'asador')
os.makedirs(OUT, exist_ok=True)
RED = (196, 40, 30)
DARK = (86, 22, 18)
YELLOW = (250, 204, 40)
ORANGE = (236, 132, 30)
BROWN = (150, 84, 36)


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


BOLD = ['arialbd.ttf', 'DejaVuSans-Bold.ttf']
SCRIPT = ['segoesc.ttf', 'BRUSHSCI.TTF', 'georgiai.ttf', 'ariali.ttf']
SERIF = ['georgiab.ttf', 'timesbd.ttf', 'arialbd.ttf']


def chicken(d, cx, cy, r, skin=BROWN, shine=(214, 140, 60)):
    """a roast chicken on its back: the body, the two drumsticks up, a shine"""
    d.ellipse([cx - r, cy - r * 0.62, cx + r, cy + r * 0.62], fill=skin)
    for s in (-1, 1):
        d.ellipse([cx + s * r * 0.5 - r * 0.3, cy - r * 0.95, cx + s * r * 0.5 + r * 0.3, cy - r * 0.2], fill=skin)
        d.rectangle([cx + s * r * 0.5 - r * 0.07, cy - r * 1.2, cx + s * r * 0.5 + r * 0.07, cy - r * 0.9], fill=(240, 232, 214))
        d.ellipse([cx + s * r * 0.5 - r * 0.12, cy - r * 1.3, cx + s * r * 0.5 + r * 0.12, cy - r * 1.1], fill=(240, 232, 214))
    d.ellipse([cx - r * 0.55, cy - r * 0.3, cx + r * 0.1, cy + r * 0.1], fill=shine)


def rotulo():
    w, h = 1160, 300
    im = Image.new('RGBA', (w, h), (250, 248, 240, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=(60, 60, 60, 255), width=6)
    d.ellipse([24, 22, 280, 278], fill=ORANGE + (255,), outline=DARK + (255,), width=6)
    chicken(d, 152, 120, 62)
    f = font(SCRIPT, 66)
    d.text((152 - d.textlength('Javi', font=f) / 2, 152), 'Javi', font=f, fill=(255, 250, 235, 255))
    big = font(SERIF, 104)
    mid = font(SERIF, 74)
    words = (('P', ''), ('OLLOS', ' '), ('A', ''), ('SADOS', ''))        # (the user: "En vez de Asador de Pollos mejor llamarlo Pollos Asados")
    total = sum(d.textlength(wd, font=big if len(wd) == 1 else mid) + (34 if sep else 2) for wd, sep in words)
    x = 318 + (w - 358 - total) / 2
    for word, sep in words:
        fnt = big if len(word) == 1 else mid
        y = 28 if len(word) == 1 else 54
        col = RED if len(word) == 1 else DARK
        d.text((x, y), word, font=fnt, fill=col + (255,))
        x += d.textlength(word, font=fnt) + (34 if sep else 2)
    d.line([(318, 168), (w - 40, 168)], fill=RED + (255,), width=5)
    small = font(BOLD, 52)
    d.text((318 + (w - 358 - d.textlength('COMIDAS PREPARADAS', font=small)) / 2, 190), 'COMIDAS PREPARADAS', font=small, fill=(40, 40, 40, 255))
    im.save(os.path.join(OUT, 'rotulo.png'))
    print('rotulo.png', im.size)


def banderola():
    w, h = 220, 1200
    im = Image.new('RGBA', (w, h), DARK + (255,))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=(20, 16, 14, 255), width=8)
    d.rectangle([14, 14, w - 15, 200], fill=(40, 16, 12, 255))
    chicken(d, w / 2, 130, 70, (190, 104, 40), (240, 170, 80))
    d.rectangle([14, 214, w - 15, h - 15], fill=RED + (255,))
    f = font(BOLD, 86)
    y = 226
    for word in ('POLLOS', 'ASADOS'):
        for ch in word:
            d.text(((w - d.textlength(ch, font=f)) / 2, y), ch, font=f, fill=YELLOW + (255,))
            y += 76
        y += 34
    im.save(os.path.join(OUT, 'banderola.png'))
    print('banderola.png', im.size)


def carta():
    w, h = 720, 540
    im = Image.new('RGBA', (w, h), (36, 60, 44, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=(150, 110, 60, 255), width=14)
    t = font(SCRIPT, 54)
    d.text(((w - d.textlength('Hoy tenemos', font=t)) / 2, 22), 'Hoy tenemos', font=t, fill=(250, 240, 200, 255))
    f = font(BOLD, 36)
    for i, line in enumerate(['POLLO ASAO', 'MEDIO POLLO', 'PATATAS', 'CROQUETAS CASERAS', 'ALITAS', 'CALAMARES', 'PISTO', 'PAN Y BEBIDA']):
        col = (250, 250, 240, 255) if i % 2 == 0 else (250, 220, 120, 255)
        d.text((60, 118 + i * 50), '· ' + line, font=f, fill=col)
    chicken(d, w - 130, 410, 62, (200, 120, 50), (240, 180, 90))
    im.save(os.path.join(OUT, 'carta.png'))
    print('carta.png', im.size)


def reparto():
    w, h = 420, 560
    im = Image.new('RGBA', (w, h), (252, 244, 214, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=RED + (255,), width=10)
    f = font(BOLD, 62)
    for i, line in enumerate(['REPARTO', 'A CASA']):
        d.text(((w - d.textlength(line, font=f)) / 2, 30 + i * 70), line, font=f, fill=RED + (255,))
    chicken(d, w / 2, 290, 86)
    f2 = font(BOLD, 44)
    for i, line in enumerate(['MARTES', 'Y DOMINGOS']):
        d.text(((w - d.textlength(line, font=f2)) / 2, 400 + i * 56), line, font=f2, fill=DARK + (255,))
    im.save(os.path.join(OUT, 'reparto.png'))
    print('reparto.png', im.size)


def horario():
    w, h = 380, 470
    im = Image.new('RGBA', (w, h), (250, 250, 244, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=DARK + (255,), width=8)
    f = font(BOLD, 58)
    d.text(((w - d.textlength('HORARIO', font=f)) / 2, 26), 'HORARIO', font=f, fill=RED + (255,))
    d.line([(30, 104), (w - 30, 104)], fill=DARK + (255,), width=4)
    f2 = font(BOLD, 46)
    f3 = font(BOLD, 40)
    y = 124
    for day, hours in (('MARTES', '7:00 - 16:00'), ('DOMINGOS', '7:00 - 16:00')):
        d.text(((w - d.textlength(day, font=f2)) / 2, y), day, font=f2, fill=DARK + (255,))
        d.text(((w - d.textlength(hours, font=f3)) / 2, y + 54), hours, font=f3, fill=(40, 40, 40, 255))
        y += 136
    f4 = font(BOLD, 30)
    d.text(((w - d.textlength('Los demás días, cerrado', font=f4)) / 2, y + 6), 'Los demás días, cerrado', font=f4, fill=RED + (255,))
    im.save(os.path.join(OUT, 'horario.png'))
    print('horario.png', im.size)


if __name__ == '__main__':
    horario()
    rotulo()
    banderola()
    carta()
    reparto()
