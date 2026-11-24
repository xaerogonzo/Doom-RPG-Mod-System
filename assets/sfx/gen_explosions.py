"""Small-explosion sound for Explosive Shots and Submunitions bomblets (replaces the borrowed vanilla imp/shotx).

Run:  python assets/sfx/gen_explosions.py      (needs the toolkit with up to 96 layers)
Then: python -m doomcreator audition assets/sfx/explosions_candidates.json -o audition_explosions.html
Compare by numbers: python assets/sfx/analyze_wav.py ref.wav candidate.wav

Round 5. What the numbers said (analyze_wav.py on the toolkit's own `explosion` preset, the one that came closest):
its energy is WIDEBAND, nearly equal from 43 Hz to 11 kHz, and every band dies together, in about 1 s. It is not a dark
graded rumble (rounds 2-3) and not a pentatonic sparkle (round 4): the tones must be a subtle layer on top of a rough
wideband body. So each sound here is a stack of components with deliberately different gains:
  1. rough body: self-feedback FM with deep modulation plus noise, the preset's recipe, shorter and softer (the main level)
  2. low-passed noise bed: weight in the lows without a tonal thump
  3. crackle: sparse tiny high-passed noise grains and a few short FM "ticks", spread over the decay
  4. tonal sparkle: a handful of short pentatonic pings, at low gain, only a hint of the slot-machine reward sound
Everything is randomised from a fixed seed. About 0.65-0.9 s, -24 dBFS RMS.
"""
import json
import math
import os
import random

RATE = 44100


def env(a, d, r=0.03):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def body(dur, fb, depth, noise_lv, d, cutoff, hz=60.0):
    return {"duration": dur, "pitch": hz, "pitch_env": {"start": 2.0, "end": 0.45, "time": dur * 0.5, "curve": 2.0},
            "operators": [{"ratio": 1.0, "level": 1.0, "feedback": fb, "env": env(0.002, d)},
                          {"ratio": 0.5, "level": 1.0, "env": env(0.002, d * 0.8)}],
            "carriers": [0], "mods": [[1, 0, depth]],
            "noise": {"level": noise_lv, "env": env(0.001, d * 1.1)},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def bed(dur, d, cutoff, a=0.003):
    return {"duration": dur, "pitch": 100, "operators": [{"ratio": 1.0, "level": 0.0, "env": env(0.001, dur)}],
            "carriers": [0], "noise": {"level": 1.0, "env": env(a, d)},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.7}}


def grain(cutoff):
    return {"duration": 0.04, "pitch": 100, "operators": [{"ratio": 1.0, "level": 0.0, "env": env(0.001, 0.03)}],
            "carriers": [0], "noise": {"level": 1.0, "env": env(0.0005, 0.012, 0.01)},
            "filter": {"type": "hp", "cutoff": cutoff, "q": 0.7}}


def tick(hz):
    return {"duration": 0.05, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "feedback": 1.2, "env": env(0.0005, 0.02, 0.01)}],
            "carriers": [0], "filter": {"type": "lp", "cutoff": 6000, "q": 0.7}}


def ping(hz, dur):
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.001, dur * 0.55)},
                          {"ratio": 2.76, "level": 0.2, "env": env(0.001, dur * 0.3)}],
            "carriers": [0, 1], "filter": {"type": "lp", "cutoff": 5000, "q": 0.7}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


PENTA = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0]


def blast(sid, seed, dur, body_cut, noise_lv, crackle, ticks, pings, ping_lv, bed_lv=0.5, rms=-18):
    rng = random.Random(seed)
    layers = [L(0.0, 1.0, body(dur, 1.5, 4.0, noise_lv, dur * 0.5, body_cut)),
              L(0.0, bed_lv, bed(dur, dur * 0.4, 900))]
    for _ in range(14 + int(crackle * 16)):                           # crackle grains, dense early, sparse late
        t = min(-math.log(1 - rng.random()) * dur * 0.25, dur * 0.85)
        layers.append(L(t, crackle * rng.uniform(0.4, 1.0) * (1 - 0.6 * t / dur), grain(rng.choice([1500, 2500, 4000]))))
    for _ in range(ticks):
        t = rng.uniform(0.01, dur * 0.5)
        layers.append(L(t, crackle * 0.8 * rng.uniform(0.4, 1.0), tick(rng.uniform(300, 900))))
    for _ in range(pings):                                            # subtle tonal sparkle
        t = min(-math.log(1 - rng.random()) * dur * 0.2, dur * 0.7)
        layers.append(L(t, ping_lv * rng.uniform(0.4, 1.0), ping(rng.choice(PENTA), rng.uniform(0.08, 0.2))))
    return {"id": sid, "alias": "cand15/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = [
    blast("explosion__e1", 51, 0.65, 3200, 1.2, 0.30, 6, 10, 0.10),     # closest to the preset, shorter, light crackle, hint of tone
    blast("explosion__e2", 52, 0.8, 2600, 1.2, 0.55, 10, 12, 0.12),     # more crackle
    blast("explosion__e3", 53, 0.75, 1800, 1.4, 0.35, 6, 16, 0.18),     # darker, a bit more tone
    blast("explosion__e4", 54, 0.9, 2600, 1.0, 0.40, 8, 24, 0.22),      # most tonal sparkle, still a layer
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "explosions_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2043, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds,", max(len(s["fm"]["layers"]) for s in sounds), "layers max")
