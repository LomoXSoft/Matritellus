"""Where on the ground a pixel of a Street View screenshot is: the foot of a wall, the edge of a kerb, a tree's base.

    python tools/plaza/suelo_px.py u,n,h heading pitch fov [WxH] px,py ...

u, n: where the camera stands in the square's own frame (u along the town hall, n out from it); h: its height over
the ground the pixel lies on; heading (compass), pitch and fov (vertical) as in the shot's address. Prints each
pixel's (u, n) and how far it is from the camera. The ground must be level, and the pixel must be where something
meets the ground: the top of a wall, seen from a camera higher than it, lands further away than its foot.
A metre of error in the camera's place is a metre of error in the answer; 5 cm in its height is 2 % in the distance."""
import math, sys
U = (0.9049, 0.4256)
UB = math.degrees(math.atan2(U[0], -U[1]))          # the compass bearing of +u

def ground(cam, heading, pitch, fov, W, H, px, py):
    f = (H / 2.0) / math.tan(math.radians(fov) / 2.0)
    dx, dy = px - W / 2.0, H / 2.0 - py
    p = math.radians(pitch)
    fwd = f * math.cos(p) - dy * math.sin(p)
    up = f * math.sin(p) + dy * math.cos(p)
    if up >= 0: return None
    t = cam[2] / -up
    b = math.radians(heading - UB)                    # the view's direction, from +u towards +n
    return (cam[0] + t * (fwd * math.cos(b) - dx * math.sin(b)), cam[1] + t * (fwd * math.sin(b) + dx * math.cos(b)), t * math.hypot(fwd, dx))

if __name__ == '__main__':
    a = sys.argv[1:]
    cam = [float(v) for v in a[0].split(',')]
    heading, pitch, fov = float(a[1]), float(a[2]), float(a[3])
    W, H = 800.0, 600.0
    rest = a[4:]
    if rest and 'x' in rest[0]:
        W, H = [float(v) for v in rest[0].split('x')]; rest = rest[1:]
    for q in rest:
        px, py = [float(v) for v in q.split(',')]
        g = ground(cam, heading, pitch, fov, W, H, px, py)
        print('%s -> %s' % (q, 'above the horizon' if g is None else '(%.1f, %.1f)  %.1f m away' % g))
