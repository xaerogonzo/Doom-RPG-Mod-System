"""Small-explosion sound for Explosive Shots and Submunitions bomblets (replaces the borrowed vanilla imp/shotx).

Run:  python assets/sfx/gen_explosions.py      (needs the toolkit with up to 96 layers)
Then: python -m doomcreator audition assets/sfx/explosions_candidates.json -o audition_explosions.html
Compare by numbers: python assets/sfx/analyze_wav.py candidate.wav reference.wav

Round 7: built from the MEASURED frequency shape of the vanilla Doom explosion sounds (DSFIRXPL, DSBAREXP; measured only
with analyze_wav.py, nothing copied or resampled, and the output below is pure synthesis). What the numbers showed:
  * the energy is equal in every octave band (that is PINK noise, 1/f), not a bright white burst and not a tonal drum;
  * it is band-limited at about 5.5 kHz (the sounds are 11 kHz samples), with a lot of body in the low-mids and lows;
  * the highs die first (about -40 dB over a second) while the lows and mids hold (-12 to -18 dB): the sound darkens
    as it decays, and it starts at full level in all bands at once.
A sum of equal-power low-passed noise layers at octave-spaced cutoffs is exactly pink, so each sound here is eight noise
layers (cutoffs 5.6 kHz down to 90 Hz), each with its own decay (short for the highs, long for the lows), plus a sharp
attack crack, sparse debris crackle and a very quiet tonal edge. No pitched low body at all (that was the bass drum).
Variants differ in how much low end, how long, and how much crackle. 0.5-0.8 s, level matched.
"""
import json
import math
import os
import random

RATE = 44100


def env(a, d, r=0.02):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def noise(dur, d, cutoff, kind="lp", a=0.0008, q=0.7):
    return {"duration": dur, "pitch": 100, "operators": [{"ratio": 1.0, "level": 0.0, "env": env(0.001, dur)}],
            "carriers": [0], "noise": {"level": 1.0, "env": env(a, d)},
            "filter": {"type": kind, "cutoff": cutoff, "q": q}}


def ping(hz, dur):
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.002, dur * 0.55)},
                          {"ratio": 2.01, "level": 0.2, "env": env(0.002, dur * 0.3)}],
            "carriers": [0, 1], "filter": {"type": "lp", "cutoff": 4500, "q": 0.7}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


PENTA = [1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0, 2349.3, 2637.0]
CUTS = [5600, 2800, 1400, 700, 350, 175, 88]                 # octave-spaced: equal power per layer = pink noise
# decay (seconds) of each octave layer, from the measured vanilla fall-off over about one second (highs die first)
DECAYS = [0.30, 0.42, 0.62, 0.8, 0.95, 1.05, 1.1]


def blast(sid, seed, dur, scale, low_gain, crack, debris, edge, rms=-18):
    rng = random.Random(seed)
    layers = []
    for k, (fc, d) in enumerate(zip(CUTS, DECAYS)):
        gain = 1.0 if k < 4 else low_gain * (0.85 ** (k - 4))     # low_gain trims the two or three lowest octaves
        layers.append(L(0.0, gain, noise(dur, d * scale, fc, a=0.001 + 0.002 * k)))
    layers.append(L(0.0, crack, noise(0.1, 0.03, 1500, kind="hp", a=0.0004)))            # sharp onset
    for _ in range(int(10 + 22 * debris)):                                                # debris crackle
        t = 0.03 + min(-math.log(1 - rng.random()) * dur * 0.3, dur * 0.8)
        layers.append(L(t, debris * rng.uniform(0.3, 1.0) * (1 - 0.7 * t / dur),
                        noise(0.03, 0.008, rng.choice([2000, 3000, 4500]), kind="hp", a=0.0005)))
    for _ in range(8):                                                                    # very quiet tonal edge
        t = rng.uniform(0.01, dur * 0.45)
        layers.append(L(t, edge * rng.uniform(0.5, 1.0), ping(rng.choice(PENTA), rng.uniform(0.08, 0.18))))
    return {"id": sid, "alias": "cand15/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = [
    blast("explosion__e1", 71, 0.7, 0.6, 1.0, 0.35, 0.20, 0.03),    # measured shape, shortened to a small blast
    blast("explosion__e2", 72, 0.6, 0.55, 0.45, 0.4, 0.2, 0.03),    # same, much less low end (firework-like)
    blast("explosion__e3", 73, 0.75, 0.65, 0.7, 0.3, 0.45, 0.04),   # more crackle, medium bass
    blast("explosion__e4", 74, 0.5, 0.45, 0.6, 0.5, 0.25, 0.03),    # shortest and snappiest
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "explosions_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2043, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds,", max(len(s["fm"]["layers"]) for s in sounds), "layers max")
