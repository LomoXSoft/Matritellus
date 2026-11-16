"""Several of capturas.py's pictures on one sheet, each under its name: to look through them quickly.

    python tools/kebabdeluxe/contactos.py FOLDER OUT.jpg name [name ...]      (two to a row)
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

if __name__ == '__main__':
    folder, out, names = sys.argv[1], sys.argv[2], sys.argv[3:]
    W, H = 760, 475
    try:
        font = ImageFont.truetype('arial.ttf', 18)
    except Exception:
        font = ImageFont.load_default()
    rows = (len(names) + 1) // 2
    sheet = Image.new('RGB', (2 * W + 6, rows * (H + 4)), (20, 20, 22))
    d = ImageDraw.Draw(sheet)
    for i, n in enumerate(names):
        im = Image.open(os.path.join(folder, n + ('' if n.endswith(('.png', '.jpg')) else '.jpg'))).convert('RGB').resize((W, H), Image.LANCZOS)
        x, y = (i % 2) * (W + 6), (i // 2) * (H + 4)
        sheet.paste(im, (x, y))
        d.rectangle([x, y, x + 12 + 10 * len(n), y + 24], fill=(0, 0, 0))
        d.text((x + 5, y + 2), n, fill=(255, 255, 0), font=font)
    sheet.save(out, quality=88)
    print(out, sheet.size)
