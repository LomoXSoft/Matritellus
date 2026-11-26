"""The pictures of the Sala Cuevas (godot/scripts/cuevas.gd), all made here, none taken from a photograph:

    python tools/cuevas/texturas.py        -> godot/assets/cuevas/*.png

  pintura_nueva.png   the dark paint of its front, fresh, on rough render: anthracite, not black, with the render's grain
                      lit from above and the roller's passes (the user, 25 November 2026: «La pintura tan negra y lisa
                      hace que casi no se vean los outlines ni las formas. Le pondría algo de textura»)
  pintura_vieja.png   the dark paint of its front gone pale, flaked off in patches down to the render, with runs of dirt
  blanco_viejo.png    the white of the terrace's walls, grey with damp, flaked, with rust runs
  celosia.png         the concrete lattice at the back of its arches (see-through)
  marca.png           the mark on its sign: our own, three cave mouths under one arch (not the real hall's letter)
  marca_vieja.png     ...half of it gone
  roca.png            the rock of the cave inside (cuevas_dentro.gd), mid-dark, cracked, lit from above
  suelo_sala.png      its floor of dark slabs; pista.png, the smaller ones of the dance floor
  bola.png            the little mirrors of the mirror balls
  motas.png           the spots a mirror ball throws about (see-through)

The two paints tile (4 m to the picture). Always the same pictures: the dice are seeded.
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'cuevas')
N = 512


def noise(n, cells, rng):
    """value noise that wraps: `cells` knots to the side"""
    g = rng.random((cells, cells))
    xs = np.arange(n) * cells / n
    i0 = np.floor(xs).astype(int)
    f = xs - i0
    f = f * f * (3 - 2 * f)
    i1 = (i0 + 1) % cells
    a, b, c, d = g[i0][:, i0], g[i0][:, i1], g[i1][:, i0], g[i1][:, i1]
    fx, fy = f[None, :], f[:, None]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(n, rng, base=4, octaves=5):
    out = np.zeros((n, n))
    amp, tot = 1.0, 0.0
    for k in range(octaves):
        out += noise(n, base * 2 ** k, rng) * amp
        tot += amp
        amp *= 0.5
    return out / tot


def runs(n, rng, count, long, wide):
    """runs of dirt down the wall, as a mask 0..1 (they wrap, top to bottom)"""
    m = np.zeros((n, n))
    ys = np.arange(n)
    for _ in range(count):
        x = rng.integers(0, n)
        y0 = rng.integers(0, n)
        ln = rng.integers(long[0], long[1])
        w = rng.uniform(wide[0], wide[1])
        fall = np.clip(1.0 - ((ys - y0) % n) / ln, 0.0, 1.0) ** 0.7
        for dx in range(-int(w * 3), int(w * 3) + 1):
            m[:, (x + dx) % n] = np.maximum(m[:, (x + dx) % n], fall * np.exp(-(dx / w) ** 2) * rng.uniform(0.5, 1.0))
    return m


def mix(a, b, t):
    return a * (1 - t[..., None]) + b * t[..., None]


def old_paint(seed, paint, washed, bare, flake_at, dirt, dirt_col, name):
    rng = np.random.default_rng(seed)
    img = np.ones((N, N, 3)) * np.array(paint)
    img *= (0.86 + 0.28 * fbm(N, rng, 8, 5))[..., None]                       # the brush and the weather
    fade = np.clip((fbm(N, rng, 2, 4) - 0.38) * 3.2, 0.0, 1.0)                # where the sun has had it longest
    img = mix(img, np.array(washed) * (0.9 + 0.2 * fbm(N, rng, 16, 3))[..., None], fade * 0.85)
    f = fbm(N, rng, 6, 5) * 0.7 + fbm(N, rng, 3, 2) * 0.3                     # where it has come off: patches with a ragged edge
    flake = np.clip((f - flake_at) * 40.0, 0.0, 1.0)
    rim = np.clip((f - flake_at + 0.02) * 40.0, 0.0, 1.0) - flake
    img = mix(img, np.array(bare) * (0.82 + 0.3 * fbm(N, rng, 24, 3))[..., None], flake)
    img *= (1.0 - 0.35 * np.clip(rim, 0.0, 1.0))[..., None]
    d = runs(N, rng, dirt, (90, 300), (1.5, 5.0))
    img = mix(img, np.array(dirt_col), d * 0.55)
    img += (rng.random((N, N, 1)) - 0.5) * 0.035
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), 'RGB').save(os.path.join(OUT, name))
    print(name)


def new_paint(seed, paint, name):
    rng = np.random.default_rng(seed)
    h = noise(N, 256, rng) * 0.36 + noise(N, 128, rng) * 0.3 + noise(N, 64, rng) * 0.22 + noise(N, 32, rng) * 0.12      # the render's grain, coarse and fine, as heights
    lit = np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)                                     # lit from above: each grain bright on top, dark below
    lit = lit / (np.abs(lit).max() + 1e-9)
    img = np.ones((N, N, 3)) * np.array(paint)
    img *= (0.78 + 0.44 * fbm(N, rng, 3, 6))[..., None]                                      # the trowel under it and the roller over it: paler and darker patches
    img *= (0.93 + 0.14 * noise(N, 16, rng)[0:1, :])[..., None]                              # ...and the roller's passes, down the wall
    img *= (1.0 + 0.62 * lit)[..., None]
    img += (rng.random((N, N, 1)) - 0.5) * 0.02
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), 'RGB').save(os.path.join(OUT, name))
    print(name)


def rock(seed, name):
    """the rock of the cave inside (cuevas_dentro.gd): masses, cracks and ochre veins, lit from above. Mid-dark, never
    black: it has to take the colours of the party lights and let the shapes be read"""
    rng = np.random.default_rng(seed)
    mass = fbm(N, rng, 3, 6)
    h = mass * 0.55 + noise(N, 48, rng) * 0.25 + noise(N, 128, rng) * 0.2
    lit = np.roll(h, -2, axis=0) - np.roll(h, 2, axis=0)
    lit = lit / (np.abs(lit).max() + 1e-9)
    c = fbm(N, rng, 5, 4)
    crack = np.clip(1.0 - np.abs(c - 0.5) * 70.0, 0.0, 1.0)
    img = np.ones((N, N, 3)) * np.array((0.46, 0.43, 0.41))
    img *= (0.72 + 0.56 * mass)[..., None]
    vein = np.clip((fbm(N, rng, 4, 4) - 0.5) * 4.0, 0.0, 1.0)
    img = mix(img, img * np.array((1.14, 1.0, 0.84)), vein)
    img *= (1.0 + 0.55 * lit)[..., None]
    img *= (1.0 - 0.5 * crack)[..., None]
    img += (rng.random((N, N, 1)) - 0.5) * 0.03
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), 'RGB').save(os.path.join(OUT, name))
    print(name)


def floor(seed, name, k, base):
    """the hall's floor: k x k dark slabs to the picture, each its own shade, mottled, with its joints"""
    rng = np.random.default_rng(seed)
    s = N // k
    img = np.ones((N, N, 3)) * np.array(base)
    img *= (0.82 + 0.36 * fbm(N, rng, 6, 5))[..., None]
    for j in range(k):
        for i in range(k):
            img[j * s:(j + 1) * s, i * s:(i + 1) * s] *= rng.uniform(0.86, 1.12)
            img[j * s:j * s + 2, i * s:(i + 1) * s] *= 0.5
            img[j * s:(j + 1) * s, i * s:i * s + 2] *= 0.5
    speck = rng.random((N, N))
    img[speck > 0.992] *= 1.5
    img += (rng.random((N, N, 1)) - 0.5) * 0.025
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), 'RGB').save(os.path.join(OUT, name))
    print(name)


def mirror_ball():
    """the little mirrors of a mirror ball, 32 round it and 16 from top to bottom, each catching a different light"""
    rng = np.random.default_rng(21)
    w, h, c = 512, 256, 16
    img = np.zeros((h, w, 3))
    for j in range(h // c):
        for i in range(w // c):
            v = rng.uniform(0.3, 0.75) if rng.random() > 0.14 else rng.uniform(0.9, 1.0)
            img[j * c:(j + 1) * c, i * c:(i + 1) * c] = v * np.array((0.93, 0.96, 1.0))
            img[j * c:j * c + 1, i * c:(i + 1) * c] *= 0.35
            img[j * c:(j + 1) * c, i * c:i * c + 1] *= 0.35
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), 'RGB').save(os.path.join(OUT, 'bola.png'))
    print('bola.png')


def dots():
    """what a mirror ball throws about the room: soft white spots on nothing (a decal turns it over the floor)"""
    rng = np.random.default_rng(33)
    n = 512
    a = np.zeros((n, n))
    yy, xx = np.mgrid[0:n, 0:n]
    for _ in range(120):
        ang = rng.uniform(0, 2 * np.pi)
        rad = n * 0.47 * np.sqrt(rng.uniform(0.02, 1.0))
        cx, cy = n / 2 + np.cos(ang) * rad, n / 2 + np.sin(ang) * rad
        r = rng.uniform(4.0, 7.5)
        a = np.maximum(a, np.clip(1.25 - np.hypot(xx - cx, yy - cy) / r, 0.0, 1.0) * rng.uniform(0.55, 1.0))
    rgba = np.zeros((n, n, 4), np.uint8)
    rgba[..., :3] = (np.clip(a, 0, 1) * 255).astype(np.uint8)[..., None]      # (black but for the spots: a decal's light is the picture's colour, whatever its alpha)
    rgba[..., 3] = (np.clip(a, 0, 1) * 255).astype(np.uint8)
    Image.fromarray(rgba, 'RGBA').save(os.path.join(OUT, 'motas.png'))
    print('motas.png')


def lattice():
    """concrete blocks, each with a lozenge through it: 4 x 4 of them, 0.8 m to the picture"""
    n, k = 256, 4
    s = n // k
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rng = np.random.default_rng(7)
    for j in range(k):
        for i in range(k):
            x, y = i * s, j * s
            v = int(196 + rng.integers(-14, 14))
            d.rectangle([x, y, x + s - 1, y + s - 1], fill=(v, v, v - 4, 255))
            m, c = 9, s // 2
            d.polygon([(x + c, y + m), (x + s - m, y + c), (x + c, y + s - m), (x + m, y + c)], fill=(0, 0, 0, 0))
            d.rectangle([x, y, x + s - 1, y + s - 1], outline=(120, 120, 118, 255))
            d.line([(x + c - 2, y + m), (x + c - 2, y + s - m)], fill=(0, 0, 0, 0))      # (nothing: keeps the lozenge whole)
            d.rectangle([x + c - 3, y + 2, x + c + 2, y + s - 3], fill=(v - 10, v - 10, v - 14, 255))   # its upright rib
            d.rectangle([x + 2, y + c - 3, x + s - 3, y + c + 2], fill=(v - 10, v - 10, v - 14, 255))   # ...and the one across
    im.save(os.path.join(OUT, 'celosia.png'))
    print('celosia.png')


def mark():
    """our own mark: three cave mouths under one arch, white"""
    n = 512
    im = Image.new('L', (n, n), 0)
    d = ImageDraw.Draw(im)
    d.pieslice([56, 70, 456, 470], 180, 360, fill=255)                   # the hill
    d.rectangle([56, 268, 456, 330], fill=255)
    d.pieslice([108, 122, 404, 418], 180, 360, fill=0)                   # hollowed: an arch
    d.rectangle([108, 268, 404, 332], fill=0)
    for cx in (176, 256, 336):                                           # the three mouths under it
        d.pieslice([cx - 34, 236, cx + 34, 304], 180, 360, fill=255)
        d.rectangle([cx - 34, 268, cx + 34, 330], fill=255)
    d.rectangle([56, 352, 456, 380], fill=255)                           # the ground line
    im = im.filter(ImageFilter.GaussianBlur(1.2))
    a = np.asarray(im).astype(np.float64) / 255.0
    rgba = np.zeros((n, n, 4), np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = (a * 255).astype(np.uint8)
    Image.fromarray(rgba, 'RGBA').save(os.path.join(OUT, 'marca.png'))
    rng = np.random.default_rng(11)                                      # ...and what the weather has left of it
    gone = np.clip((fbm(n, rng, 7, 5) - 0.55) * 30.0, 0.0, 1.0)
    rgba[..., 3] = (a * (1.0 - gone) * 255 * 0.8).astype(np.uint8)
    Image.fromarray(rgba, 'RGBA').save(os.path.join(OUT, 'marca_vieja.png'))
    print('marca.png marca_vieja.png')


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    new_paint(2, (0.275, 0.28, 0.315), 'pintura_nueva.png')
    old_paint(3, (0.25, 0.26, 0.33), (0.42, 0.43, 0.5), (0.68, 0.66, 0.62), 0.565, 30, (0.12, 0.12, 0.13), 'pintura_vieja.png')
    old_paint(5, (0.9, 0.89, 0.85), (0.8, 0.8, 0.77), (0.6, 0.56, 0.5), 0.6, 60, (0.42, 0.36, 0.28), 'blanco_viejo.png')
    lattice()
    mark()
    rock(41, 'roca.png')
    floor(43, 'suelo_sala.png', 4, (0.3, 0.3, 0.33))
    floor(47, 'pista.png', 8, (0.23, 0.23, 0.27))
    mirror_ball()
    dots()
