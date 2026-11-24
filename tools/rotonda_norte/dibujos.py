"""The pictures of the roundabout at the north entrance, where the old Madrid-Cadiz road comes into the town
(godot/assets/rotonda_norte/), drawn here (the user, 24 November 2026: "Un poco más adelante hay una rotonda bastante
bonita", with two Street View captures of November 2024).

    python tools/rotonda_norte/dibujos.py

chapa.png   the face of the long board of rusty steel on the lawn: MADRIDEJOS painted on it in white by hand, as the
            real one (the town keeps its name: Matritellus is the game's title). 4.60 x 0.86 m, the face that looks
            north, to who comes from Madrid
oxido.png   the bare rust of its back and its curled end (a piece that repeats)
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'rotonda_norte')
os.makedirs(OUT, exist_ok=True)
FONTS = os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts')


def rust(w, h, seed):
    """weathered steel: a dark brown, patches of orange rust, darker runs from the top edge, fine grain"""
    rnd = random.Random(seed)
    im = Image.new('RGB', (w, h), (78, 48, 34))
    for size, n, cols in ((90, 70, (104, 62, 40)), (40, 260, (118, 70, 44)), (16, 1400, (60, 38, 28)), (8, 3000, (128, 78, 50))):
        lay = Image.new('L', (w, h), 0)
        d = ImageDraw.Draw(lay)
        for _ in range(n * w * h // (2048 * 384)):
            x, y = rnd.randrange(w), rnd.randrange(h)
            r = size * rnd.uniform(0.4, 1.0)
            d.ellipse([x - r, y - r * rnd.uniform(0.5, 1.0), x + r, y + r * rnd.uniform(0.5, 1.0)], fill=rnd.randint(60, 150))
        lay = lay.filter(ImageFilter.GaussianBlur(size * 0.35))
        im = Image.composite(Image.new('RGB', (w, h), cols), im, lay)
    runs = Image.new('L', (w, h), 0)                     # (rain has drawn the rust down from the top)
    d = ImageDraw.Draw(runs)
    for _ in range(w // 9):
        x = rnd.randrange(w)
        d.line([(x, 0), (x + rnd.randint(-4, 4), rnd.randint(h // 4, h))], fill=rnd.randint(20, 70), width=rnd.randint(2, 7))
    runs = runs.filter(ImageFilter.GaussianBlur(3))
    im = Image.composite(Image.new('RGB', (w, h), (58, 34, 24)), im, runs)
    px = im.load()
    for _ in range(w * h // 6):
        x, y = rnd.randrange(w), rnd.randrange(h)
        c = px[x, y]
        k = rnd.randint(-14, 10)
        px[x, y] = (max(0, min(255, c[0] + k)), max(0, min(255, c[1] + k)), max(0, min(255, c[2] + k)))
    return im


def board():
    """the board's face at 445 pixels a metre: the white letters painted with a dry brush, a little uneven"""
    w, h = 2048, 383
    im = rust(w, h, 11)
    fnt = ImageFont.truetype(os.path.join(FONTS, 'Inkfree.ttf'), 300)
    word = 'MADRIDEJOS'
    # each letter on its own: tall and narrow as the real ones, set along the board with a slightly wandering line
    rnd = random.Random(5)
    ink = Image.new('L', (w, h), 0)
    left, right = 150, w - 110                          # (the real word starts a little in from the curled end)
    step = (right - left) / len(word)
    for i, ch in enumerate(word):
        g = Image.new('L', (400, 420), 0)
        if ch == 'I':                                   # (the real I is one plain stroke, with no bars)
            ImageDraw.Draw(g).line([(200, 60), (196, 360)], fill=255, width=34)
        else:
            ImageDraw.Draw(g).text((200, 210), ch, font=fnt, fill=255, anchor='mm', stroke_width=1, stroke_fill=255)
        g = g.crop(g.getbbox())
        gh = int(h * rnd.uniform(0.57, 0.62))
        gw = int(g.width * gh / g.height * 0.78)
        g = g.resize((gw, gh), Image.LANCZOS).rotate(rnd.uniform(-4, 4), resample=Image.BICUBIC, expand=True)
        cx = left + step * (i + 0.5)
        cy = h * 0.5 + rnd.uniform(-10, 10)
        ink.paste(g, (int(cx - g.width / 2), int(cy - g.height / 2)), g)
    # a dry brush: the paint thins in streaks along the strokes and the rust shows through in specks
    grain = Image.effect_noise((w, h), 60).filter(ImageFilter.GaussianBlur(1.0))
    grain = grain.point(lambda v: 255 if v > 92 else int(v * 2.2))
    ink = ImageChops.multiply(ink.filter(ImageFilter.GaussianBlur(1.2)), grain)
    paint = Image.new('RGB', (w, h), (232, 233, 230))
    im = Image.composite(paint, im, ink)
    im.save(os.path.join(OUT, 'chapa.png'))


rust(512, 512, 23).save(os.path.join(OUT, 'oxido.png'))
board()
print('ok', sorted(os.listdir(OUT)))
