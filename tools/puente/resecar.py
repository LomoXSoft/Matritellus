"""Where a Street View panorama really stood, from the directions in which it sees things whose place is known (the
openings of the houses of the east row, as the game has them), in the bridge's frame (tools/puente/alturas.py).

    python tools/puente/resecar.py            fits the crossroads panorama of May 2009 (J) and prints where it puts the bridge

Least squares over the camera's place and an error of heading. Headings are read off the thumbnails: 1024 px wide,
heading = centre + atan((x - 512) / f), f = 512 / tan(hfov / 2).
"""
import math

AXIS = 333.7        # the heading of the frame's -z (up the bed, towards the Calle del Santo)


def heading(c, hfov, x):
    return c + math.degrees(math.atan((x - 512) / (512 / math.tan(math.radians(hfov / 2)))))


def seen(cam, p):
    """the heading at which a camera at cam sees the frame point p"""
    dx, dz = p[0] - cam[0], p[1] - cam[1]
    return (AXIS + math.degrees(math.atan2(dx, -dz))) % 360


def diff(a, b):
    return (a - b + 180) % 360 - 180


def fit(obs, start, with_heading=True):
    best = None
    jx0, jz0 = start
    span, step = 6.0, 0.5
    cx, cz, cd = jx0, jz0, 0.0
    for it in range(6):
        for ix in range(-12, 13):
            for iz in range(-12, 13):
                for idd in (range(-12, 13) if with_heading else [0]):
                    jx, jz, d = cx + ix * step, cz + iz * step, cd + idd * step * 0.5
                    e = sum(diff(seen((jx, jz), p) + d, h) ** 2 for h, p in obs)
                    if best is None or e < best[0]:
                        best = (e, jx, jz, d)
        _, cx, cz, cd = best
        step /= 3.0
    return best


if __name__ == '__main__':
    # the east row as the game has it: arroyuelo_34 from (5.9, -3.3) to (6.6, 10.9), arroyuelo_36 from (5.9, -13.4) to (5.9, -3.3)
    def on34(s): return (5.9 + 0.7 * s / 14.2, -3.3 + 14.2 * s / 14.2)
    def on36(s): return (5.9, -13.4 + s)
    obs = [
        (heading(345, 25, 712), on34(0.0)),                    # where the cream house ends and the brick one begins
        (heading(345, 25, 737), on34(0.12 * 14.2 - 0.55)), (heading(345, 25, 805), on34(0.12 * 14.2 + 0.55)),      # the brick house's first window
        (heading(345, 25, 885), on34(0.28 * 14.2 - 0.5)), (heading(345, 25, 955), on34(0.28 * 14.2 + 0.5)),        # its door
        (heading(350, 50, 664), on34(0.45 * 14.2 - 0.55)), (heading(350, 50, 722), on34(0.45 * 14.2 + 0.55)),      # its second window
        (heading(350, 50, 815), on34(0.75 * 14.2 - 1.4)), (heading(350, 50, 980), on34(0.75 * 14.2 + 1.4)),        # its garage door
        (heading(345, 25, 629), on36(0.8 * 10.1)),             # the cream house's door
        (heading(345, 25, 521), on36(0.35 * 10.1)),            # ...and its window
    ]
    for wh in (False, True):
        e, jx, jz, d = fit(obs, (0.9, 17.7), wh)
        print('heading free' if wh else 'heading fixed', ': J at (%.2f, %.2f), heading error %.2f, rms %.2f deg' % (jx, jz, d, math.sqrt(e / len(obs))))
        for h, p in obs:
            print('   seen %.2f  fitted %.2f  (%.1f, %.1f)' % (h, (seen((jx, jz), p) + d) % 360, p[0], p[1]))
        # the bridge: the east ends of its two parapets, seen in the 345/25 view at x = 770 (near one) and 690 (far one)
        for name, x in (('near parapet end', 770), ('far parapet end', 690), ('pier base', 352), ('recess left', 660), ('recess right', 720)):
            h = heading(345, 25, x) - d
            t = math.radians(h - AXIS)
            print('   %s: heading %.2f -> x = jx + (jz - z) * %.4f ; at x=4.4: z = %.2f ; at x=4.7: z = %.2f' % (name, h, math.tan(t), jz - (4.4 - jx) / math.tan(t), jz - (4.7 - jx) / math.tan(t)))
