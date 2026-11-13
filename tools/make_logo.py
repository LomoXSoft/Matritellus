"""Draws the Matritellus crest (our own design: a towerless castle wall and a palm tree) and writes
godot/icon.png (512), godot/assets/logo.png (1024) and godot/icon.ico (for Windows installers/executables).

  pip install pillow
  python tools/make_logo.py
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
S = 4                      # supersampling
W = 1024 * S
img = Image.new('RGBA', (W, W), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
def P(x, y): return (x * S, y * S)
def poly(pts, **kw): d.polygon([P(*p) for p in pts], **kw)
def rect(x0, y0, x1, y1, **kw): d.rectangle([P(x0, y0), P(x1, y1)], **kw)

INK = (62, 42, 28, 255); GOLD = (232, 178, 58, 255); TERRA = (201, 96, 58, 255); STONE = (245, 232, 200, 255)
SKY = (120, 186, 226, 255); GRASS = (104, 168, 84, 255); TRUNK = (138, 96, 56, 255); LEAF = (58, 140, 78, 255)

# --- shield outline: flat top, straight sides, rounded point ---
def shield(inset):
    pts = [(152 + inset, 96 + inset), (872 - inset, 96 + inset), (872 - inset, 520)]
    for i in range(0, 41):      # right curve down to the tip
        t = i / 40
        pts.append((512 + (360 - inset) * math.cos(t * math.pi / 2), 520 + (340 - inset) * math.sin(t * math.pi / 2)))
    for i in range(40, -1, -1):
        t = i / 40
        pts.append((512 - (360 - inset) * math.cos(t * math.pi / 2), 520 + (340 - inset) * math.sin(t * math.pi / 2)))
    pts.append((152 + inset, 520))
    return pts

poly(shield(-14), fill=INK)
poly(shield(0), fill=GOLD)
mask = Image.new('L', (W, W), 0)
ImageDraw.Draw(mask).polygon([P(*p) for p in shield(26)], fill=255)
field = Image.new('RGBA', (W, W), (0, 0, 0, 0))
f = ImageDraw.Draw(field)
f.rectangle([P(0, 0), P(512, 1024)], fill=TERRA)          # left: terracotta
f.rectangle([P(512, 0), P(1024, 1024)], fill=SKY)         # right: sky
f.rectangle([P(512, 610), P(1024, 1024)], fill=GRASS)     # ground under the palm

# --- left: a castle wall with battlements and a gate, and no tower ---
def fr(x0, y0, x1, y1, col): f.rectangle([P(x0, y0), P(x1, y1)], fill=col)
fr(214, 420, 478, 640, STONE)
for i in range(5):
    fr(214 + i * 58, 372, 214 + i * 58 + 34, 424, STONE)
for row in range(5):                                        # stone courses
    y = 452 + row * 40
    f.line([P(214, y), P(478, y)], fill=(200, 180, 140, 255), width=4 * S)
    for k in range(6):
        x = 214 + k * 52 + (26 if row % 2 else 0)
        if 214 < x < 478:
            f.line([P(x, y), P(x, y + 40)], fill=(200, 180, 140, 255), width=4 * S)
f.pieslice([P(306, 510), P(386, 590)], 180, 360, fill=INK)  # arched gate
fr(306, 550, 386, 640, INK)
fr(244, 470, 266, 512, INK); fr(426, 470, 448, 512, INK)    # arrow slits

# --- right: a palm tree ---
trunk = []
for i in range(0, 21):
    t = i / 20
    trunk.append((690 + 40 * math.sin(t * 1.4) - 16 * (1 - t * 0.5), 640 - t * 250))
for i in range(20, -1, -1):
    t = i / 20
    trunk.append((690 + 40 * math.sin(t * 1.4) + 16 * (1 - t * 0.5), 640 - t * 250))
f.polygon([P(*p) for p in trunk], fill=TRUNK)
for k in range(9):                                          # rings on the trunk
    t = (k + 0.5) / 9
    x = 690 + 40 * math.sin(t * 1.4); y = 640 - t * 250
    f.line([P(x - 14, y), P(x + 14, y - 5)], fill=(104, 70, 40, 255), width=4 * S)
cx, cy = 690 + 40 * math.sin(1.4), 390
for ang, length in [(-165, 150), (-135, 170), (-100, 160), (-70, 165), (-40, 170), (-12, 150), (165, 120), (18, 120)]:
    pts = []
    a = math.radians(ang)
    for i in range(0, 13):                                  # a drooping frond
        t = i / 12
        x = cx + math.cos(a) * length * t
        y = cy + math.sin(a) * length * t + 90 * t * t
        pts.append((x, y))
    for i, (x, y) in enumerate(pts[:-1]):
        w = int((26 - i * 1.8) * S)
        f.line([P(x, y), P(*pts[i + 1])], fill=LEAF, width=max(w, 4 * S))
        f.ellipse([P(x - w / S / 2, y - w / S / 2), P(x + w / S / 2, y + w / S / 2)], fill=LEAF)
for ox, oy in [(-10, 14), (12, 18), (2, 30)]:               # dates
    f.ellipse([P(cx + ox - 11, cy + oy - 11), P(cx + ox + 11, cy + oy + 11)], fill=(120, 72, 36, 255))

f.line([P(512, 96), P(512, 880)], fill=GOLD, width=10 * S)  # the pale between the two halves
img.paste(field, (0, 0), mask)

# --- ribbon with the name ---
poly([(112, 846), (912, 846), (880, 900), (912, 956), (112, 956), (144, 900)], fill=INK)
poly([(128, 858), (896, 858), (868, 900), (896, 944), (128, 944), (156, 900)], fill=STONE)
font = None
for name in ('arialbd.ttf', 'segoeuib.ttf', 'DejaVuSans-Bold.ttf'):
    try:
        font = ImageFont.truetype(name, 62 * S); break
    except OSError:
        pass
txt = 'MATRITELLUS'
if font:
    box = d.textbbox((0, 0), txt, font=font)
    d.text(((W - (box[2] - box[0])) / 2 - box[0], 901 * S - (box[3] - box[1]) / 2 - box[1]), txt, font=font, fill=INK)

out = img.resize((1024, 1024), Image.LANCZOS)
os.makedirs(os.path.join(HERE, '..', 'godot', 'assets'), exist_ok=True)
out.save(os.path.join(HERE, '..', 'godot', 'assets', 'logo.png'))
out.resize((512, 512), Image.LANCZOS).save(os.path.join(HERE, '..', 'godot', 'icon.png'))
out.save(os.path.join(HERE, '..', 'godot', 'icon.ico'), sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])
print('logo written')
