"""The pictures of the two signs at the town's north entrance, by the old Madrid-Cádiz road (godot/assets/entrada/),
drawn here (the user, 23 November 2026: "Hay dos carteles en la entrada de Madridejos que me gustaría añadir", with
three Street View captures of November 2024). They say MADRIDEJOS, as the real ones (the town keeps its name; Matritellus
is the game's title, its old Latin name). The crests are ours:
the town's own (assets/logo.png, with its ribbon: MATRITELLUS, the town's old name, may be there -- the user, 24 Nov 2026) and a shield drawn here for the twin town.

    python tools/entrada/dibujos.py

lugar.png      the long glazed tile on the whitewashed wall, over Don Quixote: "Un lugar de la Mancha" in a slanting
               hand, black on white in a thin black frame (1.96 x 0.26 m)
nombre.png     the tile under it: the town's name in serif capitals, MADRIDEJOS (1.40 x 0.26 m)
hermanado.png  the sign on two posts beside the road (1.20 x 0.87 m): white gone yellow, a red border; the town's crest
               and MADRIDEJOS, "HERMANADO CON LA VILLA DE", a blue shield and NÉRAC (FRANCE); dirty, as it is
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
OUT = os.path.join(ROOT, 'godot', 'assets', 'entrada')
os.makedirs(OUT, exist_ok=True)
FONTS = os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts')
INK = (28, 26, 26)
RED = (196, 40, 46)
CREAM = (236, 229, 206)


def font(names, size, var=None):
    for n in names:
        try:
            f = ImageFont.truetype(os.path.join(FONTS, n), size)
            if var:
                try:
                    f.set_variation_by_name(var)
                except Exception:
                    pass
            return f
        except Exception:
            pass
    return ImageFont.load_default()


def tile(w, h, words, fnt, path, frame=7):
    """a glazed white tile in a thin black frame, its words in the middle"""
    im = Image.new('RGB', (w, h), (244, 243, 238))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=INK, width=frame)
    d.rectangle([frame + 5, frame + 5, w - frame - 6, h - frame - 6], outline=(196, 194, 188), width=2)
    d.text((w / 2, h / 2 + 2), words, font=fnt, fill=INK, anchor='mm')
    rnd = random.Random(len(words))
    px = im.load()
    for _ in range(w * h // 40):                # (glaze, a little grime)
        x, y = rnd.randrange(w), rnd.randrange(h)
        c = px[x, y]
        k = rnd.randint(-10, 4)
        px[x, y] = (max(0, c[0] + k), max(0, c[1] + k), max(0, c[2] + k))
    im.save(os.path.join(OUT, path))


tile(1470, 196, 'Un lugar de la Mancha', font(['palai.ttf', 'Gabriola.ttf', 'georgiai.ttf'], 132), 'lugar.png')
tile(1050, 196, 'MADRIDEJOS', font(['pala.ttf', 'times.ttf', 'georgia.ttf'], 128), 'nombre.png')


def town_crest(h):
    """the town's crest (the game's own, assets/logo.png, with its ribbon), h pixels high"""
    logo = Image.open(os.path.join(ROOT, 'godot', 'assets', 'logo.png')).convert('RGBA')
    shield = logo.crop(logo.getbbox())
    return shield.resize((round(h * shield.width / shield.height), h), Image.LANCZOS)


def twin_crest(h):
    """the twin town's shield, ours: blue in a gold rim, a gold castle of three towers over a white wavy river"""
    S = 4
    W, H = 300 * S, 360 * S
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    def outline(inset):
        pts = [(inset, inset), (W - inset, inset), (W - inset, H * 0.55)]
        for i in range(1, 30):
            t = i / 30
            a = math.pi * 0.5 * t
            pts.append((W / 2 + (W / 2 - inset) * math.cos(a), H * 0.55 + (H * 0.45 - inset) * math.sin(a)))
        pts += [(W / 2, H - inset)]
        for i in range(29, 0, -1):
            t = i / 30
            a = math.pi * 0.5 * t
            pts.append((W / 2 - (W / 2 - inset) * math.cos(a), H * 0.55 + (H * 0.45 - inset) * math.sin(a)))
        pts += [(inset, H * 0.55)]
        return pts

    d.polygon(outline(0), fill=(40, 34, 30))
    d.polygon(outline(7 * S), fill=(226, 178, 52))
    d.polygon(outline(18 * S), fill=(36, 84, 168))
    gold = (238, 196, 64)
    base = 230 * S
    for cx, tw, th in ((150, 60, 120), (82, 44, 84), (218, 44, 84)):         # the castle: a keep and two towers
        x0, x1 = (cx - tw / 2) * S, (cx + tw / 2) * S
        d.rectangle([x0, base - th * S, x1, base], fill=gold)
        n = 3
        for k in range(n):
            mx0 = x0 + (x1 - x0) * (2 * k) / (2 * n - 1)
            d.rectangle([mx0, base - th * S - 14 * S, mx0 + (x1 - x0) / (2 * n - 1), base - th * S], fill=gold)
    d.rectangle([60 * S, base - 50 * S, 240 * S, base], fill=gold)            # the curtain wall between them
    d.pieslice([132 * S, base - 46 * S, 168 * S, base + 6 * S], 180, 360, fill=(36, 84, 168))   # its gate
    d.rectangle([132 * S, base - 20 * S, 168 * S, base], fill=(36, 84, 168))
    for wy in (258, 286):                                                     # the river under it
        pts = [(x * S, (wy + 8 * math.sin(x / 18.0)) * S) for x in range(40, 262, 4)]
        d.line(pts, fill=(240, 240, 236), width=9 * S)
    im = im.resize((round(h * W / H), h), Image.LANCZOS)
    return im


def sign():
    """the twinning sign, 1.20 x 0.87 m at 1000 pixels a metre"""
    w, h = 1200, 870
    im = Image.new('RGB', (w, h), CREAM)
    d = ImageDraw.Draw(im)
    r = 34
    d.rounded_rectangle([14, 14, w - 15, h - 15], radius=r, outline=RED, width=22)
    big = font(['bahnschrift.ttf', 'arialbd.ttf'], 108, 'Bold')
    mid = font(['bahnschrift.ttf', 'arialbd.ttf'], 50, 'SemiBold')
    small = font(['bahnschrift.ttf', 'arialbd.ttf'], 74, 'SemiBold')
    # laid out square (the user, 24 Nov 2026: "está un poco descentrada, cuadrala un poco"): two columns, the crests
    # and the words, the pair centred across the sign; the two rows and the line between them spaced evenly from the
    # red border at the top to the one at the bottom; each word set by its own ink, not by the font's box
    def ink(t, f):
        return d.textbbox((0, 0), t, font=f, anchor='ls')

    def put(t, f, x, y):                       # the ink of t centred on (x, y)
        l, tp, rt, b = ink(t, f)
        d.text((x - (l + rt) / 2, y - (tp + b) / 2), t, font=f, fill=INK, anchor='ls')

    c1 = town_crest(190)
    c2 = twin_crest(196)
    gap = 56
    words_w = max(ink(t, f)[2] - ink(t, f)[0] for t, f in (('MADRIDEJOS', big), ('NÉRAC', big), ('(FRANCE)', small)))
    crest_w = max(c1.width, c2.width)
    x0 = (w - (crest_w + gap + words_w)) / 2
    cx = x0 + crest_w / 2                      # the crests' column (their middles)
    tx = x0 + crest_w + gap + words_w / 2      # the words' column (their middles)
    top, bottom = 36, h - 36                   # inside the red border
    l, tp, rt, b = ink('HERMANADO CON LA VILLA DE', mid)
    line_h = b - tp
    space = (bottom - top - c1.height - line_h - c2.height) / 4
    y1 = top + space + c1.height / 2           # the middle of the top row
    ym = top + 2 * space + c1.height + line_h / 2
    y2 = bottom - space - c2.height / 2        # the middle of the bottom row
    im.paste(c1, (round(cx - c1.width / 2), round(y1 - c1.height / 2)), c1)
    put('MADRIDEJOS', big, tx, y1)
    put('HERMANADO CON LA VILLA DE', mid, w / 2, ym)
    im.paste(c2, (round(cx - c2.width / 2), round(y2 - c2.height / 2)), c2)
    a_h = ink('NÉRAC', big)[3] - ink('NÉRAC', big)[1]
    f_h = ink('(FRANCE)', small)[3] - ink('(FRANCE)', small)[1]
    lead = 30
    block = a_h + lead + f_h                   # the two lines together, centred on the crest beside them
    put('NÉRAC', big, tx, y2 - block / 2 + a_h / 2)
    put('(FRANCE)', small, tx, y2 + block / 2 - f_h / 2)
    # years of sun and road dust: the white gone yellow, grime run down from the top, a stain low on the right
    rnd = random.Random(7)
    dirt = Image.new('L', (w, h), 0)
    dd = ImageDraw.Draw(dirt)
    for _ in range(90):
        x = rnd.randrange(w)
        y0 = rnd.randrange(30, 140)
        dd.line([(x, y0), (x + rnd.randint(-6, 6), y0 + rnd.randint(80, 420))], fill=rnd.randint(14, 34), width=rnd.randint(3, 12))
    dd.ellipse([w - 330, h - 300, w - 40, h - 60], fill=40)
    dd.ellipse([60, h - 170, 360, h - 40], fill=22)
    dirt = dirt.filter(ImageFilter.GaussianBlur(14))
    brown = Image.new('RGB', (w, h), (150, 128, 86))
    im = Image.composite(brown, im, dirt)
    px = im.load()
    for _ in range(w * h // 30):
        x, y = rnd.randrange(w), rnd.randrange(h)
        c = px[x, y]
        k = rnd.randint(-12, 6)
        px[x, y] = (max(0, c[0] + k), max(0, c[1] + k), max(0, c[2] + k))
    im.save(os.path.join(OUT, 'hermanado.png'))


sign()
print('ok', sorted(os.listdir(OUT)))
