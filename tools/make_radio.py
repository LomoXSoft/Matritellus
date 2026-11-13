"""Sets up godot/radio/: one folder per station of the car radio (radio1, radio2, ...), each with

    emisora.json    {"nombre": ..., "descripcion": ...}      <- edit these by hand
    logo.png        shown at the bottom of the screen for a few seconds when you tune in
    *.ogg *.mp3 *.wav   whatever is in the folder is what the station plays, in name order, round and round

Run once (python tools/make_radio.py). It never overwrites an emisora.json or a logo.png that is already there, so it
is safe to run again after adding a station to STATIONS below; it moves the placeholder tunes out of assets/audio.
"""
import json, os, shutil
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', 'godot', 'radio')
OLD = os.path.join(HERE, '..', 'godot', 'assets', 'audio')

STATIONS = [        # five (the user's call, Nov 2026); four more are set aside in godot/radio/_reserva
    ('Los 40 Secundarios', 'Los éxitos de ayer y hoy... aunque más de ayer.', (0xf2, 0x7a, 0x12)),      # name, words and logo are the user's
    ('Traktor FM', 'Más Metal que en los arados de tu abuelo.', (0x2f, 0x8f, 0x5b)),                       # name and words are the user's
    ('Onda Azafrán', 'Clásica. La pone el notario y nadie se atreve a cambiarla.', (0x7d, 0x3f, 0xc4)),
    ('Radio Parroquia', 'El rosario, los avisos y la tómbola. Don Anselmo al aparato.', (0x6a, 0x4a, 0x2c)),
    ('Rap-A-Polvo', 'Rap y hip hop de secano. Rimas con más polvo que el camino de la era.', (0xbe, 0x34, 0x2e)),      # the user's name
]

LEEME = """EMISORAS DE LA RADIO DEL COCHE
==============================

Cada carpeta radio1, radio2, radio3... es una emisora. El juego las lee al arrancar, por orden, hasta que falta un
número: para añadir una emisora nueva basta con crear la carpeta siguiente (radio9, radio10...).

Dentro de cada carpeta:

  emisora.json   El nombre y la descripción de la emisora. Se edita con el Bloc de notas:
                     {
                       "nombre": "Radio Matritellus",
                       "descripcion": "La del pueblo. Esquelas, el tiempo y quién ha aparcao mal."
                     }
                 (Ojo con las comillas y la coma entre las dos líneas. Si el fichero está mal escrito, la emisora
                 sale como «Radio 3» sin descripción, y el juego sigue.)

  logo.png       El logo. Sale unos segundos abajo en pantalla, junto al nombre y la descripción, al cambiar de
                 emisora. Cuadrado, mejor de 256 x 256 o más. Si falta, sale solo el texto.

  la música      Cualquier fichero .ogg, .mp3 o .wav que haya en la carpeta. Si hay varios suenan uno detrás de otro
                 por orden alfabético y vuelta a empezar (ponles 01_, 02_... delante para ordenarlos). Si solo hay uno,
                 suena en bucle. Los «provisional.wav» son los de relleno: bórralos cuando metas los buenos.
                 El nombre del fichero (sin el número de delante) es lo que sale en pantalla como canción que
                 suena: «01_Körnamenta - La Tijera.ogg» se anuncia como «Körnamenta - La Tijera».

La carpeta _reserva guarda emisoras que de momento no suenan (Radio Matritellus, Kiss Mancha, Radio Olé Tú, Cadena
Pipa), con su nombre, descripción y logo. Para recuperar una: cópiala fuera con el número siguiente (radio5, por
ejemplo) y métele música.

No hace falta tocar nada más: ni el código ni el editor de Godot.
"""

def font(size):
    for name in ('ariblk.ttf', 'arialbd.ttf'):
        try:
            return ImageFont.truetype(os.path.join(os.environ.get('WINDIR', r'C:\\Windows'), 'Fonts', name), size)
        except OSError:
            pass
    return ImageFont.load_default()

def logo(path, name, colour):
    s = 4
    im = Image.new('RGBA', (256 * s, 256 * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([8 * s, 8 * s, 248 * s, 248 * s], radius=44 * s, fill=colour + (255,), outline=(74, 52, 36, 255), width=8 * s)
    for k in range(3):                                  # the waves of a radio, top right
        r = (34 + k * 26) * s
        d.arc([196 * s - r, 60 * s - r, 196 * s + r, 60 * s + r], 100, 170, fill=(255, 246, 224, 255), width=7 * s)
    d.ellipse([186 * s, 50 * s, 206 * s, 70 * s], fill=(255, 246, 224, 255))
    words = [w for w in name.replace('Radio ', 'R ').split() if w]
    letters = ''.join(w[0] for w in words)[:3].upper() if not name[:1].isdigit() else name.split()[1][:2]
    f = font(104 * s if len(letters) < 3 else 84 * s)
    box = d.textbbox((0, 0), letters, font=f)
    d.text(((256 * s - (box[2] - box[0])) / 2 - box[0], 150 * s - (box[3] - box[1]) / 2 - box[1]), letters, font=f, fill=(255, 246, 224, 255))
    im.resize((256, 256), Image.LANCZOS).save(path)

def main():
    os.makedirs(ROOT, exist_ok=True)
    open(os.path.join(ROOT, '.gdignore'), 'w').close()           # Godot leaves the folder alone: the game reads the files as they are
    with open(os.path.join(ROOT, 'LEEME.txt'), 'w', encoding='utf8', newline='\r\n') as f:
        f.write(LEEME)
    for i, (name, about, colour) in enumerate(STATIONS, 1):
        d = os.path.join(ROOT, 'radio%d' % i)
        os.makedirs(d, exist_ok=True)
        card = os.path.join(d, 'emisora.json')
        if not os.path.exists(card):
            with open(card, 'w', encoding='utf8', newline='\r\n') as f:
                json.dump({'nombre': name, 'descripcion': about}, f, ensure_ascii=False, indent=2)
        pic = os.path.join(d, 'logo.png')
        if not os.path.exists(pic):
            logo(pic, name, colour)
        old = os.path.join(OLD, 'radio_%d.wav' % i)
        if os.path.exists(old):
            shutil.move(old, os.path.join(d, 'provisional.wav'))
            if os.path.exists(old + '.import'):
                os.remove(old + '.import')
        print('radio%d  %-18s %s' % (i, name, sorted(f for f in os.listdir(d))))

if __name__ == '__main__':
    main()
