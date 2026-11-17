"""The pictures the post office of the Calle de Zaragoza is painted with (godot/assets/correos/), all drawn here. The user,
17 November 2026: "En vez de Correos la llamaremos Correa (Servicio Postal Correa). El rótulo debería ser Correa, no
Correos". Its
yellow boards with the blue foot, a post horn of our own (no crown, not the real one's) and its word; the plate of its
hours by the door.

    python tools/correos/dibujos.py [OUT_FOLDER] [WORD]

rotulo.png   one length of board (3.6 x 0.6 m): yellow, the horn, the word in blue
corto.png    the short board over the arch (2.4 x 0.6 m)
horario.png  the plate of its hours (Monday to Friday, 8:00 to 20:00: the user, through Sistemas, 17 Nov 2026)
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', 'godot', 'assets', 'correos')
WORD = sys.argv[2] if len(sys.argv) > 2 else 'CORREA'      # the user's name for it (17 Nov 2026: "la llamaremos Correa (Servicio Postal Correa)")
FONTS = os.path.join(os.environ.get('WINDIR', 'C:\\Windows'), 'Fonts')
BOLD = os.path.join(FONTS, 'arialbd.ttf')
YELLOW = (250, 206, 0)
BLUE = (16, 62, 140)
os.makedirs(OUT, exist_ok=True)


def save(im, name):
    im.save(os.path.join(OUT, name))
    print(name, im.size)


def horn(d, cx, cy, s, col):
    """a post horn: the bell to the left, the coiled tube, the mouthpiece to the right (ours: no crown)"""
    w = max(3, int(s * 0.09))
    d.ellipse([cx - s * 0.55, cy - s * 0.32, cx + s * 0.05, cy + s * 0.28], outline=col, width=w)          # the coil
    d.polygon([(cx - s * 0.6, cy - s * 0.02), (cx - s * 1.0, cy - s * 0.38), (cx - s * 1.0, cy + s * 0.34)], fill=col)   # the bell
    d.line([(cx + s * 0.05, cy - s * 0.02), (cx + s * 0.6, cy - s * 0.02)], fill=col, width=w)            # the lead pipe
    d.ellipse([cx + s * 0.56, cy - s * 0.1, cx + s * 0.72, cy + s * 0.06], fill=col)                      # the mouthpiece


def board(W, H, name, word, logo=True):
    im = Image.new('RGB', (W, H), YELLOW)
    d = ImageDraw.Draw(im)
    for y in range(int(H * 0.08)):                                    # a little shade at the top, the board being round
        d.line([(0, y), (W, y)], fill=(236, 190, 0))
    f = ImageFont.truetype(BOLD, int(H * 0.5))
    tw = d.textlength(word, font=f)
    total = tw + (H * 1.0 if logo else 0)
    x = (W - total) / 2
    if logo:
        horn(d, x + H * 0.48, H * 0.5, H * 0.42, BLUE)
        x += H * 1.0
    d.text((x, H * 0.22), word, font=f, fill=BLUE)
    save(im, name)


def horario():
    W, H = 300, 400
    im = Image.new('RGB', (W, H), (250, 250, 246))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W, 70], fill=YELLOW)
    horn(d, 52, 35, 28, BLUE)
    f = ImageFont.truetype(BOLD, 22)
    d.text((92, 10), 'SERVICIO POSTAL', font=f, fill=BLUE)
    d.text((92, 36), 'CORREA', font=ImageFont.truetype(BOLD, 26), fill=BLUE)
    f2 = ImageFont.truetype(BOLD, 26)
    for i, s in enumerate(('HORARIO', 'Lunes a viernes', '8:00 a 20:00', 'Sábados, domingos', 'y festivos: CERRADO')):
        d.text((W / 2 - d.textlength(s, font=f2) / 2, 100 + i * 46), s, font=f2, fill=(30, 30, 30))
    save(im, 'horario.png')


if __name__ == '__main__':
    board(1440, 240, 'rotulo.png', WORD)
    board(960, 240, 'corto.png', WORD)
    horario()
