"""The game's name in a joined-up hand, for the title screen (the user, 14 November 2026: "Matritellus con letra
cursiva y bonita", fading in over the town seen from the air). Drawn once to a picture, from a script face of the
machine (Segoe Script Bold, a Windows font: the picture is shipped, never the font itself):

    python tools/make_titulo.py        ->  godot/assets/titulo/matritellus.png

Cream letters going to gold at their feet, a thin dark-brown edge, and a soft shadow under them so they read over
any sky.
"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "godot", "assets", "titulo", "matritellus.png")
FONT = "C:/Windows/Fonts/segoescb.ttf"
TEXT = "Matritellus"
SIZE = 220                 # (the picture is about 1500 px wide: sharp on a 4K screen at a third of its width)
EDGE = 5
PAD = 60


def main():
    font = ImageFont.truetype(FONT, SIZE)
    box = font.getbbox(TEXT, stroke_width=EDGE)
    w, h = box[2] - box[0] + PAD * 2, box[3] - box[1] + PAD * 2
    at = (PAD - box[0], PAD - box[1])
    # the letters alone, as a mask
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).text(at, TEXT, font=font, fill=255)
    edge = Image.new("L", (w, h), 0)
    ImageDraw.Draw(edge).text(at, TEXT, font=font, fill=255, stroke_width=EDGE, stroke_fill=255)
    # cream going to gold from top to foot
    fill = Image.new("RGBA", (w, h))
    top, foot = (255, 249, 232), (240, 196, 110)
    for y in range(h):
        k = min(1.0, max(0.0, (y - PAD) / max(1, h - PAD * 2)))
        c = tuple(int(top[i] + (foot[i] - top[i]) * k) for i in range(3))
        ImageDraw.Draw(fill).line([(0, y), (w, y)], fill=c + (255,))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (20, 10, 4, 0))
    shadow.putalpha(edge.filter(ImageFilter.GaussianBlur(14)).point(lambda v: int(v * 0.55)))
    out.alpha_composite(shadow, (6, 10))
    brown = Image.new("RGBA", (w, h), (58, 32, 16, 255))
    brown.putalpha(edge)
    out.alpha_composite(brown)
    fill.putalpha(mask)
    out.alpha_composite(fill)
    out = out.crop(out.getbbox())
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.save(OUT)
    print(OUT, out.size)


if __name__ == "__main__":
    main()
