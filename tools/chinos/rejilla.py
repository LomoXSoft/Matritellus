"""A piece of a picture, enlarged, under a grid numbered in the picture's own pixels: to read off where things are.

    python tools/chinos/rejilla.py PICTURE x0 y0 x1 y1 OUT [zoom [step]]      (the grid: every `step` pixels, 10 if not given, numbered every fifth line)
"""
import sys
from PIL import Image, ImageDraw, ImageFont

if __name__ == '__main__':
    src, x0, y0, x1, y1, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), sys.argv[6]
    k = float(sys.argv[7]) if len(sys.argv) > 7 else 3.0
    st = int(sys.argv[8]) if len(sys.argv) > 8 else 10
    im = Image.open(src).convert('RGB').crop((x0, y0, x1, y1))
    im = im.resize((int(im.size[0] * k), int(im.size[1] * k)), Image.LANCZOS)
    d = ImageDraw.Draw(im, 'RGBA')
    try:
        font = ImageFont.truetype('arial.ttf', 13)
    except Exception:
        font = ImageFont.load_default()
    for x in range((x0 // st) * st, x1 + 1, st):
        if x < x0:
            continue
        big = x % (st * 5) == 0
        d.line([((x - x0) * k, 0), ((x - x0) * k, im.size[1])], fill=(255, 255, 0, 150 if big else 55), width=1)
        if big:
            d.text(((x - x0) * k + 2, 2), str(x), fill=(255, 255, 0, 255), font=font)
    for y in range((y0 // st) * st, y1 + 1, st):
        if y < y0:
            continue
        big = y % (st * 5) == 0
        d.line([(0, (y - y0) * k), (im.size[0], (y - y0) * k)], fill=(0, 255, 255, 150 if big else 55), width=1)
        if big:
            d.text((2, (y - y0) * k + 2), str(y), fill=(0, 255, 255, 255), font=font)
    im.save(out, quality=92)
    print(out, im.size)
