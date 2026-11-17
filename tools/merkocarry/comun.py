"""What the Merkocarry's tools share: the game's map (its relief, as map_data.gd reads it), and the lines of the
shop's fronts from Catastro (4790703VJ5649S), each from its left end as seen from the street to its right end."""
import json, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.environ.get('MATRITELLUS', os.path.join(HERE, '..', '..'))
_map = None

def game_map():
    global _map
    if _map is None:
        _map = json.load(open(os.path.join(ROOT, 'godot', 'data', 'map.json'), encoding='utf-8'))
    return _map

def height(x, z):
    """the ground of the game there (MapData.height)"""
    r = game_map()['relief']
    g, nx, nz, h = r['g'], r['nx'], r['nz'], r['h']
    fx = min(max((x - r['x0']) / g, 0.0), nx - 1.001)
    fz = min(max((z - r['z0']) / g, 0.0), nz - 1.001)
    i, j = int(fx), int(fz)
    fx -= i; fz -= j
    o = j * nx + i
    a, c = h[o] * 0.01, h[o + nx + 1] * 0.01
    if fx >= fz:
        b = h[o + 1] * 0.01
        return a + fx * (b - a) + fz * (c - b)
    d = h[o + nx] * 0.01
    return a + fz * (d - a) + fx * (c - d)

# the fronts, from Catastro: (left end, right end) seen from outside
FRONTS = {
    'santaana': ((461.41, 158.56), (445.71, 154.61)),      # east to west: the narrow front, beside the greengrocer's house
    'cristo': ((410.35, 178.75), (397.57, 207.25)),         # north to south: the side of the hall (part 3)
    'suspiro': ((445.05, 222.26), (467.48, 182.94)),        # south to north: the long side (parts 1, 4, 5)
}

def along(front, s):
    a, b = FRONTS[front]
    L = math.dist(a, b)
    return (a[0] + (b[0] - a[0]) * s / L, a[1] + (b[1] - a[1]) * s / L)
