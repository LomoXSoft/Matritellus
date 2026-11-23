"""The pictures of the Plaza de Jesús Requejo (godot/assets/requejo/), drawn here: the block of the Red Cross and the
park behind it (the user, 23 November 2026: "Ahora la cruz roja y el parque que tiene detrás, los dos lados de la misma
manzana"). The game shows no real organisation's name or emblem: the cross is green and the name is NAME below, the
user's ("Que llamaremos la cruz verde. La plaza puede mantener el nombre"). No telephone, no address, no social
network; the town is
"MATRITELLUS" on signs, as everywhere in the game.

    python tools/requejo/dibujos.py

rotulo.png    the words painted on the white wing over the office's door and windows (0.8 m high, see-through round
              them): the cross, the name in dark capitals and small letters, the town under it in green
cartel.png    the board hung on the balcony's railing of the front (1.75 x 0.55 m): white, the cross, the name
placa.png     a plaque by the door (0.55 x 0.45 m): white, a plain blue round emblem of our own and lines too small to
              read
cruz.png      the little white sign with the cross by the office's door (0.3 x 0.4 m)
mural.png     the mural on the south walls, over the park (21.6 x 3.8 m): a painted town of coloured houses with
              tiled roofs, the church tower, a windmill on its hill, a tractor, the sky with a bird (our own drawing:
              the real one is a town of coloured houses too)
panel.png     the park's notice board (1.0 x 0.75 m): white, a green band on top, lines too small to read
vado.png      the plate on the east wing's garage door (0.36 x 0.6 m): the round no-parking sign over a white plate
              saying VADO PERMANENTE (no number on it)
the transformer hut on the corner of the square (requejo_1):
aviso.png     the yellow warning triangle with the black lightning bolt on its sheet-metal door (0.3 m)
chapa.png     the old metal plate over its door (0.65 x 0.3 m): rusty brass, lines worn past reading
calle.png     the square's name plate on its front (0.55 x 0.35 m): grey stone, PLAZA / D. JESUS / REQUEJO (the
              user: "La plaza puede mantener el nombre")
camino.png    the little blue tile with the yellow arrow of the pilgrims' way on its east side (0.15 m)
desconchon.png  a patch of its west gable where the whitewash and the render have fallen (0.75 x 1.2 m, see-through round
              it): the brown render under it, its broken edge, the stain run down from it
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'requejo')
os.makedirs(OUT, exist_ok=True)
NAME = 'Cruz Verde'                  # (the user's name for it, 23 Nov 2026)
TOWN = 'MATRITELLUS'
GREEN = (22, 150, 72)
INK = (44, 40, 40)
WHITE = (250, 250, 248)
GREY = (150, 150, 152)


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


SERIF_B = ['georgiab.ttf', 'timesbd.ttf', 'arialbd.ttf']
BOLD = ['arialbd.ttf', 'DejaVuSans-Bold.ttf']
SANS = ['arial.ttf', 'DejaVuSans.ttf']


def cross(d, cx, cy, s, fill):
    """a Greek cross of arms s wide, 3 s across"""
    d.rectangle([cx - s * 1.5, cy - s / 2, cx + s * 1.5, cy + s / 2], fill=fill)
    d.rectangle([cx - s / 2, cy - s * 1.5, cx + s / 2, cy + s * 1.5], fill=fill)


def rotulo():
    f = font(SERIF_B, 150)
    f2 = font(BOLD, 78)
    probe = ImageDraw.Draw(Image.new('RGBA', (8, 8)))
    w = probe.textlength(NAME, font=f)
    t2 = probe.textlength(TOWN, font=f2)
    im = Image.new('RGBA', (int(300 + max(w, t2) + 40), 400), (0, 0, 0, 0))     # (as wide as the words: requejo.gd reads its width)
    d = ImageDraw.Draw(im)
    cross(d, 150, 170, 62, GREEN + (255,))
    d.text((300, 60), NAME, font=f, fill=INK + (255,))
    d.text((300 + w / 2 - t2 / 2, 250), TOWN, font=f2, fill=GREEN + (255,))
    im.save(os.path.join(OUT, 'rotulo.png'))


def cartel():
    im = Image.new('RGB', (700, 220), WHITE)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 699, 219], outline=(200, 200, 200), width=6)
    cross(d, 110, 110, 34, GREEN)
    size = 92
    f = font(SERIF_B, size)
    while d.textlength(NAME, font=f) > 470 and size > 30:         # (the name fits the board, whatever it is)
        size -= 4
        f = font(SERIF_B, size)
    d.text((190, 110 - size * 0.62), NAME, font=f, fill=INK)
    im.save(os.path.join(OUT, 'cartel.png'))


def placa():
    im = Image.new('RGB', (220, 180), WHITE)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 219, 179], outline=(190, 190, 190), width=4)
    d.ellipse([78, 14, 142, 78], fill=(36, 70, 150))              # (a plain emblem of our own: no real one)
    d.ellipse([92, 28, 128, 64], outline=(250, 250, 248), width=5)
    for i, w in enumerate([150, 170, 130, 160]):
        y = 96 + i * 17
        d.rectangle([110 - w / 2, y, 110 + w / 2, y + 7], fill=GREY)
    im.save(os.path.join(OUT, 'placa.png'))


def cruz_signo():
    im = Image.new('RGB', (150, 200), WHITE)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 149, 199], outline=(190, 190, 190), width=4)
    cross(d, 75, 80, 26, GREEN)
    for i, w in enumerate([100, 80]):
        d.rectangle([75 - w / 2, 150 + i * 16, 75 + w / 2, 157 + i * 16], fill=GREY)
    im.save(os.path.join(OUT, 'cruz.png'))


def panel():
    im = Image.new('RGB', (400, 300), WHITE)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 399, 60], fill=(46, 140, 70))
    d.rectangle([20, 18, 230, 42], fill=(230, 240, 230))
    for i in range(9):
        w = 340 if i % 4 != 3 else 220
        d.rectangle([28, 84 + i * 22, 28 + w, 92 + i * 22], fill=GREY)
    d.rectangle([300, 250, 380, 285], fill=(30, 60, 140))
    d.rectangle([0, 0, 399, 299], outline=(170, 170, 170), width=4)
    im.save(os.path.join(OUT, 'panel.png'))


def vado():
    im = Image.new('RGB', (240, 400), WHITE)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 239, 399], outline=(190, 190, 190), width=4)
    d.ellipse([30, 20, 210, 200], fill=(200, 30, 36))                  # the round sign: red rim, blue disc, red bar
    d.ellipse([52, 42, 188, 178], fill=(30, 70, 160))
    d.line([(70, 60), (170, 160)], fill=(200, 30, 36), width=22)
    f = font(BOLD, 58)
    w = d.textlength('VADO', font=f)
    d.text((120 - w / 2, 225), 'VADO', font=f, fill=INK)
    f2 = font(BOLD, 30)
    w2 = d.textlength('PERMANENTE', font=f2)
    d.text((120 - w2 / 2, 300), 'PERMANENTE', font=f2, fill=INK)
    d.rectangle([40, 352, 200, 360], fill=GREY)
    im.save(os.path.join(OUT, 'vado.png'))


def aviso():
    im = Image.new('RGBA', (300, 270), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(150, 6), (294, 262), (6, 262)], fill=(24, 22, 20))
    d.polygon([(150, 34), (268, 246), (32, 246)], fill=(246, 196, 24))
    d.polygon([(168, 92), (118, 172), (150, 172), (124, 232), (186, 150), (154, 150), (178, 92)], fill=(24, 22, 20))
    im.save(os.path.join(OUT, 'aviso.png'))


def chapa():
    rnd = random.Random(7)
    im = Image.new('RGB', (520, 240), (122, 96, 62))
    d = ImageDraw.Draw(im)
    for k in range(900):                                     # the rust and the wear
        x, y = rnd.randrange(520), rnd.randrange(240)
        c = rnd.choice([(96, 70, 44), (140, 112, 74), (84, 60, 40), (150, 124, 86)])
        d.ellipse([x, y, x + rnd.randrange(3, 14), y + rnd.randrange(2, 8)], fill=c)
    d.rectangle([0, 0, 519, 239], outline=(70, 52, 34), width=8)
    for row in range(4):                                     # lines of letters worn past reading
        y = 38 + row * 48
        x = 40 if row else 120
        while x < (480 if row else 400):
            w = rnd.randrange(14, 30)
            d.rectangle([x, y, x + w, y + 22], fill=rnd.choice([(58, 42, 28), (66, 48, 30), (80, 60, 40)]))
            x += w + rnd.choice([6, 6, 6, 22])
    for x, y in [(18, 18), (500, 18), (18, 220), (500, 220)]:
        d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=(60, 50, 40))
    im.save(os.path.join(OUT, 'chapa.png'))


def calle():
    im = Image.new('RGB', (440, 280), (196, 196, 192))
    d = ImageDraw.Draw(im)
    rnd = random.Random(3)
    for k in range(500):
        x, y = rnd.randrange(440), rnd.randrange(280)
        g = rnd.randrange(170, 215)
        d.point((x, y), fill=(g, g, g - 4))
    d.rectangle([0, 0, 439, 279], outline=(150, 150, 146), width=6)
    for i, (s, size) in enumerate([('PLAZA', 64), ('D. JESÚS', 56), ('REQUEJO', 60)]):
        f = font(SERIF_B, size)
        w = d.textlength(s, font=f)
        d.text((220 - w / 2, 22 + i * 82), s, font=f, fill=(78, 76, 74))
    im.save(os.path.join(OUT, 'calle.png'))


def camino():
    im = Image.new('RGB', (160, 160), (28, 72, 160))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 159, 159], outline=(20, 50, 120), width=5)
    d.rectangle([26, 66, 100, 94], fill=(250, 204, 20))
    d.polygon([(96, 40), (138, 80), (96, 120)], fill=(250, 204, 20))
    im.save(os.path.join(OUT, 'camino.png'))


def desconchon():
    rnd = random.Random(11)
    im = Image.new('RGBA', (300, 480), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    mid = (150, 110)
    pts = []
    for k in range(22):
        a = math.tau * k / 22
        r = 96 + rnd.uniform(-26, 22)
        pts.append((mid[0] + math.cos(a) * r * 1.25, mid[1] + math.sin(a) * r * 0.9))
    d.polygon(pts, fill=(112, 92, 70, 255))                         # the broken edge, darker...
    inner = [(mid[0] + (x - mid[0]) * 0.86, mid[1] + (y - mid[1]) * 0.86) for x, y in pts]
    d.polygon(inner, fill=(146, 124, 96, 255))                      # ...the brown render under the whitewash
    for k in range(260):
        x, y = rnd.uniform(70, 230), rnd.uniform(40, 180)
        c = rnd.choice([(128, 106, 80), (160, 138, 108), (118, 98, 74)])
        d.ellipse([x, y, x + rnd.uniform(3, 10), y + rnd.uniform(2, 7)], fill=c + (255,))
    for x0, w, reach in [(132, 9, 300), (158, 6, 220), (112, 5, 160)]:       # the stain run down from it
        for y in range(190, 190 + reach):
            f = 1.0 - (y - 190) / reach
            xx = x0 + 4 * math.sin(y / 23.0)
            d.line([(xx - w * f / 2, y), (xx + w * f / 2, y)], fill=(126, 104, 78, int(220 * f)))
    im.save(os.path.join(OUT, 'desconchon.png'))


# ---------------- the mural ----------------
HOUSE_COLS = [(232, 92, 84), (246, 196, 72), (92, 150, 220), (124, 196, 120), (238, 140, 180), (250, 250, 244),
              (250, 160, 70), (150, 110, 200), (90, 190, 200), (230, 70, 110), (250, 226, 150), (110, 170, 90)]
ROOF_COLS = [(176, 70, 44), (150, 58, 40), (196, 92, 52), (120, 60, 50)]


def house(d, x, base, w, h, col, roof, rnd):
    d.rectangle([x, base - h, x + w, base], fill=col, outline=(70, 60, 60), width=2)
    rh = rnd.randint(int(w * 0.25), int(w * 0.45))
    d.polygon([(x - 6, base - h), (x + w + 6, base - h), (x + w / 2, base - h - rh)], fill=roof, outline=(70, 50, 40))
    # windows and a door
    rows = max(1, int(h / 70))
    for r in range(rows):
        y = base - h + 24 + r * 70
        for k in range(max(1, int(w / 46))):
            wx = x + 12 + k * 46
            if wx + 22 > x + w - 6:
                break
            d.rectangle([wx, y, wx + 20, y + 28], fill=(60, 90, 130) if rnd.random() < 0.6 else (250, 250, 250), outline=(60, 50, 50), width=2)
    if rnd.random() < 0.8:
        dx = x + w / 2 - 12
        d.rectangle([dx, base - 44, dx + 24, base], fill=(120, 70, 40) if rnd.random() < 0.5 else (40, 110, 80), outline=(60, 40, 30))


def mural():
    W, H = 2400, 420
    rnd = random.Random(7)
    im = Image.new('RGB', (W, H), (150, 206, 236))
    d = ImageDraw.Draw(im)
    for y in range(0, 230):                                  # the sky, paler down to the hills
        t = y / 230
        c = tuple(int(a + (b - a) * t) for a, b in zip((112, 182, 230), (196, 228, 244)))
        d.line([(0, y), (W, y)], fill=c)
    for cx, cy, s in [(300, 50, 1.0), (980, 36, 1.3), (1700, 60, 0.9), (2200, 30, 1.1)]:
        for dx, dy, r in [(-40, 10, 30), (0, 0, 40), (40, 8, 32), (75, 16, 22)]:
            d.ellipse([cx + dx * s - r * s, cy + dy * s - r * s, cx + dx * s + r * s, cy + dy * s + r * s], fill=(252, 252, 250))
    for bx in (1320, 1360):                                  # a bird
        d.arc([bx, 70, bx + 40, 100], 200, 340, fill=(40, 40, 50), width=4)
    # the hills, the windmill on the first
    d.polygon([(0, 250), (260, 170), (520, 230), (760, 200), (1100, 240), (1500, 205), (1900, 235), (2400, 195), (2400, 420), (0, 420)], fill=(200, 176, 110))
    d.polygon([(0, 290), (400, 250), (900, 280), (1400, 255), (2000, 285), (2400, 260), (2400, 420), (0, 420)], fill=(176, 150, 92))
    mx, my = 250, 175
    d.polygon([(mx - 26, my), (mx + 26, my), (mx + 18, my - 90), (mx - 18, my - 90)], fill=(250, 250, 246), outline=(80, 70, 60), width=2)
    d.polygon([(mx - 24, my - 90), (mx + 24, my - 90), (mx, my - 122)], fill=(70, 60, 56))
    for a in range(4):
        ang = math.radians(25 + a * 90)
        ex, ey = mx + math.cos(ang) * 95, my - 96 + math.sin(ang) * 95
        d.line([(mx, my - 96), (ex, ey)], fill=(70, 60, 56), width=5)
        px, py = -math.sin(ang) * 14, math.cos(ang) * 14
        d.polygon([(mx + (ex - mx) * 0.25, my - 96 + (ey - my + 96) * 0.25), (ex, ey), (ex + px, ey + py), (mx + (ex - mx) * 0.25 + px, my - 96 + (ey - my + 96) * 0.25 + py)], fill=(236, 230, 214), outline=(70, 60, 56))
    # the church tower behind the houses
    tx = 1180
    d.rectangle([tx, 70, tx + 70, 260], fill=(214, 170, 120), outline=(90, 60, 40), width=3)
    d.polygon([(tx - 6, 70), (tx + 76, 70), (tx + 35, 18)], fill=(150, 70, 50))
    d.rectangle([tx + 22, 100, tx + 48, 140], fill=(60, 50, 50))
    d.line([(tx + 35, 18), (tx + 35, -2)], fill=(40, 40, 40), width=3)
    d.line([(tx + 25, 6), (tx + 45, 6)], fill=(40, 40, 40), width=3)
    # two rows of houses
    for row, (base, hmin, hmax) in enumerate([(300, 80, 140), (372, 90, 170)]):
        x = -20 + row * 30
        while x < W:
            w = rnd.randint(80, 170)
            h = rnd.randint(hmin, hmax)
            if not (row == 0 and 150 < x < 340):              # (the windmill's hill stays clear)
                house(d, x, base, w, h, rnd.choice(HOUSE_COLS), rnd.choice(ROOF_COLS), rnd)
            x += w + rnd.randint(4, 18)
    # the street at the foot, a tractor going along it
    d.rectangle([0, 372, W, 420], fill=(214, 206, 190))
    d.line([(0, 372), (W, 372)], fill=(120, 110, 100), width=3)
    tx, ty = 420, 404
    d.rectangle([tx, ty - 46, tx + 110, ty - 12], fill=(56, 140, 64), outline=(30, 60, 30), width=2)
    d.rectangle([tx + 60, ty - 82, tx + 108, ty - 46], fill=(56, 140, 64), outline=(30, 60, 30), width=2)
    d.rectangle([tx + 68, ty - 76, tx + 100, ty - 52], fill=(170, 210, 230))
    d.ellipse([tx + 62, ty - 52, tx + 122, ty + 8], fill=(40, 40, 40))
    d.ellipse([tx + 80, ty - 34, tx + 104, ty - 10], fill=(200, 60, 50))
    d.ellipse([tx - 4, ty - 30, tx + 34, ty + 8], fill=(40, 40, 40))
    d.ellipse([tx + 8, ty - 18, tx + 22, ty - 4], fill=(200, 60, 50))
    d.rectangle([tx + 20, ty - 70, tx + 28, ty - 46], fill=(60, 60, 60))
    im.save(os.path.join(OUT, 'mural.png'))


rotulo()
cartel()
placa()
cruz_signo()
panel()
vado()
aviso()
chapa()
calle()
camino()
desconchon()
mural()
print('ok', OUT)
