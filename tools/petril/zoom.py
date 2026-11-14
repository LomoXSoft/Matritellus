"""a piece of a picture, enlarged, with a grid in the picture's own pixels:
   python zoom.py in.jpg out.jpg x0 y0 x1 y1 [k] [step]"""
import sys
from PIL import Image, ImageDraw, ImageFont
src = Image.open(sys.argv[1]).convert('RGB')
out = sys.argv[2]
x0, y0, x1, y1 = [int(v) for v in sys.argv[3:7]]
k = float(sys.argv[7]) if len(sys.argv) > 7 else 3.0
step = int(sys.argv[8]) if len(sys.argv) > 8 else 20
im = src.crop((x0, y0, x1, y1))
big = im.resize((int(im.width * k), int(im.height * k)), Image.LANCZOS)
d = ImageDraw.Draw(big)
try: font = ImageFont.truetype('arial.ttf', 12)
except Exception: font = ImageFont.load_default()
if step > 0:
    x = (x0 // step + 1) * step
    while x < x1:
        d.line([((x - x0) * k, 0), ((x - x0) * k, big.height)], fill=(255, 255, 0) if x % (step * 5) == 0 else (120, 120, 60), width=1)
        d.text(((x - x0) * k + 2, 2), str(x), fill=(255, 255, 0), font=font)
        x += step
    y = (y0 // step + 1) * step
    while y < y1:
        d.line([(0, (y - y0) * k), (big.width, (y - y0) * k)], fill=(255, 255, 0) if y % (step * 5) == 0 else (120, 120, 60), width=1)
        d.text((2, (y - y0) * k + 2), str(y), fill=(255, 255, 0), font=font)
        y += step
big.save(out, quality=92); print(out, big.size)
