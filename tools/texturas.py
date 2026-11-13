# Prepares the photographic textures of the houses for the game.
#
#   python tools/texturas.py
#
# Reads the sets downloaded to tools/descargas/texturas/<set>/ (colour, normal, AO+roughness; all CC0, from Poly Haven:
# see CREDITOS.txt there and in godot/assets/texturas/) and writes godot/assets/texturas/<set>/ with what the game
# loads (godot/scripts/texturas.gd). Sets marked "tint" are painted surfaces whose colour the game chooses (render,
# doors): their colour map is brought to a near-white of even hue, keeping only the stains, cracks and grain, so that
# white render reads WHITE and any other colour can be multiplied in.
import os, sys, json, shutil
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'descargas', 'texturas')
DST = os.path.join(HERE, '..', 'godot', 'assets', 'texturas')

# set: (how it is treated, ...)   "keep": as photographed.   "tint": (percentile taken as the paint, what it becomes, contrast)
SETS = {
    'painted_plaster_wall': ('tint', 55, 0.95, 1.6),
    'white_plaster_02': ('tint', 65, 0.95, 1.25),
    'white_rough_plaster': ('tint', 80, 0.96, 0.8),
    'plastered_wall_04': ('tint', 55, 0.95, 1.6),
    'stone_tile_wall': ('tint', 55, 0.95, 1.3),
    'granite_tile_04': ('tint', 55, 0.95, 1.2),
    'granite_tile_03': ('tint', 55, 0.95, 1.0),
    'old_planks_02': ('grain', 45, 1.0, 0.5),
    'weathered_planks': ('grain', 45, 1.0, 0.5),
    'brown_planks_03': ('grain', 45, 1.0, 0.5),
    # "keep": the mean brightness it is brought up to, and how much its colour is strengthened (photographs are darker
    # and greyer than the game's painted world, and most walls are seen in the shade under a blue sky)
    # the user's choice for facing brick (12 November 2026): this texture, but in the colour the town's brick had --
    # so it is brought to the old painted brick's own colour, and casas.gd MASONRY goes on tinting it as before
    'brick_wall_003': ('recolour', (0.785, 0.53, 0.35), 1.15),
    'brick_wall_07': ('keep', 0.66, 1.2),
    'yellow_brick': ('keep', 0.64, 1.25),
    'red_brick_03': ('keep', 0.46, 1.4),
    'brick_wall_006': ('keep', 0.5, 1.2),
    'brick_wall_09': ('keep', 0.55, 1.4),
    'brick_wall_10': ('keep', 0.32, 1.2),
    'clay_roof_tiles': ('keep', 0.42, 1.0),
    'clay_roof_tiles_02': ('keep', 0.5, 1.0),
    'roof_tiles': ('keep', 0.5, 1.0),
}
# the size of a repeat in metres, where the source's own figure is not to be trusted (judged from the courses of brick)
METRES = {'brick_wall_003': 1.2, 'brick_wall_006': 2.6, 'brick_wall_07': 1.45, 'brick_wall_09': 2.0, 'brick_wall_10': 1.75,
          'red_brick_03': 0.95, 'yellow_brick': 1.9, 'white_plaster_02': 2.0, 'white_rough_plaster': 2.0, 'brown_planks_03': 1.4,
      'old_planks_02': 1.6, 'weathered_planks': 1.6, 'clay_roof_tiles': 3.2, 'clay_roof_tiles_02': 2.5, 'roof_tiles': 2.0}

def main():
    os.makedirs(DST, exist_ok=True)
    credits = ['Texturas de las casas. Todas de Poly Haven (https://polyhaven.com), licencia CC0 (dominio publico):',
               'no obligan a citar a nadie; se apunta de donde viene cada una.', '']
    for name in sorted(os.listdir(SRC)):
        d = os.path.join(SRC, name)
        if not os.path.isfile(os.path.join(d, 'info.json')):
            continue
        info = json.load(open(os.path.join(d, 'info.json')))
        out = os.path.join(DST, name)
        os.makedirs(out, exist_ok=True)
        how = SETS.get(name, ('keep', 0.52, 1.15))
        img = Image.open(os.path.join(d, 'color.jpg')).convert('RGB')
        a = np.asarray(img).astype(np.float32) / 255.0
        if how[0] == 'keep':
            gain = min(2.5, max(1.0, how[1] / a.mean()))
            a = a * gain
            lum = a.mean(axis=2, keepdims=True)
            a = lum + (a - lum) * how[2]
            img = Image.fromarray((np.clip(a, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8))
        elif how[0] == 'recolour':
            mean = a.reshape(-1, 3).mean(axis=0)
            a = 1.0 + (a / mean - 1.0) * how[2]
            img = Image.fromarray((np.clip(a * np.array(how[1], dtype=np.float32), 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8))
        elif how[0] == 'grain':                                  # wood: only its light and dark, the game gives the colour
            lum = a.mean(axis=2)
            g = 1.0 + (lum / np.percentile(lum, how[1]) - 1.0) * how[3]
            g = np.clip(g * how[2], 0.0, 1.0)
            img = Image.fromarray((np.repeat(g[:, :, None], 3, axis=2) * 255.0 + 0.5).astype(np.uint8))
        else:
            lum = a.mean(axis=2)
            ref = np.percentile(lum, how[1])
            near = np.abs(lum - ref) < 0.03                      # the pixels that are "the paint"
            paint = a[near].mean(axis=0) if near.any() else a.reshape(-1, 3).mean(axis=0)
            a = a / paint                                        # the paint becomes 1, of no hue
            a = 1.0 + (a - 1.0) * how[3]
            a = np.clip(a * how[2], 0.0, 1.0)
            img = Image.fromarray((a * 255.0 + 0.5).astype(np.uint8))
        img.save(os.path.join(out, 'color.jpg'), quality=92)
        for f in ('normal.jpg', 'arm.jpg'):
            if os.path.isfile(os.path.join(d, f)):
                shutil.copyfile(os.path.join(d, f), os.path.join(out, f))
        size = METRES.get(name, (info.get('dimensions_mm') or [2000, 2000])[0] / 1000.0)
        json.dump({'metres': round(size, 3), 'tint': how[0] != 'keep'}, open(os.path.join(out, 'set.json'), 'w'))
        credits.append('%s -- %s -- CC0 -- %s' % (name, ', '.join((info.get('authors') or {}).keys()), info.get('source')))
        print(name, how[0], size)
    for where in (SRC, DST):
        open(os.path.join(where, 'CREDITOS.txt'), 'w', encoding='utf8').write('\n'.join(credits) + '\n')

if __name__ == '__main__':
    main()
