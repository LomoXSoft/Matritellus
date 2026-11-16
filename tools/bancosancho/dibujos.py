"""The pictures of the corner house of the bank and the copy shop (godot/assets/bancosancho/), all drawn here: names the
user gave (17 November 2026: "la copistería xijote (que llamaremos copistería Sancho panza) y el banco Santander (que
llamaremos banco Cantabria)"), emblems of our own -- not the real ones.

    python tools/bancosancho/dibujos.py

banco.png        the bank's red band: "Banco Cantabria" in white and our emblem, a ring with three waves of the sea (4 x 0.6 m)
banco_cubo.png   the red box at the end of the band and the sign standing out at the corner: the emblem alone
cartel_banco.png a poster in the bank's window (our own: a home and a key, "HIPOTECA")
copisteria.png   the panel in the copy shop's window: "Copistería Sancho Panza", what it does, and a donkey of our own
electricidad.png the electrician's sign: what he does, no name (the user's rule: signs say what is sold)
energia.png      the panel over his door: green, "ENERGÍA", a sun
cajero.png       the screen and keys of the cash machine
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'bancosancho')
FONTS = os.path.join(os.environ.get('WINDIR', 'C:\\Windows'), 'Fonts')
SEMI = os.path.join(FONTS, 'segoeuisb.ttf') if os.path.exists(os.path.join(FONTS, 'segoeuisb.ttf')) else os.path.join(FONTS, 'segoeuib.ttf')
BOLD = os.path.join(FONTS, 'arialbd.ttf')
SCRIPT = os.path.join(FONTS, 'segoescb.ttf')
RED = (218, 34, 38)
WHITE = (250, 250, 248)
os.makedirs(OUT, exist_ok=True)


def save(im, name):
    im.save(os.path.join(OUT, name))
    print(name, im.size)


def emblem(d, cx, cy, r, fg, bg):
    """a ring, and in it three waves of the sea, the top one with a crest"""
    w = max(3, int(r * 0.16))
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=fg, width=w)
    for k, (dy, amp) in enumerate(((-0.3, 0.13), (0.05, 0.11), (0.38, 0.09))):
        pts = []
        for i in range(41):
            t = i / 40.0
            x = cx - r * 0.62 + t * r * 1.24
            y = cy + r * dy + math.sin(t * math.pi * 2.0 + k) * r * amp
            pts.append((x, y))
        d.line(pts, fill=fg, width=max(2, int(r * 0.13)), joint='curve')


def banco():
    W, H = 2000, 300                                         # 500 px a metre
    im = Image.new('RGB', (W, H), RED)
    d = ImageDraw.Draw(im)
    emblem(d, 250, H / 2, 95, WHITE, RED)
    f = ImageFont.truetype(SEMI, 150)
    d.text((390, H / 2 + 4), 'Banco Cantabria', font=f, fill=WHITE, anchor='lm')
    x = 390 + d.textlength('Banco Cantabria', font=f) + 40
    d.line([(x, 70), (x, 230)], fill=WHITE, width=5)
    d.text((x + 36, H / 2 + 2), 'Agentes', font=ImageFont.truetype(SEMI, 80), fill=WHITE, anchor='lm')
    save(im, 'banco.png')


def banco_cubo():
    W = 300
    im = Image.new('RGB', (W, W), RED)
    d = ImageDraw.Draw(im)
    emblem(d, W / 2, W / 2, 95, WHITE, RED)
    save(im, 'banco_cubo.png')


def cartel_banco():
    W, H = 400, 640
    im = Image.new('RGB', (W, H), (232, 48, 44))
    d = ImageDraw.Draw(im)
    d.rectangle([24, 24, W - 24, H - 24], outline=WHITE, width=4)
    d.polygon([(110, 300), (200, 210), (290, 300), (290, 400), (110, 400)], outline=WHITE, width=10)       # a house
    d.rectangle([180, 330, 220, 400], fill=WHITE)
    d.ellipse([255, 360, 315, 420], outline=WHITE, width=9)                                              # its key
    d.line([(305, 410), (350, 455)], fill=WHITE, width=9)
    d.line([(335, 440), (322, 453)], fill=WHITE, width=7)
    d.text((W / 2, 120), 'TU CASA', font=ImageFont.truetype(BOLD, 52), fill=WHITE, anchor='mm')
    d.text((W / 2, 500), 'HIPOTECA', font=ImageFont.truetype(BOLD, 56), fill=WHITE, anchor='mm')
    d.text((W / 2, 560), 'Pregunta dentro', font=ImageFont.truetype(BOLD, 30), fill=WHITE, anchor='mm')
    save(im, 'cartel_banco.png')


def donkey(d, x, y, s, c):
    """a donkey of our own, side on, looking right: a round barrel of a body, short legs, a thick neck held low, a long
    head with a pale muzzle, two long ears laid back, a tuft of a tail"""
    def P(px, py): return (x + px * s, y + py * s)
    d.ellipse([P(0.1, 0.32), P(0.72, 0.66)], fill=c)                      # body
    for lx in (0.18, 0.3, 0.54, 0.64):                                    # legs, with hooves
        d.rectangle([P(lx - 0.025, 0.55), P(lx + 0.025, 0.92)], fill=c)
        d.rectangle([P(lx - 0.035, 0.9), P(lx + 0.035, 0.95)], fill=c)
    d.polygon([P(0.6, 0.36), P(0.76, 0.2), P(0.86, 0.26), P(0.74, 0.5)], fill=c)      # neck
    d.polygon([P(0.74, 0.18), P(0.86, 0.14), P(1.02, 0.3), P(0.98, 0.38), P(0.86, 0.34)], fill=c)   # head, long
    d.ellipse([P(0.94, 0.28), P(1.04, 0.38)], fill=(150, 150, 150))       # muzzle
    d.polygon([P(0.77, 0.17), P(0.62, 0.0), P(0.66, -0.02), P(0.81, 0.15)], fill=c)  # ears, laid back
    d.polygon([P(0.8, 0.15), P(0.7, -0.04), P(0.74, -0.05), P(0.84, 0.14)], fill=c)
    d.line([P(0.11, 0.42), P(0.03, 0.66)], fill=c, width=max(2, int(s * 0.025)))      # tail and its tuft
    d.ellipse([P(0.0, 0.64), P(0.06, 0.74)], fill=c)


def copisteria():
    W, H = 900, 500                                           # 1.8 x 1.0 m
    im = Image.new('RGB', (W, H), (238, 244, 236))
    d = ImageDraw.Draw(im)
    green = (52, 110, 74)
    for k in range(7):                                        # splashes of green behind the donkey
        cx, cy, r = 770 + 35 * math.cos(k), 260 + 55 * math.sin(k * 1.7), 55 + 12 * (k % 3)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(178, 214, 176))
    d.text((50, 130), 'Copistería', font=ImageFont.truetype(SCRIPT, 88), fill=(38, 38, 40), anchor='lm')
    d.text((50, 245), 'Sancho Panza', font=ImageFont.truetype(SCRIPT, 84), fill=green, anchor='lm')
    d.text((54, 350), 'PAPELERÍA · DISEÑO GRÁFICO', font=ImageFont.truetype(BOLD, 28), fill=(38, 38, 40), anchor='lm')
    d.text((54, 400), 'Fotocopias · Encuadernaciones', font=ImageFont.truetype(BOLD, 24), fill=green, anchor='lm')
    donkey(d, 660, 160, 210, (38, 38, 40))
    save(im, 'copisteria.png')


def electricidad():
    W, H = 1000, 400
    im = Image.new('RGB', (W, H), (30, 42, 110))
    d = ImageDraw.Draw(im)
    for k in range(3):                                        # three slanting strokes of yellow at its left, a spark
        x0 = 60 + k * 62
        d.polygon([(x0 + 60, 60), (x0 + 95, 60), (x0 + 35, 340), (x0, 340)], fill=(242, 196, 32))
    d.text((300, 90), 'INSTALACIONES', font=ImageFont.truetype(BOLD, 60), fill=WHITE, anchor='lm')
    d.text((300, 160), 'ELÉCTRICAS', font=ImageFont.truetype(BOLD, 60), fill=(242, 196, 32), anchor='lm')
    f = ImageFont.truetype(BOLD, 30)
    for k, t in enumerate(('· Antenas y porteros', '· Aire acondicionado', '· Energía solar')):
        d.text((300, 230 + k * 40), t, font=f, fill=WHITE, anchor='lm')
    d.rectangle([300, 350, 900, 352], fill=(242, 196, 32))
    d.text((300, 375), '~~~ ~~~ ~~~', font=ImageFont.truetype(BOLD, 22), fill=(200, 200, 220), anchor='lm')   # (a phone number, scribbled: the user's rule)
    save(im, 'electricidad.png')


def energia():
    W, H = 1200, 300
    im = Image.new('RGB', (W, H), (244, 246, 242))
    d = ImageDraw.Draw(im)
    green = (60, 140, 70)
    cx, cy = 150, 150
    d.ellipse([cx - 50, cy - 50, cx + 50, cy + 50], fill=(242, 190, 40))
    for k in range(12):
        a = k * math.pi / 6.0
        d.line([(cx + math.cos(a) * 65, cy + math.sin(a) * 65), (cx + math.cos(a) * 95, cy + math.sin(a) * 95)], fill=(242, 190, 40), width=10)
    d.text((280, 130), 'ENERGÍA', font=ImageFont.truetype(SEMI, 130), fill=green, anchor='lm')
    d.text((290, 240), 'LUZ · GAS · AUTOCONSUMO', font=ImageFont.truetype(BOLD, 40), fill=(60, 60, 60), anchor='lm')
    save(im, 'energia.png')


def cajero():
    W, H = 300, 400
    im = Image.new('RGB', (W, H), (60, 64, 70))
    d = ImageDraw.Draw(im)
    d.rectangle([40, 40, W - 40, 190], fill=(40, 90, 150))
    d.text((W / 2, 90), 'Bienvenido', font=ImageFont.truetype(BOLD, 30), fill=WHITE, anchor='mm')
    d.text((W / 2, 140), 'Introduzca su tarjeta', font=ImageFont.truetype(BOLD, 18), fill=WHITE, anchor='mm')
    for r in range(4):
        for c in range(3):
            d.rectangle([80 + c * 50, 220 + r * 40, 115 + c * 50, 248 + r * 40], fill=(190, 192, 196))
    d.rectangle([60, 380, W - 60, 390], fill=(20, 20, 20))
    save(im, 'cajero.png')


if __name__ == '__main__':
    banco(); banco_cubo(); cartel_banco(); copisteria(); electricidad(); energia(); cajero()
