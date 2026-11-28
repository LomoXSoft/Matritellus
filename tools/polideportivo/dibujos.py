"""The pictures of the Polideportivo Municipal (godot/assets/polideportivo/), drawn here. The town's sports hall (the
user, 28 November 2026: "Ese es el polideportivo. Se lo pasamos a pretil", then, with photographs of its inside:
"Quiero que se pueda acceder"). No real mark on any of them: the adverts on its wall are the game's own shops, with
no telephone, address or web; where the real hall has the five rings over its plate, an emblem of our own.

    python tools/polideportivo/dibujos.py [where]      (where: another folder to draw into, to look at them first)

emblema.png   outside, over the plate on the middle piers: a ball in a wreath, black on nothing (0.6 x 0.4 m)
pista.png     inside, the floor from the stand's foot to the west wall (44 x 22 m at 50 px/m): the blue court of 40 x 20
              with its handball lines in white, the basketball ones in dark blue and the volleyball ones in yellow, and
              the orange border round it
anuncios.png  inside, the two clusters of advert boards on the west wall, side by side (each 6 x 3 m: six boards)
marcador.png  inside, the scoreboard between them (1.6 x 1.2 m)
After adding or changing them: Godot --headless --path godot --import.
"""
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', 'godot', 'assets', 'polideportivo')
os.makedirs(OUT, exist_ok=True)


def font(size, names=('arialbd.ttf', 'DejaVuSans-Bold.ttf')):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except OSError:
            pass
    return ImageFont.load_default()


def emblema():
    s = 4
    w, h = 600 * s, 400 * s
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ink = (26, 26, 28, 255)
    cx, cy, r = w // 2, int(h * 0.47), int(h * 0.27)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=ink, width=14 * s)
    for k in (-1, 1):                                   # the ball's seams
        d.arc([cx + k * r * 0.45 - r, cy - r, cx + k * r * 0.45 + r, cy + r], 120 if k > 0 else -60, 240 if k > 0 else 60, fill=ink, width=10 * s)
    d.line([cx - r, cy, cx + r, cy], fill=ink, width=10 * s)
    for side in (-1, 1):                                # the wreath: leaves along an arc either side
        for i in range(9):
            a = math.radians(238 - i * 13) if side < 0 else math.radians(-58 + i * 13)
            R = r * 1.55
            px, py = cx + R * math.cos(a), cy - R * math.sin(a)
            leaf = Image.new('RGBA', (int(r * 0.58), int(r * 0.22)), (0, 0, 0, 0))
            ImageDraw.Draw(leaf).ellipse([0, 0, leaf.width - 1, leaf.height - 1], fill=ink)
            turn = math.degrees(a) + (65 if side > 0 else -65)
            leaf = leaf.rotate(turn, expand=True, resample=Image.BICUBIC)
            im.alpha_composite(leaf, (int(px - leaf.width / 2), int(py - leaf.height / 2)))
    d.rectangle([cx - r * 0.5, cy + r * 1.42, cx + r * 0.5, cy + r * 1.5], fill=ink)      # the knot under it
    im.resize((600, 400), Image.LANCZOS).save(os.path.join(OUT, 'emblema.png'))


def arc_pts(cx, cy, r, a0, a1, n=64):
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)), cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def pista():
    k = 50                                              # pixels to the metre
    W, H = 44 * k, 22 * k
    im = Image.new('RGB', (W, H), (219, 102, 33))       # the orange border
    d = ImageDraw.Draw(im)
    x0, y0, x1, y1 = 2 * k, 1 * k, 42 * k, 21 * k       # the court of 40 x 20
    blue = (52, 122, 190)
    d.rectangle([x0, y0, x1, y1], fill=blue)
    for i in range(0, 40):                              # the sheets of the floor, a shade apart
        if i % 2:
            d.rectangle([x0 + i * k, y0, x0 + (i + 1) * k, y1], fill=(49, 118, 186))
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    white, dark, yellow = (244, 244, 238), (22, 34, 78), (236, 200, 44)

    def line(pts, col, w, dash=0):
        if not dash:
            d.line(pts, fill=col, width=w, joint='curve')
            return
        run, on = 0.0, True
        for a, b in zip(pts, pts[1:]):
            seg = math.hypot(b[0] - a[0], b[1] - a[1])
            if on:
                d.line([a, b], fill=col, width=w)
            run += seg
            if run >= dash:
                run, on = 0.0, not on

    # volleyball, yellow, under the others: 18 x 9 with its middle line and the attack lines
    vx, vy = 9 * k, 4.5 * k
    d.rectangle([cx - vx, cy - vy, cx + vx, cy + vy], outline=yellow, width=3)
    for dx in (-3 * k, 0, 3 * k):
        d.line([cx + dx, cy - vy, cx + dx, cy + vy], fill=yellow, width=3)
    # basketball, dark blue: 28 x 15, its circle, the keys and the three-point lines
    bx, by = 14 * k, 7.5 * k
    d.rectangle([cx - bx, cy - by, cx + bx, cy + by], outline=dark, width=3)
    d.line([cx, cy - by, cx, cy + by], fill=dark, width=3)
    line(arc_pts(cx, cy, 1.8 * k, 0, 360), dark, 3)
    for s in (-1, 1):
        base = cx + s * bx
        ft = base - s * 5.8 * k
        d.rectangle([min(base, ft), cy - 2.45 * k, max(base, ft), cy + 2.45 * k], outline=dark, width=3)
        line(arc_pts(ft, cy, 1.8 * k, 0, 360), dark, 3)
        hoop = base - s * 1.575 * k
        ang = math.degrees(math.acos((by - 0.9 * k) / (6.75 * k)))
        a0 = (90 - ang) if s < 0 else (90 + ang)
        a1 = (-90 + ang) if s < 0 else (270 - ang)
        pts = arc_pts(hoop, cy, 6.75 * k, a0, a1)
        line([(base, pts[0][1])] + pts + [(base, pts[-1][1])], dark, 3)
    # handball and five-a-side, white, over them: the outline, the middle, the areas, the dashed line at 9 m, the marks
    d.rectangle([x0, y0, x1, y1], outline=white, width=4)
    d.line([cx, y0, cx, y1], fill=white, width=4)
    line(arc_pts(cx, cy, 3 * k, 0, 360), white, 4)
    for s in (-1, 1):
        gx = cx + s * 20 * k
        for r, dash in ((6 * k, 0), (9 * k, 0.3 * k)):
            top = arc_pts(gx, cy - 1.5 * k, r, -90, -180, 48) if s > 0 else arc_pts(gx, cy - 1.5 * k, r, -90, 0, 48)
            bot = arc_pts(gx, cy + 1.5 * k, r, 180, 90, 48) if s > 0 else arc_pts(gx, cy + 1.5 * k, r, 0, 90, 48)
            pts = [p for p in top if y0 <= p[1]] + [p for p in bot if p[1] <= y1]
            line(pts, white, 4, dash)
        d.line([gx - s * 7 * k, cy - 0.5 * k, gx - s * 7 * k, cy + 0.5 * k], fill=white, width=4)
        d.line([gx - s * 4 * k, cy - 0.08 * k, gx - s * 4 * k, cy + 0.08 * k], fill=white, width=4)
    im.save(os.path.join(OUT, 'pista.png'))


def anuncios():
    # the game's own shops, in the boards' places; AHORROS RURALES where the real wall has the savings bank's green board
    boards = [('MERCAMONA', (236, 240, 236), (22, 120, 70)), ('TODOPIZZA', (200, 40, 36), (250, 240, 210)), ('TELE DÜRUM', (250, 214, 60), (150, 30, 24)),
              ('POLLOS ASADOS\nJAVI', (246, 240, 228), (170, 70, 20)), ('ÓPTICA CORSA', (30, 60, 130), (240, 244, 250)), ('TALLERES\nXANDRO', (28, 28, 32), (240, 200, 40)),
              ('AHORROS\nRURALES', (20, 110, 60), (248, 248, 240)), ('MASAHORRO', (226, 44, 40), (255, 255, 255)), ('PIZZERÍA TOTI', (250, 246, 236), (30, 110, 60)),
              ('CAFETERÍA RIZE', (92, 60, 40), (244, 226, 190)), ('KEBAB DELUXE', (24, 24, 28), (226, 176, 60)), ('PISACASTAÑA', (232, 222, 204), (110, 60, 30))]
    bw, bh = 400, 300                                   # a board of 2 x 1.5 m
    im = Image.new('RGB', (bw * 6, bh * 2), (238, 236, 230))
    d = ImageDraw.Draw(im)
    for i, (name, bg, ink) in enumerate(boards):
        cl, j = divmod(i, 6)
        x = cl * bw * 3 + (j % 3) * bw
        y = (j // 3) * bh
        d.rectangle([x + 6, y + 6, x + bw - 7, y + bh - 7], fill=bg, outline=(150, 150, 146), width=2)
        size = 64
        while size > 20:
            f = font(size)
            box = d.multiline_textbbox((0, 0), name, font=f, align='center', spacing=8)
            if box[2] - box[0] < bw - 50 and box[3] - box[1] < bh - 110:
                break
            size -= 4
        d.multiline_text((x + bw / 2, y + bh / 2 - 22), name, font=f, fill=ink, anchor='mm', align='center', spacing=8)
        d.line([x + 60, y + bh - 78, x + bw - 60, y + bh - 78], fill=ink, width=3)
        d.text((x + bw / 2, y + bh - 50), 'CON EL DEPORTE', font=font(24), fill=ink, anchor='mm')
    im.save(os.path.join(OUT, 'anuncios.png'))


def marcador():
    im = Image.new('RGB', (640, 480), (24, 44, 120))
    d = ImageDraw.Draw(im)
    d.rectangle([8, 8, 631, 471], outline=(200, 206, 220), width=4)
    d.text((170, 70), 'LOCAL', font=font(44), fill=(240, 240, 236), anchor='mm')
    d.text((470, 70), 'VISITANTE', font=font(44), fill=(240, 240, 236), anchor='mm')
    for x in (170, 470):
        d.rectangle([x - 100, 110, x + 100, 270], fill=(12, 14, 22))
        d.text((x, 190), '00', font=font(130), fill=(236, 50, 40), anchor='mm')
    d.rectangle([200, 310, 440, 430], fill=(12, 14, 22))
    d.text((320, 370), '00:00', font=font(86), fill=(240, 190, 40), anchor='mm')
    d.text((110, 370), 'PERIODO', font=font(26), fill=(240, 240, 236), anchor='mm')
    d.text((530, 370), 'FALTAS', font=font(26), fill=(240, 240, 236), anchor='mm')
    im.save(os.path.join(OUT, 'marcador.png'))


emblema()
pista()
anuncios()
marcador()
print('drawn in', os.path.abspath(OUT))
