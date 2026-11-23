"""The pictures of the roundabout of the Tricornios (godot/scripts/rotonda.gd), drawn here in the game's flat look.

    python tools/rotonda/dibujos.py

Writes into godot/assets/rotonda/:
  bandera.png   the flag: red, yellow, red (1:2:1), plain -- as the barracks' and the patrol cars' (no arms)
  emblema.png   the iron emblem on the monolith, as a cut-out: a crown over the tricorn of the Tricornios' own badge
                (assets/tricornios/logo.png), a sword and a baton crossed behind -- ours, not the real one
  placa.png     the plaque: dark bronze in a gold rim, the town's crest (assets/logo.png, its ribbon with MATRITELLUS:
                the town's old name may be there, the user, 24 Nov 2026) and the Tricornios' badge,
                the words in gold
  grava.png     the white gravel of the island (repeats without a seam)
  mantillo.png  the dark bark of its beds
"""
import os, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, '..', '..', 'godot', 'assets')
OUT = os.path.join(ASSETS, 'rotonda')
FONTS = os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts')
WORDS = ['MADRIDEJOS',                # (the town's name: Matritellus is the game's title -- the user, 23 Nov 2026)
         'EN HONOR A LOS TRICORNIOS,', 'EJEMPLO DE SERVICIO, ENTREGA', 'Y COMPROMISO CON NUESTRO PUEBLO']
DATE = '12 de octubre'
rnd = random.Random(1210)


def flag():
    w, h = 600, 400
    im = Image.new('RGB', (w, h), (198, 11, 30))
    ImageDraw.Draw(im).rectangle([0, h // 4, w, h * 3 // 4], fill=(255, 196, 0))
    im.save(os.path.join(OUT, 'bandera.png'))


def emblem():
    S = 4                                            # drawn big, then shrunk: smooth edges
    w, h = 512 * S, 560 * S
    im = Image.new('L', (w, h), 0)
    d = ImageDraw.Draw(im)
    k = lambda pts: [(x * S, y * S) for x, y in pts]
    # the sword and the baton, crossed behind
    d.line(k([(90, 520), (420, 170)]), fill=255, width=22 * S)          # the blade
    d.polygon(k([(420, 170), (452, 128), (432, 186)]), fill=255)       # its point
    d.line(k([(60, 470), (140, 552)]), fill=255, width=18 * S)          # its guard
    d.ellipse(k([(62, 528), (96, 562)]), fill=255)                     # its pommel
    d.line(k([(422, 520), (92, 170)]), fill=255, width=30 * S)          # the baton
    for t in (0.18, 0.5, 0.82):
        x, y = 422 + (92 - 422) * t, 520 + (170 - 520) * t
        d.ellipse(k([(x - 24, y - 24), (x + 24, y + 24)]), fill=255)
    # the tricorn (the badge's hat: a crown of the hat, its brim)
    d.polygon(k([(150, 300), (362, 300), (334, 400), (178, 400)]), fill=255)
    d.rounded_rectangle(k([(118, 398), (394, 428)]), 10 * S, fill=255)
    d.ellipse(k([(196, 330), (316, 404)]), fill=0)                       # (the hollow, as on the badge)
    # the crown over it all: its band, five points with balls, its arches and the cross
    d.rounded_rectangle(k([(170, 226), (342, 262)]), 8 * S, fill=255)
    for i in range(5):
        x = 180 + i * 38
        d.polygon(k([(x - 14, 228), (x + 14, 228), (x, 178)]), fill=255)
        d.ellipse(k([(x - 11, 166), (x + 11, 188)]), fill=255)
    d.arc(k([(186, 92), (326, 250)]), 180, 360, fill=255, width=16 * S)
    d.arc(k([(226, 104), (286, 250)]), 180, 360, fill=255, width=12 * S)
    d.ellipse(k([(240, 70), (272, 102)]), fill=255)
    d.line(k([(256, 30), (256, 76)]), fill=255, width=12 * S)
    d.line(k([(238, 46), (274, 46)]), fill=255, width=12 * S)
    im = im.resize((512, 560), Image.LANCZOS)
    rgba = Image.new('RGBA', im.size, (40, 40, 44, 0))
    rgba.putalpha(im)
    rgba.save(os.path.join(OUT, 'emblema.png'))


def plaque():
    w, h = 800, 520
    im = Image.new('RGB', (w, h), (48, 40, 30))
    d = ImageDraw.Draw(im)
    d.rectangle([10, 10, w - 11, h - 11], outline=(201, 160, 72), width=8)
    d.rectangle([28, 28, w - 29, h - 29], outline=(150, 118, 52), width=2)
    for path, x in ((os.path.join(ASSETS, 'logo.png'), 70), (os.path.join(ASSETS, 'tricornios', 'logo.png'), w - 210)):
        try:
            badge = Image.open(path).convert('RGBA').resize((140, 140), Image.LANCZOS)
            im.paste(badge, (x, 50), badge)
        except OSError:
            pass
    gold = (226, 190, 98)
    big = ImageFont.truetype(os.path.join(FONTS, 'georgiab.ttf'), 46)
    small = ImageFont.truetype(os.path.join(FONTS, 'georgia.ttf'), 34)
    tiny = ImageFont.truetype(os.path.join(FONTS, 'georgiai.ttf'), 28)
    d.text((w / 2, 120), WORDS[0], font=big, fill=gold, anchor='mm')
    for i, line in enumerate(WORDS[1:]):
        d.text((w / 2, 250 + i * 58), line, font=small, fill=gold, anchor='mm')
    d.text((w - 70, h - 60), DATE, font=tiny, fill=gold, anchor='rm')
    im.save(os.path.join(OUT, 'placa.png'))


def speckle(name, base, stones, n, rmin, rmax, size=256):
    im = Image.new('RGB', (size, size), base)
    d = ImageDraw.Draw(im)
    for i in range(n):
        x, y, r = rnd.uniform(0, size), rnd.uniform(0, size), rnd.uniform(rmin, rmax)
        c = rnd.choice(stones)
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d.ellipse([x + ox - r, y + oy - r * 0.8, x + ox + r, y + oy + r * 0.8], fill=c)
    im.filter(ImageFilter.GaussianBlur(0.5)).save(os.path.join(OUT, name))


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    flag()
    emblem()
    plaque()
    speckle('grava.png', (200, 196, 186), [(244, 242, 236), (232, 228, 220), (214, 208, 198), (250, 249, 246), (190, 184, 174)], 2600, 2.0, 5.0)
    speckle('mantillo.png', (74, 52, 36), [(96, 66, 44), (60, 42, 30), (110, 80, 54), (84, 58, 40), (128, 96, 70)], 2200, 1.5, 4.5)
    print('written to', os.path.abspath(OUT))
