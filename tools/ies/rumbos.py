"""One of capturas.py's pictures with compass bearings drawn over it (an upright line every 5 degrees, each with its
bearing from north, clockwise), to read where things are from each camera: two bearings to the same thing from two
cameras place it on the map (planta.py).

    python tools/ies/rumbos.py SV_FOLDER OUT_FOLDER name [name ...]
"""
import json, math, os, sys
from PIL import Image, ImageDraw, ImageFont

if __name__ == '__main__':
    folder, out = sys.argv[1], sys.argv[2]
    views = json.load(open(os.path.join(folder, 'views.json')))
    font = ImageFont.truetype('arial.ttf', 22)
    for n in sys.argv[3:]:
        v = views[n]
        im = Image.open(os.path.join(folder, n + '.jpg')).convert('RGB')
        w, h = im.size
        f = (w / 2.0) / math.tan(math.radians(v['hfov'] / 2.0))
        d = ImageDraw.Draw(im)
        b = math.ceil((v['heading'] - v['hfov'] / 2.0) / 5.0) * 5
        while b < v['heading'] + v['hfov'] / 2.0:
            x = w / 2.0 + f * math.tan(math.radians(b - v['heading']))
            d.line([(x, 0), (x, h)], fill=(255, 255, 0) if b % 10 == 0 else (255, 255, 255), width=2 if b % 10 == 0 else 1)
            if b % 10 == 0:
                d.rectangle([x + 2, 30, x + 58, 56], fill=(0, 0, 0))
                d.text((x + 4, 31), str(b % 360), fill=(255, 255, 0), font=font)
                d.rectangle([x + 2, h - 60, x + 58, h - 34], fill=(0, 0, 0))
                d.text((x + 4, h - 59), str(b % 360), fill=(255, 255, 0), font=font)
            b += 5
        d.rectangle([0, 0, 330, 28], fill=(0, 0, 0))
        d.text((4, 2), '%s  (%.1f, %.1f)' % (n, v['x'], v['z']), fill=(0, 255, 255), font=font)
        im.resize((1400, int(1400 * h / w)), Image.LANCZOS).save(os.path.join(out, 'rumbo_%s.jpg' % n), quality=85)
        print(n)
