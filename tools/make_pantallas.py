"""The fights on the screens of the Galaxy Recress (recress_sala.gd), from the user's GIFs.

    python -I tools/make_pantallas.py

Reads referencias/recress/Tokken9_*.gif (the user's, 13 November 2026: eight frames each) and writes
godot/assets/recress/peleas.png: one fight to a row, its frames left to right, each frame a square CELL pixels across.
It prints the time each fight's frames last, for MS in the screen shader (recress_sala.gd SCREEN_SHADER).
"""
import glob
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'referencias', 'recress')
OUT = os.path.join(ROOT, 'godot', 'assets', 'recress', 'peleas.png')
CELL = 256
FRAMES = 8


def main() -> None:
    gifs = sorted(glob.glob(os.path.join(SRC, 'Tokken9_*.gif')))
    if not gifs:
        sys.exit('no Tokken9_*.gif in ' + SRC)
    sheet = Image.new('RGB', (CELL * FRAMES, CELL * len(gifs)), (0, 0, 0))
    ms = []
    for row, path in enumerate(gifs):
        im = Image.open(path)
        n = getattr(im, 'n_frames', 1)
        durs = []
        for i in range(FRAMES):
            im.seek(i % n)
            durs.append(im.info.get('duration', 160) or 160)
            fr = im.convert('RGB')
            side = min(fr.size)                       # (they are nearly square: the middle square of each)
            left = (fr.width - side) // 2
            top = (fr.height - side) // 2
            fr = fr.crop((left, top, left + side, top + side)).resize((CELL, CELL), Image.LANCZOS)
            sheet.paste(fr, (i * CELL, row * CELL))
        ms.append(round(sum(durs[:n]) / n))
        print('%d  %s  %d frames, %d ms each' % (row, os.path.basename(path), n, ms[-1]))
    sheet.save(OUT, optimize=True)
    print('%s  %dx%d' % (OUT, sheet.width, sheet.height))
    print('MS = float[](%s);' % ', '.join('%.1f' % m for m in ms))


if __name__ == '__main__':
    main()
