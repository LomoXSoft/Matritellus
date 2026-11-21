"""The pictures of the Cafetería Rize and its alley (godot/assets/rize/), drawn here. The user, 21 November 2026: "la
cafetería rice con todo su callejón incluido" and then "Lo llamaremos al local Rize en vez de Rice".

    python tools/rice/dibujos.py

mural.png    the emblem painted on the garage's wall opposite the café (1.7 x 2.1 m): the game's own, in the place of
             the real one (a peña's, with a red cap and a moustache that is too like a well-known plumber): a yellow
             zigzag shield, a black quiff and a black moustache, a ribbon that says SIEMPRE DE FIESTA
ramas.png    what is painted on the garage's white door (3.0 x 2.6 m): black branches, blue flowers, a few leaves, a
             little bird house
pizarra.png  the blackboard at the alley's mouth: RIZE, ¡ABIERTO!, Tapas, Raciones, Menú diario
rotulo.png   the café's name on its awning
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'rize')
os.makedirs(OUT, exist_ok=True)


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


BOLD = ['arialbd.ttf']
HAND = ['segoepr.ttf', 'segoesc.ttf', 'comic.ttf', 'ariali.ttf']
CHALK = ['segoepr.ttf', 'comic.ttf', 'arial.ttf']


def mural():
    w, h = 680, 840
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    yellow, edge = (246, 206, 40, 255), (40, 34, 20, 255)
    shield = [(60, 240), (190, 40), (340, 250), (490, 40), (620, 240), (540, 520), (430, 780), (340, 560), (250, 780), (140, 520)]
    d.polygon(shield, fill=yellow, outline=edge)
    d.line(shield + shield[:1], fill=edge, width=8)
    # the quiff: a black wave swept up and back
    d.pieslice([150, 150, 560, 470], 180, 360, fill=(22, 20, 22, 255))
    d.ellipse([300, 110, 600, 330], fill=(22, 20, 22, 255))
    d.ellipse([360, 150, 520, 250], fill=(60, 58, 64, 255))
    d.rectangle([150, 300, 560, 330], fill=yellow)
    # the moustache
    for s in (-1, 1):
        d.ellipse([340 + s * 95 - 100, 400, 340 + s * 95 + 100, 480], fill=(22, 20, 22, 255))
        d.polygon([(340 + s * 150, 430), (340 + s * 230, 400), (340 + s * 170, 478)], fill=(22, 20, 22, 255))
    # the ribbon and its words
    d.polygon([(40, 600), (640, 540), (650, 640), (50, 700)], fill=(232, 214, 176, 255), outline=edge)
    d.line([(40, 600), (640, 540), (650, 640), (50, 700), (40, 600)], fill=edge, width=6)
    f = font(BOLD, 50)
    txt = Image.new('RGBA', (600, 80), (0, 0, 0, 0))
    td = ImageDraw.Draw(txt)
    td.text(((600 - td.textlength('SIEMPRE DE FIESTA', font=f)) / 2, 8), 'SIEMPRE DE FIESTA', font=f, fill=edge)
    txt = txt.rotate(5.7, resample=Image.BICUBIC, expand=True)
    im.alpha_composite(txt, (40, 560))
    im.save(os.path.join(OUT, 'mural.png'))
    print('mural.png', im.size)


def ramas():
    w, h = 900, 780
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rnd = random.Random(21)
    black = (26, 24, 26, 255)

    def branch(p, ang, ln, wd, depth):
        q = (p[0] + math.cos(ang) * ln, p[1] + math.sin(ang) * ln)
        d.line([p, q], fill=black, width=max(3, int(wd)))
        if depth > 0:
            for k in range(2):
                branch(q if k == 0 else (p[0] + (q[0] - p[0]) * 0.55, p[1] + (q[1] - p[1]) * 0.55), ang + rnd.uniform(-0.75, 0.75), ln * rnd.uniform(0.55, 0.8), wd * 0.65, depth - 1)
        else:
            c = rnd.choice([(60, 120, 210, 255), (90, 150, 230, 255), (70, 140, 80, 255), (200, 70, 60, 255)])
            if c[2] > 200:                              # (a blue flower of five petals)
                for a in range(5):
                    d.ellipse([q[0] + math.cos(a * 1.257) * 12 - 9, q[1] + math.sin(a * 1.257) * 12 - 9, q[0] + math.cos(a * 1.257) * 12 + 9, q[1] + math.sin(a * 1.257) * 12 + 9], fill=c)
                d.ellipse([q[0] - 6, q[1] - 6, q[0] + 6, q[1] + 6], fill=(240, 210, 60, 255))
            else:                                       # (a leaf)
                d.ellipse([q[0] - 12, q[1] - 6, q[0] + 12, q[1] + 6], fill=c)

    for start, ang in (((-10, 250), 0.1), ((910, 180), 3.05), ((-10, 560), -0.25), ((910, 520), 3.4), ((300, 790), -1.3)):
        branch(start, ang, 230, 16, 3)
    # the little bird house, hung near the top
    d.polygon([(110, 60), (175, 20), (240, 60)], fill=(120, 70, 40, 255))
    d.rectangle([125, 60, 225, 160], fill=(150, 100, 60, 255), outline=(80, 50, 30, 255), width=4)
    d.ellipse([155, 85, 195, 125], fill=(30, 24, 20, 255))
    im.save(os.path.join(OUT, 'ramas.png'))
    print('ramas.png', im.size)


def pizarra():
    w, h = 420, 640
    im = Image.new('RGBA', (w, h), (28, 30, 32, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=(110, 80, 50, 255), width=16)
    f = font(CHALK, 110)
    d.text(((w - d.textlength('RIZE', font=f)) / 2, 22), 'RIZE', font=f, fill=(245, 245, 240, 255))
    f2 = font(CHALK, 62)
    d.text(((w - d.textlength('¡ABIERTO!', font=f2)) / 2, 170), '¡ABIERTO!', font=f2, fill=(120, 220, 140, 255))
    f3 = font(CHALK, 44)
    for i, (line, col) in enumerate((('Tapas', (250, 220, 120, 255)), ('Raciones', (255, 160, 150, 255)), ('Menú diario', (140, 200, 255, 255)))):
        d.text((44 + i * 8, 290 + i * 86), '* ' + line, font=f3, fill=col)
    for k in range(5):                                  # (a few chalk stars)
        x, y = 50 + k * 80, 580 - (k % 2) * 14
        d.line([(x - 10, y), (x + 10, y)], fill=(245, 245, 240, 255), width=3)
        d.line([(x, y - 10), (x, y + 10)], fill=(245, 245, 240, 255), width=3)
    im.save(os.path.join(OUT, 'pizarra.png'))
    print('pizarra.png', im.size)


def rotulo():
    w, h = 1000, 140
    im = Image.new('RGBA', (w, h), (30, 52, 120, 255))
    d = ImageDraw.Draw(im)
    f = font(BOLD, 86)
    txt = 'CAFETERÍA  RIZE'
    d.text(((w - d.textlength(txt, font=f)) / 2, 22), txt, font=f, fill=(250, 250, 244, 255))
    im.save(os.path.join(OUT, 'rotulo.png'))
    print('rotulo.png', im.size)


if __name__ == '__main__':
    mural()
    ramas()
    pizarra()
    rotulo()
