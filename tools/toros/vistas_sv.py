"""The game photographed from where Street View stood round the old bullring, and the two side by side.

    python tools/toros/vistas_sv.py [name ...]                 prints the vistas=... for tools/run_tests.py (views tr_...)
    python tools/toros/vistas_sv.py hoja OUT.jpg SV_FOLDER name [name ...]   Street View | game, one pair to a row

The views are the pictures of capturas.py (2009: before the restoration; 2013 and 2024: after), 2.5 m over the street.
For the views of 2009 the game must show the ruin; for the others, run it with --toros-restaurada.
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import capturas
from PIL import Image, ImageDraw, ImageFont

O = (476.3, 548.5)          # the middle of the ring, on the map (the frame is the map's own axes from there)
FIX = {}
CAM = 2.5


def view(name):
    for n, key, h, p, fov in capturas.SHOTS:
        if n == name:
            pid, x, z = capturas.PANO[key]
            ex, ez = x - O[0], z - O[1]
            fx, fz = FIX.get(key, (0.0, 0.0))
            ex += fx; ez += fz
            dx, dz = math.sin(math.radians(h)), -math.cos(math.radians(h))          # on the map: x east, z south
            d = 30.0
            tx = ex + dx * d * math.cos(math.radians(p)); tz = ez + dz * d * math.cos(math.radians(p))
            vfov = math.degrees(2 * math.atan(math.tan(math.radians(fov / 2)) * 640 / 1024))
            return 'tr_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f' % (name, ex, ez, CAM, tx, tz, CAM + d * math.sin(math.radians(p)), vfov)
    raise SystemExit('no view called ' + name)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'hoja':
        out, folder, names = sys.argv[2], sys.argv[3], sys.argv[4:]
        shots = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'godot', 'shots')
        W, H = 640, 400
        sheet = Image.new('RGB', (2 * W + 6, len(names) * (H + 22)), (22, 22, 24))
        d = ImageDraw.Draw(sheet)
        try:
            font = ImageFont.truetype('arial.ttf', 15)
        except Exception:
            font = ImageFont.load_default()
        for i, n in enumerate(names):
            y = i * (H + 22)
            d.text((6, y + 3), n + '   (Street View | juego)', fill=(240, 240, 240), font=font)
            sv = Image.open(os.path.join(folder, n + '.jpg')).convert('RGB').resize((W, H), Image.LANCZOS)
            g = Image.open(os.path.join(shots, 'vista_tr_%s.png' % n)).convert('RGB')
            gw = int(g.size[1] * 1024 / 640)
            g = g.crop(((g.size[0] - gw) // 2, 0, (g.size[0] + gw) // 2, g.size[1])).resize((W, H), Image.LANCZOS)
            sheet.paste(sv, (0, y + 22)); sheet.paste(g, (W + 6, y + 22))
        sheet.save(out, quality=90)
        print(out, sheet.size)
    else:
        names = sys.argv[1:] or [s[0] for s in capturas.SHOTS]
        print('vistas=' + ';'.join(view(n) for n in names))
