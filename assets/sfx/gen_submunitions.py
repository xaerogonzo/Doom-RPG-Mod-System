"""Submunitions: ONE soft "cluster" sound of several small metal balls pinging and settling.

Run:  python assets/sfx/gen_submunitions.py      (needs the toolkit with up to 96 layers)
Then: python -m doomcreator audition assets/sfx/submunitions_candidates.json -o audition_submunitions.html

Brief: metal bouncing explosive balls; tonal and pleasant because it is heard a lot; one gated sound for the
whole burst (not one per bomblet) that still sounds like 6 or more balls; the bouncing itself subtle.
Construction: each ball is a short series of soft metallic "dings" (a pentatonic note, a quiet inharmonic
partial for the metal, low-passed) whose spacing shrinks and whose level falls like a ball settling; the balls
start a little apart and have different notes. Under each ding sits a very quiet soft thump (the bounce).
The sound starts with a short silence (0.2 s) so it lines up with the first bomblets leaving the spawner.
Everything is seeded: same script, same sound. The gate in the script allows one cluster per 40 tics.
"""
import json
import os
import random

RATE = 44100


def env(a, d, r=0.05):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def ding(hz, decay, metal, cutoff=3200):
    return {"duration": decay * 2.2 + 0.05, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.002, decay)}, {"ratio": 2.76, "level": metal, "env": env(0.002, decay * 0.45)},
                          {"ratio": 1.004, "level": 0.4, "env": env(0.003, decay)}],
            "carriers": [0, 1, 2], "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def thump(hz, decay=0.045):
    return {"duration": 0.09, "pitch": hz, "operators": [{"level": 1.0, "env": env(0.002, decay, 0.02)}], "carriers": [0],
            "pitch_env": {"start": 1.6, "end": 1.0, "time": 0.03, "curve": 5.0}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


PENTA = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.7, 1318.5]   # C5 D5 E5 G5 A5 C6 D6 E6


def cluster(sid, seed, balls, bounces, spread, ring, thump_lv, notes, rms=-28):
    rng = random.Random(seed)
    layers = []
    end = 0.0
    for b in range(balls):
        t = 0.2 + b * spread * rng.uniform(0.6, 1.4)
        hz = rng.choice(notes)
        gap = rng.uniform(0.11, 0.19)
        lvl = rng.uniform(0.7, 1.0)
        for k in range(bounces):
            layers.append(L(t, lvl * (0.62 ** k), ding(hz * rng.uniform(0.995, 1.005), 0.12 + 0.03 * rng.random(), ring)))
            if thump_lv:
                layers.append(L(t, thump_lv * (0.7 ** k), thump(rng.choice([110, 130, 150]))))
            end = max(end, t + 0.3)
            t += gap
            gap *= 0.68
    dur = min(1.6, end + 0.1)
    return {"id": sid, "alias": "cand9/" + sid.replace("__", "/"),
            "fm": {"duration": round(dur, 3), "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = [
    cluster("cluster__n1", 1, 6, 3, 0.05, 0.25, 0.12, PENTA[:5]),                 # six balls, balanced
    cluster("cluster__n2", 2, 7, 3, 0.045, 0.2, 0.08, PENTA[1:6]),                # seven, a touch softer
    cluster("cluster__n3", 3, 6, 4, 0.06, 0.35, 0.1, PENTA[:4]),                  # lower notes, more metal, longer settle
    cluster("cluster__n4", 4, 8, 2, 0.04, 0.25, 0.1, PENTA[2:8]),                 # eight balls, quick, higher
    cluster("cluster__n5", 5, 6, 3, 0.055, 0.15, 0.18, PENTA[:5]),                # softer metal, more bounce thump
    cluster("cluster__n6", 6, 7, 4, 0.05, 0.3, 0.06, PENTA[2:7]),                 # barely any thump, more ring
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "submunitions_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2036, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds,", sum(len(s["fm"]["layers"]) for s in sounds), "layers in total")
