"""The night wind of the cemetery: three gusts, made here from noise (no recording), for zonas.gd.

Luis, 25/11/2026: «De noche quita la música chill que tenemos y deja solo el leve sonido del viento de vez en cuando.
Que dé algo de mal rollo».

Each gust is brown noise through a resonant band-pass whose middle wanders slowly (the howl), with a little hiss of
higher noise over it. It swells for a few seconds, holds, and dies away; the ends are silent, so it can start and
stop at any time. Mono, 22050 Hz, 16 bits.

usage: python tools/cementerio/viento.py      -> godot/assets/cementerio/viento_0.wav, _1, _2 (import them after)
"""
import math
import os
import wave

import numpy as np

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "godot", "assets", "cementerio")


def smooth_curve(rng, n, knots, lo, hi):
    """a slow wandering curve of n samples through `knots` random points between lo and hi"""
    xs = np.linspace(0, n - 1, knots)
    ys = rng.uniform(lo, hi, knots)
    curve = np.interp(np.arange(n), xs, ys)
    k = int(RATE * 0.4)                                         # (soften its corners)
    kernel = np.hanning(k)
    kernel /= kernel.sum()
    return np.convolve(np.pad(curve, (k, k), mode="edge"), kernel, mode="same")[k:-k]


def bandpass(x, centre, q):
    """a state-variable band-pass, its middle (Hz) a curve over time"""
    y = np.zeros_like(x)
    low = band = 0.0
    for i in range(len(x)):
        f = 2.0 * math.sin(math.pi * centre[i] / RATE)
        high = x[i] - low - q * band
        band += f * high
        low += f * band
        y[i] = band
    return y


def gust(seed, seconds):
    rng = np.random.default_rng(seed)
    n = int(RATE * seconds)
    white = rng.standard_normal(n)
    brown = np.cumsum(white)
    brown -= np.convolve(brown, np.ones(2048) / 2048, mode="same")      # (keep it from drifting off)
    brown /= np.max(np.abs(brown)) + 1e-9
    centre = smooth_curve(rng, n, 7, 260.0, 720.0)
    howl = bandpass(brown, centre, 0.22)
    howl /= np.max(np.abs(howl)) + 1e-9
    hiss = bandpass(white, smooth_curve(rng, n, 5, 1800.0, 3200.0), 0.9)
    hiss /= np.max(np.abs(hiss)) + 1e-9
    t = np.arange(n) / n
    rise = rng.uniform(0.25, 0.4)
    fall = rng.uniform(0.55, 0.7)
    env = np.where(t < rise, (t / rise) ** 1.6, np.where(t > fall, ((1.0 - t) / (1.0 - fall)) ** 1.4, 1.0))
    env *= smooth_curve(rng, n, 9, 0.6, 1.0)                           # (it breathes)
    sig = env * (0.85 * howl + 0.18 * hiss * env)
    sig /= np.max(np.abs(sig)) + 1e-9
    return (sig * 0.8 * 32767).astype(np.int16)


def main():
    os.makedirs(OUT, exist_ok=True)
    for k, (seed, secs) in enumerate([(1906, 9.0), (2511, 11.5), (777, 7.5)]):
        data = gust(seed, secs)
        path = os.path.join(OUT, "viento_%d.wav" % k)
        with wave.open(path, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(data.tobytes())
        print(path, "%.1f s" % secs)


if __name__ == "__main__":
    main()
