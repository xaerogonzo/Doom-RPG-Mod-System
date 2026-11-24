"""Small-explosion sound for Explosive Shots and Submunitions bomblets (replaces the borrowed vanilla imp/shotx).

Run:  python assets/sfx/gen_explosions.py
Then: python -m doomcreator audition assets/sfx/explosions_candidates.json -o audition_explosions.html

A small explosion: a short band-limited noise burst for the blast, a darker longer noise rumble, a rough self-feedback FM
low body (not a clean sine, which sounds like a drum) and a quiet sub. e4 is the toolkit's own explosion preset, low-passed. Lower and rounder
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


def noise(dur, level, d, cutoff, a=0.001):
    return {"duration": dur, "pitch": 100, "operators": [{"ratio": 1.0, "level": 0.0, "env": env(0.001, dur)}],
            "carriers": [0], "noise": {"level": level, "env": env(a, d, 0.02)},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.7}}


def grit(hz, dur, fb, cutoff):
    # self-feedback FM: rough, inharmonic, noise-like low rumble (not a clean drum tone)
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "feedback": fb, "env": env(0.002, dur * 0.6)}],
            "carriers": [0], "pitch_env": {"start": 1.5, "end": 0.8, "time": dur * 0.8, "curve": 2.0},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


def boom(sid, dur, burst_cut, rumble_cut, fb, hz, sub):
    layers = [L(0.0, 1.0, noise(0.3, 1.0, 0.16, burst_cut)),                 # the blast itself: a short band-limited burst
              L(0.0, 0.8, noise(dur, 1.0, dur * 0.7, rumble_cut, a=0.004)),   # dark, longer rumble
              L(0.0, 0.7, grit(hz, dur * 0.8, fb, 1200)),                     # rough low body
              L(0.0, sub, grit(hz * 0.5, dur, 0.0, 200))]                     # quiet sub, no clean drum thump
    return {"id": sid, "alias": "cand15/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": -22, "layers": layers}}


sounds = [
    boom("explosion__e1", 0.6, 3200, 700, 1.2, 80, 0.2),
    boom("explosion__e2", 0.7, 2400, 500, 1.6, 65, 0.25),
    boom("explosion__e3", 0.5, 4000, 900, 1.0, 95, 0.15),
    {"id": "explosion__e4", "preset": "explosion", "alias": "cand15/explosion/e4",
     "overrides": {"filter": {"type": "lp", "cutoff": 2600, "q": 0.8}}},
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "explosions_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2043, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
