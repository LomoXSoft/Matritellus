"""The tiled name plate over the old school's door, painted after the user's photograph of the real one
(referencias/colegio_viejo/placa_original.webp): white glazed tiles, the name in dark blue capitals with its great
initials in gold, a blue line round it and a blue scroll in each corner.

    python tools/colegio/placa.py [OUT]

OUT: godot/assets/colegio/placa_instituto.png (then: Godot --headless --path godot --import).
The real plate is 2.07 x 0.49 m (measured on that photograph against the 4.84 m of the panel it hangs in).
The name is the school's real one: the user asked for it ("podríamos dejarla y usar su nombre, total, lleva años cerrado").
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 1242, 294                    # 600 pixels to a metre
TILE = (244, 241, 230)
JOINT = (214, 210, 198)
BLUE = (28, 40, 110)
GOLD = (214, 160, 28)


def font(size):
    for name in ('georgiab.ttf', 'timesbd.ttf', 'DejaVuSerif-Bold.ttf'):
        try:
            return ImageFont.truetype(os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts', name), size)
        except Exception:
            pass
    return ImageFont.load_default()


def line(d, y, parts, cap):
    """one line of the name, centred: parts are (text, how tall against the capitals, colour), all on one baseline"""
    fonts = [font(int(cap * k)) for _, k, _ in parts]
    widths = [d.textlength(t, font=f) for (t, _, _), f in zip(parts, fonts)]
    x = (W - sum(widths)) / 2.0
    for (t, k, colour), f, w in zip(parts, fonts, widths):
        d.text((x, y), t, font=f, fill=colour, anchor='ls')
        x += w


def scroll(d, cx, cy, sx, sy, r):
    """a corner's ornament: two curls and a leaf, turned by sx, sy into its corner"""
    for k, (ox, oy, rr) in enumerate(((0.0, 0.0, r), (r * 1.15, r * 0.25, r * 0.62), (r * 0.25, r * 1.15, r * 0.62))):
        pts = []
        for i in range(34):
            a = i / 33.0 * math.pi * 2.6
            q = rr * (1.0 - i / 44.0)
            pts.append((cx + sx * (ox + q * math.cos(a)), cy + sy * (oy + q * math.sin(a))))
        d.line(pts, fill=BLUE, width=5 if k == 0 else 4)
    d.ellipse([cx + sx * r * 1.9 - 5, cy + sy * r * 0.2 - 5, cx + sx * r * 1.9 + 5, cy + sy * r * 0.2 + 5], fill=BLUE)
    d.ellipse([cx + sx * r * 0.2 - 5, cy + sy * r * 1.9 - 5, cx + sx * r * 0.2 + 5, cy + sy * r * 1.9 + 5], fill=BLUE)


if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', 'godot', 'assets', 'colegio', 'placa_instituto.png')
    im = Image.new('RGB', (W, H), TILE)
    d = ImageDraw.Draw(im)
    cols, rows = 13, 3
    for i in range(1, cols):
        d.line([(i * W / cols, 0), (i * W / cols, H)], fill=JOINT, width=2)
    for j in range(1, rows):
        d.line([(0, j * H / rows), (W, j * H / rows)], fill=JOINT, width=2)
    d.rectangle([9, 9, W - 10, H - 10], outline=BLUE, width=5)
    d.rectangle([20, 20, W - 21, H - 21], outline=BLUE, width=2)
    for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        scroll(d, (48 if sx > 0 else W - 48), (48 if sy > 0 else H - 48), sx, sy, 20)
    cap = 86
    line(d, 128, [('I', 1.0, GOLD), ('NSTITUTO', 0.8, BLUE)], cap)
    line(d, 248, [('G', 1.0, GOLD), ('ARCILASO', 0.8, BLUE), (' DE LA ', 0.56, BLUE), ('V', 1.0, GOLD), ('EGA', 0.8, BLUE)], cap)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    im.save(out)
    print(out, im.size)
