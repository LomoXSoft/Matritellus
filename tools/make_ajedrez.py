"""Draws the holograms over the pieces of the Ajedrez humano (godot/assets/ajedrez/holo_<kind>_<side>.png).

Each is the chess symbol of the piece (from DejaVu Sans, in the Windows fonts folder: its licence lets the letters be
used for anything; the picture is uploaded, never the font), white or dark inside as the piece is, with a cyan rim, a
cyan glow round it and scan lines across, so that it reads as a hologram floating over the head. The user asked for it
on 16 November 2026: "a cada pieza le ponemos un holograma encima de su cabeza que indique qué pieza son... un simple
.png que siempre mire a cámara".

    python tools/make_ajedrez.py
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "godot", "assets", "ajedrez")
FONT = r"C:\Windows\Fonts\DejaVuSans.ttf"
GLYPHS = {"p": "\u265f", "n": "\u265e", "b": "\u265d", "r": "\u265c", "q": "\u265b", "k": "\u265a"}     # the solid ones
SIDES = {"blanca": (250, 248, 240), "gris": (64, 66, 74)}
CYAN = (110, 232, 255)
INK = (16, 36, 64)
SIZE = 256
UP = 4                                     # drawn four times as big, then shrunk (smooth edges)


def glyph_mask(ch: str) -> Image.Image:
    n = SIZE * UP
    font = ImageFont.truetype(FONT, int(n * 0.74))
    m = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(m)
    box = d.textbbox((0, 0), ch, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    d.text(((n - w) / 2 - box[0], (n - h) / 2 - box[1]), ch, font=font, fill=255)
    return m


def hologram(mask: Image.Image, fill) -> Image.Image:
    n = mask.size[0]
    inked = mask.filter(ImageFilter.MaxFilter(3 * UP + 1))                 # a dark line round the shape (it reads on a light floor)...
    grown = inked.filter(ImageFilter.MaxFilter(4 * UP + 1))                # ...and the cyan rim round that
    glow = grown.filter(ImageFilter.MaxFilter(6 * UP + 1)).filter(ImageFilter.GaussianBlur(9 * UP))
    out = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    out = Image.alpha_composite(out, Image.merge("RGBA", (*[Image.new("L", (n, n), c) for c in CYAN], glow.point(lambda v: int(v * 0.7)))))
    out = Image.alpha_composite(out, Image.merge("RGBA", (*[Image.new("L", (n, n), c) for c in CYAN], grown)))
    out = Image.alpha_composite(out, Image.merge("RGBA", (*[Image.new("L", (n, n), c) for c in INK], inked)))
    body = Image.merge("RGBA", (*[Image.new("L", (n, n), c) for c in fill], mask.point(lambda v: int(v * 0.93))))
    out = Image.alpha_composite(out, body)
    # scan lines: every few rows a little fainter, and a light sweep down from the top
    lines = Image.new("L", (n, n), 255)
    d = ImageDraw.Draw(lines)
    for y in range(0, n, 5 * UP):
        d.rectangle([0, y, n, y + UP * 2 - 1], fill=225)
    r, g, b, a = out.split()
    a = ImageChops.multiply(a, lines)
    return Image.merge("RGBA", (r, g, b, a)).resize((SIZE, SIZE), Image.LANCZOS)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    for kind, ch in GLYPHS.items():
        mask = glyph_mask(ch)
        for side, fill in SIDES.items():
            path = os.path.join(OUT, "holo_%s_%s.png" % (kind, side))
            hologram(mask, fill).save(path)
            print(path)


if __name__ == "__main__":
    main()
