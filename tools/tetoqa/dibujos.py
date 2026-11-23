"""The pictures of the accessories shop "Tetoqa" (godot/assets/tetoqa/), drawn here: the game's own signs for the
"Complementos" of the corner of the Calle de Santa Ana and the Calle del Cristo (the real Tutoq; the user, 23 November
2026: "Vamos con la tienda de complementos Tutoq (que llamaremos Tetoqa). Mismo tratamiento que con MiniPrecio pero
esta vez para complementos"). The real board says "Complementos" in pink handwriting between two sprigs of pink
blossom, the shop's name small in a corner; ours is drawn anew: almond blossom (the first of La Mancha's springs), our
own name. No telephone, no address, no social network.

    python tools/tetoqa/dibujos.py

rotulo.png    the board over the Santa Ana's first window (2.4 x 0.56 m): white with a thin frame, "Complementos" in
              pink handwriting with a flourish under it, sprigs of almond blossom at its ends, "Tetoqa" small at its
              bottom right
horario.png   the card of its hours on the glass by the door (made up: Google Maps gives the real shop none, 23 Nov
              2026): Monday to Friday 10:00-13:30 and 17:30-20:30, Saturday 10:00-14:00, Sunday shut
caja.png      the light box on the Cristo by the chamfer (2.5 : 1; Street View 2024 shows the real one's name in thin
              grey capitals between pink sprigs, in a green frame: the frame is the box's own, in tetoqa.gd)
mural.png     the inside's back wall: "Tetoqa" big in pink handwriting, "complementos" under it, a sprig of blossom
              (see-through round it)
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'tetoqa')
os.makedirs(OUT, exist_ok=True)
WHITE = (250, 249, 247)
PINK = (222, 74, 128)            # the handwriting (Street View 2024: a strong pink on the white board)
PINK_DARK = (170, 40, 92)
PETAL = (246, 186, 206)          # the almond blossom: pale pink petals...
PETAL_DEEP = (232, 128, 166)     # ...deeper at their hearts
HEART = (160, 34, 70)
TWIG = (96, 62, 44)
FRAME = (58, 52, 56)
INK = (40, 34, 40)


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


SCRIPT = ['segoescb.ttf', 'segoesc.ttf', 'Gabriola.ttf', 'ariali.ttf']
SCRIPT_THIN = ['segoesc.ttf', 'Gabriola.ttf', 'ariali.ttf']
BOLD = ['arialbd.ttf', 'DejaVuSans-Bold.ttf']


def blossom(d, c, r, rng, turn=None):
    """one almond flower at c, r its radius: five round petals, pale with a deeper heart, dark stamens"""
    a0 = rng.uniform(0, math.tau) if turn is None else turn
    for k in range(5):
        a = a0 + k * math.tau / 5
        px, py = c[0] + math.cos(a) * r * 0.55, c[1] + math.sin(a) * r * 0.55
        pr = r * 0.52
        d.ellipse([px - pr, py - pr, px + pr, py + pr], fill=PETAL)
    d.ellipse([c[0] - r * 0.42, c[1] - r * 0.42, c[0] + r * 0.42, c[1] + r * 0.42], fill=PETAL_DEEP)
    for k in range(7):
        a = a0 + k * math.tau / 7 + 0.3
        q = (c[0] + math.cos(a) * r * 0.34, c[1] + math.sin(a) * r * 0.34)
        d.line([c, q], fill=HEART, width=max(1, int(r * 0.07)))
        d.ellipse([q[0] - r * 0.06, q[1] - r * 0.06, q[0] + r * 0.06, q[1] + r * 0.06], fill=HEART)


def bud(d, c, r):
    d.ellipse([c[0] - r * 0.5, c[1] - r * 0.7, c[0] + r * 0.5, c[1] + r * 0.7], fill=PETAL_DEEP)


def sprig(img, base, tip, size, seed, flowers=5):
    """a twig of almond from base to tip, a little bent, with flowers and buds along it"""
    rng = random.Random(seed)
    d = ImageDraw.Draw(img)
    pts = []
    for k in range(21):
        t = k / 20
        bend = math.sin(math.pi * t) * size * 0.35
        nx, ny = -(tip[1] - base[1]), tip[0] - base[0]
        ln = math.hypot(nx, ny)
        pts.append((base[0] + (tip[0] - base[0]) * t + nx / ln * bend, base[1] + (tip[1] - base[1]) * t + ny / ln * bend))
    d.line(pts, fill=TWIG, width=max(2, int(size * 0.09)), joint='curve')
    for k in (6, 12):                                   # two small side twigs
        p = pts[k]
        q = (p[0] + (tip[0] - base[0]) * 0.18 + rng.uniform(-1, 1) * size * 0.4, p[1] + (tip[1] - base[1]) * 0.18 - size * 0.5)
        d.line([p, q], fill=TWIG, width=max(2, int(size * 0.06)))
        bud(d, q, size * 0.22)
    for k in range(flowers):
        p = pts[min(20, 3 + k * 17 // max(1, flowers - 1))]
        off = (rng.uniform(-1, 1) * size * 0.25, rng.uniform(-1, 1) * size * 0.25)
        blossom(d, (p[0] + off[0], p[1] + off[1]), size * rng.uniform(0.42, 0.6), rng)
    bud(d, tip, size * 0.25)


def rotulo():
    w, h = 1200, 280
    s = 2
    W, H = w * s, h * s
    img = Image.new('RGB', (W, H), WHITE)
    d = ImageDraw.Draw(img)
    for k in range(40):                                 # a faint pink wash towards its ends
        a = k / 40
        col = tuple(int(WHITE[i] + (PETAL[i] - WHITE[i]) * 0.22 * (1 - a)) for i in range(3))
        d.rectangle([int(W * 0.5 * a * 0.5), 0, int(W * 0.5 * a * 0.5) + W // 160, H], fill=col)
        d.rectangle([W - int(W * 0.5 * a * 0.5) - W // 160, 0, W - int(W * 0.5 * a * 0.5), H], fill=col)
    sprig(img, (W * 0.02, H * 0.2), (W * 0.15, H * 0.12), H * 0.16, 3, 4)
    sprig(img, (W * 0.99, H * 0.12), (W * 0.82, H * 0.2), H * 0.16, 5, 4)
    sprig(img, (W * 0.995, H * 0.86), (W * 0.86, H * 0.8), H * 0.12, 9, 3)
    f = font(SCRIPT, int(H * 0.46))
    t = 'Complementos'
    tw = d.textlength(t, font=f)
    x0 = (W - tw) / 2 - W * 0.02
    y0 = H * 0.12
    d.text((x0 + 4, y0 + 5), t, font=f, fill=(240, 200, 214))       # (a soft shadow)
    d.text((x0, y0), t, font=f, fill=PINK)
    fl = []                                              # the flourish under the word
    for k in range(61):
        t_ = k / 60
        fl.append((x0 + tw * (0.08 + 0.84 * t_), H * 0.8 + math.sin(t_ * math.pi * 2.0) * H * 0.035 - t_ * H * 0.03))
    d.line(fl, fill=PINK, width=int(H * 0.018), joint='curve')
    fs = font(SCRIPT_THIN, int(H * 0.16))
    n = 'Tetoqa'
    d.text((W * 0.83 - d.textlength(n, font=fs), H * 0.74), n, font=fs, fill=PINK_DARK)
    img = img.resize((w, h), Image.LANCZOS)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w - 1, h - 1], outline=FRAME, width=6)
    d.rectangle([7, 7, w - 8, h - 8], outline=(214, 206, 208), width=2)
    img.save(os.path.join(OUT, 'rotulo.png'))


def horario():
    w, h = 300, 400
    img = Image.new('RGB', (w, h), WHITE)
    d = ImageDraw.Draw(img)
    d.rectangle([6, 6, w - 7, h - 7], outline=PINK, width=4)
    sprig(img, (w * 0.08, h * 0.14), (w * 0.34, h * 0.07), 26, 11, 3)
    sprig(img, (w * 0.92, h * 0.14), (w * 0.66, h * 0.07), 26, 13, 3)
    fn = font(SCRIPT, 40)
    t = 'Tetoqa'
    d.text(((w - d.textlength(t, font=fn)) / 2, 52), t, font=fn, fill=PINK)
    fb = font(BOLD, 26)
    fs = font(BOLD, 22)
    t = 'HORARIO'
    d.text(((w - d.textlength(t, font=fb)) / 2, 122), t, font=fb, fill=PINK_DARK)
    rows = ['Lunes a viernes', '10:00 - 13:30', '17:30 - 20:30', 'Sábado', '10:00 - 14:00', 'Domingo cerrado']
    y = 166
    for i, a in enumerate(rows):
        colour = INK if a[0].isdigit() else PINK_DARK
        d.text(((w - d.textlength(a, font=fs)) / 2, y), a, font=fs, fill=colour)
        y += 32 if i not in (2, 4) else 42
    img.save(os.path.join(OUT, 'horario.png'))


def caja():
    w, h = 1000, 400
    s = 2
    W, H = w * s, h * s
    img = Image.new('RGB', (W, H), WHITE)
    sprig(img, (W * 0.01, H * 0.92), (W * 0.14, H * 0.74), H * 0.11, 21, 4)
    sprig(img, (W * 0.99, H * 0.08), (W * 0.86, H * 0.26), H * 0.11, 23, 4)
    d = ImageDraw.Draw(img)
    f = font(['segoeuil.ttf', 'segoeui.ttf', 'arial.ttf'], int(H * 0.36))
    t = 'TETOQA'
    sp = H * 0.05
    tw = sum(d.textlength(c, font=f) for c in t) + sp * (len(t) - 1)
    x = (W - tw) / 2
    for c in t:                                        # (spaced out, as the real one's)
        d.text((x, H * 0.27), c, font=f, fill=(120, 116, 118))
        x += d.textlength(c, font=f) + sp
    img = img.resize((w, h), Image.LANCZOS)
    img.save(os.path.join(OUT, 'caja.png'))


def mural():
    w, h = 1024, 512
    s = 2
    W, H = w * s, h * s
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    f = font(SCRIPT, int(H * 0.42))
    t = 'Tetoqa'
    tw = d.textlength(t, font=f)
    d.text(((W - tw) / 2, H * 0.08), t, font=f, fill=PINK + (255,))
    fs = font(SCRIPT_THIN, int(H * 0.13))
    t2 = 'complementos'
    d.text(((W - d.textlength(t2, font=fs)) / 2, H * 0.66), t2, font=fs, fill=PINK_DARK + (255,))
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sprig(layer, (W * 0.02, H * 0.9), (W * 0.2, H * 0.62), H * 0.09, 17, 5)
    sprig(layer, (W * 0.995, H * 0.06), (W * 0.86, H * 0.2), H * 0.09, 19, 4)
    img.alpha_composite(layer)
    img = img.resize((w, h), Image.LANCZOS)
    img.save(os.path.join(OUT, 'mural.png'))


if __name__ == '__main__':
    rotulo()
    horario()
    caja()
    mural()
    print('ok', os.path.abspath(OUT))
