"""Cuts the downloaded vehicle sounds (tools/sonidos_origen/, see CREDITOS.txt there) into what the game uses:
godot/assets/audio/vehiculos/*.ogg

    python tools/sonidos_vehiculos.py

  horns     each blast cut out on its own (where a recording has several, several), silence trimmed, faded in and out
            in a few milliseconds, all brought to the same peak
  skids     the short screeches the same way; and a steady stretch of a long squeal made into a seamless loop
  engines   a steady stretch of each recording (the quietest, most even few seconds where the engine is running)
            made into a seamless loop: its last quarter of a second is blended into its first. The game raises its
            pitch with the revs.

Needs ffmpeg on the PATH and numpy.
"""
import os, subprocess, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'sonidos_origen')
OUT = os.path.join(os.path.dirname(HERE), 'godot', 'assets', 'audio', 'vehiculos')
RATE = 44100


def load(name):
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', os.path.join(SRC, name), '-ac', '1', '-ar', str(RATE), '-f', 'f32le', '-'],
                         stdout=subprocess.PIPE, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).copy()


def save(x, name):
    os.makedirs(OUT, exist_ok=True)
    pcm = (np.clip(x, -1.0, 1.0) * 32767.0).astype('<i2').tobytes()
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 's16le', '-ar', str(RATE), '-ac', '1', '-i', '-', '-c:a', 'libvorbis', '-q:a', '5',
                    os.path.join(OUT, name + '.ogg')], input=pcm, check=True)
    print('%-22s %5.2f s' % (name, len(x) / RATE))


def env(x, win=0.02):
    n = max(1, int(win * RATE))
    k = len(x) // n
    return np.sqrt((x[:k * n].reshape(k, n) ** 2).mean(axis=1) + 1e-12), n


def segments(x, below_db=26.0, min_len=0.12, gap=0.09):
    """the stretches louder than `below_db` under the loudest moment: [(start, end) in samples]"""
    e, n = env(x)
    on = 20 * np.log10(e) > 20 * np.log10(e.max()) - below_db
    out, start, quiet = [], None, 0
    for i, v in enumerate(on):
        if v:
            if start is None:
                start = i
            quiet = 0
        elif start is not None:
            quiet += 1
            if quiet * n / RATE > gap:
                end = i - quiet + 1
                if (end - start) * n / RATE >= min_len:
                    out.append((start * n, end * n))
                start, quiet = None, 0
    if start is not None and (len(on) - start) * n / RATE >= min_len:
        out.append((start * n, len(on) * n))
    return out


def one_shot(x, seg, longest=2.5, peak=0.85):
    a, b = seg
    pad = int(0.02 * RATE)
    a, b = max(0, a - pad), min(len(x), b + pad, a + pad + int(longest * RATE))
    y = x[a:b].copy()
    f = min(int(0.012 * RATE), len(y) // 4)
    y[:f] *= np.linspace(0, 1, f)
    tail = min(int(0.06 * RATE), len(y) // 3)
    y[-tail:] *= np.linspace(1, 0, tail)
    return y * (peak / max(1e-6, np.abs(y).max()))


def loop(x, seconds, fade=0.25, level=0.12, skip=0.0):
    """the steadiest `seconds` of x (where it is running, not starting or stopping), as a seamless loop"""
    L, F = int(seconds * RATE), int(fade * RATE)
    if len(x) < L + F:
        L = len(x) - F
    e, n = env(x, 0.05)
    w = max(1, L // n)
    best, best_cost = 0, 1e9
    top = np.percentile(e, 90)
    first = int(skip * RATE) // n
    for i in range(first, len(e) - w - F // n):
        win = e[i:i + w]
        if win.mean() < top * 0.35:          # (not the silence before it starts or after it stops)
            continue
        cost = win.std() / win.mean()
        if cost < best_cost:
            best, best_cost = i, cost
    a = best * n
    y = x[a:a + L].copy()
    tail = x[a + L:a + L + F]
    ramp = np.linspace(0, 1, len(tail))
    y[:len(tail)] = y[:len(tail)] * ramp + tail * (1 - ramp)
    rms = np.sqrt((y ** 2).mean())
    return y * (level / max(1e-6, rms))


def as_loop(x, level=0.12):
    """a recording that is a loop already: only brought to the same loudness"""
    rms = np.sqrt((x ** 2).mean())
    return x * (level / max(1e-6, rms))


def main():
    # --- horns ---
    for src, name, count in [('bigsoundbank/claxon_coche_1.ogg', 'claxon_coche_1', 1), ('bigsoundbank/claxon_coche_2.ogg', 'claxon_coche_2', 1),
                             ('freesound/claxon_coche_3.wav', 'claxon_coche_3', 1), ('freesound/claxon_coche_4.wav', 'claxon_coche_4', 1),
                             ('freesound/claxon_coche_5.wav', 'claxon_coche_5', 1), ('bigsoundbank/claxon_autobus.ogg', 'claxon_autobus', 1),
                             ('freesound/claxon_furgoneta_lluvia.wav', 'claxon_furgoneta', 2), ('freesound/claxon_pickup_varios.wav', 'claxon_pickup', 3),
                             ('freesound/claxon_aire_industrial.wav', 'claxon_aire', 1), ('freesound/claxon_tractor.wav', 'claxon_tractor', 1),
                             ('freesound/tractores_protesta.wav', 'claxon_tractor_protesta', 2), ('freesound/claxon_uga.wav', 'claxon_uga', 1)]:
        x = load(src)
        segs = segments(x)
        if not segs:
            print('!! nothing loud in', src)
            continue
        segs = sorted(segs, key=lambda s: -np.abs(x[s[0]:s[1]]).max())[:count]       # the loudest blasts
        for k, s in enumerate(sorted(segs)):
            save(one_shot(x, s, 1.6 if 'protesta' in src or 'pickup' in src else 2.5), name if count == 1 else '%s_%d' % (name, k + 1))
    # --- skids ---
    for k, src in enumerate(['bigsoundbank/frenazo_1.ogg', 'bigsoundbank/frenazo_2.ogg', 'bigsoundbank/frenazo_3.ogg', 'bigsoundbank/frenazo_4.ogg', 'freesound/frenazo_ruedas.aiff']):
        x = load(src)
        segs = segments(x, 30.0)
        if segs:
            s = (segs[0][0], segs[-1][1])
            save(one_shot(x, s, 3.0), 'frenazo_%d' % (k + 1))
    save(loop(load('bigsoundbank/derrape_largo.ogg'), 1.8, 0.3, 0.16), 'derrape_bucle_1')
    save(loop(load('freesound/derrape_chrysler.wav'), 1.6, 0.3, 0.16), 'derrape_bucle_2')
    # --- engines ---
    save(as_loop(load('freesound/motor_mini_ralenti.wav')), 'motor_mini')
    save(as_loop(load('freesound/motor_vw_t4_ralenti.wav')), 'motor_vw_t4')
    save(as_loop(load('freesound/motor_diesel_ralenti.wav')), 'motor_diesel')
    save(loop(load('freesound/motor_peugeot308_ralenti.wav'), 3.0), 'motor_peugeot308')
    save(loop(load('freesound/motor_maquinaria_ralenti.flac'), 3.0), 'motor_maquinaria')
    for src, name, secs, skip in [('bigsoundbank/motor_peugeot107.ogg', 'motor_peugeot107', 2.5, 6.0), ('bigsoundbank/motor_ford_courier.ogg', 'motor_ford_courier', 2.5, 2.0),
                                  ('bigsoundbank/motor_iveco_daily.ogg', 'motor_iveco', 2.5, 3.0), ('bigsoundbank/motor_tractor_pequeno.ogg', 'motor_tractor', 2.5, 0.0),
                                  ('bigsoundbank/motor_escape_roto.ogg', 'motor_escape_roto', 2.5, 6.0), ('bigsoundbank/motor_aston_martin.ogg', 'motor_aston', 1.5, 0.0)]:
        save(loop(load(src), secs, skip=skip), name)


if __name__ == '__main__':
    main()
