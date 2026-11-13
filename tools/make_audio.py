"""Synthesises every music and ambience track of Matritellus from scratch (original material, no samples),
so the game owns all of its audio outright.

  pip install numpy
  python tools/make_audio.py        ->  godot/assets/audio/*.wav   (32 kHz, 16-bit mono)

These are placeholders with the right mood and structure; any of them can be swapped for a recorded track
by dropping a .wav of the same name in that folder.
"""
import math, os, wave
import numpy as np

SR = 32000
rng = np.random.default_rng(7)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'godot', 'assets', 'audio')
os.makedirs(OUT, exist_ok=True)

def save(name, x, peak=0.85):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1.0
    data = (x / m * peak * 32767).astype(np.int16)
    path = os.path.join(OUT, name + '.wav')
    if name.startswith('radio_'):                # the car radio's stations live in godot/radio/radioN (tools/make_radio.py)
        folder = os.path.join(OUT, '..', '..', 'radio', 'radio' + name[6:])
        if not os.path.isdir(folder) or any(f.lower().endswith(('.ogg', '.mp3')) for f in os.listdir(folder)):
            return                               # no such station, or it has real music now: no placeholder
        path = os.path.join(folder, 'provisional.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
    print('%-22s %5.1f s' % (name, len(x) / SR))

def hz(note):                                   # 'A4' -> 440
    names = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
    n = names[note[0]]; i = 1
    if note[i] == '#': n += 1; i += 1
    elif note[i] == 'b': n -= 1; i += 1
    return 440.0 * 2 ** ((n - 9 + (int(note[i:]) - 4) * 12) / 12)

def t_(dur): return np.arange(int(SR * dur)) / SR
def silence(dur): return np.zeros(int(SR * dur))
def put(buf, x, at, gain=1.0):                  # mix x into buf at time `at`, wrapping round so loops are seamless
    i = int(at * SR) % len(buf)
    n = len(x)
    if i + n <= len(buf): buf[i:i + n] += x * gain
    else:
        k = len(buf) - i
        buf[i:] += x[:k] * gain; buf[:n - k] += x[k:] * gain

def filt(x, lo=0.0, hi=1e9, slope=4):           # smooth band-pass in the frequency domain
    X = np.fft.rfft(x); f = np.fft.rfftfreq(len(x), 1 / SR)
    g = np.ones_like(f)
    if lo > 0: g *= 1 / np.sqrt(1 + (lo / np.maximum(f, 1e-6)) ** (2 * slope))
    if hi < SR / 2: g *= 1 / np.sqrt(1 + (f / hi) ** (2 * slope))
    return np.fft.irfft(X * g, len(x))

def env(n, a=0.01, d=0.1, s=0.7, r=0.1):
    e = np.ones(n) * s
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    na = min(na, n); e[:na] = np.linspace(0, 1, na)
    nd = min(nd, n - na)
    if nd > 0: e[na:na + nd] = np.linspace(1, s, nd)
    nr = min(nr, n)
    e[n - nr:] *= np.linspace(1, 0, nr)
    return e

def saw(f, dur, vib=0.0):
    t = t_(dur)
    ph = np.cumsum(f * (1 + vib * np.sin(2 * np.pi * 5.2 * t)) / SR)
    return 2 * (ph % 1.0) - 1

def brass(note, dur, vol=1.0):                  # cornet / trumpet section
    f = hz(note)
    x = saw(f, dur, 0.004) + 0.5 * saw(f * 1.003, dur, 0.004)
    x = filt(x, 180, 2400, 2) * env(len(x), 0.06, 0.12, 0.8, 0.12)
    return x * vol

def organ(note, dur, vol=1.0):
    f = hz(note); t = t_(dur)
    x = sum(a * np.sin(2 * np.pi * f * k * t) for k, a in [(1, 1), (2, .5), (3, .3), (4, .2), (6, .1)])
    return x * env(len(x), 0.05, 0.1, 0.9, 0.15) * vol

def keys(note, dur, vol=1.0):                   # soft electric piano
    f = hz(note); t = t_(dur)
    x = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t * 6) + 0.12 * np.sin(2 * np.pi * 3 * f * t) * np.exp(-t * 9)
    return x * np.exp(-t * 1.6) * env(len(x), 0.006, 0.05, 1.0, 0.08) * (1 + 0.08 * np.sin(2 * np.pi * 4.5 * t)) * vol

def bass(note, dur, vol=1.0):
    f = hz(note); t = t_(dur)
    return (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * 2 * f * t)) * env(len(t), 0.01, 0.1, 0.8, 0.06) * vol

def pluck(note, dur, vol=1.0, bright=0.5):      # Karplus-Strong nylon string
    f = hz(note); N = max(2, int(SR / f)); n = int(SR * dur)
    period = rng.uniform(-1, 1, N); period = filt(np.tile(period, 4), 0, 1500 + 5000 * bright, 2)[:N]
    out = np.zeros(n); cur = period.copy(); decay = 0.996
    for i in range(0, n, N):
        k = min(N, n - i); out[i:i + k] = cur[:k]
        cur = decay * 0.5 * (cur + np.roll(cur, -1))
    return out * env(n, 0.002, 0.02, 1.0, 0.05) * vol

def chug(note, dur, vol=1.0):                   # palm-muted distorted power chord
    f = hz(note)
    x = saw(f, dur) + saw(f * 1.5, dur) + 0.6 * saw(f * 2.0, dur)
    x = np.tanh(x * 3.5)
    x = filt(x, 90, 3200, 2) * env(len(x), 0.003, 0.05, 0.55, 0.02)
    return x * vol

def lead(note, dur, vol=1.0):                   # distorted lead guitar
    f = hz(note)
    x = np.tanh((saw(f, dur, 0.006) + 0.5 * saw(f * 2, dur, 0.006)) * 2.5)
    return filt(x, 200, 4200, 2) * env(len(x), 0.01, 0.08, 0.8, 0.06) * vol

def kick(vol=1.0, low=48):
    t = t_(0.22); f = low + 90 * np.exp(-t * 32)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 16) * vol
def snare(vol=1.0, dur=0.16):
    t = t_(dur)
    return (filt(rng.uniform(-1, 1, len(t)), 900, 7000) * np.exp(-t * 26) + 0.5 * np.sin(2 * np.pi * 185 * t) * np.exp(-t * 34)) * vol
def hat(vol=1.0, dur=0.05):
    t = t_(dur); return filt(rng.uniform(-1, 1, len(t)), 6000) * np.exp(-t * 70) * vol
def clap(vol=1.0):                              # palmas
    x = silence(0.09)
    for off in (0.0, 0.011, 0.023):
        t = t_(0.05); put(x, filt(rng.uniform(-1, 1, len(t)), 1100, 3600) * np.exp(-t * 60), off)
    return x * vol
def big_drum(vol=1.0):                          # bombo de procesión
    t = t_(0.7); f = 52 + 40 * np.exp(-t * 20)
    return (np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 5.5) + 0.2 * filt(rng.uniform(-1, 1, len(t)), 0, 400) * np.exp(-t * 30)) * vol

VOWELS = {'a': (760, 1250, 2600), 'e': (480, 1900, 2550), 'i': (300, 2250, 3000), 'o': (500, 950, 2500), 'u': (320, 800, 2400)}
def vowel(v, f0, dur, shape=1.0):
    t = t_(dur); x = np.zeros(len(t)); k = 1
    F = [q * shape for q in VOWELS[v]]
    while k * f0 < 3800:
        f = k * f0
        a = math.exp(-((f - F[0]) / 130) ** 2) + 0.6 * math.exp(-((f - F[1]) / 170) ** 2) + 0.25 * math.exp(-((f - F[2]) / 240) ** 2) + 0.03
        x += a * np.sin(2 * np.pi * f * t); k += 1
    return x * env(len(t), 0.02, 0.03, 0.9, 0.04)

def babble(dur, voices=6, density=5.0):         # people talking over each other: nothing you can make out
    buf = silence(dur)
    for _ in range(voices):
        f0 = rng.uniform(95, 240); shape = 1.0 if f0 < 160 else 1.15; t = rng.uniform(0, 1)
        while t < dur:
            for _ in range(int(rng.integers(2, 9))):                 # a phrase
                d = rng.uniform(0.07, 0.16)
                put(buf, vowel(rng.choice(list('aeiou')), f0 * rng.uniform(0.9, 1.15), d, shape), t, rng.uniform(0.4, 1.0))
                t += d * rng.uniform(0.9, 1.5)
            t += rng.uniform(0.2, 6.0 / density)
    return filt(buf, 150, 3200, 2)

# ================================ title: a slow procession march ================================
def title_march():
    bpm = 62; beat = 60 / bpm; bars = 16
    buf = silence(bars * 4 * beat)
    melody = [   # (note, beats) — an original tune in A minor with the raised seventh
        [('A4', 3), ('C5', 1)], [('B4', 2), ('G#4', 2)], [('A4', 1), ('B4', 1), ('C5', 1), ('D5', 1)], [('E5', 4)],
        [('F5', 3), ('E5', 1)], [('D5', 2), ('C5', 2)], [('B4', 1), ('C5', 1), ('B4', 1), ('A4', 1)], [('G#4', 2), ('E4', 2)],
        [('A4', 3), ('C5', 1)], [('E5', 2), ('D5', 2)], [('C5', 1), ('D5', 1), ('E5', 1), ('F5', 1)], [('E5', 4)],
        [('D5', 3), ('F5', 1)], [('E5', 2), ('C5', 2)], [('B4', 1.5), ('C5', 0.5), ('B4', 1), ('G#4', 1)], [('A4', 4)],
    ]
    chords = ['A2', 'E2', 'A2', 'E2', 'F2', 'D2', 'E2', 'E2', 'A2', 'C3', 'A2', 'E2', 'D2', 'A2', 'E2', 'A2']
    third = {'A4': 'F4', 'B4': 'G#4', 'C5': 'A4', 'D5': 'B4', 'E5': 'C5', 'F5': 'D5', 'G#4': 'E4', 'E4': 'C4'}
    for b in range(bars):
        t0 = b * 4 * beat; at = 0.0
        for note, n in melody[b]:
            put(buf, brass(note, n * beat * 0.96), t0 + at * beat, 0.8)
            put(buf, brass(third[note], n * beat * 0.96), t0 + at * beat, 0.45)
            at += n
        put(buf, brass(chords[b], 4 * beat * 0.98) + organ(chords[b], 4 * beat * 0.98) * 0.5, t0, 0.5)   # low brass
        put(buf, big_drum(), t0, 1.0); put(buf, big_drum(0.8), t0 + 2 * beat, 1.0)
        for k in range(4):                                           # the snare: steady steps, a roll into each bar
            put(buf, snare(0.5), t0 + k * beat, 0.6)
            put(buf, snare(0.3), t0 + (k + 0.5) * beat, 0.6)
        for k in range(12):
            put(buf, snare(0.12 + 0.03 * k, 0.07), t0 + 3 * beat + k * beat / 12, 0.6)
    return filt(buf, 40, 6000, 2)

# ================================ on foot: lo-fi ================================
def lofi():
    bpm = 74; beat = 60 / bpm; bars = 8
    buf = silence(bars * 4 * beat)
    prog = [(['F3', 'A3', 'C4', 'E4'], 'F2'), (['E3', 'G3', 'B3', 'D4'], 'E2'), (['D3', 'F3', 'A3', 'C4'], 'D2'), (['C3', 'E3', 'G3', 'B3'], 'C2')]
    sw = 0.58                                                        # swing
    for b in range(bars):
        notes, root = prog[(b // 2) % 4]; t0 = b * 4 * beat
        for i, nt in enumerate(notes):
            put(buf, keys(nt, 3.6 * beat), t0 + i * 0.03, 0.34)
        if b % 2 == 1:
            put(buf, keys(notes[2], 1.2 * beat), t0 + 2.5 * beat, 0.3); put(buf, keys(notes[3], 1.5 * beat), t0 + 3 * beat, 0.3)
        put(buf, bass(root, 1.6 * beat), t0, 0.7); put(buf, bass(root, 0.8 * beat), t0 + 2.5 * beat, 0.55)
        put(buf, kick(0.9), t0, 0.8); put(buf, kick(0.7), t0 + (2 + sw) * beat, 0.8)
        put(buf, snare(0.35, 0.2), t0 + beat, 0.5); put(buf, snare(0.35, 0.2), t0 + 3 * beat, 0.5)
        for k in range(4):
            put(buf, hat(0.25), t0 + k * beat, 0.4); put(buf, hat(0.15), t0 + (k + sw) * beat, 0.4)
    mel = ['A4', 'G4', 'E4', 'D4', 'E4', 'G4', 'A4', 'C5']
    for i, nt in enumerate(mel):
        put(buf, keys(nt, 2.5 * beat), (i * 4 + 1.5) * beat, 0.22)
    buf = filt(buf, 60, 3200, 2)
    crackle = (rng.uniform(0, 1, len(buf)) > 0.9994) * rng.uniform(-1, 1, len(buf))
    return buf + filt(crackle, 1500, 9000) * 0.25 + filt(rng.uniform(-1, 1, len(buf)), 300, 4000) * 0.004

# ================================ chase: flamenco meets metalcore ================================
def chase():
    bpm = 176; beat = 60 / bpm; bars = 16
    buf = silence(bars * 4 * beat)
    cadence = [('A2', ['A3', 'C4', 'E4']), ('G2', ['G3', 'B3', 'D4']), ('F2', ['F3', 'A3', 'C4']), ('E2', ['E3', 'G#3', 'B3'])]   # the Andalusian cadence
    phry = ['E4', 'F4', 'G#4', 'A4', 'B4', 'C5', 'D5', 'E5']
    for b in range(bars):
        root, tri = cadence[(b // 2) % 4]; t0 = b * 4 * beat; half = b >= 12            # last four bars: half-time breakdown
        for k in range(16):                                           # guitars: sixteenth-note chugs with accents
            if half and k % 4 not in (0, 3): continue
            acc = 1.0 if k % 4 == 0 else 0.6
            put(buf, chug(root, beat / 4 * (1.6 if half else 0.9), acc), t0 + k * beat / 4, 0.55)
        for k in range(16):                                           # double kick
            if not half or k % 8 in (0, 3, 6):
                put(buf, kick(0.9, 55), t0 + k * beat / 4, 0.75)
        for k in ([2] if half else [1, 3]):
            put(buf, snare(1.0, 0.2), t0 + k * beat, 0.9)
        for k in range(8):
            put(buf, hat(0.35), t0 + k * beat / 2, 0.45)
        # flamenco on top: palmas with off-beat accents, and a nylon guitar rolling the chord
        for k in (0, 1.5, 3, 4.5, 5.5, 7):
            if k / 2 < 4: put(buf, clap(1.0), t0 + k * beat / 2, 0.6)
        for k in range(8):
            put(buf, pluck(tri[k % 3], beat * 0.9, 1.0, 0.8), t0 + k * beat / 2, 0.5)
        if b % 2 == 1:                                                # rasgueo: the whole chord raked
            for i, nt in enumerate(tri + [tri[0]]):
                put(buf, pluck(nt, beat * 1.5, 1.0, 0.9), t0 + 3 * beat + i * 0.018, 0.55)
        if b % 4 == 3 or half:                                        # a Phrygian run on the lead guitar
            run = phry if b % 8 == 3 else phry[::-1]
            for i, nt in enumerate(run):
                put(buf, lead(nt, beat / 2 * 0.95), t0 + i * beat / 2, 0.32)
    return np.tanh(filt(buf, 45, 7000, 2) * 1.4)

# ================================ the fight: a brass fanfare over a marching beat ================================
def fight():
    bpm = 132; beat = 60 / bpm; bars = 16
    buf = silence(bars * 4 * beat)
    # an original heroic tune in C: rising calls, held answers
    tune = [
        [('C5', .5), ('C5', .5), ('E5', .5), ('G5', .5), ('C6', 2)], [('B5', .5), ('G5', .5), ('E5', .5), ('G5', .5), ('A5', 2)],
        [('F5', .5), ('F5', .5), ('A5', .5), ('C6', .5), ('D6', 2)], [('C6', 1), ('B5', 1), ('G5', 2)],
        [('C5', .5), ('C5', .5), ('E5', .5), ('G5', .5), ('C6', 2)], [('D6', .5), ('C6', .5), ('B5', .5), ('A5', .5), ('G5', 2)],
        [('A5', 1), ('B5', 1), ('C6', 1), ('D6', 1)], [('E6', 3), ('C6', 1)],
    ]
    roots = ['C2', 'A2', 'F2', 'G2', 'C2', 'G2', 'F2', 'C2']
    for b in range(bars):
        t0 = b * 4 * beat; at = 0.0
        for note, n in tune[b % 8]:
            put(buf, brass(note, n * beat * 0.92), t0 + at * beat, 0.75)
            if b >= 8: put(buf, brass(note.replace('5', '4').replace('6', '5'), n * beat * 0.92), t0 + at * beat, 0.4)     # octave doubling second time round
            at += n
        root = roots[b % 8]
        for k in range(8):                                           # driving bass in octaves
            put(buf, bass(root if k % 2 == 0 else root.replace('2', '3'), beat * 0.45), t0 + k * beat / 2, 0.6)
        put(buf, organ(root.replace('2', '3'), 4 * beat * 0.95), t0, 0.22)
        for k in range(4):
            put(buf, kick(1.0, 50), t0 + k * beat, 0.8)
            put(buf, hat(0.3), t0 + (k + 0.5) * beat, 0.4)
        for k in (1, 3):
            put(buf, snare(0.9, 0.18), t0 + k * beat, 0.8)
        if b % 4 == 3:                                               # a roll into the next phrase
            for k in range(8): put(buf, snare(0.2 + 0.08 * k, 0.07), t0 + 3 * beat + k * beat / 8, 0.7)
        put(buf, big_drum(0.9), t0, 0.5)                             # timpani on the one
    return filt(buf, 40, 7000, 2)

# ================================ radio stations (placeholders) ================================
def radio(x):                                    # squeeze it through a small dashboard speaker
    x = filt(x, 280, 3600, 3)
    return x / (np.max(np.abs(x)) or 1) + filt(rng.uniform(-1, 1, len(x)), 500, 5000) * 0.012

def pattern_song(bpm, prog, lead_notes, style):
    beat = 60 / bpm; bars = len(prog) * 2
    buf = silence(bars * 4 * beat)
    for b in range(bars):
        root, tri = prog[(b // 2) % len(prog)]; t0 = b * 4 * beat
        if style == 'pop':
            for k in range(4): put(buf, kick(), t0 + k * beat, 0.8)
            for k in (1, 3): put(buf, clap(0.8), t0 + k * beat, 0.6)
            for k in range(8):
                put(buf, hat(0.3), t0 + (k + 0.5) * beat / 2, 0.4)
                put(buf, keys(tri[k % 3].replace('3', '4'), beat * 0.45), t0 + k * beat / 2, 0.35)
            put(buf, bass(root, beat * 3.6), t0, 0.6)
        elif style == 'rock':
            for k in range(8): put(buf, chug(root, beat * 0.45, 1.0 if k % 2 == 0 else 0.7), t0 + k * beat / 2, 0.5)
            for k in (0, 2): put(buf, kick(), t0 + k * beat, 0.8)
            for k in (1, 3): put(buf, snare(1.0, 0.2), t0 + k * beat, 0.8)
            for k in range(8): put(buf, hat(0.3), t0 + k * beat / 2, 0.4)
        elif style == 'rumba':
            for k in (0, 1.5, 2, 3, 3.5):                              # the rumba strum
                for i, nt in enumerate(tri): put(buf, pluck(nt, beat * 0.8, 1.0, 0.8), t0 + k * beat + i * 0.012, 0.4)
            for k in (1, 2.5, 3): put(buf, clap(), t0 + k * beat, 0.5)
            put(buf, bass(root, beat * 1.4), t0, 0.5); put(buf, bass(root, beat), t0 + 2.5 * beat, 0.4)
        elif style == 'ballad':
            for i, nt in enumerate(tri + [tri[1]]): put(buf, keys(nt.replace('3', '4'), beat * 2.5), t0 + i * beat, 0.4)
            put(buf, bass(root, beat * 3.8), t0, 0.5)
        elif style == 'classical':
            for k in range(8):
                nt = tri[[0, 1, 2, 1][k % 4]].replace('3', '4')
                x = filt(saw(hz(nt), beat * 0.6, 0.004), 200, 2600, 2) * env(int(SR * beat * 0.6), 0.08, 0.1, 0.8, 0.2)
                put(buf, x, t0 + k * beat / 2, 0.3)
            put(buf, organ(root, beat * 3.9), t0, 0.25)
        if lead_notes and b % 2 == 0:
            for i in range(4):
                nt = lead_notes[(b * 2 + i) % len(lead_notes)]
                put(buf, (lead(nt, beat * 0.9) if style == 'rock' else keys(nt, beat * 1.5)), t0 + (i * 2 + 1) * beat, 0.3)
    return buf

def stations():
    C = [('C2', ['C3', 'E3', 'G3']), ('G2', ['G3', 'B3', 'D4']), ('A2', ['A3', 'C4', 'E4']), ('F2', ['F3', 'A3', 'C4'])]
    Am = [('A2', ['A3', 'C4', 'E4']), ('G2', ['G3', 'B3', 'D4']), ('F2', ['F3', 'A3', 'C4']), ('E2', ['E3', 'G#3', 'B3'])]
    Em = [('E2', ['E3', 'G3', 'B3']), ('C2', ['C3', 'E3', 'G3']), ('G2', ['G3', 'B3', 'D4']), ('D2', ['D3', 'F#3', 'A3'])]
    out = {}
    # 1 local chat show: a tertulia over a quiet bed
    bed = pattern_song(96, C, None, 'ballad')
    out['radio_1'] = babble(len(bed) / SR, 4, 6.0) * 1.0 + bed / (np.max(np.abs(bed)) or 1) * 0.12
    out['radio_2'] = pattern_song(122, C, ['E5', 'G5', 'A5', 'G5', 'E5', 'D5', 'C5', 'D5'], 'pop')
    out['radio_3'] = pattern_song(72, C[::-1], ['C5', 'E5', 'D5', 'C5'], 'ballad')
    out['radio_4'] = pattern_song(144, Em, ['E4', 'G4', 'A4', 'B4', 'D5', 'B4', 'A4', 'G4'], 'rock')
    out['radio_5'] = pattern_song(104, Am, None, 'rumba')
    out['radio_6'] = pattern_song(84, C, None, 'classical')
    # 7 rolling news: the time pips, then people being serious
    n = int(SR * 16); news = babble(16, 2, 4.0)
    for k in range(6):
        t = t_(0.5 if k == 5 else 0.1); put(news, np.sin(2 * np.pi * 1000 * t) * env(len(t), 0.005, 0.01, 1, 0.01), 0.5 + k * 1.0, 0.5)
    out['radio_7'] = news[:n]
    # 8 the parish station: one note, one voice, organ underneath
    par = silence(16)
    for k, nt in enumerate(['A2', 'A2', 'D3', 'A2']): put(par, organ(nt, 3.9), k * 4, 0.35)
    t = 0.3
    while t < 15.5:
        d = rng.uniform(0.22, 0.42); put(par, vowel(rng.choice(list('aeiou')), 131, d), t, 0.8); t += d * 1.05
        if rng.uniform() < 0.12: t += 0.7
    out['radio_8'] = par
    for name, x in out.items():
        save(name, radio(x), 0.7)

# ================================ ambience ================================
def crickets():
    buf = silence(6.0)
    for _ in range(5):
        f = rng.uniform(3900, 4700); rate = rng.uniform(1.6, 2.4); gain = rng.uniform(0.3, 1.0); t = rng.uniform(0, 0.5)
        while t < 6.0:
            for p in range(3):
                tt = t_(0.035); put(buf, np.sin(2 * np.pi * f * tt) * np.sin(np.pi * tt / 0.035) ** 2, t + p * 0.045, gain)
            t += 1 / rate
    return buf

def chirp(kind):
    if kind == 0:   t = t_(0.12); f = 3200 + 2200 * t / 0.12
    elif kind == 1: t = t_(0.16); f = 5200 - 2000 * t / 0.16
    elif kind == 2: t = t_(0.5);  f = 4200 + 500 * np.sign(np.sin(2 * np.pi * 14 * t))
    elif kind == 3: t = t_(0.3);  f = 3600 + 900 * np.sin(2 * np.pi * 9 * t)
    else:           t = t_(0.09); f = 2600 + 3000 * (t / 0.09) ** 2
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / t[-1]) ** 1.5
    if kind in (0, 4):
        x = np.concatenate([x, silence(0.06), x * 0.8, silence(0.05), x * 0.6])
    return x

def bark(kind):
    f0, dur, reps, gap = [(210, 0.16, 1, 0), (240, 0.13, 2, 0.16), (430, 0.09, 3, 0.11), (190, 0.9, 1, 0)][kind]
    out = silence(dur * reps + gap * reps + 0.1)
    for r in range(reps):
        t = t_(dur)
        f = f0 * (1.25 - 0.45 * t / dur) if kind < 3 else f0 * (1.0 + 0.5 * np.sin(np.pi * t / dur) - 0.3 * t / dur)
        ph = np.cumsum(f) / SR
        src = (2 * (ph % 1) - 1) + rng.uniform(-1, 1, len(t)) * (0.6 if kind < 3 else 0.2)
        x = filt(src, 350, 700, 2) * 1.0 + filt(src, 900, 1500, 2) * 0.8 + filt(src, 2000, 2800, 2) * 0.25
        e = np.sin(np.pi * t / dur) ** (0.5 if kind < 3 else 0.8)
        put(out, x * e, r * (dur + gap))
    # heard from a few streets away
    return filt(out, 250, 2600, 2)

if __name__ == '__main__':
    save('title_march', title_march())
    save('lofi', lofi(), 0.7)
    save('chase', chase(), 0.9)
    save('fight', fight(), 0.9)
    stations()
    save('crickets', crickets(), 0.6)
    save('murmur', babble(8.0, 9, 9.0), 0.6)
    for i in range(5): save('bird_%d' % i, chirp(i), 0.6)
    for i in range(4): save('dog_%d' % i, bark(i), 0.7)
