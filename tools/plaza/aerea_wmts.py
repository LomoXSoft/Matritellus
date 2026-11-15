"""The IGN aerial (PNOA, WMTS tiles) for a rectangle in the game's metres, resampled to a north-up picture in metres.
    python tools/plaza/aerea_wmts.py x0 z0 x1 z1 mpp out [zoom]      (out without extension: writes out.jpg and out.json)
(The WMS that tools/fetch_ortho.py asks fails at this detail; the tiles always answer. tools/ign/plaza_wmts.jpg is
    python tools/plaza/aerea_wmts.py -252 -112 -108 44 0.1 tools/ign/plaza_wmts 20 )"""
import io, json, math, sys, time, urllib.request
import numpy as np
from PIL import Image
LAT0, LON0 = 39.4690, -3.5335
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0
x0, z0, x1, z1, mpp = map(float, sys.argv[1:6]); out = sys.argv[6]
Z = int(sys.argv[7]) if len(sys.argv) > 7 else 20
n = 2 ** Z
def tile_xy(lon, lat):
    return (lon + 180.0) / 360.0 * n, (1.0 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2.0 * n
def get(tx, ty):
    url = ('https://www.ign.es/wmts/pnoa-ma?layer=OI.OrthoimageCoverage&style=default&tilematrixset=GoogleMapsCompatible&Service=WMTS&Request=GetTile'
           '&Version=1.0.0&Format=image/jpeg&TileMatrix=%d&TileCol=%d&TileRow=%d' % (Z, tx, ty))
    err = None
    for attempt in range(5):
        try:
            d = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'map-tool/1.0'}), timeout=60).read()
            if d[:2] == bytes([255, 216]): return Image.open(io.BytesIO(d)).convert('RGB')
            err = d[:120]
        except Exception as e:
            err = e
        time.sleep(1.5)
    raise SystemExit('tile %d/%d/%d failed: %s' % (Z, tx, ty, err))
lonA, lonB = LON0 + x0 / KX, LON0 + x1 / KX
latA, latB = LAT0 - z0 / KZ, LAT0 - z1 / KZ          # A = north edge
fx0, fy0 = tile_xy(lonA, latA); fx1, fy1 = tile_xy(lonB, latB)
tx0, tx1, ty0, ty1 = int(math.floor(fx0)), int(math.floor(fx1)), int(math.floor(fy0)), int(math.floor(fy1))
mosaic = Image.new('RGB', ((tx1 - tx0 + 1) * 256, (ty1 - ty0 + 1) * 256))
for ty in range(ty0, ty1 + 1):
    for tx in range(tx0, tx1 + 1):
        mosaic.paste(get(tx, ty), ((tx - tx0) * 256, (ty - ty0) * 256))
M = np.asarray(mosaic).astype(np.float32)
w, h = int(round((x1 - x0) / mpp)), int(round((z1 - z0) / mpp))
xs = x0 + (np.arange(w) + 0.5) * mpp; zs = z0 + (np.arange(h) + 0.5) * mpp
lon = LON0 + xs / KX; lat = LAT0 - zs / KZ
px = ((lon + 180.0) / 360.0 * n - tx0) * 256.0 - 0.5
py = ((1.0 - np.arcsinh(np.tan(np.radians(lat))) / math.pi) / 2.0 * n - ty0) * 256.0 - 0.5
PX, PY = np.meshgrid(px, py)
i0 = np.clip(np.floor(PX).astype(int), 0, M.shape[1] - 2); j0 = np.clip(np.floor(PY).astype(int), 0, M.shape[0] - 2)
fx = np.clip(PX - i0, 0, 1)[..., None]; fy = np.clip(PY - j0, 0, 1)[..., None]
img = M[j0, i0] * (1 - fx) * (1 - fy) + M[j0, i0 + 1] * fx * (1 - fy) + M[j0 + 1, i0] * (1 - fx) * fy + M[j0 + 1, i0 + 1] * fx * fy
Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save(out + '.jpg', quality=94)
json.dump({'x0': x0, 'z0': z0, 'x1': x1, 'z1': z1, 'mpp': mpp, 'zoom': Z, 'source': 'PNOA (c) Instituto Geografico Nacional, CC BY 4.0'}, open(out + '.json', 'w'))
print(out, w, 'x', h, 'from', (tx1 - tx0 + 1) * (ty1 - ty0 + 1), 'tiles at zoom', Z, '(%.3f m/px native)' % (156543.03392 * math.cos(math.radians(LAT0)) / n))
