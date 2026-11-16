"""The official aerial photo of the barracks under a grid in the game's metres, with Catastro's parts drawn on it:
to trace the court, its fence and its trees.

    python tools/fetch_ortho.py cuartel 20 -565 125 -465 0.1       (once: tools/ign/cuartel.jpg)
    python tools/cuartel/planta.py OUT.jpg [x0 z0 x1 z1 [zoom]]          (the piece to show, in map metres)

Yellow: the map's metres (x east, z south), a line every 2 m, numbered every 10. Red: Catastro's parts
(tools/casas/3891715VJ5639S/datos.json). Cyan: the frame of godot/scripts/cuartel.gd -- its origin and 10 m of each axis.
"""
import json, os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
O = (46.84, -534.47)
U = (0.165, 0.986)
OUT = (-0.986, 0.165)

if __name__ == '__main__':
    out = sys.argv[1]
    box = [float(v) for v in sys.argv[2:6]] if len(sys.argv) > 5 else [30.0, -555.0, 110.0, -475.0]
    k = float(sys.argv[6]) if len(sys.argv) > 6 else 2.0
    meta = json.load(open(os.path.join(HERE, '..', 'ign', 'cuartel.json')))
    im = Image.open(os.path.join(HERE, '..', 'ign', 'cuartel.jpg')).convert('RGB')
    x0 = meta.get('x0', meta.get('xmin', -500.0)); z0 = meta.get('z0', meta.get('zmin', 5.0))
    mpp = meta.get('mpp', 0.12)
    crop = im.crop((int((box[0] - x0) / mpp), int((box[1] - z0) / mpp), int((box[2] - x0) / mpp), int((box[3] - z0) / mpp)))
    crop = crop.resize((int(crop.size[0] * k), int(crop.size[1] * k)), Image.LANCZOS)
    s = k / mpp                                    # pixels to a metre

    def px(p):
        return ((p[0] - box[0]) * s, (p[1] - box[1]) * s)

    d = ImageDraw.Draw(crop, 'RGBA')
    try:
        font = ImageFont.truetype('arial.ttf', 13)
    except Exception:
        font = ImageFont.load_default()
    x = int(box[0] // 2) * 2
    while x <= box[2]:
        if x >= box[0]:
            big = x % 10 == 0
            d.line([px((x, box[1])), px((x, box[3]))], fill=(255, 255, 0, 150 if big else 45), width=1)
            if big:
                d.text((px((x, box[1]))[0] + 2, 2), str(x), fill=(255, 255, 0, 255), font=font)
        x += 2
    z = int(box[1] // 2) * 2
    while z <= box[3]:
        if z >= box[1]:
            big = z % 10 == 0
            d.line([px((box[0], z)), px((box[2], z))], fill=(255, 255, 0, 150 if big else 45), width=1)
            if big:
                d.text((2, px((box[0], z))[1] + 2), str(z), fill=(255, 255, 0, 255), font=font)
        z += 2
    data = json.load(open(os.path.join(HERE, '..', 'casas', '4397001VJ5649N', 'datos.json'), encoding='utf-8'))
    for part in data['parts']:
        ring = [px(p) for p in part['ring']]
        d.line(ring + [ring[0]], fill=(255, 60, 60, 230), width=2)
    for axis in (U, OUT):
        d.line([px(O), px((O[0] + axis[0] * 10, O[1] + axis[1] * 10))], fill=(0, 255, 255, 255), width=2)
    crop.save(out, quality=90)
    print(out, crop.size)
