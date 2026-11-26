"""Generates the Radio Patio car-radio station (godot/radio/radio7/) from guion/radio_patio.json
using Microsoft Edge neural TTS voices:
  - Wenceslao Carreño ("Wences", Madridejos):        es-ES-AlvaroNeural
  - María Justina de la Llave ("La Justi", Consuegra): es-ES-ElviraNeural

Production pipeline:
  1. Synthesises each line at native neural pitch (+0Hz, avoiding robotic DSP pitch-shift
     artefacts) with lively rate variations and conversational micro-overlaps.
  2. Applies a warm, natural broadcast studio voice chain (gentle warmth, de-harshing around
     3.6 kHz, subtle studio early reflections) on the voice bus alone.
  3. Composes one of three upbeat Spanish acoustic radio music beds (nylon guitar, walking bass,
     palmas/cajón, electric piano) with smooth dynamic sidechain ducking + vocal-band softening
     so voices sit crystal-clear on top while the music rises in pauses and transitions.
  4. Adds an FM dial tuning hook, energetic intro/outro sintonías, mid-show bumpers, and
     curated comedic SFX (mixing real Matritellus audio assets + crisp synthesized radio SFX).
  5. Masters to -15.5 LUFS (matching radio1..radio6) and encodes Ogg Vorbis (and optional MP3).

Usage:
    python tools/make_radio_patio.py                 # build emisora.json, logo.png and all programmes
    python tools/make_radio_patio.py --only 01 06    # rebuild only selected programme IDs
    python tools/make_radio_patio.py --mp3 01        # also export an MP3 preview in dist/
    python tools/make_radio_patio.py --no-cache      # ignore cached TTS lines
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import math
import re
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import edge_tts
import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
SCRIPT_JSON = ROOT / "guion" / "radio_patio.json"
RADIO_ROOT = ROOT / "godot" / "radio"
ASSETS_AUDIO = ROOT / "godot" / "assets" / "audio"
DIST_DIR = ROOT / "dist"
SR = 44100

# Expressive deltas: ONLY rate (%) and gentle gain (dB) — pitch stays +0Hz so Microsoft's
# neural voices never suffer metallic DSP pitch-shifting!
MOODS = {
    "normal":     (0,   0.0),
    "alegre":     (4,   0.3),
    "emocionada": (8,   0.6),
    "risa":       (6,   0.4),
    "indignada":  (5,   0.7),
    "sorpresa":   (5,   0.5),
    "susurro":    (-6, -2.8),
    "rapido":     (10,  0.3),
    "serio":      (-4,  0.0),
}


# ---------------------------------------------------------------------------
# TTS helpers
# ---------------------------------------------------------------------------

def _parse_signed_int(val: str, suffix: str) -> int:
    s = str(val).strip()
    if s.endswith(suffix):
        s = s[: -len(suffix)]
    return int(s)


def format_prosody(base_rate: str, mood: str) -> tuple[str, str, float]:
    dr, gain_db = MOODS.get(mood, MOODS["normal"])
    rate = _parse_signed_int(base_rate, "%") + dr
    rate = max(-15, min(22, rate))
    return f"{rate:+d}%", "+0Hz", gain_db


def tts_clean(text: str) -> str:
    """Prepare Manchego script text so Edge neural TTS reads contractions fluidly."""
    t = text
    t = t.replace("«", '"').replace("»", '"')
    t = re.sub(r"\bl'á\b", "le ha", t, flags=re.IGNORECASE)
    t = re.sub(r"\bla'é\b", "la he", t, flags=re.IGNORECASE)
    t = re.sub(r"\bd'ande\b", "de ande", t, flags=re.IGNORECASE)
    t = re.sub(r"\bpa'l\b", "pal", t, flags=re.IGNORECASE)
    t = re.sub(r"\bZ15\b", "zeta quince", t)
    t = re.sub(r"\b4L\b", "cuatro ele", t)
    t = re.sub(r"\s*—\s*", ", ", t)
    return t.strip()


async def synth_line(
    sem: asyncio.Semaphore,
    text: str,
    voice: str,
    rate: str,
    pitch: str,
    cache_dir: Path,
    use_cache: bool,
) -> Path:
    cleaned = tts_clean(text)
    key = hashlib.sha1(f"v2|{voice}|{rate}|{pitch}|{cleaned}".encode("utf-8")).hexdigest()[:16]
    mp3_path = cache_dir / f"{key}.mp3"
    if use_cache and mp3_path.exists() and mp3_path.stat().st_size > 512:
        return mp3_path

    async with sem:
        last_err: Exception | None = None
        for attempt in range(4):
            try:
                tmp = cache_dir / f"{key}.{attempt}.tmp.mp3"
                comm = edge_tts.Communicate(cleaned, voice=voice, rate=rate, pitch=pitch)
                await comm.save(str(tmp))
                if tmp.exists() and tmp.stat().st_size > 512:
                    tmp.replace(mp3_path)
                    return mp3_path
            except Exception as exc:  # pragma: no cover - network retry
                last_err = exc
                await asyncio.sleep(1.0 + attempt * 1.5)
        raise RuntimeError(f"Edge TTS failed for {cleaned!r}: {last_err}")


def decode_audio_mono(path: Path, max_sec: float | None = None) -> np.ndarray:
    cmd = ["ffmpeg", "-v", "error", "-i", str(path)]
    if max_sec is not None:
        cmd += ["-t", f"{max_sec:.3f}"]
    cmd += ["-f", "f32le", "-acodec", "pcm_f32le", "-ac", "1", "-ar", str(SR), "pipe:1"]
    res = subprocess.run(cmd, check=True, capture_output=True)
    return np.frombuffer(res.stdout, dtype=np.float32).copy()


def trim_silence(audio: np.ndarray, threshold: float = 0.009) -> np.ndarray:
    if audio.size == 0:
        return audio
    above = np.flatnonzero(np.abs(audio) > threshold)
    if above.size == 0:
        return audio[: int(0.05 * SR)]
    pad_head = int(0.018 * SR)
    pad_tail = int(0.045 * SR)
    start = max(0, int(above[0]) - pad_head)
    end = min(audio.size, int(above[-1]) + pad_tail)
    clip = audio[start:end].copy()
    fi = min(int(0.010 * SR), clip.size // 4)
    fo = min(int(0.020 * SR), clip.size // 4)
    if fi > 1:
        clip[:fi] *= np.linspace(0.0, 1.0, fi, dtype=np.float32)
    if fo > 1:
        clip[-fo:] *= np.linspace(1.0, 0.0, fo, dtype=np.float32)
    return clip


def level_voice(clip: np.ndarray, target_rms: float = 0.16, gain_db: float = 0.0) -> np.ndarray:
    if clip.size == 0:
        return clip
    active = clip[np.abs(clip) > 0.018]
    rms = float(np.sqrt(np.mean(active * active))) if active.size > 64 else float(np.sqrt(np.mean(clip * clip)))
    if rms > 1e-5:
        gain = (target_rms / rms) * (10.0 ** (gain_db / 20.0))
        gain = min(gain, 2.8)
        clip = clip * gain
    peak = float(np.max(np.abs(clip)))
    if peak > 0.92:
        clip = clip * (0.92 / peak)
    return clip


def pan_mono(mono: np.ndarray, pan: float) -> np.ndarray:
    angle = (pan + 1.0) * 0.25 * np.pi
    out = np.empty((mono.size, 2), dtype=np.float32)
    out[:, 0] = mono * np.cos(angle)
    out[:, 1] = mono * np.sin(angle)
    return out


# ---------------------------------------------------------------------------
# DSP & musical synthesis primitives
# ---------------------------------------------------------------------------

_NOTE_OFFSETS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def hz(note: str) -> float:
    n = _NOTE_OFFSETS[note[0]]
    i = 1
    if note[i] == "#":
        n += 1
        i += 1
    elif note[i] == "b":
        n -= 1
        i += 1
    octave = int(note[i:])
    return 440.0 * (2.0 ** ((n - 9 + (octave - 4) * 12) / 12.0))


def fft_bandpass(x: np.ndarray, lo: float = 0.0, hi: float = SR / 2, slope: int = 3) -> np.ndarray:
    if x.size < 4:
        return x
    X = np.fft.rfft(x.astype(np.float64))
    f = np.fft.rfftfreq(x.size, 1.0 / SR)
    g = np.ones_like(f)
    if lo > 0:
        g /= np.sqrt(1.0 + (lo / np.maximum(f, 1e-6)) ** (2 * slope))
    if hi < SR / 2:
        g /= np.sqrt(1.0 + (f / hi) ** (2 * slope))
    return np.fft.irfft(X * g, x.size).astype(np.float32)


def adsr(n: int, a: float = 0.006, d: float = 0.08, s: float = 0.7, r: float = 0.08) -> np.ndarray:
    e = np.full(n, s, dtype=np.float32)
    na = min(int(a * SR), n)
    nd = min(int(d * SR), max(0, n - na))
    nr = min(int(r * SR), n)
    if na > 1:
        e[:na] = np.linspace(0.0, 1.0, na, dtype=np.float32)
    if nd > 1:
        e[na : na + nd] = np.linspace(1.0, s, nd, dtype=np.float32)
    if nr > 1:
        e[-nr:] *= np.linspace(1.0, 0.0, nr, dtype=np.float32)
    return e


def nylon_pluck(note: str, dur: float, amp: float = 0.22, bright: float = 0.55, rng: np.random.Generator | None = None) -> np.ndarray:
    """Warm Karplus-Strong Spanish nylon-string guitar pluck."""
    if rng is None:
        rng = np.random.default_rng(11)
    f = hz(note)
    period_len = max(2, int(round(SR / f)))
    n = int(dur * SR)
    seed = rng.uniform(-1.0, 1.0, period_len).astype(np.float32)
    seed = fft_bandpass(np.tile(seed, 4), 70.0, 1400.0 + 3800.0 * bright, 2)[:period_len]
    out = np.zeros(n, dtype=np.float32)
    cur = seed.copy()
    decay = 0.9955
    for i in range(0, n, period_len):
        k = min(period_len, n - i)
        out[i : i + k] = cur[:k]
        cur = decay * 0.5 * (cur + np.roll(cur, -1))
    return out * adsr(n, 0.003, 0.03, 1.0, 0.05) * amp


def warm_bass(note: str, dur: float, amp: float = 0.24) -> np.ndarray:
    f = hz(note)
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    sig = (
        1.00 * np.sin(2 * np.pi * f * t)
        + 0.32 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-3.0 * t)
        + 0.10 * np.sin(2 * np.pi * 3 * f * t) * np.exp(-6.0 * t)
    )
    return (sig * adsr(n, 0.010, 0.10, 0.72, 0.06) * amp).astype(np.float32)


def rhodes(note: str, dur: float, amp: float = 0.14) -> np.ndarray:
    f = hz(note)
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    sig = (
        1.00 * np.sin(2 * np.pi * f * t)
        + 0.30 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-5.0 * t)
        + 0.10 * np.sin(2 * np.pi * 3 * f * t) * np.exp(-9.0 * t)
    ) * np.exp(-1.4 * t)
    trem = 1.0 + 0.06 * np.sin(2 * np.pi * 4.2 * t)
    return (sig * trem * adsr(n, 0.006, 0.05, 1.0, 0.09) * amp).astype(np.float32)


def cajon_kick(amp: float = 0.22) -> np.ndarray:
    n = int(0.18 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    f = 62.0 + 95.0 * np.exp(-34.0 * t)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-18.0 * t)
    return (body * amp).astype(np.float32)


def cajon_slap(amp: float = 0.14, rng: np.random.Generator | None = None) -> np.ndarray:
    if rng is None:
        rng = np.random.default_rng(19)
    n = int(0.11 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    noise = fft_bandpass(rng.uniform(-1.0, 1.0, n).astype(np.float32), 700.0, 4200.0, 2)
    wood = np.sin(2 * np.pi * 240.0 * t) * np.exp(-38.0 * t)
    return ((noise * np.exp(-28.0 * t) * 0.75 + wood * 0.45) * amp).astype(np.float32)


def palmas(amp: float = 0.11, rng: np.random.Generator | None = None) -> np.ndarray:
    if rng is None:
        rng = np.random.default_rng(23)
    n = int(0.10 * SR)
    buf = np.zeros(n, dtype=np.float32)
    for offset_ms in (0.0, 9.0, 17.0):
        idx = int(offset_ms * SR / 1000.0)
        rem = n - idx
        if rem > 16:
            t = np.arange(rem, dtype=np.float32) / SR
            cl = fft_bandpass(rng.uniform(-1.0, 1.0, rem).astype(np.float32), 950.0, 3600.0, 2)
            buf[idx:] += cl * np.exp(-42.0 * t) * 0.45
    return buf * amp


def shaker(amp: float = 0.055, rng: np.random.Generator | None = None) -> np.ndarray:
    if rng is None:
        rng = np.random.default_rng(31)
    n = int(0.055 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    noise = fft_bandpass(rng.uniform(-1.0, 1.0, n).astype(np.float32), 4500.0, 9500.0, 2)
    return (noise * np.exp(-55.0 * t) * amp).astype(np.float32)


def _mix_in(buf: np.ndarray, seg: np.ndarray, pos: int) -> None:
    if pos >= buf.shape[0] or pos + seg.shape[0] <= 0:
        return
    src_start = max(0, -pos)
    dst_start = max(0, pos)
    length = min(buf.shape[0] - dst_start, seg.shape[0] - src_start)
    if length > 0:
        buf[dst_start : dst_start + length] += seg[src_start : src_start + length]


# ---------------------------------------------------------------------------
# Continuous Radio Music Beds (3 distinct Spanish acoustic morning-radio grooves)
# ---------------------------------------------------------------------------

GROOVES = {
    "patio": {
        "bpm": 108.0,
        "seed": 101,
        # A - E - F#m - D (sunny upbeat patio folk-rumba)
        "chords": [
            ("A2",  ["A3", "C#4", "E4", "A4"],  ["E5", "C#5", "A4", "B4"]),
            ("E2",  ["G#3", "B3", "E4", "G#4"], ["B4", "G#4", "E5", "B4"]),
            ("F#2", ["A3", "C#4", "F#4", "A4"], ["C#5", "A4", "F#4", "A4"]),
            ("D2",  ["A3", "D4", "F#4", "A4"],  ["D5", "C#5", "B4", "A4"]),
        ],
        "lead_instrument": "nylon",
    },
    "plaza": {
        "bpm": 114.0,
        "seed": 202,
        # G - Em - C - D7 (playful bouncy plaza tertulia)
        "chords": [
            ("G2",  ["G3", "B3", "D4", "G4"],   ["D5", "B4", "G4", "A4"]),
            ("E2",  ["G3", "B3", "E4", "G4"],   ["B4", "E5", "D5", "B4"]),
            ("C2",  ["G3", "C4", "E4", "G4"],   ["C5", "E5", "G4", "C5"]),
            ("D2",  ["A3", "C4", "D4", "F#4"],  ["D5", "C5", "A4", "B4"]),
        ],
        "lead_instrument": "rhodes",
    },
    "mancha": {
        "bpm": 110.0,
        "seed": 303,
        # D - Bm - G - A (warm cheeky afternoon village magazine)
        "chords": [
            ("D2",  ["A3", "D4", "F#4", "A4"],  ["F#5", "D5", "A4", "B4"]),
            ("B2",  ["F#3", "B3", "D4", "F#4"], ["D5", "B4", "F#4", "B4"]),
            ("G2",  ["G3", "B3", "D4", "G4"],   ["B4", "D5", "G4", "A4"]),
            ("A2",  ["A3", "C#4", "E4", "A4"],  ["E5", "C#5", "A4", "G4"]),
        ],
        "lead_instrument": "nylon",
    },
}


def make_music_loop(groove_name: str) -> np.ndarray:
    """Build an 8-bar seamless stereo loop for the chosen radio groove."""
    cfg = GROOVES.get(groove_name, GROOVES["patio"])
    rng = np.random.default_rng(cfg["seed"])
    bpm = cfg["bpm"]
    beat = 60.0 / bpm
    bars = 8
    loop_sec = bars * 4 * beat
    loop_n = int(round(loop_sec * SR))
    buf = np.zeros((loop_n, 2), dtype=np.float32)

    kick_s = cajon_kick(0.20)
    slap_s = cajon_slap(0.11, rng)
    clap_s = palmas(0.09, rng)
    shak_s = shaker(0.045, rng)

    chords = cfg["chords"]
    for bar in range(bars):
        bass_root, chord_notes, mel_notes = chords[bar % len(chords)]
        bar_t = bar * 4 * beat

        # Warm walking bass on beats 1, 2.5, 3, 4
        bass_pattern = [(0.0, bass_root, 0.85), (1.5, bass_root, 0.45), (2.0, chord_notes[0], 0.70), (3.5, bass_root, 0.40)]
        for bt, bnote, bdur in bass_pattern:
            seg = pan_mono(warm_bass(bnote, bdur * beat, 0.20), -0.05)
            pos = int((bar_t + bt * beat) * SR) % loop_n
            _put_wrap(buf, seg, pos)

        # Spanish rumba-folk nylon guitar strums (slight arpeggiated strum offset per string)
        strum_beats = [(0.0, 0.21, 0.60), (0.75, 0.14, 0.45), (1.5, 0.18, 0.55), (2.5, 0.15, 0.50), (3.0, 0.19, 0.55)]
        for bt, amp, br in strum_beats:
            for s_idx, nname in enumerate(chord_notes):
                st_delay = s_idx * 0.013
                p = nylon_pluck(nname, 0.55 * beat, amp=amp * 0.42, bright=br, rng=rng)
                seg = pan_mono(p, -0.35 + 0.12 * s_idx)
                pos = int((bar_t + bt * beat + st_delay) * SR) % loop_n
                _put_wrap(buf, seg, pos)

        # Soft Rhodes chord pad on beat 1 and 3 for cozy studio warmth
        for bt in (0.0, 2.0):
            for s_idx, nname in enumerate(chord_notes[:3]):
                r_seg = pan_mono(rhodes(nname, 1.6 * beat, amp=0.075), 0.30 - 0.10 * s_idx)
                pos = int((bar_t + bt * beat) * SR) % loop_n
                _put_wrap(buf, r_seg, pos)

        # Light playful melodic hook every second half (bars 0,1,2,3 sparse; 4,5,6,7 brighter)
        mel_positions = [0.0, 1.0, 2.0, 3.0] if bar >= 4 else [0.5, 2.5]
        for idx, bt in enumerate(mel_positions):
            mnote = mel_notes[idx % len(mel_notes)]
            if cfg["lead_instrument"] == "nylon":
                m_sig = nylon_pluck(mnote, 0.65 * beat, amp=0.11, bright=0.65, rng=rng)
            else:
                m_sig = rhodes(mnote, 0.75 * beat, amp=0.10)
            pos = int((bar_t + bt * beat) * SR) % loop_n
            _put_wrap(buf, pan_mono(m_sig, 0.28), pos)

        # Cajón + palmas + shaker rhythm
        for bt in (0.0, 1.5, 2.0):
            _put_wrap(buf, pan_mono(kick_s, 0.0), int((bar_t + bt * beat) * SR) % loop_n)
        for bt in (1.0, 3.0):
            _put_wrap(buf, pan_mono(slap_s, 0.15), int((bar_t + bt * beat) * SR) % loop_n)
        for bt in (1.0, 2.5, 3.0):
            _put_wrap(buf, pan_mono(clap_s, -0.22), int((bar_t + bt * beat) * SR) % loop_n)
        for sub in range(8):
            _put_wrap(buf, pan_mono(shak_s * (1.0 if sub % 2 == 0 else 0.6), 0.32), int((bar_t + sub * 0.5 * beat) * SR) % loop_n)

    # Gentle high-cut so the bed stays warm and velvety behind speech
    buf[:, 0] = fft_bandpass(buf[:, 0], 45.0, 9000.0, 2)
    buf[:, 1] = fft_bandpass(buf[:, 1], 45.0, 9000.0, 2)
    peak = float(np.max(np.abs(buf))) or 1.0
    return (buf / peak * 0.75).astype(np.float32)


def _put_wrap(buf: np.ndarray, seg: np.ndarray, pos: int) -> None:
    n = buf.shape[0]
    m = seg.shape[0]
    if pos + m <= n:
        buf[pos : pos + m] += seg
    else:
        k = n - pos
        buf[pos:] += seg[:k]
        buf[: m - k] += seg[k:]


def tile_music_bed(loop: np.ndarray, total_n: int) -> np.ndarray:
    reps = int(math.ceil(total_n / loop.shape[0]))
    return np.tile(loop, (reps, 1))[:total_n].copy()


# ---------------------------------------------------------------------------
# Radio Hooks, Bumpers & Curated SFX Library
# ---------------------------------------------------------------------------

def build_sfx_library() -> dict[str, np.ndarray]:
    rng = np.random.default_rng(42)
    lib: dict[str, np.ndarray] = {}

    # 1. FM dial tuning sweep (vintage radio hook at episode start)
    n = int(0.55 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    static = fft_bandpass(rng.uniform(-1.0, 1.0, n).astype(np.float32), 700.0, 4600.0, 2) * 0.16
    whistle_f = 1900.0 - 1150.0 * (t / 0.55) + 260.0 * np.sin(2 * np.pi * 6.5 * t)
    whistle = np.sin(2 * np.pi * np.cumsum(whistle_f) / SR) * 0.11 * np.exp(-3.0 * t)
    lib["dial"] = pan_mono((static + whistle) * adsr(n, 0.04, 0.10, 0.75, 0.12), 0.0)

    # 2. Mid-show radio bumper (whoosh + bright 4-note Spanish chime riff)
    n = int(1.55 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    whoosh_n = int(0.45 * SR)
    wt = np.arange(whoosh_n, dtype=np.float32) / SR
    whoosh = fft_bandpass(rng.uniform(-1.0, 1.0, whoosh_n).astype(np.float32), 400.0, 3200.0, 2) * np.sin(np.pi * wt / 0.45) * 0.16
    bmp = np.zeros((n, 2), dtype=np.float32)
    _mix_in(bmp, pan_mono(whoosh, -0.2), 0)
    for st, nn, pan in [(0.16, "E4", -0.3), (0.30, "G#4", 0.3), (0.44, "B4", -0.2), (0.60, "E5", 0.0), (0.62, "B4", 0.25), (0.64, "G#4", -0.25)]:
        tone = nylon_pluck(nn, 0.75, amp=0.22, bright=0.85, rng=rng) + rhodes(nn, 0.75, amp=0.10)
        _mix_in(bmp, pan_mono(tone, pan), int(st * SR))
    lib["bumper"] = bmp

    # 3. Exclusiva (newsroom/gossip 3-note chime)
    n = int(0.95 * SR)
    exc = np.zeros((n, 2), dtype=np.float32)
    for st, nn, pan in [(0.0, "E5", -0.2), (0.14, "G#5", 0.2), (0.28, "B5", 0.0)]:
        k = int(0.55 * SR)
        tk = np.arange(k, dtype=np.float32) / SR
        f = hz(nn)
        chime = (np.sin(2 * np.pi * f * tk) + 0.35 * np.sin(2 * np.pi * 2 * f * tk) * np.exp(-8 * tk)) * np.exp(-5.5 * tk) * 0.24
        _mix_in(exc, pan_mono(chime, pan), int(st * SR))
    lib["exclusiva"] = exc

    # 4. Rimshot (ba-dum-tss!)
    n = int(0.95 * SR)
    rim = np.zeros((n, 2), dtype=np.float32)
    _mix_in(rim, pan_mono(cajon_slap(0.28, rng), -0.15), int(0.02 * SR))
    _mix_in(rim, pan_mono(cajon_kick(0.32), 0.0), int(0.16 * SR))
    cym_n = int(0.55 * SR)
    ct = np.arange(cym_n, dtype=np.float32) / SR
    cym = fft_bandpass(rng.uniform(-1.0, 1.0, cym_n).astype(np.float32), 3800.0, 11000.0, 2) * np.exp(-6.5 * ct) * 0.24
    _mix_in(rim, pan_mono(cym, 0.25), int(0.32 * SR))
    lib["rimshot"] = rim

    # 5. Vinilo (record scratch / comical screech stop)
    n = int(0.48 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    f = 950.0 * np.exp(-5.0 * t) + 180.0 * np.sin(2 * np.pi * 24.0 * t) * np.exp(-3.0 * t)
    scr = np.tanh(np.sin(2 * np.pi * np.cumsum(f) / SR) * 2.4) * adsr(n, 0.01, 0.05, 0.8, 0.14) * 0.20
    scr = fft_bandpass(scr, 350.0, 4200.0, 2)
    lib["vinilo"] = pan_mono(scr, 0.12)

    # 6. Cha-ching (cash register bell + coin jingle)
    n = int(0.85 * SR)
    cc = np.zeros((n, 2), dtype=np.float32)
    # mechanical clack
    clk_n = int(0.08 * SR)
    ct = np.arange(clk_n, dtype=np.float32) / SR
    clack = fft_bandpass(rng.uniform(-1.0, 1.0, clk_n).astype(np.float32), 1200.0, 5000.0, 2) * np.exp(-35.0 * ct) * 0.22
    _mix_in(cc, pan_mono(clack, -0.1), 0)
    # bright metallic bell ring
    bn = int(0.72 * SR)
    bt = np.arange(bn, dtype=np.float32) / SR
    bell = (
        np.sin(2 * np.pi * 2120.0 * bt) * np.exp(-5.0 * bt)
        + 0.65 * np.sin(2 * np.pi * 4240.0 * bt) * np.exp(-7.5 * bt)
        + 0.35 * np.sin(2 * np.pi * 6380.0 * bt) * np.exp(-10.0 * bt)
    ) * 0.22
    _mix_in(cc, pan_mono(bell, 0.18), int(0.09 * SR))
    lib["chaching"] = cc

    # 7. Suspense (playful short mystery dun-dun-duuun)
    n = int(1.05 * SR)
    sus = np.zeros((n, 2), dtype=np.float32)
    for st, dur, notes in [(0.0, 0.18, ["D3", "F3", "Ab3"]), (0.20, 0.18, ["C#3", "E3", "G3"]), (0.40, 0.62, ["C3", "Eb3", "Gb3", "A3"])]:
        k = int(dur * SR)
        tk = np.arange(k, dtype=np.float32) / SR
        ch = sum(np.sin(2 * np.pi * hz(nn) * tk) + 0.35 * np.sin(2 * np.pi * 2 * hz(nn) * tk) for nn in notes) / len(notes)
        ch = fft_bandpass(ch.astype(np.float32), 120.0, 2600.0, 2) * adsr(k, 0.015, 0.04, 0.85, 0.16) * 0.24
        _mix_in(sus, pan_mono(ch, 0.0), int(st * SR))
    lib["suspense"] = sus

    # 8. Campana (warm bronze church/convent bell)
    n = int(1.65 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    f0 = 330.0
    bell = (
        0.70 * np.sin(2 * np.pi * f0 * 0.5 * t) * np.exp(-1.5 * t)
        + 1.00 * np.sin(2 * np.pi * f0 * 1.0 * t) * np.exp(-2.2 * t)
        + 0.65 * np.sin(2 * np.pi * f0 * 1.20 * t) * np.exp(-2.8 * t)
        + 0.45 * np.sin(2 * np.pi * f0 * 1.50 * t) * np.exp(-3.4 * t)
        + 0.50 * np.sin(2 * np.pi * f0 * 2.00 * t) * np.exp(-4.0 * t)
        + 0.25 * np.sin(2 * np.pi * f0 * 2.75 * t) * np.exp(-5.5 * t)
    ) * adsr(n, 0.004, 0.04, 1.0, 0.25) * 0.13
    lib["campana"] = pan_mono(bell.astype(np.float32), -0.25)

    # 9. Boing (playful cartoon spring)
    n = int(0.55 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    f = 220.0 + 340.0 * (1.0 - np.exp(-6.0 * t)) + 75.0 * np.sin(2 * np.pi * 16.0 * t) * np.exp(-3.5 * t)
    boing = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-4.2 * t) * 0.22
    lib["boing"] = pan_mono(boing.astype(np.float32), 0.20)

    # 10. Sirena (brief comical Pitufos/Tricornios police chirp)
    n = int(0.85 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    f = 780.0 + 260.0 * np.sin(2 * np.pi * 2.4 * t)
    sir = (np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.25 * np.sin(2 * np.pi * 2 * np.cumsum(f) / SR))
    sir = fft_bandpass(sir.astype(np.float32), 350.0, 2600.0, 2) * adsr(n, 0.06, 0.05, 0.85, 0.18) * 0.14
    lib["sirena"] = pan_mono(sir, -0.35)

    # 11. Viento (gusty La Mancha torbonera whoosh)
    n = int(1.30 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    wind = fft_bandpass(rng.uniform(-1.0, 1.0, n).astype(np.float32), 220.0, 1300.0, 3)
    env_w = np.sin(np.pi * t / 1.30) ** 1.4
    lib["viento"] = pan_mono((wind * env_w * 0.26).astype(np.float32), 0.10)

    # 12. Real Matritellus game SFX assets!
    game_assets = [
        ("claxon_uga",     ASSETS_AUDIO / "vehiculos" / "claxon_uga.ogg",     0.95, 0.24,  0.22),
        ("claxon_tractor", ASSETS_AUDIO / "vehiculos" / "claxon_tractor.ogg", 0.70, 0.22, -0.22),
        ("frenazo",        ASSETS_AUDIO / "vehiculos" / "frenazo_1.ogg",      0.75, 0.22,  0.28),
        ("perro",          ASSETS_AUDIO / "dog_1.wav",                        0.90, 0.30, -0.25),
        ("grillos",        ASSETS_AUDIO / "crickets.wav",                     1.15, 0.22,  0.00),
        ("pajaros",        ASSETS_AUDIO / "bird_0.wav",                       1.10, 0.24,  0.28),
        ("murmullo",       ASSETS_AUDIO / "murmur.wav",                       1.40, 0.20,  0.00),
    ]
    for name, path, max_s, amp, pan in game_assets:
        if path.exists():
            raw = decode_audio_mono(path, max_sec=max_s)
            if raw.size > 64:
                peak = float(np.max(np.abs(raw))) or 1.0
                raw = (raw / peak * amp).astype(np.float32)
                raw *= adsr(raw.size, 0.04, 0.05, 1.0, 0.16)
                lib[name] = pan_mono(raw, pan)

    return lib


# ---------------------------------------------------------------------------
# Dynamic Sidechain Ducking + Studio Voice Polish
# ---------------------------------------------------------------------------

def smooth_envelope(voice_stereo: np.ndarray) -> np.ndarray:
    """Compute a smooth 0..1 voice-activity envelope with lookahead, fast attack and gentle release."""
    mono = np.max(np.abs(voice_stereo), axis=1)
    # Downsample to 100 Hz control rate for blazing-fast, artifact-free smoothing
    hop = SR // 100
    n_frames = int(math.ceil(mono.size / hop))
    padded = np.pad(mono, (0, n_frames * hop - mono.size))
    rms = np.sqrt(np.mean(padded.reshape(n_frames, hop) ** 2, axis=1))
    # Binary-ish soft gate: voice active when RMS > 0.015
    active = np.clip((rms - 0.012) / 0.035, 0.0, 1.0)
    # 120 ms lookahead (12 frames) so music ducks smoothly right before speech starts
    lookahead = 12
    shifted = np.zeros_like(active)
    for k in range(lookahead):
        shifted = np.maximum(shifted, np.roll(active, -k))
    shifted[-lookahead:] = active[-lookahead:]

    env_ctrl = np.zeros_like(shifted)
    cur = 0.0
    atk = 0.35   # ~40ms attack
    rel = 0.055  # ~350ms smooth swell back up during pauses
    for i in range(shifted.size):
        target = float(shifted[i])
        cur += (target - cur) * (atk if target > cur else rel)
        env_ctrl[i] = cur

    # Upsample back to audio rate with linear interpolation
    x_ctrl = np.arange(n_frames, dtype=np.float32) * hop
    x_audio = np.arange(mono.size, dtype=np.float32)
    return np.interp(x_audio, x_ctrl, env_ctrl).astype(np.float32)


def add_studio_ambience(stereo: np.ndarray) -> np.ndarray:
    """Tiny, subtle studio-booth early reflections so voices feel present in a real room."""
    out = stereo.copy()
    taps = [(0.011, 0.045, True), (0.019, 0.032, False), (0.029, 0.020, True)]
    for delay_s, gain, swap in taps:
        d = int(delay_s * SR)
        if d < stereo.shape[0]:
            ref = stereo[:-d] * gain
            if swap:
                ref = ref[:, ::-1]
            out[d:] += ref
    return out


def polish_voice_bus(voice_stereo: np.ndarray) -> np.ndarray:
    """Warm, natural broadcast voice bus via ffmpeg: gentle warmth + de-harshing at 3.6 kHz."""
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        in_wav = Path(tf.name)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf2:
        out_wav = Path(tf2.name)
    try:
        write_wav_stereo(in_wav, add_studio_ambience(voice_stereo))
        af = (
            "highpass=f=85,"
            "equalizer=f=165:width_type=o:width=1.3:g=1.6,"
            "equalizer=f=3600:width_type=o:width=1.4:g=-1.8,"
            "treble=g=0.8:f=7500,"
            "acompressor=threshold=-18dB:ratio=2.0:attack=16:release=190:makeup=1.5"
        )
        subprocess.run(
            ["ffmpeg", "-y", "-v", "error", "-i", str(in_wav), "-af", af, "-ar", str(SR), "-ac", "2", str(out_wav)],
            check=True,
        )
        cmd = ["ffmpeg", "-v", "error", "-i", str(out_wav), "-f", "f32le", "-acodec", "pcm_f32le", "-ac", "2", "-ar", str(SR), "pipe:1"]
        res = subprocess.run(cmd, check=True, capture_output=True)
        arr = np.frombuffer(res.stdout, dtype=np.float32).reshape(-1, 2).copy()
        # Match original length exactly
        if arr.shape[0] < voice_stereo.shape[0]:
            arr = np.pad(arr, ((0, voice_stereo.shape[0] - arr.shape[0]), (0, 0)))
        return arr[: voice_stereo.shape[0]]
    finally:
        for p in (in_wav, out_wav):
            if p.exists():
                p.unlink()


# ---------------------------------------------------------------------------
# Episode assembly & mastering
# ---------------------------------------------------------------------------

def mix_episode(
    turns: list[dict],
    music_loop: np.ndarray,
    sfx_lib: dict[str, np.ndarray],
) -> np.ndarray:
    """Assemble FM dial hook + intro music + ducked music bed + voices + bumpers + SFX + outro."""
    intro_music_s = 2.65
    outro_tail_s = 2.60

    cursor = int(intro_music_s * SR)
    voice_events: list[tuple[int, np.ndarray]] = []
    sfx_events: list[tuple[int, np.ndarray]] = []

    # Opening FM dial sweep right at the very start
    if "dial" in sfx_lib:
        sfx_events.append((0, sfx_lib["dial"]))

    for item in turns:
        sfx_pre = item.get("sfx_pre")
        sfx_post = item.get("sfx_post")
        clip = item["stereo"]
        gap_ms = int(item.get("gap", 140))

        if sfx_pre and sfx_pre in sfx_lib:
            s_arr = sfx_lib[sfx_pre]
            if sfx_pre == "bumper":
                # Give the mid-show bumper clean breathing room so the music swells & punches!
                cursor += int(0.22 * SR)
                sfx_events.append((cursor, s_arr))
                cursor += int(1.18 * SR)
            elif sfx_pre == "exclusiva":
                sfx_events.append((cursor, s_arr))
                cursor += int(0.55 * SR)
            else:
                # Subtle ambient cue starting slightly before the line
                sfx_events.append((max(0, cursor - int(0.15 * SR)), s_arr))

        voice_pos = max(int(0.5 * SR), cursor)
        voice_events.append((voice_pos, clip))
        line_end = voice_pos + clip.shape[0]

        if sfx_post and sfx_post in sfx_lib:
            s_arr = sfx_lib[sfx_post]
            post_pos = max(0, line_end - int(0.06 * SR))
            sfx_events.append((post_pos, s_arr))
            # Let punchline SFX land briefly before the next speaker jumps in
            extra = min(int(0.45 * SR), s_arr.shape[0] // 2)
            cursor = line_end + extra + max(0, int(gap_ms * SR / 1000.0))
        else:
            # gap_ms can be negative for natural overlapping interruptions!
            cursor = line_end + int(gap_ms * SR / 1000.0)

    total_n = max(cursor + int(outro_tail_s * SR), int(6.0 * SR))

    # 1. Build Voice bus
    voice_bus = np.zeros((total_n, 2), dtype=np.float32)
    for pos, seg in voice_events:
        _mix_in(voice_bus, seg, pos)
    voice_bus = polish_voice_bus(voice_bus)

    # 2. Build SFX bus
    sfx_bus = np.zeros((total_n, 2), dtype=np.float32)
    for pos, seg in sfx_events:
        _mix_in(sfx_bus, seg, pos)

    # 3. Build Music Bed bus with smooth dynamic sidechain ducking!
    #    - Full warm presence (0.50) during intro, mid-show bumpers & outro
    #    - Gently ducked (0.145) & softly mellowed underneath speech so voices shine 100% clear!
    bed_bright = tile_music_bed(music_loop, total_n)
    bed_mellow = np.empty_like(bed_bright)
    bed_mellow[:, 0] = fft_bandpass(bed_bright[:, 0], 55.0, 2600.0, 2)
    bed_mellow[:, 1] = fft_bandpass(bed_bright[:, 1], 55.0, 2600.0, 2)

    # Duck against voices + major SFX bumpers
    duck_driver = voice_bus + sfx_bus * 0.45
    duck_env = smooth_envelope(duck_driver)

    music_gain = 0.48 * (1.0 - duck_env) + 0.145 * duck_env
    # Smooth intro fade-in (after dial click) & warm outro fade-out
    fi = int(0.35 * SR)
    fo = int(1.25 * SR)
    music_gain[: int(0.18 * SR)] = 0.0
    music_gain[int(0.18 * SR) : int(0.18 * SR) + fi] *= np.linspace(0.0, 1.0, fi, dtype=np.float32)
    music_gain[-fo:] *= np.linspace(1.0, 0.0, fo, dtype=np.float32)

    music_bus = (bed_bright * (1.0 - duck_env)[:, None] + bed_mellow * duck_env[:, None]) * music_gain[:, None]

    # 4. Sum buses (voices clearly in front!)
    mix = voice_bus * 1.00 + music_bus * 0.92 + sfx_bus * 0.85
    peak = float(np.max(np.abs(mix)))
    if peak > 0.94:
        mix *= 0.94 / peak
    return mix


def write_wav_stereo(path: Path, stereo: np.ndarray) -> None:
    pcm = np.clip(stereo * 32767.0, -32768, 32767).astype(np.int16)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(pcm.tobytes())


def master_to_ogg(wav_path: Path, ogg_path: Path) -> None:
    """Final broadcast loudness normalisation (-15.5 LUFS, matching radio1..radio6) + Ogg Vorbis."""
    cmd = [
        "ffmpeg", "-y", "-v", "error",
        "-i", str(wav_path),
        "-af", "loudnorm=I=-15.5:TP=-2.0:LRA=8",
        "-c:a", "libvorbis", "-q:a", "4.5",
        "-ar", str(SR), "-ac", "2",
        str(ogg_path),
    ]
    subprocess.run(cmd, check=True)


def export_mp3_preview(ogg_path: Path, prog_id: str, titulo: str) -> Path:
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    safe = re.sub(r"[^\wáéíóúÁÉÍÓÚñÑ]+", "_", titulo).strip("_")
    mp3_path = DIST_DIR / f"Radio_Patio_{prog_id}_{safe}.mp3"
    subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-i", str(ogg_path), "-c:a", "libmp3lame", "-q:a", "2", str(mp3_path)],
        check=True,
    )
    return mp3_path


async def build_programme(
    prog: dict,
    voces: dict,
    out_dir: Path,
    cache_dir: Path,
    use_cache: bool,
    sem: asyncio.Semaphore,
    music_loops: dict[str, np.ndarray],
    sfx_lib: dict[str, np.ndarray],
) -> tuple[Path, float, int]:
    tasks = []
    turn_specs = []
    for raw in prog["lineas"]:
        if isinstance(raw, dict):
            spk, text, mood, gap = raw["s"], raw["t"], raw.get("m", "normal"), raw.get("gap", 140)
            sfx_pre, sfx_post = raw.get("sfx_pre"), raw.get("sfx_post")
        else:
            spk, text, mood, gap = raw
            sfx_pre, sfx_post = None, None
        vcfg = voces[spk]
        rate, pitch, gain_db = format_prosody(vcfg["rate"], mood)
        tasks.append(synth_line(sem, text, vcfg["voice"], rate, pitch, cache_dir, use_cache))
        turn_specs.append({"pan": vcfg["pan"], "gain_db": gain_db, "gap": gap, "sfx_pre": sfx_pre, "sfx_post": sfx_post})

    mp3_paths = await asyncio.gather(*tasks)

    turns: list[dict] = []
    for mp3_path, spec in zip(mp3_paths, turn_specs):
        mono = trim_silence(decode_audio_mono(mp3_path))
        mono = level_voice(mono, target_rms=0.16, gain_db=spec["gain_db"])
        spec["stereo"] = pan_mono(mono, spec["pan"])
        turns.append(spec)

    groove = prog.get("groove", "patio")
    if groove not in music_loops:
        music_loops[groove] = make_music_loop(groove)

    mix = mix_episode(turns, music_loops[groove], sfx_lib)
    dur_s = mix.shape[0] / SR
    ogg_path = out_dir / prog["archivo"]
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        wav_tmp = Path(tf.name)
    try:
        write_wav_stereo(wav_tmp, mix)
        master_to_ogg(wav_tmp, ogg_path)
    finally:
        if wav_tmp.exists():
            wav_tmp.unlink()

    return ogg_path, dur_s, ogg_path.stat().st_size


async def run(only: set[str] | None, use_cache: bool, mp3_ids: set[str]) -> None:
    data = json.loads(SCRIPT_JSON.read_text(encoding="utf-8"))
    em = data["emisora"]
    out_dir = RADIO_ROOT / em["carpeta"]
    out_dir.mkdir(parents=True, exist_ok=True)

    # 1. emisora.json
    card_path = out_dir / "emisora.json"
    card = {"nombre": em["nombre"], "descripcion": em["descripcion"]}
    card_path.write_text(json.dumps(card, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # 2. logo.png (keep custom user logo if already present)
    logo_path = out_dir / "logo.png"
    if not logo_path.exists():
        sys.path.insert(0, str(HERE))
        import make_radio_logos

        station_num = int(re.sub(r"\D+", "", em["carpeta"]))
        if station_num in make_radio_logos.LOGOS:
            make_radio_logos.draw(station_num)

    # 3. Prepare SFX library & music grooves
    cache_dir = Path(tempfile.gettempdir()) / "matritellus_radio_patio_cache"
    cache_dir.mkdir(parents=True, exist_ok=True)

    sfx_lib = build_sfx_library()
    music_loops: dict[str, np.ndarray] = {}
    sem = asyncio.Semaphore(4)

    programas = [p for p in data["programas"] if only is None or p["id"] in only]
    if only is None:
        expected = {p["archivo"] for p in programas}
        for old_ogg in out_dir.glob("*.ogg"):
            if old_ogg.name not in expected:
                old_ogg.unlink()

    total_dur = 0.0
    total_bytes = 0
    for prog in programas:
        print(
            f"[{prog['id']}] Generando ({prog.get('groove', 'patio')}): {prog['titulo']} "
            f"({len(prog['lineas'])} intervenciones)...",
            flush=True,
        )
        ogg_path, dur_s, size = await build_programme(
            prog, em["voces"], out_dir, cache_dir, use_cache, sem, music_loops, sfx_lib
        )
        total_dur += dur_s
        total_bytes += size
        print(f"     -> {ogg_path.name} ({dur_s:.1f} s, {size / 1024:.0f} KB)", flush=True)
        if prog["id"] in mp3_ids:
            mp3_path = export_mp3_preview(ogg_path, prog["id"], prog["titulo"])
            print(f"     -> MP3 preview: {mp3_path.relative_to(ROOT)}", flush=True)

    print(
        f"\nRadio Patio lista en {out_dir.relative_to(ROOT)}: "
        f"{len(programas)} programas, {total_dur / 60:.1f} min, {total_bytes / (1024 * 1024):.2f} MB"
    )


def main() -> None:
    ap = argparse.ArgumentParser(description="Genera la emisora Radio Patio con Microsoft Edge TTS, música y SFX.")
    ap.add_argument("--only", nargs="+", help="IDs de programas a regenerar (ej. --only 01 06)")
    ap.add_argument("--mp3", nargs="*", default=[], help="IDs de programas para exportar también en MP3 en dist/")
    ap.add_argument("--no-cache", action="store_true", help="Ignora la caché local de líneas TTS")
    args = ap.parse_args()
    only = set(args.only) if args.only else None
    mp3_ids = set(args.mp3) if args.mp3 else set()
    asyncio.run(run(only, use_cache=not args.no_cache, mp3_ids=mp3_ids))


if __name__ == "__main__":
    main()
