"""Bouncy Shots: a soft energy-field blip played when a boosted projectile bounces.

Run:  python assets/sfx/gen_bouncy.py
Then: python -m doomcreator audition assets/sfx/bouncy_candidates.json -o audition_bouncy.html

Brief: not a stereotypical bounce / boing; a high-tech energy field around the projectile; neutral enough for
rockets and plasma alike; short, soft and pleasant because a projectile can bounce several times and the
sound is heard on rapid-fire weapons too (a time gate in the script gives only about one projectile per
25 tics the sound at all, but it must still be easy to hear a lot).
Design: no noise, no thump: a soft sine with a fast pitch glide (a "field flick"), detuned copy for shimmer,
a touch of gentle FM, low-passed, 0.15-0.25 s, quiet. Eight variants on different notes and glide shapes,
all in the same consonant family so any sequence of them sounds fine together. Distinct from the ECM tones
(slow soft notes), Thorns chimes (glassy, longer) and Shield bubbles (low, layered).
"""
import json
import os

RATE = 44100


def env(a, d, r=0.04):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def flick(hz, dur, a, d, glide, cutoff=2600, fm_ratio=0.0, fm_depth=0.0, chorus=0.6, detune=1.007, partial=0.25, r=0.05):
    ops = [{"ratio": 1.0, "level": 1.0, "env": env(a, d, r)},
           {"ratio": 2.0, "level": partial, "env": env(a, d * 0.6, r)},
           {"ratio": detune, "level": chorus, "env": env(a * 1.2, d, r)}]
    mods = []
    if fm_ratio:
        ops.append({"ratio": fm_ratio, "level": 1.0, "env": env(a, d * 0.5, r)})
        mods = [[3, 0, fm_depth], [3, 2, fm_depth * 0.6]]
    p = {"duration": dur, "pitch": hz, "operators": ops, "carriers": [0, 1, 2],
         "pitch_env": {"start": glide[0], "end": glide[1], "time": glide[2], "curve": 3.0},
         "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}
    if mods:
        p["mods"] = mods
    return p


def L(off, level, patch):
    return {"offset": off, "level": level, "patch": patch}


def snd(sid, dur, layers, rms=-29):
    return {"id": sid, "alias": "cand7/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = [
    snd("bouncy__k1", 0.20, [L(0, 1.0, flick(700, 0.3, 0.004, 0.12, (0.6, 1.0, 0.05)))]),                 # rising flick
    snd("bouncy__k2", 0.22, [L(0, 1.0, flick(600, 0.3, 0.004, 0.14, (1.45, 1.0, 0.06)))]),                # falling flick
    snd("bouncy__k3", 0.24, [L(0, 1.0, flick(784, 0.3, 0.004, 0.09, (1.0, 1.0, 0.05))),
                             L(0.06, 0.8, flick(587, 0.3, 0.004, 0.12, (1.0, 1.0, 0.05)))]),             # two notes, G5 then D5
    snd("bouncy__k4", 0.24, [L(0, 1.0, flick(500, 0.3, 0.003, 0.14, (0.8, 1.0, 0.06), cutoff=2200, fm_ratio=1.5, fm_depth=0.8))]),   # soft FM hum
    snd("bouncy__k5", 0.24, [L(0, 1.0, flick(880, 0.3, 0.05, 0.12, (0.9, 1.0, 0.08), cutoff=2400, chorus=0.8))]),   # reversed micro-swell, glassy
    snd("bouncy__k6", 0.26, [L(0, 1.0, flick(300, 0.3, 0.005, 0.16, (0.7, 1.0, 0.06), cutoff=1800, fm_ratio=2.0, fm_depth=0.5))]),   # deeper "thum"
    snd("bouncy__k7", 0.26, [L(0, 1.0, flick(660, 0.3, 0.01, 0.16, (1.0, 1.0, 0.05), cutoff=2400, chorus=1.0, detune=1.012)),
                             L(0, 0.6, flick(990, 0.3, 0.012, 0.14, (1.0, 1.0, 0.05), cutoff=2400, chorus=0.8, detune=1.01))]),    # detuned shimmer pair
    snd("bouncy__k8", 0.22, [L(0.0, 0.9, flick(523, 0.2, 0.003, 0.07, (1.0, 1.0, 0.03))), L(0.035, 0.8, flick(659, 0.2, 0.003, 0.07, (1.0, 1.0, 0.03))),
                             L(0.07, 0.7, flick(784, 0.2, 0.003, 0.09, (1.0, 1.0, 0.03)))]),               # quick three-note trill
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bouncy_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2034, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
