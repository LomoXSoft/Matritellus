"""Crops of the orthophoto of the MasAhorro (tools/ign/masahorro.jpg) with a grid of 5 m, labelled every
10 m, to trace its buildings: python tools/masahorro/recortes.py OUT_FOLDER name:x0,z0,x1,z1 [...]"""
import json, os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
IGN = os.path.join(HERE, '..', 'ign')
SOURCES = ['masahorro']


def crop(x0, z0, x1, z1, scale=10.0):
    out = Image.new('RGB', (int((x1 - x0) * scale), int((z1 - z0) * scale)), (0, 0, 0))
    for s in SOURCES:
        j = json.load(open(os.path.join(IGN, s + '.json')))
        im = Image.open(os.path.join(IGN, s + '.jpg')).convert('RGB')
        k = 1.0 / j['mpp']
        a = (max(x0, j['x0']), max(z0, j['z0']), min(x1, j['x1']), min(z1, j['z1']))
        if a[0] >= a[2] or a[1] >= a[3]:
            continue
        piece = im.crop((int((a[0] - j['x0']) * k), int((a[1] - j['z0']) * k), int((a[2] - j['x0']) * k), int((a[3] - j['z0']) * k)))
        piece = piece.resize((int((a[2] - a[0]) * scale), int((a[3] - a[1]) * scale)))
        out.paste(piece, (int((a[0] - x0) * scale), int((a[1] - z0) * scale)))
    d = ImageDraw.Draw(out)
    f = ImageFont.truetype('arial.ttf', 14)
    for x in range(int(x0 // 5 * 5), int(x1) + 1, 5):
        X = (x - x0) * scale
        d.line([(X, 0), (X, out.size[1])], fill=(255, 255, 0) if x % 10 == 0 else (255, 255, 255), width=1)
        if x % 10 == 0:
            d.text((X + 2, 2), str(x), fill=(255, 255, 0), font=f)
    for z in range(int(z0 // 5 * 5), int(z1) + 1, 5):
        Z = (z - z0) * scale
        d.line([(0, Z), (out.size[0], Z)], fill=(255, 255, 0) if z % 10 == 0 else (255, 255, 255), width=1)
        if z % 10 == 0:
            d.text((2, Z + 2), str(z), fill=(255, 255, 0), font=f)
    return out


if __name__ == '__main__':
    folder = sys.argv[1]
    for arg in sys.argv[2:]:
        name, box = arg.split(':')
        x0, z0, x1, z1 = map(float, box.split(','))
        crop(x0, z0, x1, z1, float(os.environ.get('ESCALA', '10'))).save(os.path.join(folder, name + '.jpg'), quality=88)
        print(name)
