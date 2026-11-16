"""The pictures the MasAhorro is painted with (godot/assets/masahorro/), all drawn here, none taken from anywhere:

    python tools/masahorro/dibujos.py

chapa.png      corrugated sheet: one metre of it, upright ribs every 25 cm, grey (each wall tints it)
panel.png      one of the front's composite panels (2.95 x 0.97 m), mustard yellow, its joints dark
rotulo.png     the name over the doors, "MasAhorro": our own lettering (green "Mas", red "Ahorro", a red swoosh under),
               not the real chain's; the letters are cut out (transparent round them) to stand proud of the panels
rotulo_sombra.png  the same letters in one dark colour: their shadow on the panels, a hand's breadth behind
placas.png     a solar panel seen from above: dark blue cells in a silver frame
parking.png    the blue "P" sign at the car park's way in, "CLIENTES" under it
minusvalido.png  the white wheelchair painted on the blue bays (transparent round it)
horario.png    the plate on the post by the way in: the car park's hours
ropa.png       the label of the green bin for old clothes
marquesina.png the badge on the side of the trolleys' shelter (our name, small)
"""
import math, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'masahorro')
FONTS = os.path.join(os.environ.get('WINDIR', 'C:\\Windows'), 'Fonts')
BLACK = os.path.join(FONTS, 'ariblk.ttf')
BOLD = os.path.join(FONTS, 'arialbd.ttf')
GREEN = (46, 140, 58)
RED = (206, 34, 40)
os.makedirs(OUT, exist_ok=True)


def save(im, name):
    im.save(os.path.join(OUT, name))
    print(name, im.size)


def chapa():
    """256 px = 1 m: four ribs, each a flat crown, two slopes and a flat valley, lit from the left"""
    W = 256
    im = Image.new('L', (W, 64))
    px = im.load()
    for x in range(W):
        t = (x % 64) / 64.0                     # one rib: 25 cm
        if t < 0.18:
            v = 236                             # its crown
        elif t < 0.3:
            v = 200                             # the slope in the shade
        elif t < 0.82:
            v = 222                             # the valley
        elif t < 0.9:
            v = 246                             # the lit slope
        else:
            v = 236
        for y in range(64):
            px[x, y] = v
    save(im.convert('RGB'), 'chapa.png')


def panel():
    """one composite panel, 2.95 x 0.97 m at 160 px a metre; its joint (3 cm, dark) along its left and bottom edges"""
    W, H = 472, 155
    im = Image.new('RGB', (W, H), (214, 160, 38))
    d = ImageDraw.Draw(im)
    for y in range(H):                          # a faint sheen across it
        k = 1.0 + 0.04 * math.sin(y / H * math.pi)
        d.line([(0, y), (W, y)], fill=tuple(min(255, int(c * k)) for c in (214, 160, 38)))
    d.rectangle([0, 0, 4, H], fill=(96, 70, 22))
    d.rectangle([0, H - 5, W, H], fill=(96, 70, 22))
    d.line([(5, 0), (5, H - 6)], fill=(236, 188, 70))
    d.line([(5, 0), (W, 0)], fill=(236, 188, 70))
    save(im, 'panel.png')


def lettering(fill_mas, fill_ahorro, fill_swoosh, W=2400, H=520):
    """the name, leaning forward; returns an RGBA picture"""
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    big = ImageFont.truetype(BLACK, 330)
    x = 70
    d.text((x, 20), 'Mas', font=big, fill=fill_mas)
    x += d.textlength('Mas', font=big) + 10
    d.text((x, 20), 'Ahorro', font=big, fill=fill_ahorro)
    end = x + d.textlength('Ahorro', font=big)
    # the swoosh: a red blade under "Ahorro", thick in its middle, rising to the right
    pts = []
    for i in range(41):
        t = i / 40.0
        pts.append((x + 10 + t * (end - x - 10), 430 - 40 * t - 10 * math.sin(t * math.pi)))
    for i in range(40, -1, -1):
        t = i / 40.0
        pts.append((x + 10 + t * (end - x - 10), 430 - 40 * t + 26 * math.sin(t * math.pi) + 4))
    d.polygon(pts, fill=fill_swoosh)
    # lean it forward (12 degrees)
    k = math.tan(math.radians(12))
    im = im.transform((W, H), Image.AFFINE, (1, k, -k * H, 0, 1, 0), resample=Image.BICUBIC)
    bbox = im.getbbox()
    return im.crop((bbox[0] - 12, bbox[1] - 12, bbox[2] + 12, bbox[3] + 12))


def rotulo():
    face = lettering(GREEN + (255,), RED + (255,), RED + (255,))
    save(face, 'rotulo.png')
    shade = lettering((40, 30, 10, 150), (40, 30, 10, 150), (40, 30, 10, 150)).filter(ImageFilter.GaussianBlur(6))
    save(shade.resize(face.size), 'rotulo_sombra.png')
    lit = lettering((40, 190, 70, 255), (235, 40, 45, 255), (235, 40, 45, 255))     # (at night, lit from inside: its own colours)
    save(lit.resize(face.size), 'rotulo_luz.png')


def placas():
    W, H = 200, 120                              # 1.65 x 1.0 m
    im = Image.new('RGB', (W, H), (200, 204, 208))
    d = ImageDraw.Draw(im)
    d.rectangle([4, 4, W - 5, H - 5], fill=(26, 38, 74))
    for i in range(1, 10):
        x = 4 + i * (W - 8) / 10.0
        d.line([(x, 4), (x, H - 5)], fill=(70, 86, 126), width=1)
    for j in range(1, 6):
        y = 4 + j * (H - 8) / 6.0
        d.line([(4, y), (W - 5, y)], fill=(70, 86, 126), width=1)
    save(im, 'placas.png')


def parking():
    W, H = 300, 420
    im = Image.new('RGB', (W, H), (20, 70, 160))
    d = ImageDraw.Draw(im)
    d.rectangle([8, 8, W - 9, H - 9], outline=(240, 240, 240), width=6)
    d.text((W / 2, 150), 'P', font=ImageFont.truetype(BOLD, 250), fill=(245, 245, 245), anchor='mm')
    d.polygon([(200, 260), (250, 300), (200, 340), (200, 318), (150, 318), (150, 282), (200, 282)], fill=(245, 245, 245))
    d.text((W / 2, 385), 'CLIENTES', font=ImageFont.truetype(BOLD, 40), fill=(245, 245, 245), anchor='mm')
    save(im, 'parking.png')


def minusvalido():
    W = 256
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = (245, 245, 245, 255)
    d.ellipse([120, 18, 156, 54], fill=c)                                   # the head
    d.line([(132, 66), (122, 140)], fill=c, width=22)                        # the back
    d.line([(122, 140), (184, 140), (206, 196)], fill=c, width=18)           # the legs
    d.line([(128, 92), (176, 92)], fill=c, width=16)                         # the arm
    d.arc([46, 110, 166, 230], 100, 420, fill=c, width=16)                   # the wheel
    save(im, 'minusvalido.png')


def horario():
    W, H = 300, 220
    im = Image.new('RGB', (W, H), (24, 24, 26))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(BOLD, 26)
    for i, (t, y) in enumerate((('APARCAMIENTO', 30), ('DE CLIENTES', 62))):
        d.text((W / 2, y), t, font=f, fill=(235, 235, 235), anchor='mm')
    d.rectangle([40, 92, W - 40, 175], fill=(235, 235, 235))
    d.text((W / 2, 115), 'de 9:00', font=ImageFont.truetype(BOLD, 30), fill=(24, 24, 26), anchor='mm')
    d.text((W / 2, 152), 'a 21:30 h', font=ImageFont.truetype(BOLD, 30), fill=(24, 24, 26), anchor='mm')
    d.text((W / 2, 198), 'MasAhorro', font=ImageFont.truetype(BOLD, 22), fill=(120, 200, 120), anchor='mm')
    save(im, 'horario.png')


def ropa():
    W, H = 260, 200
    im = Image.new('RGB', (W, H), (40, 128, 70))
    d = ImageDraw.Draw(im)
    d.text((W / 2, 60), 'ROPA', font=ImageFont.truetype(BLACK, 60), fill=(245, 245, 240), anchor='mm')
    d.text((W / 2, 120), 'Y CALZADO', font=ImageFont.truetype(BOLD, 34), fill=(245, 245, 240), anchor='mm')
    d.text((W / 2, 165), 'USADO', font=ImageFont.truetype(BOLD, 34), fill=(245, 245, 240), anchor='mm')
    save(im, 'ropa.png')


def marquesina():
    W, H = 600, 150
    im = Image.new('RGB', (W, H), (238, 236, 230))
    face = lettering(GREEN + (255,), RED + (255,), RED + (255,))
    face.thumbnail((W - 40, H - 30))
    im.paste(face, ((W - face.size[0]) // 2, (H - face.size[1]) // 2), face)
    save(im, 'marquesina.png')


if __name__ == '__main__':
    chapa(); panel(); rotulo(); placas(); parking(); minusvalido(); horario(); ropa(); marquesina()
