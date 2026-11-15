"""The ground of the square seen from above, rebuilt from Street View screenshots: every pixel that looks at the
ground is put back where it lies (the square is level), in the square's own frame (u along the town hall, n out).

    python tools/plaza/suelo.py views.json u0 n0 u1 n1 px_per_m out.jpg [--only A,C] [--grid S]
(the screenshots named in views.json are looked for beside this script; they are not kept in the repository)

views.json: {"cams": {"A": {"u": .., "n": .., "h": camera height, "dh": heading correction}}, "views": [["file", "cam", heading, pitch, fov], ...]}
A cell takes the view that sees it sharpest (the smallest stretch of ground per pixel), and never from further than
`far` metres. The corners of Google's own page furniture are left out."""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import marco_p as marco
UB = math.degrees(math.atan2(marco.U[0], -marco.U[1]))       # the compass bearing of +u
MASK = [(0, 0, 320, 175), (640, 0, 800, 50), (0, 495, 200, 600), (690, 455, 800, 600), (200, 585, 800, 600), (340, 318, 480, 365)]

def project(cam, heading, pitch, fov, W, H, U, N):
    """pixel of each ground point (u, n); also the ground metres one pixel covers there"""
    b = math.radians(heading + cam.get('dh', 0.0) - UB)       # angle from +u towards +n
    fx, fn = math.cos(b), math.sin(b)
    du = U - cam['u']; dn = N - cam['n']
    fwd = du * fx + dn * fn
    right = -du * fn + dn * fx
    up = -cam['h'] * np.ones_like(fwd)
    p = math.radians(pitch)
    zc = fwd * math.cos(p) + up * math.sin(p)
    yc = -fwd * math.sin(p) + up * math.cos(p)
    f = (H / 2.0) / math.tan(math.radians(fov) / 2.0)
    with np.errstate(divide='ignore', invalid='ignore'):
        px = W / 2.0 + f * right / zc
        py = H / 2.0 - f * yc / zc
    d = np.hypot(du, dn)
    res = d * d / (cam['h'] * f)
    ok = (zc > 0.1) & (px >= 0) & (px < W - 1) & (py >= 0) & (py < H - 1)
    for x0, y0, x1, y1 in MASK:
        ok &= ~((px >= x0) & (px < x1) & (py >= y0) & (py < y1))
    return px, py, res, d, ok

def build(J, u0, n0, u1, n1, ppm, only=None, far=38.0):
    w, h = int((u1 - u0) * ppm), int((n1 - n0) * ppm)
    U, N = np.meshgrid(u0 + (np.arange(w) + 0.5) / ppm, n0 + (np.arange(h) + 0.5) / ppm)
    out = np.zeros((h, w, 3), np.float32); best = np.full((h, w), 1e9, np.float32)
    for name, camn, heading, pitch, fov in J['views']:
        if only and camn not in only: continue
        im = np.asarray(Image.open(os.path.join(HERE, name)).convert('RGB')).astype(np.float32)
        H, W = im.shape[:2]
        px, py, res, d, ok = project(J['cams'][camn], heading, pitch, fov, W, H, U, N)
        ok &= (d < far) & (res < best)
        i = np.clip(px, 0, W - 2); j = np.clip(py, 0, H - 2)
        i0 = np.floor(i).astype(int); j0 = np.floor(j).astype(int)
        fx = (i - i0)[..., None]; fy = (j - j0)[..., None]
        col = im[j0, i0] * (1 - fx) * (1 - fy) + im[j0, i0 + 1] * fx * (1 - fy) + im[j0 + 1, i0] * (1 - fx) * fy + im[j0 + 1, i0 + 1] * fx * fy
        out[ok] = col[ok]; best[ok] = res[ok]
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))

if __name__ == '__main__':
    a = []; only = None; step = 5.0
    i = 1
    while i < len(sys.argv):
        if sys.argv[i] == '--only': only = sys.argv[i + 1].split(','); i += 2
        elif sys.argv[i] == '--grid': step = float(sys.argv[i + 1]); i += 2
        else: a.append(sys.argv[i]); i += 1
    J = json.load(open(a[0])); u0, n0, u1, n1, ppm = map(float, a[1:6])
    im = build(J, u0, n0, u1, n1, ppm, only); d = ImageDraw.Draw(im)
    try: font = ImageFont.truetype('arial.ttf', 12)
    except Exception: font = ImageFont.load_default()
    px = lambda q: ((q[0] - u0) * ppm, (q[1] - n0) * ppm)
    g = math.ceil(u0 / step) * step
    while g <= u1:
        d.line([px((g, n0)), px((g, n1))], fill=(255, 255, 255), width=1); d.text(px((g + 0.1, n0 + 0.1)), '%g' % g, fill=(255, 255, 0), font=font); g += step
    g = math.ceil(n0 / step) * step
    while g <= n1:
        d.line([px((u0, g)), px((u1, g))], fill=(255, 255, 255), width=1); d.text(px((u0 + 0.1, g + 0.1)), '%g' % g, fill=(255, 255, 0), font=font); g += step
    for name, c in J['cams'].items():
        if only and name not in only: continue
        q = px((c['u'], c['n'])); d.ellipse([q[0] - 4, q[1] - 4, q[0] + 4, q[1] + 4], outline=(255, 0, 255), width=2); d.text((q[0] + 6, q[1] - 6), name, fill=(255, 0, 255), font=font)
    im.save(a[6], quality=92); print(a[6], im.size)
