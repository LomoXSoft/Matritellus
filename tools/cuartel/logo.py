"""The Tricornios' badge and the flag's stripe for their cars, painted here (the user, 16 November 2026: "invertir el
logo que has hecho de los tricornios en la fachada (cambiar negro por dorado y viceversa) y usarlo como su logo ...
en el frontal y en los laterales del coche, además de una franja con la bandera de España, como los oficiales").

    python tools/cuartel/logo.py

Writes godot/assets/tricornios/logo.png (a black badge with a gold rim and the tricorn hat in gold: the hat of the
barracks' own plate -- its back turned up square behind a low crown, over its brim -- with its colours changed over)
and bandera.png (red, yellow, red, leaning like the official cars' stripe; bandera_i.png is its mirror image). All on nothing: what is not painted is
see-through. Then: Godot --headless --path godot --import.
"""
import os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'tricornios')
BLACK = (28, 28, 30, 255)
GOLD = (230, 180, 34, 255)
SHADE = (176, 132, 18, 255)
RED = (200, 16, 46, 255)
YELLOW = (241, 191, 0, 255)


def logo(n=512):
    k = 4                                           # painted four times the size and brought down: smooth edges
    im = Image.new('RGBA', (n * k, n * k), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    s = n * k
    d.rounded_rectangle([s * 0.04, s * 0.04, s * 0.96, s * 0.96], radius=s * 0.16, fill=GOLD)
    d.rounded_rectangle([s * 0.075, s * 0.075, s * 0.925, s * 0.925], radius=s * 0.13, fill=BLACK)

    def at(x, y):                                   # the plate's own measures: the hat is 0.46 wide, from -0.04 to 0.2 high
        return (s * (0.5 + x * 1.6), s * (0.62 - y * 1.6))

    d.polygon([at(-0.15, 0.0), at(0.15, 0.0), at(0.2, 0.2), at(-0.2, 0.2)], fill=GOLD)                 # its back, turned up square
    x0, y0 = at(-0.13, 0.135)
    x1, y1 = at(0.13, -0.035)
    d.ellipse([x0, y0, x1, y1], fill=SHADE)                                                            # its low crown
    x0, y0 = at(-0.23, 0.005)
    x1, y1 = at(0.23, -0.035)
    d.rounded_rectangle([x0, y0, x1, y1], radius=s * 0.012, fill=GOLD)                                # its brim
    return im.resize((n, n), Image.LANCZOS)


def flag(w=512, h=192):
    k = 4
    im = Image.new('RGBA', (w * k, h * k), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    W, H = w * k, h * k
    lean = H * 0.45                                 # how far its top is ahead of its foot
    for y0, y1, colour in ((0.06, 0.28, RED), (0.28, 0.72, YELLOW), (0.72, 0.94, RED)):
        a = lean * (1.0 - y0)
        b = lean * (1.0 - y1)
        d.polygon([(W * 0.03 + a, H * y0), (W * 0.97 - lean + a, H * y0), (W * 0.97 - lean + b, H * y1), (W * 0.03 + b, H * y1)], fill=colour)
    return im.resize((w, h), Image.LANCZOS)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    logo().save(os.path.join(OUT, 'logo.png'))
    flag().save(os.path.join(OUT, 'bandera.png'))
    flag().transpose(Image.FLIP_LEFT_RIGHT).save(os.path.join(OUT, 'bandera_i.png'))      # (for the car's other side: there its top leans the other way)
    print(OUT)
