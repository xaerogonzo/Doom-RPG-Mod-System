"""Small-explosion sound for Explosive Shots and Submunitions bomblets (replaces the borrowed vanilla imp/shotx).

Run:  python assets/sfx/gen_explosions.py
Then: python -m doomcreator audition assets/sfx/explosions_candidates.json -o audition_explosions.html

A short, soft, low "boom": a pitch-dropping sine body, a low-passed FM crunch for a little bite, a very quiet,
short, dark noise tick for the onset (no long noise swell, so no whoosh) and a low sub tail. Lower and rounder
than the old fireball sound so a crowd of bomblets stays pleasant. About -24 dBFS, 0.45-0.65 s.
"""
import json
import os

RATE = 44100


def env(a, d, r=0.05):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def body(hz, dur, drop, cutoff):
    return {"duration": dur, "pitch": hz, "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.003, dur * 0.6)}],
            "carriers": [0], "pitch_env": {"start": drop, "end": 1.0, "time": 0.14, "curve": 3.0},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def crunch(hz, dur, depth, cutoff):
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.002, dur * 0.5)},
                          {"ratio": 1.41, "level": 1.0, "env": env(0.002, dur * 0.3)}],
            "carriers": [0], "mods": [[1, 0, depth]], "pitch_env": {"start": 1.8, "end": 1.0, "time": 0.08, "curve": 3.0},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def tick(dur, level, cutoff):
    return {"duration": dur, "pitch": 200, "operators": [{"ratio": 1.0, "level": 0.0, "env": env(0.001, dur)}],
            "carriers": [0], "noise": {"level": level, "env": env(0.001, dur * 0.5, 0.01)},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.7}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


def boom(sid, dur, hz, drop, cr_hz, depth, tk, tail_hz):
    layers = [L(0.0, 1.0, body(hz, dur * 0.8, drop, 420)),
              L(0.0, 0.55, crunch(cr_hz, dur * 0.5, depth, 1400)),
              L(0.0, tk, tick(0.06, 1.0, 1800)),
              L(0.03, 0.5, body(tail_hz, dur - 0.03, 1.0, 200))]
    return {"id": sid, "alias": "cand15/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": -24, "layers": layers}}


sounds = [
    boom("explosion__e1", 0.55, 75, 2.6, 130, 2.5, 0.15, 45),
    boom("explosion__e2", 0.65, 62, 2.4, 110, 2.0, 0.12, 40),
    boom("explosion__e3", 0.5, 90, 2.8, 150, 3.0, 0.2, 50),
    boom("explosion__e4", 0.6, 70, 2.2, 120, 1.5, 0.1, 42),
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "explosions_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2043, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
