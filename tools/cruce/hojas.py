"""The sheets of the crossroads of the traffic lights shown to the user (guion/fotos/cruce/).

    python tools/cruce/hojas.py sopiss                 the game's own pictures of "Seguros Sopiss" -> guion/fotos/cruce/sopiss_01..04
    python tools/cruce/hojas.py clinica                those of the dental clinic -> guion/fotos/cruce/clinica_01..03
    python tools/cruce/hojas.py stana2 | mirador | beige   the white house, the house with the bay window, the house north of the Salvador
    python tools/cruce/hojas.py cruce                  the traffic lights, the mirror and the signs -> guion/fotos/cruce/cruce_01..05
    python tools/cruce/hojas.py sopiss OUT_FOLDER SV   the game beside Street View's pictures (SV: the folder
        tools/cruce/capturas.py wrote them to): other people's pictures, so OUT_FOLDER is NOT in the repository
        (the same with clinica)

The game's pictures: python tools/run_tests.py sopiss, python tools/run_tests.py clinica (godot/shots/).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
SHOTS = os.path.join(ROOT, 'godot', 'shots')
try:
    font = ImageFont.truetype('arial.ttf', 18)
except Exception:
    font = ImageFont.load_default()


def sheet(path, rows, w, h, cols):
    n = (len(rows) + cols - 1) // cols
    out = Image.new('RGB', (cols * w + (cols - 1) * 6, n * (h + 28)), (22, 22, 24))
    d = ImageDraw.Draw(out)
    for i, (label, im) in enumerate(rows):
        x, y = (i % cols) * (w + 6), (i // cols) * (h + 28)
        d.text((x + 6, y + 4), label, fill=(240, 240, 240), font=font)
        k = min(w / im.size[0], h / im.size[1])
        t = im.resize((int(im.size[0] * k), int(im.size[1] * k)), Image.LANCZOS)
        out.paste(t, (x + (w - t.size[0]) // 2, y + 28 + (h - t.size[1]) // 2))
    out.save(path, quality=88)
    print(path, out.size)


def shot(place, n):
    return Image.open(os.path.join(SHOTS, place + '_' + n + '.png')).convert('RGB')


def sopiss(argv):
    s = lambda n: shot('sopiss', n)
    if len(argv) > 1:
        out, sv = argv[0], argv[1]
        os.makedirs(out, exist_ok=True)
        r = lambda n: Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
        sheet(os.path.join(out, 'sopiss_comparacion.jpg'), [
            ('Street View 2024 · desde Santa Ana', r('a1_frente')), ('El juego · desde Santa Ana', s('santa_ana')),
            ('Street View 2024 · la planta baja', r('a1_bajo')), ('El juego · la planta baja', s('frente')),
            ('Street View 2024 · desde los Arcos', r('r1_sur')), ('El juego · desde los Arcos', s('cervantes')),
            ('Street View 2024 · el Salvador', r('s2_norte')), ('El juego · el Salvador', s('salvador')),
            ('Street View 2024 · la esquina norte', r('cn2_esquina')), ('El juego · la esquina norte', s('avenida_norte')),
        ], 800, 500, 2)
        return
    out = os.path.join(ROOT, 'guion', 'fotos', 'cruce')
    os.makedirs(out, exist_ok=True)
    sheet(os.path.join(out, 'sopiss_01_fachadas.jpg'), [
        ('Desde la calle de Santa Ana', s('santa_ana')), ('La planta baja, a la avenida', s('frente')),
        ('Desde los Arcos: la fachada a la calle Cervantes', s('cervantes')), ('La esquina de la avenida y el Salvador', s('avenida_norte')),
        ('La fachada al Salvador', s('salvador')), ('El portal de los pisos', s('portal')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'sopiss_02_oficina.jpg'), [
        ('Abierta: por el escaparate de la avenida', s('escaparate')), ('Cerrada (domingo): el mismo escaparate', s('escaparate_cerrado')),
        ('Abierta: por el ventanal del Salvador', s('salvador_cerca')), ('La puerta, con su cartel', s('puerta')),
        ('La oficina por dentro (nadie entra)', s('dentro')), ('Por dentro, desde el fondo', s('dentro_fondo')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'sopiss_03_tejado_y_noche.jpg'), [
        ('Desde el aire', s('aire')), ('Desde el aire, por detrás', s('aire_oeste')),
        ('De noche, cerrada', s('santa_ana_noche')), ('De noche con las luces dadas (solo para verlas)', s('santa_ana_noche_luz')),
        ('De noche, el escaparate con luz', s('escaparate_noche_luz')), ('De lejos, por Santa Ana', s('santa_ana_lejos')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'sopiss_04_neon.jpg'), [
        ('El letrero «Salamanquesa» de día: azul', s('neon')), ('De noche: neón amarillo', s('neon_noche')),
        ('Desde Santa Ana, de día', s('santa_ana')), ('Desde Santa Ana, de noche', s('santa_ana_noche')),
    ], 800, 450, 2)


def clinica(argv):
    s = lambda n: shot('clinica', n)
    if len(argv) > 1:
        out, sv = argv[0], argv[1]
        os.makedirs(out, exist_ok=True)
        r = lambda n: Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
        sheet(os.path.join(out, 'clinica_comparacion.jpg'), [
            ('Street View 2024 · desde el cruce', r('d_cs_esquina')), ('El juego · desde el cruce', s('cruce')),
            ('Street View 2024 · a los Arcos', r('d_r1_este')), ('El juego · a los Arcos', s('este')),
            ('Street View 2024 · a la calle Cervantes', r('d_t1_norte')), ('El juego · a la calle Cervantes', s('cervantes')),
            ('Street View 2024 · la calle Cervantes hacia el oeste', r('d_cs_norte')), ('El juego · la calle Cervantes hacia el oeste', s('cruce_lejos')),
            ('Street View 2024 · desde los Arcos', r('d_r2_este')), ('El juego · desde los Arcos', s('arcos')),
        ], 800, 500, 2)
        return
    out = os.path.join(ROOT, 'guion', 'fotos', 'cruce')
    os.makedirs(out, exist_ok=True)
    sheet(os.path.join(out, 'clinica_01_fachadas.jpg'), [
        ('Desde el cruce', s('cruce')), ('La esquina', s('esquina')),
        ('La fachada a los Arcos', s('este')), ('La fachada a la calle Cervantes', s('cervantes_este')),
        ('Desde los Arcos', s('arcos')), ('Desde la calle Cervantes, por el oeste', s('oeste')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'clinica_02_detalles.jpg'), [
        ('Las letras y la puerta de la clínica', s('letras')), ('El portal de la casa, con su cortina', s('puerta_casa')),
        ('El piso de arriba, a los Arcos', s('este_alto')), ('El piso de arriba, a la calle Cervantes', s('cervantes_alto')),
        ('Desde el aire', s('aire')), ('Desde el aire, por el sur', s('aire_sur')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'clinica_03_horario_y_noche.jpg'), [
        ('Abierta (martes a mediodía)', s('cruce')), ('Cerrada (domingo)', s('cruce_cerrado')),
        ('De noche', s('cruce_noche')), ('De noche: las letras iluminadas', s('letras_noche')),
    ], 800, 450, 2)


def stana2(argv):
    s = lambda n: shot('stana2', n)
    if len(argv) > 1:
        out, sv = argv[0], argv[1]
        os.makedirs(out, exist_ok=True)
        r = lambda n: Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
        sheet(os.path.join(out, 'stana2_comparacion.jpg'), [
            ('Street View 2024 · la fachada a Santa Ana', r('e_a1_frente')), ('El juego · la fachada a Santa Ana', s('santa_ana')),
            ('Street View 2024 · desde el cruce', r('e_cs_esquina')), ('El juego · desde el cruce', s('cruce')),
            ('Street View 2024 · hacia el este', r('e_a1_este')), ('El juego · el portón y las ventanas', s('porton')),
            ('Street View 2024 · la fachada a los Arcos', r('e_t1_oeste')), ('El juego · la fachada a los Arcos', s('arcos')),
        ], 800, 500, 2)
        return
    out = os.path.join(ROOT, 'guion', 'fotos', 'cruce')
    os.makedirs(out, exist_ok=True)
    sheet(os.path.join(out, 'stana2_01_fachadas.jpg'), [
        ('Desde el cruce', s('cruce')), ('La fachada a Santa Ana', s('santa_ana')),
        ('El portón y las ventanas con reja', s('porton')), ('Las ventanas de arriba y la cornisa', s('ventanas')),
        ('La fachada a los Arcos', s('arcos')), ('Por Santa Ana, desde el este', s('santa_ana_este')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'stana2_02_tejado_y_noche.jpg'), [
        ('Desde el aire', s('aire')), ('Desde el aire, por el este: el patio y la construcción del fondo', s('aire_este')),
        ('De noche, desde el cruce', s('cruce_noche')), ('De noche, a Santa Ana', s('santa_ana_noche')),
    ], 800, 450, 2)


def mirador(argv):
    s = lambda n: shot('mirador', n)
    if len(argv) > 1:
        out, sv = argv[0], argv[1]
        os.makedirs(out, exist_ok=True)
        r = lambda n: Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
        sheet(os.path.join(out, 'mirador_comparacion.jpg'), [
            ('Street View 2024 · desde el cruce', r('f_cs_esquina')), ('El juego · desde el cruce', s('cruce')),
            ('Street View 2024 · el portal y el mirador', r('f_cn_esquina')), ('El juego · el portal y el mirador', s('portal')),
            ('Street View 2024 · la fachada a la avenida', r('f_cn2_oeste')), ('El juego · la fachada a la avenida', s('avenida')),
            ('Street View 2024 · la fachada a Santa Ana', r('f_a1_sur')), ('El juego · la fachada a Santa Ana', s('santa_ana')),
        ], 800, 500, 2)
        return
    out = os.path.join(ROOT, 'guion', 'fotos', 'cruce')
    os.makedirs(out, exist_ok=True)
    sheet(os.path.join(out, 'mirador_01_fachadas.jpg'), [
        ('Desde el cruce', s('cruce')), ('El portal del chaflán', s('portal')),
        ('El mirador', s('mirador')), ('La fachada a la avenida', s('avenida')),
        ('La fachada a Santa Ana', s('santa_ana')), ('El portón de arco', s('porton')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'mirador_02_tejado_y_noche.jpg'), [
        ('Desde el aire', s('aire')), ('Desde el aire, por el este: el patio', s('aire_este')),
        ('De noche, desde el cruce', s('cruce_noche')), ('De noche, a la avenida', s('avenida_noche')),
    ], 800, 450, 2)


def beige(argv):
    s = lambda n: shot('beige', n)
    if len(argv) > 1:
        out, sv = argv[0], argv[1]
        os.makedirs(out, exist_ok=True)
        r = lambda n: Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
        sheet(os.path.join(out, 'beige_comparacion.jpg'), [
            ('Street View 2024 · desde el cruce', r('g_cn_esquina')), ('El juego · desde el cruce', s('esquina')),
            ('Street View 2024 · la fachada a la avenida', r('g_cn2_oeste')), ('El juego · la fachada a la avenida', s('avenida')),
            ('Street View 2024 · el testero norte y la tapia', r('g_cn3_oeste')), ('El juego · el testero norte y la tapia', s('norte')),
            ('Street View 2024 · el Salvador hacia el cruce', r('g_s2_este')), ('El juego · el Salvador hacia el cruce', s('salvador_oeste')),
            ('Street View 2024 · el Salvador hacia el oeste', r('g_s1_oeste')), ('El juego · el Salvador hacia el oeste', s('salvador')),
        ], 800, 500, 2)
        return
    out = os.path.join(ROOT, 'guion', 'fotos', 'cruce')
    os.makedirs(out, exist_ok=True)
    sheet(os.path.join(out, 'beige_01_fachadas.jpg'), [
        ('Desde el cruce', s('cruce')), ('La esquina, desde Sopiss', s('esquina')),
        ('La fachada a la avenida', s('avenida')), ('El portal hondo', s('portal')),
        ('La fachada al Salvador', s('salvador')), ('El Salvador hacia el cruce', s('salvador_oeste')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'beige_02_detalles_y_tapia.jpg'), [
        ('Las ventanas de arriba, a la avenida', s('avenida_alto')), ('El pie del Salvador: reja de buche, trampilla y rejillas', s('salvador_bajo')),
        ('El testero norte y la tapia del solar', s('norte')), ('La cancela roja de la tapia', s('tapia')),
        ('La tapia, por la calle de Colón', s('colon')), ('De noche, desde el cruce', s('cruce_noche')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'beige_03_tejado.jpg'), [
        ('Desde el aire', s('aire')), ('Desde el aire, por el norte: el patio, el solar y su tapia', s('aire_norte')),
    ], 800, 450, 2)


def cruce(argv):
    s = lambda n: shot('cruce', n)
    if len(argv) > 1:
        out, sv = argv[0], argv[1]
        os.makedirs(out, exist_ok=True)
        r = lambda n: Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
        sheet(os.path.join(out, 'cruce_comparacion_1.jpg'), [
            ('Street View 2024 · bajando la avenida', r('x_cn2_sur')), ('El juego · bajando la avenida', s('llega_avenida')),
            ('Street View 2024 · por el Salvador', r('x_s2_este')), ('El juego · por el Salvador', s('llega_salvador')),
            ('Street View 2024 · por Santa Ana', r('x_a2_oeste')), ('El juego · por Santa Ana', s('llega_santa_ana')),
            ('Street View 2024 · subiendo los Arcos', r('x_r2_norte')), ('El juego · subiendo los Arcos', s('llega_arcos')),
        ], 800, 500, 2)
        sheet(os.path.join(out, 'cruce_comparacion_2.jpg'), [
            ('Street View 2024 · la esquina de la casa beige', r('x_cn_315')), ('El juego · la esquina de la casa beige', s('esquina_beige')),
            ('Street View 2024 · la esquina del mirador', r('x_cs_045')), ('El juego · la esquina del mirador', s('esquina_mirador')),
            ('Street View 2024 · la esquina de la casa blanca', r('x_cn_135')), ('El juego · la esquina de la casa blanca', s('esquina_stana')),
            ('Street View 2024 · la esquina de la clinica', r('x_cs_225')), ('El juego · la esquina de la clinica', s('esquina_clinica')),
            ('Street View 2024 · la esquina de Sopiss', r('x_cs_270')), ('El juego · la esquina de Sopiss', s('esquina_sopiss')),
        ], 800, 500, 2)
        return
    out = os.path.join(ROOT, 'guion', 'fotos', 'cruce')
    os.makedirs(out, exist_ok=True)
    sheet(os.path.join(out, 'cruce_01_llegadas.jpg'), [
        ('Bajando la avenida (verde)', s('llega_avenida')), ('Por el Salvador (rojo)', s('llega_salvador')),
        ('Por Santa Ana (rojo)', s('llega_santa_ana')), ('Subiendo los Arcos (verde)', s('llega_arcos')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'cruce_02_esquinas.jpg'), [
        ('La esquina de la casa beige', s('esquina_beige')), ('La esquina del mirador y el baculo', s('esquina_mirador')),
        ('La esquina de la casa blanca', s('esquina_stana')), ('La esquina de la clinica', s('esquina_clinica')),
        ('La esquina de Sopiss: el espejo', s('esquina_sopiss')), ('El poste del lado este de los Arcos', s('arcos_este')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'cruce_03_senales.jpg'), [
        ('El espejo', s('espejo')), ('El STOP bajo el espejo', s('stop_avenida')), ('El armario y el poste de la casa beige', s('armario')),
        ('Prohibido entrar al Salvador', s('prohibido_salvador')), ('El baculo sobre Santa Ana', s('baculo')), ('Ceda el paso y semaforo en Sopiss', s('salvador_ceda')),
        ('Prohibido aparcar, en la clinica', s('prohibido_aparcar')), ('Prohibido autobuses a Cervantes', s('bus')), ('Prohibido girar y STOP', s('giro')),
        ('Prohibido entrar a Santa Ana', s('prohibido_santa_ana')), ('Prohibido parar, en la avenida', s('prohibido_parar')), ('Desde el aire, por el norte', s('aire_norte')),
    ], 640, 360, 3)
    sheet(os.path.join(out, 'cruce_04_ciclo_y_noche.jpg'), [
        ('Desde el aire: lineas de detencion y pasos', s('aire')), ('La otra fase: el Salvador en verde', s('llega_salvador_fase2')),
        ('La otra fase: Santa Ana en verde', s('llega_santa_ana_fase2')), ('Ambar en los Arcos', s('llega_arcos_ambar')),
        ('De noche, subiendo los Arcos', s('llega_arcos_noche')), ('De noche, por Santa Ana', s('llega_santa_ana_noche')),
        ('De noche, la esquina de Sopiss', s('esquina_sopiss_noche')), ('De noche, la esquina del mirador', s('esquina_mirador_noche')),
    ], 800, 450, 2)
    sheet(os.path.join(out, 'cruce_05_roto.jpg'), [
        ('Un golpe: el poste de la casa blanca y su papelera, al suelo', s('esquina_stana_roto')), ('Roto: ambar por Santa Ana', s('llega_santa_ana_roto')),
        ('Roto: ambar subiendo los Arcos', s('llega_arcos_roto')), ('Roto: ambar en la esquina de Sopiss', s('esquina_sopiss_roto')),
        ('Arreglado: todo en pie otra vez', s('esquina_stana_arreglado')),
    ], 800, 450, 2)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'cruce':
        cruce(sys.argv[2:])
    elif len(sys.argv) > 1 and sys.argv[1] == 'beige':
        beige(sys.argv[2:])
    elif len(sys.argv) > 1 and sys.argv[1] == 'mirador':
        mirador(sys.argv[2:])
    elif len(sys.argv) > 1 and sys.argv[1] == 'stana2':
        stana2(sys.argv[2:])
    elif len(sys.argv) > 1 and sys.argv[1] == 'clinica':
        clinica(sys.argv[2:])
    elif len(sys.argv) > 1 and sys.argv[1] == 'sopiss':
        sopiss(sys.argv[2:])
    else:
        print(__doc__)
