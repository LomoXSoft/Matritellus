"""The island of the hermitage of the Caridad photographed in the game: prints the vistas=... for tools/run_tests.py.

    python tools/caridad/vistas.py [name ...]

Each view: where the eye is and what it looks at, in the place's own frame (x along the hermitage's south side from its
south-west corner, z out towards the avenue), heights over the GROUND there (the square's floor is 1 to 2 m above it);
the last number is the vertical field of view.
"""
import sys
O = (-489.5, 141.2); U = (0.9984, -0.0564); W = (0.0564, 0.9984)
VIEWS = [
    ('ca_avenida', (12.0, 25.5), 1.7, (12.0, 0.0), 5.0, 75), ('ca_ermita', (11.5, 11.5), 3.2, (11.5, 0.0), 4.0, 75), ('ca_cruz', (25.5, 12.0), 3.3, (15.5, 2.0), 4.0, 70),
    ('ca_guarderia', (41.0, 9.5), 3.4, (38.5, -6.0), 4.2, 75), ('ca_peso', (61.5, 5.0), 1.7, (40.0, 0.0), 4.0, 70), ('ca_fuente', (-21.0, 12.0), 1.8, (-10.0, 3.0), 1.2, 70),
    ('ca_rollo', (31.0, -37.0), 1.7, (30.5, -28.0), 2.5, 80), ('ca_oeste', (-31.0, 19.0), 1.8, (4.0, 0.0), 4.0, 70), ('ca_aire', (10.0, 46.0), 40.0, (10.0, -6.0), 0.0, 60),
    ('ca_muro', (36.0, 21.0), 1.7, (20.0, 8.0), 3.0, 75),
    ('ca_poniente', (-15.0, -7.5), 1.7, (0.0, -6.5), 3.6, 75), ('ca_fuente2', (-18.5, 9.5), 1.7, (-10.2, 3.2), 0.9, 70), ('ca_paseo', (36.0, 4.5), 3.0, (8.0, 8.5), 2.6, 80),
    ('ca_patio', (36.0, 5.0), 3.0, (37.0, -6.0), 3.8, 85), ('ca_columnas', (-9.5, -16.5), 1.7, (-1.0, -9.0), 3.0, 75),
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
