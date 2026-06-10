#!/usr/bin/env python3
"""Synthesize a short dull paper thud for stamp_slam (no ElevenLabs)."""

from __future__ import annotations

import math
import random
import struct
import subprocess
import sys
import wave
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
WAV_OUT = PROJECT_ROOT / "audio" / "sfx" / "_stamp_slam_temp.wav"
MP3_OUT = PROJECT_ROOT / "audio/sfx/stamp_slam.mp3"

SAMPLE_RATE = 44100
DURATION_S = 0.11
PEAK_GAIN = 0.42


def synthesize() -> list[float]:
    count = int(SAMPLE_RATE * DURATION_S)
    rng = random.Random(42)
    samples: list[float] = []
    lp_soft = 0.0
    lp_mid = 0.0
    for i in range(count):
        t = i / SAMPLE_RATE
        white = rng.uniform(-1.0, 1.0)
        # Heavy low-pass — papery muffled texture, no pitched drum body.
        lp_mid = lp_mid * 0.82 + white * 0.18
        lp_soft = lp_soft * 0.91 + lp_mid * 0.09

        contact = math.exp(-t * 95.0) * 0.55
        tail = math.exp(-t * 38.0) * 0.35
        sample = lp_soft * tail + lp_mid * contact
        samples.append(sample)

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
