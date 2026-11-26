"""The words cut in the gravestones of the cemetery (cementerio.gd): «R.I.P.» and «D.E.P.», each a small picture of
white letters on nothing, which the game tints (dark on pale stone, gilt on dark) and lays on the stones.

    python tools/cementerio/lapidas.py

writes godot/assets/cementerio/lapida_rip.png and lapida_dep.png (256 x 72). The letters are Pillow's own built-in
face (Aileron, CC0), thickened a little: no font file of anybody's goes into the game.
(The user, 25 Nov 2026: «Poner R.I.P y D.E.P grabado en algunas lápidas (50% de todas ellas)».)
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'godot', 'assets', 'cementerio')
W, H = 256, 72
BIG = 4                                    # drawn this many times bigger, then brought down: smooth edges


def word(text, name):
    mask = Image.new('L', (W * BIG, H * BIG), 0)
    d = ImageDraw.Draw(mask)
    size = 54 * BIG
    font = ImageFont.load_default(size=size)
    stroke = 2 * BIG // 2
    # set letter by letter, a little apart, as a mason spaces them
    gap = 5 * BIG
    widths = [d.textlength(ch, font=font) for ch in text]
    total = sum(widths) + gap * (len(text) - 1)
    x = (W * BIG - total) / 2.0
    box = d.textbbox((0, 0), 'RIPDE', font=font, stroke_width=stroke)
    y = (H * BIG - (box[3] - box[1])) / 2.0 - box[1]
    for ch, wd in zip(text, widths):
        d.text((x, y), ch, font=font, fill=255, stroke_width=stroke, stroke_fill=255)
        x += wd + gap
    mask = mask.resize((W, H), Image.LANCZOS)
    img = Image.new('RGBA', (W, H), (255, 255, 255, 0))
    img.putalpha(mask)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    img.save(path)
    print(path, img.size, 'ink', sum(1 for v in mask.getdata() if v > 127))


word('R.I.P.', 'lapida_rip.png')
word('D.E.P.', 'lapida_dep.png')
