"""The game photographed from where Street View stood, and the two side by side.

    python tools/molino/vistas_sv.py [name ...]                 prints the --vistas=... for the self-test (all, or those named)
    python tools/molino/vistas_sv.py hoja OUT.jpg SV_FOLDER name [name ...]   Street View | game, one pair to a row

The views are the pictures of capturas.py: the camera of each in the mill's frame (marco.py), 2.5 m over the street.
Google has the panoramas of the south half of this street a metre and a half east of where they were taken (the car
goes down the middle of the roadway, which the aerial photograph has at x = -16): FIX moves them back.
A picture of Street View is 1024 x 640 and its field of view is the horizontal one; the game's --vistas want the
vertical one, and its pictures are 16:9 -- the sheet cuts them to the same shape.
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import marco, capturas
from PIL import Image, ImageDraw, ImageFont

FIX = {k: (-1.5, 0.0) for k in ('O', 'O13', 'O09', 'S1', 'S2', 'S3', 'S4', 'S6')}
FIX.update({'N1': (-1.2, 0.0), 'N2': (-0.9, 0.0), 'N3': (-0.3, 0.0)})          # (less and less going north: at the old gateway Google is right)
CAM = 2.5


def view(name):
    for n, key, h, p, fov in capturas.SHOTS:
        if n == name:
            pid, x, z = capturas.PANO[key]
            ex, ez = marco.to_local((x, z))
            fx, fz = FIX.get(key, (0.0, 0.0))
            ex += fx; ez += fz
            dm = (math.sin(math.radians(h)), -math.cos(math.radians(h)))          # on the map: x east, z south
            dx = dm[0] * marco.U[0] + dm[1] * marco.U[1]; dz = dm[0] * marco.N[0] + dm[1] * marco.N[1]
            d = 30.0
            tx = ex + dx * d * math.cos(math.radians(p)); tz = ez + dz * d * math.cos(math.radians(p))
            vfov = math.degrees(2 * math.atan(math.tan(math.radians(fov / 2)) * 640 / 1024))
            return 'ml_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f' % (name, ex, ez, CAM, tx, tz, CAM + d * math.sin(math.radians(p)), vfov)
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
            g = Image.open(os.path.join(shots, 'vista_ml_%s.png' % n)).convert('RGB')
            gw = int(g.size[1] * 1024 / 640)
            g = g.crop(((g.size[0] - gw) // 2, 0, (g.size[0] + gw) // 2, g.size[1])).resize((W, H), Image.LANCZOS)
            sheet.paste(sv, (0, y + 22)); sheet.paste(g, (W + 6, y + 22))
        sheet.save(out, quality=90)
        print(out, sheet.size)
    else:
        names = sys.argv[1:] or [s[0] for s in capturas.SHOTS]
        print('vistas=' + ';'.join(view(n) for n in names))
