"""The row of the pharmacy of the Calle Real photographed in the game: prints the vistas=... for tools/run_tests.py.

    python tools/farmacia/vistas.py [name ...]

Each view: where the eye is and what it looks at, in the row's own frame (x along the fronts from the brick house's
north end, z out into the street), heights over the ground; the last number is the vertical field of view.
"""
import sys
O = (-61.17, -89.09); U = (-0.1835, 0.9830); W = (-0.9830, -0.1835)
VIEWS = [
    ('fa_drogueria', (27.0, 5.0), 1.7, (26.4, 0.0), 3.0, 85), ('fa_farmacia_sur', (20.3, 5.2), 1.7, (19.4, 0.0), 3.8, 95),
    ('fa_farmacia_norte', (10.8, 5.2), 1.7, (10.6, 0.0), 3.8, 95), ('fa_ladrillo', (3.4, 5.0), 1.7, (2.9, 0.0), 3.2, 85),
    ('fa_esquina', (40.0, 2.5), 1.7, (27.0, -1.0), 3.5, 70), ('fa_colon', (35.6, -6.2), 1.7, (31.2, -4.7), 3.0, 95),
    ('fa_desde_norte', (-5.0, 3.6), 1.7, (12.0, 0.0), 4.0, 70), ('fa_desde_sur', (33.0, 4.6), 1.7, (16.0, 0.0), 4.2, 75),
    ('fa_aire', (15.0, 24.0), 26.0, (15.0, -4.0), 3.0, 60), ('fa_puerta', (19.6, 4.2), 1.7, (18.2, 0.0), 1.9, 60),
]


def p(x, z):
    return O[0] + U[0] * x + W[0] * z, O[1] + U[1] * x + W[1] * z


if __name__ == '__main__':
    only = set(sys.argv[1:])
    out = []
    for n, e, h, t, th, fov in VIEWS:
        if only and n not in only:
            continue
        a, b = p(*e), p(*t)
        out.append('%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%d' % (n, a[0], a[1], h, b[0], b[1], th, fov))
    print('vistas=' + ';'.join(out))
