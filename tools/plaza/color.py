"""mean colour of patches of a picture: python color.py picture name:x0,y0,x1,y1 ...   (sRGB mean taken in linear light)"""
import sys
import numpy as np
from PIL import Image

def lin(c): return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
def srgb(c): return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(np.maximum(c, 0), 1 / 2.4) - 0.055)

im = np.asarray(Image.open(sys.argv[1]).convert('RGB')).astype(float) / 255.0
for a in sys.argv[2:]:
    n, v = a.split(':'); x0, y0, x1, y1 = [int(q) for q in v.split(',')]
    p = lin(im[y0:y1, x0:x1].reshape(-1, 3))
    m = srgb(p.mean(axis=0)); sd = im[y0:y1, x0:x1].reshape(-1, 3).std(axis=0).mean()
    print('%-14s (%3d,%3d,%3d)  #%02x%02x%02x  sd %.3f' % ((n,) + tuple(int(round(q * 255)) for q in m) + tuple(int(round(q * 255)) for q in m) + (sd,)))
