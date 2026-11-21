"""Flat views out of a 360 photo (equirectangular): a sheet of them, one every `step` degrees round, at eye level, and
any others asked for.

    python tools/rice/vistas360.py PANO.jpg OUT.jpg CENTRE [step=60] [fov=90] [pitch=0]
    python tools/rice/vistas360.py PANO.jpg OUT.jpg CENTRE heading,pitch,fov [heading,pitch,fov ...]

CENTRE: the compass heading the middle of the picture looks at (Google's word for it; a person's 360 is often some
degrees out: check against a wall whose bearing is known). The 360 photos are other people's: NOT kept in the repository.
"""
import math, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont


def view(src, centre, heading, pitch, fov, w=800, h=500):
    H, W = src.shape[:2]
    f = (w / 2.0) / math.tan(math.radians(fov) / 2.0)
    xs, ys = np.meshgrid(np.arange(w) - w / 2.0 + 0.5, h / 2.0 - np.arange(h) - 0.5)
    d = np.stack([xs, ys, np.full_like(xs, f)], -1)
    d /= np.linalg.norm(d, axis=-1, keepdims=True)
    p = math.radians(pitch)
    y = d[..., 1] * math.cos(p) + d[..., 2] * math.sin(p)
    z = -d[..., 1] * math.sin(p) + d[..., 2] * math.cos(p)
    x = d[..., 0]
    yaw = np.degrees(np.arctan2(x, z)) + heading - centre
    lat = np.degrees(np.arcsin(np.clip(y, -1, 1)))
    u = ((yaw / 360.0 + 0.5) % 1.0) * W
    v = (0.5 - lat / 180.0) * H
    return Image.fromarray(src[np.clip(v.astype(int), 0, H - 1), np.clip(u.astype(int), 0, W - 1)])


if __name__ == '__main__':
    src = np.asarray(Image.open(sys.argv[1]).convert('RGB'))
    out, centre = sys.argv[2], float(sys.argv[3])
    opt = {'step': 60.0, 'fov': 90.0, 'pitch': 0.0}
    shots = []
    for a in sys.argv[4:]:
        if '=' in a:
            opt[a.split('=')[0]] = float(a.split('=')[1])
        else:
            shots.append(tuple(float(q) for q in a.split(',')))
    if not shots:
        shots = [(hd, opt['pitch'], opt['fov']) for hd in np.arange(0.0, 360.0, opt['step'])]
    cols = 2
    rows = (len(shots) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * 800, rows * 500))
    d = ImageDraw.Draw(sheet)
    font = ImageFont.truetype('arial.ttf', 18)
    for i, (hd, pt, fv) in enumerate(shots):
        x, y = (i % cols) * 800, (i // cols) * 500
        sheet.paste(view(src, centre, hd, pt, fv), (x, y))
        d.rectangle((x, y, x + 230, y + 24), fill=(0, 0, 0))
        d.text((x + 6, y + 2), 'rumbo %.0f  alto %.0f  campo %.0f' % (hd, pt, fv), fill=(255, 255, 0), font=font)
    sheet.save(out, quality=88)
    print(out, sheet.size)
