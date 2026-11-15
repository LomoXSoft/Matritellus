"""The aerial photograph beside the game's own picture from straight above (shots/plaza_above.png: camera 112 m over
the point (0, 40) of the square's frame, north up), both cut to the same piece of ground.
(The game's camera has a field of 55 degrees: do not work the scale out from a roof, which is ten metres nearer the lens.)
    python tools/plaza/desde_arriba.py out.jpg [fov]"""
import json, math, os, sys
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import marco_p as m
out = sys.argv[1]; fov = float(sys.argv[2]) if len(sys.argv) > 2 else 55.0
game = Image.open(os.path.join(HERE, '..', '..', 'godot', 'shots', 'plaza_above.png')).convert('RGB')
IGN = os.path.join(HERE, '..', 'ign')
J = json.load(open(os.path.join(IGN, 'plaza_wmts.json'))); A = Image.open(os.path.join(IGN, 'plaza_wmts.jpg')).convert('RGB')
cx, cz = m.to_map((0.0, 40.0))
half_v = 112.0 * math.tan(math.radians(fov) / 2.0)          # metres from the middle to the top of the game's picture
ppm = game.height / 2.0 / half_v
side = 58.0                                                   # metres each way from the middle that both are cut to
def px(v): return (v - J['x0']) / J['mpp']
def pz(v): return (v - J['z0']) / J['mpp']
a = A.crop((int(px(cx - side)), int(pz(cz - side)), int(px(cx + side)), int(pz(cz + side))))
g = game.crop((int(game.width / 2 - side * ppm), int(game.height / 2 - side * ppm), int(game.width / 2 + side * ppm), int(game.height / 2 + side * ppm)))
w = 640
sheet = Image.new('RGB', (2 * w + 6, w + 26), (24, 24, 26)); d = ImageDraw.Draw(sheet)
try: font = ImageFont.truetype('arial.ttf', 17)
except Exception: font = ImageFont.load_default()
sheet.paste(a.resize((w, w), Image.LANCZOS), (0, 24)); sheet.paste(g.resize((w, w), Image.LANCZOS), (w + 6, 24))
d.text((6, 3), 'ortofoto PNOA (IGN, CC BY 4.0)', fill=(240, 240, 240), font=font); d.text((w + 12, 3), 'juego, desde arriba', fill=(240, 240, 240), font=font)
sheet.save(out, quality=90); print(out, sheet.size, 'ppm %.2f' % ppm)
