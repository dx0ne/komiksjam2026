#!/usr/bin/env python3
"""Synthesize organic fly wing buzz for fly_erase_click (no ElevenLabs).

Uses band-limited noise + irregular wing-beat AM — not sine harmonics (those read as synth).
"""

from __future__ import annotations

import math
import random
import struct
import subprocess
import sys
import wave
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
WAV_OUT = PROJECT_ROOT / "audio" / "sfx" / "_fly_erase_click_temp.wav"
MP3_OUT = PROJECT_ROOT / "audio/sfx/fly_erase_click.mp3"

SAMPLE_RATE = 44100
DURATION_S = 0.48
PEAK_GAIN = 0.5
SCRAPE_START_S = 0.22


def _lp_coeff(hz: float) -> float:
    return max(0.0, min(1.0, 1.0 - (2.0 * math.pi * hz) / SAMPLE_RATE))


def _one_pole_lp(state: float, input_sample: float, coeff: float) -> float:
    return state * coeff + input_sample * (1.0 - coeff)


def synthesize() -> list[float]:
    count = int(SAMPLE_RATE * DURATION_S)
    rng = random.Random(17)
    samples: list[float] = []

    lp_hi = 0.0
    lp_mid = 0.0
    lp_lo = 0.0
    lp_scrape = 0.0
    lp_beat_gain = 1.0

    wing_phase = 0.0
    wing_hz = 208.0
    drift = 0.0

    c_hi = _lp_coeff(1400.0)
    c_mid = _lp_coeff(520.0)
    c_lo = _lp_coeff(140.0)
    c_scrape = _lp_coeff(900.0)

    for i in range(count):
        t = i / SAMPLE_RATE
        white = rng.uniform(-1.0, 1.0)

        # Slow organic drift in wing rate — not periodic sine wobble.
        drift += rng.uniform(-1.0, 1.0) * 0.018
        drift *= 0.992
        wing_hz = 200.0 + drift * 10.0 + 4.0 * math.sin(t * 1.7)
        wing_hz = max(165.0, min(245.0, wing_hz))
        wing_phase += wing_hz / SAMPLE_RATE

        cycle = wing_phase % 1.0
        # Asymmetric wing stroke: quick power stroke, slower recovery.
        if cycle < 0.28:
            stroke = (cycle / 0.28) ** 0.55
        else:
            stroke = 1.0 - ((cycle - 0.28) / 0.72) ** 1.4
        stroke = max(0.0, stroke)

        # Per-beat gain jitter so it doesn't pulse like a machine.
        if cycle < 0.02 and i > 0:
            lp_beat_gain = rng.uniform(0.72, 1.0)
        beat_gain = lp_beat_gain * 0.94 + 1.0 * 0.06

        micro = 0.78 + 0.22 * math.sin(2.0 * math.pi * wing_phase * 5.7)
        am = stroke * beat_gain * micro

        lp_hi = _one_pole_lp(lp_hi, white, c_hi)
        lp_mid = _one_pole_lp(lp_mid, white, c_mid)
        lp_lo = _one_pole_lp(lp_lo, white, c_lo)

        # Turbulent wing air: mid band noise, not a pitched tone stack.
        body = lp_mid - lp_lo * 0.92
        grit = (lp_hi - lp_mid) * 0.35
        buzz = (body * 0.82 + grit) * am

        # Soft saturation — insect buzz is slightly gritty, not clean.
        buzz = math.tanh(buzz * 2.2) * 0.55

        attack = 1.0 - math.exp(-t * 520.0)
        decay = math.exp(-max(0.0, t - 0.015) * 10.5)
        buzz *= attack * decay

        scrape = 0.0
        if t >= SCRAPE_START_S:
            scrape_t = t - SCRAPE_START_S
            lp_scrape = _one_pole_lp(lp_scrape, white, c_scrape)
            scrape_env = math.exp(-scrape_t * 28.0) * (1.0 - math.exp(-scrape_t * 160.0))
            scrape = lp_scrape * scrape_env * 0.08

        samples.append(buzz + scrape)

    peak = max(abs(s) for s in samples) or 1.0
    return [max(-1.0, min(1.0, s / peak * PEAK_GAIN)) for s in samples]


def write_wav(samples: list[float], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for sample in samples:
            frames.extend(struct.pack("<h", int(sample * 32767)))
        wf.writeframes(frames)


def wav_to_mp3(wav_path: Path, mp3_path: Path) -> None:
    cmd = [
        "ffmpeg",
        "-y",
        "-i",
        str(wav_path),
        "-codec:a",
        "libmp3lame",
        "-b:a",
        "128k",
        str(mp3_path),
    ]
    subprocess.run(cmd, check=True, capture_output=True)


def main() -> int:
    samples = synthesize()
    write_wav(samples, WAV_OUT)
    try:
        wav_to_mp3(WAV_OUT, MP3_OUT)
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        print(f"ffmpeg failed: {exc}", file=sys.stderr)
        return 1
    finally:
        if WAV_OUT.is_file():
            WAV_OUT.unlink()
    print(f"Wrote {MP3_OUT.relative_to(PROJECT_ROOT)} ({MP3_OUT.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
