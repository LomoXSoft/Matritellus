"""Draws the button icons the game shows wherever it tells you which key or button does something:
godot/assets/botones/*.png (all 64 px tall; the game draws them at the height of the text around them).

    python tools/make_botones.py

  kb_<key>.png         a key of the keyboard, as Godot names it (OS.get_keycode_string): kb_E, kb_Space_es, kb_Up...
                       (the few with words on them come in Spanish and English: _es / _en)
  mouse_left.png ...   the mouse
  xb_<button>.png      an Xbox-style pad (also what a Steam Machine's or Steam Deck's buttons are): a b x y lb rb lt rt
                       back start dpad_up... ls rs
  ps_<button>.png      a PlayStation pad: cross circle square triangle l1 r1 l2 r2 share options (d-pad and sticks:
                       the xb_ ones)
  rot_left/right.png   the curved arrows that say the character in the creator can be turned

Drawn four times bigger and scaled down, for smooth edges. The lettering is the font Pillow comes with (Aileron, SIL
Open Font License), thickened a little with an outline of its own colour.
"""
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), 'godot', 'assets', 'botones')
H = 64
S = 4                                    # supersampling
INK = (58, 42, 30, 255)
CREAM = (246, 237, 218, 255)
CREAM_DARK = (205, 190, 164, 255)
PAD = (44, 44, 50, 255)
PAD_EDGE = (20, 20, 24, 255)
WHITE = (250, 250, 250, 255)


def font(px):
    return ImageFont.load_default(px)


def text_size(d, txt, f):
    b = d.textbbox((0, 0), txt, font=f, stroke_width=max(1, f.size // 22))
    return b[2] - b[0], b[3] - b[1], b


def draw_text(d, cx, cy, txt, f, fill):
    sw = max(1, f.size // 22)
    w, h, b = text_size(d, txt, f)
    d.text((cx - w / 2 - b[0], cy - h / 2 - b[1]), txt, font=f, fill=fill, stroke_width=sw, stroke_fill=fill)


def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    w = max(1, round(img.width / S))
    img.resize((w, H), Image.LANCZOS).save(os.path.join(OUT, name + '.png'))


def canvas(w):
    img = Image.new('RGBA', (w * S, H * S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


# ---------------- keyboard ----------------
def keycap(label, name, symbol=None):
    f = font(30 * S if len(label) <= 2 else 22 * S)
    probe = ImageDraw.Draw(Image.new('RGBA', (8, 8)))
    tw = text_size(probe, label, f)[0] if label else 0
    w = max(H, int(tw / S) + 30)
    img, d = canvas(w)
    r = 12 * S
    m = 3 * S
    d.rounded_rectangle((m, m + 4 * S, w * S - m, H * S - m), r, fill=INK)                    # the side of the key
    d.rounded_rectangle((m, m, w * S - m, H * S - m - 7 * S), r, fill=CREAM, outline=INK, width=4 * S)
    d.rounded_rectangle((m + 7 * S, m + 6 * S, w * S - m - 7 * S, H * S - m - 15 * S), r - 4 * S, fill=None, outline=CREAM_DARK, width=2 * S)
    cx, cy = w * S / 2, (H * S - 7 * S) / 2
    if symbol:
        symbol(d, cx, cy)
    else:
        draw_text(d, cx, cy, label, f, INK)
    save(img, name)


def arrow(direction):
    def draw(d, cx, cy):
        k = 11 * S
        pts = {'Up': [(cx, cy - k), (cx - k, cy + k * 0.7), (cx + k, cy + k * 0.7)],
               'Down': [(cx, cy + k), (cx - k, cy - k * 0.7), (cx + k, cy - k * 0.7)],
               'Left': [(cx - k, cy), (cx + k * 0.7, cy - k), (cx + k * 0.7, cy + k)],
               'Right': [(cx + k, cy), (cx - k * 0.7, cy - k), (cx - k * 0.7, cy + k)]}[direction]
        d.polygon(pts, fill=INK)
    return draw


def keyboard():
    for c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789':
        keycap(c, 'kb_' + c)
    for i in range(1, 13):
        keycap('F%d' % i, 'kb_F%d' % i)
    for c, n in [(',', 'Comma'), ('.', 'Period'), ('-', 'Minus'), ('+', 'Plus'), ('´', 'Apostrophe')]:
        keycap(c, 'kb_' + n)
    for direction in ['Up', 'Down', 'Left', 'Right']:
        keycap('', 'kb_' + direction, arrow(direction))
    for name, es, en in [('Space', 'Espacio', 'Space'), ('Enter', 'Intro', 'Enter'),
                         ('Escape', 'Esc', 'Esc'), ('Tab', 'Tab', 'Tab'), ('Ctrl', 'Ctrl', 'Ctrl'), ('Alt', 'Alt', 'Alt'),
                         ('Backspace', 'Borrar', 'Backspace'), ('CapsLock', 'Bloq Mayús', 'Caps')]:
        keycap(es, 'kb_%s_es' % name)
        keycap(en, 'kb_%s_en' % name)

    def shift(d, cx, cy):                            # (the shift arrow: the font has no accented letters for "Mayús")
        k = 13 * S
        pts = [(cx, cy - k), (cx + k, cy), (cx + k * 0.45, cy), (cx + k * 0.45, cy + k), (cx - k * 0.45, cy + k), (cx - k * 0.45, cy), (cx - k, cy), (cx, cy - k)]
        d.line(pts, fill=INK, width=4 * S, joint='curve')
    for lang in ('es', 'en'):
        keycap('Shift', 'kb_Shift_' + lang, shift)


def mouse():
    for which in ['left', 'right', 'drag']:
        w = 48
        img, d = canvas(w)
        x0, y0, x1, y1 = 8 * S, 4 * S, (w - 8) * S, (H - 4) * S
        d.rounded_rectangle((x0, y0, x1, y1), 18 * S, fill=CREAM, outline=INK, width=4 * S)
        mid = (x0 + x1) / 2
        top = y0 + 24 * S
        d.line((x0 + 2 * S, top, x1 - 2 * S, top), fill=INK, width=3 * S)
        d.line((mid, y0, mid, top), fill=INK, width=3 * S)
        if which in ('left', 'right'):
            box = (x0 + 4 * S, y0 + 4 * S, mid - 2 * S, top - 2 * S) if which == 'left' else (mid + 2 * S, y0 + 4 * S, x1 - 4 * S, top - 2 * S)
            d.rounded_rectangle(box, 6 * S, fill=(214, 96, 54, 255))
        else:                                        # a drag: arrows either side, at the bottom
            cy = top + (y1 - top) / 2
            k = 6 * S
            d.polygon([(x0 + 5 * S, cy), (x0 + 5 * S + k, cy - k), (x0 + 5 * S + k, cy + k)], fill=INK)
            d.polygon([(x1 - 5 * S, cy), (x1 - 5 * S - k, cy - k), (x1 - 5 * S - k, cy + k)], fill=INK)
        save(img, 'mouse_' + which)


# ---------------- pads ----------------
def face(name, inner):
    img, d = canvas(H)
    m = 3 * S
    d.ellipse((m, m, H * S - m, H * S - m), fill=PAD, outline=PAD_EDGE, width=3 * S)
    inner(d, H * S / 2, H * S / 2)
    save(img, name)


def letter(c, col):
    return lambda d, cx, cy: draw_text(d, cx, cy + 1 * S, c, font(34 * S), col)


def shoulder(name, label, trigger=False):
    w = 84
    img, d = canvas(w)
    m = 3 * S
    if trigger:                                      # a trigger: rounded at the top, square at the bottom
        d.rounded_rectangle((m, m, w * S - m, H * S - m), 22 * S, fill=PAD, outline=PAD_EDGE, width=3 * S)
        d.rectangle((m, H * S * 0.55, w * S - m, H * S - m), fill=PAD, outline=PAD_EDGE, width=3 * S)
        d.rectangle((m + 3 * S, H * S * 0.5, w * S - m - 3 * S, H * S - m - 3 * S), fill=PAD)
    else:                                            # a bumper: a flat pill
        d.rounded_rectangle((m, 12 * S, w * S - m, H * S - 12 * S), 18 * S, fill=PAD, outline=PAD_EDGE, width=3 * S)
    draw_text(d, w * S / 2, H * S / 2 + (3 * S if trigger else 0), label, font(26 * S), WHITE)
    save(img, name)


def small(name, inner):
    img, d = canvas(H)
    m = 8 * S
    d.ellipse((m, m, H * S - m, H * S - m), fill=PAD, outline=PAD_EDGE, width=3 * S)
    inner(d, H * S / 2, H * S / 2)
    save(img, name)


def dpad(direction):
    img, d = canvas(H)
    c = H * S / 2
    a, b = 11 * S, 30 * S
    for box in [(c - a, c - b, c + a, c + b), (c - b, c - a, c + b, c + a)]:
        d.rounded_rectangle(box, 5 * S, fill=(120, 120, 128, 255), outline=PAD_EDGE, width=3 * S)
    d.rectangle((c - a + 3 * S, c - a + 3 * S, c + a - 3 * S, c + a - 3 * S), fill=(120, 120, 128, 255))
    lit = {'up': (c - a, c - b, c + a, c - a), 'down': (c - a, c + a, c + a, c + b),
           'left': (c - b, c - a, c - a, c + a), 'right': (c + a, c - a, c + b, c + a)}[direction]
    d.rounded_rectangle(lit, 5 * S, fill=WHITE, outline=PAD_EDGE, width=3 * S)
    save(img, 'xb_dpad_' + direction)


def stick(name, label):
    img, d = canvas(H)
    m = 3 * S
    d.ellipse((m, m, H * S - m, H * S - m), fill=(120, 120, 128, 255), outline=PAD_EDGE, width=3 * S)
    d.ellipse((m + 9 * S, m + 9 * S, H * S - m - 9 * S, H * S - m - 9 * S), fill=PAD, outline=PAD_EDGE, width=2 * S)
    draw_text(d, H * S / 2, H * S / 2, label, font(26 * S), WHITE)
    save(img, name)


def pads():
    face('xb_a', letter('A', (110, 200, 90, 255)))
    face('xb_b', letter('B', (232, 88, 76, 255)))
    face('xb_x', letter('X', (80, 150, 236, 255)))
    face('xb_y', letter('Y', (244, 200, 60, 255)))
    shoulder('xb_lb', 'LB'); shoulder('xb_rb', 'RB')
    shoulder('xb_lt', 'LT', True); shoulder('xb_rt', 'RT', True)
    shoulder('ps_l1', 'L1'); shoulder('ps_r1', 'R1')
    shoulder('ps_l2', 'L2', True); shoulder('ps_r2', 'R2', True)

    def view(d, cx, cy):                             # (two overlapping squares)
        k = 7 * S
        d.rectangle((cx - k - 3 * S, cy - k - 3 * S, cx + k - 3 * S, cy + k - 3 * S), outline=WHITE, width=3 * S)
        d.rectangle((cx - k + 3 * S, cy - k + 3 * S, cx + k + 3 * S, cy + k + 3 * S), fill=PAD, outline=WHITE, width=3 * S)

    def menu(d, cx, cy):                             # (three lines)
        for dy in (-7, 0, 7):
            d.line((cx - 9 * S, cy + dy * S, cx + 9 * S, cy + dy * S), fill=WHITE, width=3 * S)
    small('xb_back', view)
    small('xb_start', menu)
    small('ps_share', lambda d, cx, cy: [d.line((cx + dx * S, cy - 8 * S, cx + dx * S, cy + 8 * S), fill=WHITE, width=3 * S) for dx in (-5, 0, 5)])
    small('ps_options', menu)
    for direction in ['up', 'down', 'left', 'right']:
        dpad(direction)
    stick('xb_ls', 'L'); stick('xb_rs', 'R')

    def cross(d, cx, cy):
        k = 12 * S
        col = (140, 170, 236, 255)
        d.line((cx - k, cy - k, cx + k, cy + k), fill=col, width=5 * S)
        d.line((cx - k, cy + k, cx + k, cy - k), fill=col, width=5 * S)

    def circle(d, cx, cy):
        k = 13 * S
        d.ellipse((cx - k, cy - k, cx + k, cy + k), outline=(236, 110, 110, 255), width=5 * S)

    def square(d, cx, cy):
        k = 11 * S
        d.rectangle((cx - k, cy - k, cx + k, cy + k), outline=(220, 150, 210, 255), width=5 * S)

    def triangle(d, cx, cy):
        k = 14 * S
        pts = [(cx, cy - k), (cx + k, cy + k * 0.75), (cx - k, cy + k * 0.75), (cx, cy - k)]
        d.line(pts, fill=(90, 205, 180, 255), width=5 * S, joint='curve')
    face('ps_cross', cross)
    face('ps_circle', circle)
    face('ps_square', square)
    face('ps_triangle', triangle)


# ---------------- the creator's turning arrows ----------------
def turn_arrows():
    for side in ['left', 'right']:
        w = 96
        img, d = canvas(w)
        box = (8 * S, 4 * S, (w - 8) * S, (H + 40) * S)          # an arc along the top of an oval round the feet
        col = (246, 237, 218, 240)
        edge = (58, 42, 30, 230)
        start, end = (200, 300) if side == 'left' else (240, 340)
        for width, c in [(14 * S, edge), (8 * S, col)]:
            d.arc(box, start, end, fill=c, width=width)
        import math
        cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
        rx, ry = (box[2] - box[0]) / 2 - 4 * S, (box[3] - box[1]) / 2 - 4 * S
        ang = math.radians(start if side == 'left' else end)
        tip = (cx + rx * math.cos(ang), cy + ry * math.sin(ang))
        tangent = (-rx * math.sin(ang), ry * math.cos(ang))
        n = math.hypot(*tangent)
        t = (tangent[0] / n, tangent[1] / n)
        if side == 'left':
            t = (-t[0], -t[1])
        k = 16 * S
        p = (-t[1], t[0])
        head = [(tip[0] + t[0] * k, tip[1] + t[1] * k), (tip[0] + p[0] * k * 0.8, tip[1] + p[1] * k * 0.8), (tip[0] - p[0] * k * 0.8, tip[1] - p[1] * k * 0.8)]
        d.polygon(head, fill=col, outline=edge, width=3 * S)
        save(img, 'rot_' + side)


if __name__ == '__main__':
    keyboard()
    mouse()
    pads()
    turn_arrows()
    print(len(os.listdir(OUT)), 'icons in', OUT)
