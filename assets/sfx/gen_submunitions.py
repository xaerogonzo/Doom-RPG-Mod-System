"""Submunitions: ONE soft "cluster" sound of several small metal balls pinging and settling.

Run:  python assets/sfx/gen_submunitions.py      (needs the toolkit with up to 96 layers)
Then: python -m doomcreator audition assets/sfx/submunitions_candidates.json -o audition_submunitions.html

Round 2 (after 'sounds like running a finger over keyboard keys'): LONGER, 4-5.5 s, with slow high bounces (0.7-1.0 s between a
ball's first bounces, shrinking), only 5-7 balls, a few low notes and long pauses so each ding is heard on its own.
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


def cluster(sid, seed, balls, bounces, first_gap, shrink, start_spread, ring, thump_lv, notes, rms=-28):
    """balls: how many; bounces: dings per ball; first_gap: seconds between a ball's first two bounces (a high
    bounce); shrink: each next gap is shrink x the previous; start_spread: how far apart the balls start"""
    rng = random.Random(seed)
    layers = []
    end = 0.0
    for b in range(balls):
        t = 0.25 + b * start_spread * rng.uniform(0.6, 1.4)
        hz = rng.choice(notes)
        gap = first_gap * rng.uniform(0.85, 1.15)
        lvl = rng.uniform(0.75, 1.0)
        for k in range(bounces):
            layers.append(L(t, lvl * (0.78 ** k), ding(hz * rng.uniform(0.996, 1.004), 0.24 + 0.08 * rng.random(), ring)))
            if thump_lv and k < 3:
                layers.append(L(t, thump_lv * (0.7 ** k), thump(rng.choice([95, 110, 125]))))
            end = max(end, t + 0.7)
            t += gap
            gap *= shrink
    dur = min(5.6, end + 0.1)
    return {"id": sid, "alias": "cand9/" + sid.replace("__", "/"),
            "fm": {"duration": round(dur, 3), "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


LOW = [392.0, 440.0, 523.25, 587.33, 659.25, 783.99]     # G4 A4 C5 D5 E5 G5: bigger balls, lower pings
sounds = [
    cluster("cluster__p1", 11, 6, 6, 0.80, 0.72, 0.30, 0.2, 0.12, LOW),                    # six big balls, high slow bounces
    cluster("cluster__p2", 12, 5, 6, 0.95, 0.74, 0.45, 0.15, 0.1, LOW[:5]),                 # five, slower and more spread
    cluster("cluster__p3", 13, 7, 5, 0.70, 0.70, 0.25, 0.3, 0.1, LOW[1:]),                 # seven, a bit quicker
    cluster("cluster__p4", 14, 6, 7, 0.85, 0.76, 0.35, 0.25, 0.08, LOW[:4]),               # six with longer settle, lower notes
    cluster("cluster__p5", 15, 6, 6, 0.75, 0.72, 0.40, 0.12, 0.18, LOW),                   # softer metal, more bounce thump
    cluster("cluster__p6", 16, 5, 7, 1.00, 0.75, 0.50, 0.3, 0.06, LOW[2:]),                # five, widest spread, most ring
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "submunitions_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2036, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds,", sum(len(s["fm"]["layers"]) for s in sounds), "layers in total")
