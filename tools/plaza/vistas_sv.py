"""The Street View shots of the Plaza del Ayuntamiento that the game is compared with: where each was taken from (as
corrected: Google's own positions for the 2013 run inside the square are 2 m off), its heading, pitch and field of view.

    python tools/plaza/vistas_sv.py            prints the --vistas argument for the self-test
    python tools/plaza/vistas_sv.py hoja OUT.jpg FOTOS name ...     Street View | game, side by side (FOTOS: the folder
                                                                    with the screenshots, which are not kept in the repository)

Shots from inside the square are given in its own frame (pz_...: u along the town hall, n out from it, heights over its
floor); shots from the streets round it, on the map (sv_...: the camera 2.5 m over the street).

The S_... shots are from a private contributor's photosphere (January 2020), stitched by a phone: its bearings are out
by up to 4 degrees from one part of the sphere to another, so each of those views carries its own heading, set by what
it shows; nothing was measured from it that the aerial photograph could give."""
import math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
M = (-162.26, -72.25); U = (0.9049, 0.4256); N = (-U[1], U[0])
UB = math.degrees(math.atan2(U[0], -U[1]))          # the compass bearing of +u (115.2)

# name: (file, kind, x or u, z or n, camera height, heading, pitch, fov)
VIEWS = {
    'A_frente':     ('A_025_p5.jpg',       'pz', -6.2,   8.7,  2.56,  25,  5, 90),
    'A_oeste':      ('A_330_p8.jpg',       'pz', -6.2,   8.7,  2.56, 330,  8, 90),
    'A_este':       ('A_080_p8.jpg',       'pz', -6.2,   8.7,  2.56,  80,  8, 90),
    'A_jardin':     ('A_205_p2.jpg',       'pz', -6.2,   8.7,  2.56, 205,  2, 90),
    'A_ajedrez':    ('A_265_p2.jpg',       'pz', -6.2,   8.7,  2.56, 265,  2, 90),
    'A_parterres':  ('A_145_p2.jpg',       'pz', -6.2,   8.7,  2.56, 145,  2, 90),
    'C_frente':     ('C_025_p8.jpg',       'pz', 21.7,  18.3,  2.56,  25,  8, 90),
    'C_jardin':     ('ipm_C_250.jpg',      'pz', 21.7,  18.3,  2.56, 250, -15, 75),
    'C_zaragoza':   ('ipm_C_160.jpg',      'pz', 21.7,  18.3,  2.56, 160, -15, 75),
    'S_frente':     ('S_034_p5_f45.jpg',   'pz', -6.9,  48.65, 1.3,  26.0,  5, 45),
    'S_fuente':     ('S_115_p0.jpg',       'pz', -6.9,  48.65, 1.3, 110.9,  0, 90),
    'S_sur':        ('S_200_p0.jpg',       'pz', -6.9,  48.65, 1.3, 195.9,  0, 90),
    'S_bar':        ('S_270_p0.jpg',       'pz', -6.9,  48.65, 1.3, 265.9,  0, 90),
    'S_juegos':     ('S_335_p2.jpg',       'pz', -6.9,  48.65, 1.3, 330.9,  2, 90),
    'S_templete':   ('S_208_p3_f50.jpg',   'pz', -6.9,  48.65, 1.3, 203.9,  3, 50),
    'W1_esquina':   ('W1_115_p5.jpg',      'sv', -198.97, -86.79, 2.5, 115, 5, 90),
    'W2_escalera':  ('W2_110_p5.jpg',      'sv', -217.18, -51.62, 2.5, 110, 5, 90),
    'SW_templete':  ('SW_055_p5.jpg',      'sv', -229.00,   5.87, 2.5,  55, 5, 90),
    'S1_cesped':    ('S1_019_p5.jpg',      'sv', -189.01,   4.41, 2.5,  19, 5, 90),
    'SE_esquina':   ('SE_333_p5.jpg',      'sv', -156.46,   2.48, 2.5, 333, 5, 90),
    'E_testero':    ('E_301_p5.jpg',       'sv', -129.74, -56.95, 2.5, 301, 5, 90),
}

def entry(name):
    f, kind, x, z, hc, head, pitch, fov = VIEWS[name]
    d = 30.0
    p = math.radians(pitch)
    if kind == 'pz':
        b = math.radians(head - UB)
        return 'pz_%s:%.2f,%.2f,%g,%.2f,%.2f,%.2f,%g' % (name, x, z, hc, x + d * math.cos(p) * math.cos(b), z + d * math.cos(p) * math.sin(b), hc + d * math.sin(p), fov)
    h = math.radians(head)
    return 'sv_%s:%.2f,%.2f,%g,%.2f,%.2f,%.2f,%g' % (name, x, z, hc, x + d * math.sin(h) * math.cos(p), z - d * math.cos(h) * math.cos(p), hc + d * math.sin(p), fov)

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'hoja':
        from PIL import Image, ImageDraw, ImageFont
        out, fotos, names = sys.argv[2], sys.argv[3], sys.argv[4:]
        shots = os.path.join(HERE, '..', '..', 'godot', 'shots')
        w, h = 560, 420
        sheet = Image.new('RGB', (2 * w + 6, len(names) * (h + 26)), (24, 24, 26)); d = ImageDraw.Draw(sheet)
        try: font = ImageFont.truetype('arial.ttf', 17)
        except Exception: font = ImageFont.load_default()
        for i, n in enumerate(names):
            a = Image.open(os.path.join(fotos, VIEWS[n][0])).convert('RGB')
            b = Image.open(os.path.join(shots, 'vista_%s_%s.png' % (VIEWS[n][1], n))).convert('RGB')
            bw = int(b.height * a.width / a.height); x0 = (b.width - bw) // 2          # (the game's shot is 16:9 with the same vertical field: cut to the screenshot's 4:3)
            b = b.crop((x0, 0, x0 + bw, b.height))
            y = i * (h + 26)
            sheet.paste(a.resize((w, h), Image.LANCZOS), (0, y + 24)); sheet.paste(b.resize((w, h), Image.LANCZOS), (w + 6, y + 24))
            d.text((6, y + 3), 'Street View  ' + n, fill=(240, 240, 240), font=font); d.text((w + 12, y + 3), 'juego', fill=(240, 240, 240), font=font)
        sheet.save(out, quality=88); print(out, sheet.size)
    else:
        names = sys.argv[1:] or list(VIEWS)
        print('--vistas=' + ';'.join(entry(n) for n in names))
