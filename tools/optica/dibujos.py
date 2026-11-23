"""The pictures of the optician "Óptica Corsa" (godot/assets/optica/), drawn here: the game's own signs for the shop of
the Calle del Salvador (the real Centro Óptico Corts; the user, 23 November 2026: "Vamos con el centro óptico cors (que
llamaremos Óptica Corsa, en C. Salvador, 5 ... aquí el NPC será una Óptica con bata blanca y solo venderá gafas ...
Se llamará Fátima Corsa"). The real board is a long teal green one with the name in white capitals; ours is drawn
anew with our own name and a pair of glasses at each end. No telephone, no address, no social network.

    python tools/optica/dibujos.py

rotulo.png     the long board over the ground floor (5.36 x 0.51 m): teal green, "ÓPTICA CORSA" in white capitals, a
               pair of glasses drawn in white at each end
horario.png    the card of its hours on the glass of the door (the real hours, Google Maps, 23 Nov 2026): Monday to
               Friday 10:00-14:00 and 18:00-21:00, Saturday 10:00-14:00, Sunday shut
placa.png      the little maroon plate on the brick pier by the flats' door: "Óptica", Fátima Corsa, what she is
carteles.png   the three posters stuck on the top of the shop window: the eye test, sunglasses, vintage frames (three
               side by side, 3 : 1)
optotipo.png   the eye chart of the room inside where the eyes are tested: rows of black capitals, smaller and smaller
               (our own rows; the last, the smallest, says the town's name)
mural.png      the inside's back wall: "Óptica Corsa" big in green with a pair of glasses over it (see-through round it)
fondo.png      the backdrop of the shop's window: pale orange hexagons, a pair of glasses drawn in some of them
novedades.png  the little sign over the wall of new frames
vintage.png    the little sign over the wall of old ones (the user: "tengo modelos nuevos y vintage")
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'optica')
os.makedirs(OUT, exist_ok=True)
GREEN = (8, 112, 96)             # the board's teal green (Street View 2013: about 0, 65, 62 in the street's shade)
GREEN_DARK = (4, 72, 62)
WHITE = (246, 248, 246)
INK = (30, 32, 34)
MAROON = (112, 30, 36)           # the plate by the flats' door (Street View 2013)
GOLD = (222, 196, 132)
BROWN = (58, 38, 28)


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


BOLD = ['segoeuib.ttf', 'arialbd.ttf', 'DejaVuSans-Bold.ttf']
PLAIN = ['segoeui.ttf', 'arial.ttf', 'DejaVuSans.ttf']
SERIF = ['georgiab.ttf', 'georgia.ttf', 'DejaVuSerif-Bold.ttf']
SCRIPT = ['segoescb.ttf', 'segoesc.ttf', 'ariali.ttf']
CHART = ['arial.ttf', 'DejaVuSans.ttf']


def gafas(d, c, w, colour, width, dark=None, round_=True):
    """a pair of glasses at c, w wide: two lenses (round or a little square), the bridge, the arms' first stretch"""
    r = w * 0.2
    for s in (-1, 1):
        x = c[0] + s * w * 0.25
        box = [x - r, c[1] - r * (1.0 if round_ else 0.8), x + r, c[1] + r * (1.0 if round_ else 0.8)]
        if dark is not None:
            if round_:
                d.ellipse(box, fill=dark)
            else:
                d.rounded_rectangle(box, radius=r * 0.35, fill=dark)
        if round_:
            d.ellipse(box, outline=colour, width=width)
        else:
            d.rounded_rectangle(box, radius=r * 0.35, outline=colour, width=width)
        d.line([(x + s * r, c[1] - r * 0.3), (x + s * (r + w * 0.07), c[1] - r * 0.45)], fill=colour, width=width)
    d.arc([c[0] - w * 0.06, c[1] - r * 0.55, c[0] + w * 0.06, c[1] - r * 0.05], 180, 360, fill=colour, width=width)


def centred(d, y, text, f, fill, w):
    d.text(((w - d.textlength(text, font=f)) / 2, y), text, font=f, fill=fill)


def rotulo():
    w, h = 2048, 194
    s = 2
    W, H = w * s, h * s
    img = Image.new('RGB', (W, H), GREEN)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W - 1, int(H * 0.035)], fill=(200, 214, 208))          # (its pale edges, top and bottom)
    d.rectangle([0, H - int(H * 0.035), W - 1, H - 1], fill=(200, 214, 208))
    f = font(BOLD, int(H * 0.66))
    t = 'ÓPTICA CORSA'
    sp = H * 0.03
    tw = sum(d.textlength(c, font=f) for c in t) + sp * (len(t) - 1)
    x = (W - tw) / 2
    for c in t:
        d.text((x, H * 0.08), c, font=f, fill=WHITE)
        x += d.textlength(c, font=f) + sp
    for cx in (W * 0.065, W * 0.935):
        gafas(d, (cx, H * 0.52), H * 1.25, WHITE, int(H * 0.06))
    img = img.resize((w, h), Image.LANCZOS)
    img.save(os.path.join(OUT, 'rotulo.png'))


def horario():
    w, h = 300, 400
    img = Image.new('RGB', (w, h), WHITE)
    d = ImageDraw.Draw(img)
    d.rectangle([6, 6, w - 7, h - 7], outline=GREEN, width=5)
    gafas(d, (w / 2, 46), 110, GREEN, 5)
    fn = font(BOLD, 30)
    centred(d, 78, 'Óptica Corsa', fn, GREEN, w)
    fb = font(BOLD, 24)
    fs = font(BOLD, 22)
    centred(d, 128, 'HORARIO', fb, GREEN_DARK, w)
    rows = ['Lunes a viernes', '10:00 - 14:00', '18:00 - 21:00', 'Sábado', '10:00 - 14:00', 'Domingo cerrado']
    y = 170
    for i, a in enumerate(rows):
        colour = INK if a[0].isdigit() else GREEN_DARK
        centred(d, y, a, fs, colour, w)
        y += 32 if i not in (2, 4) else 42
    img.save(os.path.join(OUT, 'horario.png'))


def placa():
    w, h = 400, 280
    img = Image.new('RGB', (w, h), MAROON)
    d = ImageDraw.Draw(img)
    d.rectangle([8, 8, w - 9, h - 9], outline=GOLD, width=3)
    f = font(SCRIPT, 74)
    centred(d, 24, 'Óptica', f, WHITE, w)
    fb = font(BOLD, 34)
    centred(d, 138, 'Fátima Corsa', fb, GOLD, w)
    fs = font(PLAIN, 26)
    centred(d, 186, 'óptica-optometrista', fs, WHITE, w)
    centred(d, 222, 'gafas graduadas y de sol', font(PLAIN, 22), (230, 210, 200), w)
    img.save(os.path.join(OUT, 'placa.png'))


def carteles():
    pw, h = 360, 360
    img = Image.new('RGB', (pw * 3, h), WHITE)
    d = ImageDraw.Draw(img)
    for k in range(3):
        x0 = k * pw
        d.rectangle([x0 + 4, 4, x0 + pw - 5, h - 5], outline=(200, 204, 200), width=3)
        d.rectangle([x0 + 4, 4, x0 + pw - 5, 74], fill=GREEN)
    fb = font(BOLD, 34)
    fm = font(BOLD, 28)
    fs = font(PLAIN, 24)
    # 1: the eye test
    t = 'REVISIÓN'
    d.text((pw / 2 - d.textlength(t, font=fb) / 2, 16), t, font=fb, fill=WHITE)
    cx, cy = pw / 2, 170
    d.ellipse([cx - 92, cy - 46, cx + 92, cy + 46], outline=INK, width=6)                # an eye
    d.ellipse([cx - 40, cy - 40, cx + 40, cy + 40], fill=GREEN)
    d.ellipse([cx - 18, cy - 18, cx + 18, cy + 18], fill=INK)
    d.ellipse([cx + 4, cy - 16, cx + 14, cy - 6], fill=WHITE)
    for t, y in (('DE LA VISTA', 236), ('¡Gradúate!', 284)):
        f = fm if y == 236 else font(SCRIPT, 36)
        d.text((pw / 2 - d.textlength(t, font=f) / 2, y), t, font=f, fill=GREEN_DARK if y == 236 else INK)
    # 2: sunglasses
    x0 = pw
    t = 'GAFAS DE SOL'
    d.text((x0 + pw / 2 - d.textlength(t, font=fm) / 2, 20), t, font=fm, fill=WHITE)
    gafas(d, (x0 + pw / 2, 178), 300, INK, 9, dark=(40, 44, 52), round_=False)
    t = 'Novedades'
    d.text((x0 + pw / 2 - d.textlength(t, font=font(SCRIPT, 40)) / 2, 268), t, font=font(SCRIPT, 40), fill=GREEN_DARK)
    # 3: vintage frames
    x0 = 2 * pw
    t = 'VINTAGE'
    d.text((x0 + pw / 2 - d.textlength(t, font=fb) / 2, 16), t, font=fb, fill=WHITE)
    gafas(d, (x0 + pw / 2, 172), 290, (120, 70, 36), 12)
    t = 'Monturas de siempre'
    d.text((x0 + pw / 2 - d.textlength(t, font=fs) / 2, 262), t, font=fs, fill=INK)
    t = 'como nuevas'
    d.text((x0 + pw / 2 - d.textlength(t, font=fs) / 2, 296), t, font=fs, fill=INK)
    img.save(os.path.join(OUT, 'carteles.png'))


def optotipo():
    w, h = 512, 768
    img = Image.new('RGB', (w, h), WHITE)
    d = ImageDraw.Draw(img)
    d.rectangle([4, 4, w - 5, h - 5], outline=(190, 190, 186), width=4)
    rows = ['E', 'F P', 'T O Z', 'L P E D', 'P E C F D', 'E D F C Z P', 'F E L O P Z D', 'D E F P O T E C', 'MADRIDEJOS']
    sizes = [150, 96, 72, 58, 46, 38, 31, 25, 19]
    y = 24
    for t, sz in zip(rows, sizes):
        f = font(CHART, sz)
        sp = sz * 0.35
        tw = sum(d.textlength(c, font=f) for c in t if c != ' ') + sp * (len(t.replace(' ', '')) - 1)
        x = (w - tw) / 2
        for c in t:
            if c == ' ':
                continue
            d.text((x, y), c, font=f, fill=(12, 12, 12))
            x += d.textlength(c, font=f) + sp
        y += sz * 1.32
        if t != rows[-1]:
            d.line([(w * 0.88, y - sz * 0.32), (w * 0.95, y - sz * 0.32)], fill=(200, 40, 40), width=2)    # (the little red marks at the side)
    img.save(os.path.join(OUT, 'optotipo.png'))


def mural():
    w, h = 1024, 512
    s = 2
    W, H = w * s, h * s
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    gafas(d, (W / 2, H * 0.24), H * 0.62, GREEN + (255,), int(H * 0.035))
    f = font(BOLD, int(H * 0.3))
    t = 'Óptica Corsa'
    d.text(((W - d.textlength(t, font=f)) / 2, H * 0.44), t, font=f, fill=GREEN + (255,))
    img = img.resize((w, h), Image.LANCZOS)
    img.save(os.path.join(OUT, 'mural.png'))


def fondo():
    """the backdrop of the shop's window: pale orange hexagons, a pair of glasses drawn in some of them (Street View
    2013 shows orange hexagons with glasses on them behind the real one's)"""
    w, h = 512, 512
    img = Image.new('RGB', (w, h), (236, 214, 184))
    d = ImageDraw.Draw(img)
    r = 46
    dx = r * math.sqrt(3)
    k = 0
    for row in range(-1, int(h / (r * 1.5)) + 2):
        for col in range(-1, int(w / dx) + 2):
            cx = col * dx + (dx / 2 if row % 2 else 0)
            cy = row * r * 1.5
            pts = [(cx + r * math.cos(math.radians(60 * i + 30)), cy + r * math.sin(math.radians(60 * i + 30))) for i in range(6)]
            shade = [(232, 160, 96), (244, 196, 140), (226, 140, 80), (248, 226, 196)][(row * 3 + col * 2) % 4]
            d.polygon(pts, fill=shade, outline=(250, 246, 238))
            d.line(pts + [pts[0]], fill=(250, 246, 238), width=4)
            k += 1
            if (row + col * 2) % 3 == 0:
                gafas(d, (cx, cy + 4), r * 1.35, (70, 46, 34), 3, round_=(row + col) % 2 == 0)
    img.save(os.path.join(OUT, 'fondo.png'))


def novedades():
    w, h = 512, 128
    img = Image.new('RGB', (w, h), WHITE)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w - 1, h - 1], outline=GREEN, width=6)
    f = font(BOLD, 64)
    centred(d, 18, 'NOVEDADES', f, GREEN, w)
    img.save(os.path.join(OUT, 'novedades.png'))


def vintage():
    w, h = 512, 128
    img = Image.new('RGB', (w, h), BROWN)
    d = ImageDraw.Draw(img)
    d.rectangle([6, 6, w - 7, h - 7], outline=GOLD, width=3)
    f = font(SCRIPT, 70)
    centred(d, 10, 'Vintage', f, GOLD, w)
    img.save(os.path.join(OUT, 'vintage.png'))


if __name__ == '__main__':
    rotulo()
    horario()
    placa()
    carteles()
    optotipo()
    mural()
    fondo()
    novedades()
    vintage()
    print('ok', os.path.abspath(OUT))
