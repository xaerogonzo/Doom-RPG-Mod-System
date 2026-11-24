"""Small-explosion sound for Explosive Shots and Submunitions bomblets (replaces the borrowed vanilla imp/shotx).

Run:  python assets/sfx/gen_explosions.py      (needs the toolkit with up to 96 layers)
Then: python -m doomcreator audition assets/sfx/explosions_candidates.json -o audition_explosions.html

Round 4. Rounds 1-3 (drum body, then graded noise plus a few crinkle grains) let you hear the individual parts, so they
sounded like a drum beat with static on top. This round makes the blast out of MANY small overlapping layers so no
single component stands out: a dense, front-loaded burst of dozens of short pentatonic pings spread over three octaves
(a "slot machine win" sparkle, tonal and rewarding rather than harsh), glued together by a quiet dark noise bed and a
slow-attack cluster of low detuned tones (a soft rumble chord, not one drum tone). Everything is randomised in pitch,
level, timing and decay from a fixed seed, so it is reproducible. 0.7-1.0 s, about -24 dBFS RMS (ids e1-e4 again so the SNDINFO wiring is unchanged).
"""
import json
import math
import os
import random

RATE = 44100


def env(a, d, r=0.03):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def ping(hz, dur, metal, cutoff):
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.001, dur * 0.55)},
                          {"ratio": 2.76 if metal else 2.0, "level": metal if metal else 0.2, "env": env(0.001, dur * 0.3)},
                          {"ratio": 1.006, "level": 0.5, "env": env(0.001, dur * 0.55)}],
            "carriers": [0, 1, 2], "filter": {"type": "lp", "cutoff": cutoff, "q": 0.7}}


def bed(dur, d, cutoff, a=0.004):
    return {"duration": dur, "pitch": 100, "operators": [{"ratio": 1.0, "level": 0.0, "env": env(0.001, dur)}],
            "carriers": [0], "noise": {"level": 1.0, "env": env(a, d)},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.7}}


def low(hz, dur, a):
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(a, dur * 0.6)}, {"ratio": 1.011, "level": 0.8, "env": env(a, dur * 0.6)}],
            "carriers": [0, 1], "filter": {"type": "lp", "cutoff": 320, "q": 0.7}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


# C pentatonic over four octaves: C3 D3 E3 G3 A3 ... up to G7
def scale(lo, hi):
    out = []
    for octv in range(2, 8):
        for n in (0, 2, 4, 7, 9):
            hz = 16.3516 * 2 ** (octv + n / 12.0)
            if lo <= hz <= hi:
                out.append(hz)
    return out


def blast(sid, seed, dur, pings, spread, lo, hi, metal, bed_lv, low_lv, cutoff, rms=-19):
    rng = random.Random(seed)
    notes = scale(lo, hi)
    layers = [L(0.0, bed_lv, bed(dur, dur * 0.45, 1800)),
              L(0.0, bed_lv * 0.8, bed(dur, dur * 0.7, 450, a=0.01))]
    for _ in range(pings):
        t = min(-math.log(1 - rng.random()) * spread, dur * 0.8)            # dense at the start, thinning out
        hz = rng.choice(notes) * rng.choice([1.0, 1.0, 1.0, 1.0035, 0.9965])
        d = rng.uniform(0.07, 0.28) * (1.0 - 0.5 * t / dur)
        layers.append(L(t, rng.uniform(0.25, 1.0) * (1.0 - 0.6 * t / dur), ping(hz, d + 0.04, metal, cutoff)))
    for hz in rng.sample(scale(45, 140), 5):                                  # soft low chord, slow attack: no thump
        layers.append(L(rng.uniform(0.0, 0.03), low_lv, low(hz, dur * 0.9, 0.025)))
    return {"id": sid, "alias": "cand15/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = [
    blast("explosion__e1", 41, 0.8, 64, 0.13, 260, 3200, 0.0, 0.25, 0.4, 5000),     # dense pentatonic sparkle burst
    blast("explosion__e2", 42, 0.95, 52, 0.18, 130, 2100, 0.0, 0.3, 0.6, 3500),     # lower, warmer, longer, more rumble
    blast("explosion__e3", 43, 0.75, 70, 0.1, 400, 3600, 0.3, 0.35, 0.3, 5500),     # brighter, a touch of metal (shattering)
    blast("explosion__e4", 44, 0.85, 60, 0.14, 180, 2800, 0.15, 0.5, 0.5, 4200),    # more noise bed: the most 'explosion-like'
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "explosions_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2043, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds,", max(len(s["fm"]["layers"]) for s in sounds), "layers max")
