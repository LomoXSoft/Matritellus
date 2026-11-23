"""Koke el Kokas's yellow Z15 (the user, 23 Nov 2026: "la Z15 amarilla con pintura de llamas y nitro"): the pictures
thrown on its body by godot/scripts/koke_marcas.gd. Drawn here, our own:

  llamas.png    hot-rod flames for its right side: tongues licking back from the nose (the picture's left is the nose)
  llamas_i.png  the same, mirrored, for its left side (so the nose is on the picture's right there)
  capo.png      flames for the bonnet: from its front edge (the picture's bottom) back towards the windscreen
  taxi.png      the roof sign: TAXI in yellow on black, and KOKAS under it

Run: python tools/koke/pinturas.py   (then Godot --headless --path godot --import, for new pictures)
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "godot", "assets", "koke")
os.makedirs(OUT, exist_ok=True)
S = 4                                    # drawn this many times bigger, then shrunk (smooth edges)

def tongue(x0, y0, length, width, bend, n=40):
    """one flame's outline: from its root at (x0, y0) along +x, a long licking point, bending up or down"""
    top, bot = [], []
    for i in range(n + 1):
        t = i / n
        half = width * (1.0 - t) ** 0.85 * (0.55 + 0.45 * math.sin(math.pi * min(1.0, t * 1.6)))
        x = x0 + length * t
        y = y0 + bend * math.sin(t * math.pi * 1.35) * t ** 0.8       # (an S: up, then licking back down)
        top.append((x, y - half))
        bot.append((x, y + half))
    return top + bot[::-1]

def flames(w, h, seed, rows):
    """a band of flames w x h: a solid root on the left that breaks into tongues going right"""
    random.seed(seed)
    W, H = w * S, h * S
    mask = Image.new("L", (W, H), 0)
    inner = Image.new("L", (W, H), 0)
    d, di = ImageDraw.Draw(mask), ImageDraw.Draw(inner)
    d.rectangle([0, int(H * 0.12), int(W * 0.10), int(H * 0.88)], fill=255)
    d.ellipse([-int(W * 0.06), int(H * 0.06), int(W * 0.22), int(H * 0.94)], fill=255)
    for k in range(rows):
        cy = H * (0.16 + 0.68 * (k + 0.5) / rows) + random.uniform(-0.03, 0.03) * H
        length = W * random.uniform(0.55, 0.95)
        width = H * random.uniform(0.11, 0.17)
        bend = H * random.uniform(-0.18, 0.18)
        d.polygon(tongue(W * 0.05, cy, length, width, bend), fill=255)
        di.polygon(tongue(W * 0.05, cy, length * 0.72, width * 0.45, bend * 0.8), fill=255)
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    edge = mask.filter(ImageFilter.MaxFilter(13))
    out.paste((120, 14, 8, 255), (0, 0), edge)                  # the dark red line round them
    grad = Image.new("RGBA", (W, H))
    gd = ImageDraw.Draw(grad)
    for x in range(W):                                           # deep red at the root to orange at the tips
        t = x / W
        r = 214 + int(41 * t)
        g = 32 + int(108 * t)
        b = 18 + int(8 * t)
        gd.line([(x, 0), (x, H)], fill=(r, g, b, 255))
    out.paste(grad, (0, 0), mask)
    out.paste((255, 150, 28, 255), (0, 0), inner)               # a hotter tongue inside each (orange: the car itself is yellow)
    return out.resize((w, h), Image.LANCZOS)

side = flames(1024, 320, 7, 5)
side.save(os.path.join(OUT, "llamas.png"))
side.transpose(Image.FLIP_LEFT_RIGHT).save(os.path.join(OUT, "llamas_i.png"))
hood = flames(512, 512, 11, 4).rotate(90, expand=True)          # (rotated: the root along the bottom, the tongues up)
hood.save(os.path.join(OUT, "capo.png"))

W, H = 512 * 2, 160 * 2
sign = Image.new("RGBA", (W, H), (22, 22, 24, 255))
sd = ImageDraw.Draw(sign)
sd.rectangle([6, 6, W - 7, H - 7], outline=(242, 200, 30, 255), width=8)
big = ImageFont.truetype("C:/Windows/Fonts/ariblk.ttf", 170)
small = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 64)
sd.text((W / 2, H * 0.40), "TAXI", font=big, fill=(242, 200, 30, 255), anchor="mm")
sd.text((W / 2, H * 0.82), "· KOKAS ·", font=small, fill=(255, 122, 16, 255), anchor="mm")
sign.resize((512, 160), Image.LANCZOS).save(os.path.join(OUT, "taxi.png"))
print("ok", os.path.abspath(OUT))
