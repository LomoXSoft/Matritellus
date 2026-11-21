"""A piece of the orthophoto of the almazara (tools/ign/almazara_fina.jpg, 0.1 m a pixel) with a grid in the game's
metres, Catastro's parts of it, the line of its front on the road with the metres along it (s, from its south-west
corner), and, if given, the model's own outlines (planta.json: {"name": [[x, z], ...]}), to trace what Catastro lacks
(the tall nave of the 2010s) and to check the model against the ground.

    python tools/almazara/plano.py OUT.png x0 z0 x1 z1 [px_per_m] [planta.json]
"""
import json, math, os, re, sys, zipfile
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
sys.path.insert(0, os.path.join(HERE, '..'))
from house_data import utm30_to_local

A = (264.27, -523.36)            # the front's south-west corner on the road (Catastro)
U = (0.7340, -0.6792)            # along it, to the north-east

if __name__ == '__main__':
    out = sys.argv[1]
    x0, z0, x1, z1 = [float(a) for a in sys.argv[2:6]]
    k = float(sys.argv[6]) if len(sys.argv) > 6 else 8.0
    j = json.load(open(os.path.join(ROOT, 'tools', 'ign', 'almazara_fina.json')))
    src = Image.open(os.path.join(ROOT, 'tools', 'ign', 'almazara_fina.jpg')).convert('RGB')
    s = 1.0 / j['mpp']
    W, H = int((x1 - x0) * k), int((z1 - z0) * k)
    im = src.transform((W, H), Image.AFFINE, (s / k, 0, (x0 - j['x0']) * s, 0, s / k, (z0 - j['z0']) * s), resample=Image.BICUBIC)
    d = ImageDraw.Draw(im, 'RGBA')
    f = ImageFont.truetype('arial.ttf', 12)
    P = lambda p: ((p[0] - x0) * k, (p[1] - z0) * k)
    for gx in range(int(math.ceil(x0)), int(x1) + 1):
        if gx % 5 == 0:
            d.line([P((gx, z0)), P((gx, z1))], fill=(255, 255, 0, 150 if gx % 10 == 0 else 70), width=1)
            if gx % 10 == 0:
                d.text((P((gx, z0))[0] + 2, 2), str(gx), fill=(255, 255, 0, 255), font=f)
    for gz in range(int(math.ceil(z0)), int(z1) + 1):
        if gz % 5 == 0:
            d.line([P((x0, gz)), P((x1, gz))], fill=(255, 255, 0, 150 if gz % 10 == 0 else 70), width=1)
            if gz % 10 == 0:
                d.text((2, P((x0, gz))[1] + 2), str(gz), fill=(255, 255, 0, 255), font=f)
    zf = zipfile.ZipFile(os.path.join(ROOT, 'tools', 'catastro', 'A.ES.SDGC.BU.45088.zip'))
    gml = zf.read([n for n in zf.namelist() if n.endswith('.buildingpart.gml')][0]).decode('utf-8')
    for m in re.finditer(r'<bu-ext2d:BuildingPart gml:id="ES\.SDGC\.BU\.(46990(?:11|12|13|18)[^"]*)">(.*?)</bu-ext2d:BuildingPart>', gml, re.S):
        for ring in re.findall(r'<gml:exterior>.*?<gml:posList[^>]*>([^<]+)</gml:posList>', m.group(2), re.S):
            v = np.array(ring.split(), dtype=float).reshape(-1, 2)
            x, z = utm30_to_local(v[:, 0], v[:, 1])
            d.line([P(p) for p in zip(x, z)], fill=(255, 60, 200, 255), width=1)
    for sm in range(0, 200, 5):                           # the front's line, and the metres along it
        p = (A[0] + U[0] * sm, A[1] + U[1] * sm)
        q = (p[0] + U[1] * -1.5, p[1] + U[0] * 1.5)       # (a tick out towards the road)
        d.line([P(p), P(q)], fill=(0, 255, 255, 255), width=1)
        if sm % 10 == 0:
            d.text(P((q[0] + 0.4, q[1] + 0.4)), str(sm), fill=(0, 255, 255, 255), font=f)
    d.line([P(A), P((A[0] + U[0] * 195, A[1] + U[1] * 195))], fill=(0, 255, 255, 160), width=1)
    if len(sys.argv) > 7:
        for name, pts in json.load(open(sys.argv[7])).items():
            d.line([P(p) for p in pts] + [P(pts[0])], fill=(60, 255, 60, 255), width=2)
            d.text(P(pts[0]), name, fill=(60, 255, 60, 255), font=f)
    im.save(out)
    print(out, im.size)
