"""The hum of the A-4 heard from the cemetery's zone: one loop, made here from noise (no recording), for autovia.gd.

Luis, 25/11/2026, of the things proposed after the review («El rumor de la A-4 cerca de su valla, hecho por programa
como el viento»): «Haz las 8».

The steady roar of a motorway a little way off: low noise (tyres and engines, most of it under 300 Hz) with a hiss of
tyres over it, swelling as a lorry or a few cars go by. It is made in the frequency domain (random phases, the shape
of its spectrum drawn by hand), so the loop's end runs into its beginning with no click; the swells are placed round
the loop the same way. Mono, 22050 Hz, 16 bits; its length a whole number of the frames Godot packs it in.

usage: python tools/cementerio/rumor.py      -> godot/assets/autovia/rumor.wav (import it after)
"""
import os
import wave

import numpy as np

RATE = 22050
FRAME = 5120                                                        # (a frame of Godot's packed sound: 256 slices of 20)
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "godot", "assets", "autovia")


def shaped_noise(rng, n, shape):
    """noise of n samples, periodic over them, its spectrum `shape` (a function of the frequency in Hz)"""
    freqs = np.fft.rfftfreq(n, 1.0 / RATE)
    spec = shape(freqs) * np.exp(1j * rng.uniform(0.0, 2.0 * np.pi, len(freqs)))
    spec[0] = 0.0
    x = np.fft.irfft(spec, n)
    return x / (np.max(np.abs(x)) + 1e-9)


def swells(rng, n, count, lo, hi, width):
    """bumps round the loop: `count` of them, each this high and this wide (a share of the loop)"""
    t = np.arange(n) / n
    env = np.zeros(n)
    for _ in range(count):
        c = rng.uniform()
        w = rng.uniform(*width)
        d = np.abs(t - c)
        d = np.minimum(d, 1.0 - d)                                  # (round the loop's ends)
        env += rng.uniform(lo, hi) * np.exp(-0.5 * (d / w) ** 2)
    return env


def hum(seed, seconds):
    rng = np.random.default_rng(seed)
    n = int(round(RATE * seconds / FRAME)) * FRAME
    roar = shaped_noise(rng, n, lambda f: (f / 70.0) ** 2 / (1.0 + (f / 70.0) ** 2) / (1.0 + (f / 240.0) ** 1.7) / (1.0 + (f / 1500.0) ** 3))
    hiss = shaped_noise(rng, n, lambda f: np.exp(-0.5 * ((np.log(f + 1.0) - np.log(1200.0)) / 0.5) ** 2))
    drone = shaped_noise(rng, n, lambda f: np.exp(-0.5 * ((f - 92.0) / 14.0) ** 2) + 0.6 * np.exp(-0.5 * ((f - 138.0) / 18.0) ** 2))
    lorries = swells(rng, n, 5, 0.25, 0.6, (0.035, 0.07))
    cars = swells(rng, n, 9, 0.15, 0.4, (0.012, 0.03))
    sig = roar * (0.62 + lorries) + drone * 0.5 * lorries + hiss * (0.1 + 0.35 * cars + 0.15 * lorries)
    sig /= np.max(np.abs(sig)) + 1e-9
    return (sig * 0.8 * 32767).astype(np.int16)


def main():
    os.makedirs(OUT, exist_ok=True)
    data = hum(4, 16.0)
    path = os.path.join(OUT, "rumor.wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print(path, "%.2f s, %d samples" % (len(data) / RATE, len(data)))


if __name__ == "__main__":
    main()
