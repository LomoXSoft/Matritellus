"""The IGN's historical aerial photographs (PNOA historico, CC BY 4.0) for a rectangle of the game's metres.
    python tools/plaza/historico.py LAYER x0 z0 x1 z1 mpp out        (out.jpg + out.json, north up, like fetch_ortho.py)
    python tools/plaza/historico.py --years x0 z0 x1 z1 mpp prefix   one small picture of every year, to choose from
(for aerea_marco.py --src to find one, write it into tools/ign/:  ... PNOA2021 -252 -112 -108 44 0.15 tools/ign/plaza_2021)
Big pictures are asked for in pieces (the service refuses large ones)."""
import io, json, math, sys, time, urllib.request
from PIL import Image
LAT0, LON0 = 39.4690, -3.5335
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0

def piece(layer, x0, z0, x1, z1, w, h):
    lon0, lon1 = LON0 + x0 / KX, LON0 + x1 / KX
    lat1, lat0 = LAT0 - z0 / KZ, LAT0 - z1 / KZ
    url = ('https://www.ign.es/wms/pnoa-historico?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=%s&STYLES=&CRS=EPSG:4326'
           '&BBOX=%.7f,%.7f,%.7f,%.7f&WIDTH=%d&HEIGHT=%d&FORMAT=image/jpeg' % (layer, lat0, lon0, lat1, lon1, w, h))
    err = None
    for attempt in range(4):
        try:
            d = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'map-tool/1.0'}), timeout=90).read()
            if d[:2] == bytes([255, 216]): return Image.open(io.BytesIO(d)).convert('RGB')
            err = d[:160]
        except Exception as e:
            err = e
        time.sleep(1.5)
    raise RuntimeError('%s: %s' % (layer, err))

def fetch(layer, x0, z0, x1, z1, mpp, out, tile=512):
    w, h = int(round((x1 - x0) / mpp)), int(round((z1 - z0) / mpp))
    im = Image.new('RGB', (w, h))
    for ty in range(0, h, tile):
        for tx in range(0, w, tile):
            tw, th = min(tile, w - tx), min(tile, h - ty)
            im.paste(piece(layer, x0 + tx * mpp, z0 + ty * mpp, x0 + (tx + tw) * mpp, z0 + (ty + th) * mpp, tw, th), (tx, ty))
    im.save(out + '.jpg', quality=94)
    json.dump({'x0': x0, 'z0': z0, 'x1': x1, 'z1': z1, 'mpp': mpp, 'layer': layer, 'source': 'PNOA historico (c) Instituto Geografico Nacional, CC BY 4.0'}, open(out + '.json', 'w'))
    return im

if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == '--years':
        x0, z0, x1, z1, mpp = map(float, a[1:6])
        for layer in ['PNOA%d' % y for y in range(2004, 2025)] + ['pnoa10_2007', 'OrtoExpeditaLIDAR2023', 'OrtoExpeditaLIDAR2024', 'SIGPAC', 'OLISTAT']:
            try:
                im = fetch(layer, x0, z0, x1, z1, mpp, a[6] + layer)
                px = list(im.resize((8, 8)).getdata())
                blank = max(max(p) for p in px) - min(min(p) for p in px) < 12
                print(layer, im.size, 'BLANK' if blank else 'ok')
            except Exception as e:
                print(layer, 'failed:', str(e)[:120])
    else:
        x0, z0, x1, z1, mpp = map(float, a[1:6])
        print(a[0], fetch(a[0], x0, z0, x1, z1, mpp, a[6]).size)
