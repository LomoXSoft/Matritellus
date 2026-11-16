"""The poster on the grocer's door: the user's own poster of his made-up energy drink ("Roster Energy"), redrawn in the
game's way -- a handful of flat colours, no grain, no photograph -- and given a paper edge.

    python tools/chinos/poster.py [ORIGINAL] [OUT]

ORIGINAL: referencias/chinos_arroyuelo/roster_energy_original.png (the user's picture, 15 November 2026).
OUT: godot/assets/chinos/poster_roster.png (then: Godot --headless --path godot --import).
"""
import os, sys
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
BLACK, DARK, GREY, LIGHT = (20, 22, 20), (52, 56, 52), (128, 134, 128), (238, 240, 232)
LIME, DEEP = (170, 228, 44), (92, 142, 26)
PAPER = (232, 228, 214)
W, H, EDGE = 300, 400, 7


def flat(p):
    r, g, b = p
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    if g > r * 1.18 and g > b * 1.5 and g > 70:            # the drink's green: bright or deep
        return LIME if lum > 120 else DEEP
    if lum < 38:
        return BLACK
    if lum < 86:
        return DARK
    if lum < 158:
        return GREY
    return LIGHT


if __name__ == '__main__':
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'referencias', 'chinos_arroyuelo', 'roster_energy_original.png')
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, 'godot', 'assets', 'chinos', 'poster_roster.png')
    im = Image.open(src).convert('RGB').resize((W * 2, H * 2), Image.LANCZOS)
    im = im.filter(ImageFilter.MedianFilter(7)).filter(ImageFilter.MedianFilter(5))       # (the drops, the grain and the scratches go)
    im = im.resize((W, H), Image.LANCZOS)
    px = im.load()
    for y in range(H):
        for x in range(W):
            px[x, y] = flat(px[x, y])
    im = im.filter(ImageFilter.ModeFilter(5))                                               # (no specks: every patch is one colour)
    sheet = Image.new('RGB', (W + 2 * EDGE, H + 2 * EDGE), PAPER)
    sheet.paste(im, (EDGE, EDGE))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(out, sheet.size)
