"""Small-explosion sound for Explosive Shots and Submunitions bomblets (replaces the borrowed vanilla imp/shotx).

Run:  python assets/sfx/gen_explosions.py
Then: python -m doomcreator audition assets/sfx/explosions_candidates.json -o audition_explosions.html

Round 3. Rounds 1-2 sounded like a bass drum, then a snare: a short noise burst plus a tonal body is a drum. A real
blast instead (a) darkens as it dies, so the noise comes in several layers with falling cutoffs and growing decays
(bright crack gone in 0.1 s, mid body 0.3 s, dark rumble 0.8 s), (b) has NO tonal low body (no sine, no pitch drop), the
rumble is low-passed noise with a slow attack so there is no thump, and (c) has crinkly debris after the blast: a
scatter of tiny, quiet, high-passed grains (e1-e3) or, for a pleasant tonal flavour, soft high pings (e4). Quiet, soft,
0.8-1.0 s.
"""
import json
import os
import random

RATE = 44100


def env(a, d, r=0.03):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def noise(dur, d, cutoff, a=0.001, kind="lp", q=0.7):
    return {"duration": dur, "pitch": 100, "operators": [{"ratio": 1.0, "level": 0.0, "env": env(0.001, dur)}],
            "carriers": [0], "noise": {"level": 1.0, "env": env(a, d)},
            "filter": {"type": kind, "cutoff": cutoff, "q": q}}


def ping(hz, dur):
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.001, dur * 0.5)},
                          {"ratio": 2.01, "level": 0.25, "env": env(0.001, dur * 0.3)}],
            "carriers": [0, 1], "filter": {"type": "lp", "cutoff": 6000, "q": 0.7}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


def blast(sid, seed, dur, crack, mid, rumble, crinkle, grains, pings=None, rms=-16):
    rng = random.Random(seed)
    layers = [L(0.0, crack, noise(0.2, 0.09, 5500)),                 # bright crack, gone almost at once
              L(0.0, mid, noise(0.5, 0.28, 2200, a=0.002)),          # mid body
              L(0.0, 1.0, noise(dur, dur * 0.55, 700, a=0.004)),     # dark body
              L(0.0, rumble, noise(dur, dur * 0.75, 220, a=0.02))]   # sub rumble: slow attack, no thump, no tone
    t = 0.03
    for i in range(grains):
        t += rng.uniform(0.012, 0.05) * (1 + i * 0.12)               # sparser as it dies
        if t > dur * 0.8:
            break
        lv = crinkle * (1.0 - t / dur) * rng.uniform(0.5, 1.0)
        if pings:
            layers.append(L(t, lv, ping(rng.choice(pings), 0.09)))
        else:
            layers.append(L(t, lv, noise(0.03, 0.006, 1800, kind="hp")))
    return {"id": sid, "alias": "cand15/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


PENTA = [1568.0, 1760.0, 2093.0, 2349.3, 2637.0, 3136.0]      # G6 A6 C7 D7 E7 G7

sounds = [
    blast("explosion__e1", 31, 0.8, 0.5, 0.9, 0.5, 0.45, 16),       # balanced, crinkly tail
    blast("explosion__e2", 32, 0.95, 0.35, 0.7, 0.8, 0.35, 14),     # darker, more rumble
    blast("explosion__e3", 33, 0.7, 0.6, 1.0, 0.35, 0.6, 22),       # crisper, lots of debris
    blast("explosion__e4", 34, 0.85, 0.35, 0.8, 0.6, 0.5, 14, pings=PENTA),   # tonal flavour: soft pings instead of grit
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "explosions_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2043, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds,", max(len(s["fm"]["layers"]) for s in sounds), "layers max")
