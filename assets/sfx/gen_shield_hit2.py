"""Melee Shield "hit" (absorb) sounds, round 2: bubblier, deeper, more layered, less ding-like.

Run:  python assets/sfx/gen_shield_hit2.py
Then: python -m doomcreator audition assets/sfx/shield_hit2_candidates.json -o audition_hit2.html

Feedback: the first absorb sounds were short and ding-like. So: deeper base pitch (130-230 Hz), bubble-like glides
(each "bubble" is a sine whose pitch rises quickly and then settles, with a little FM warble), several bubbles
and a soft low swell layered together, low-passed (<= 1800 Hz), 0.28-0.4 s. Quiet (-28 dBFS), heard on blows
absorbed (at most every 12 tics).
"""
import json
import os

RATE = 44100


def env(a, d, r=0.06):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def bubble(hz, dur, rise=0.55, glide=0.05, decay=0.1, warble=0.3, cutoff=1600):
    """one bubble: pitch rises from rise*hz to hz, with a little FM warble and a detuned copy"""
    hz = hz * 1.25   # tuned after a first listen of the centroid: 130-230 Hz bases were too bassy (centroid ~170 Hz)
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.004, decay)},
                          {"ratio": 1.01, "level": 0.5, "env": env(0.006, decay)},
                          {"ratio": 2.0, "level": 1.0, "env": env(0.004, decay * 0.5)}],
            "carriers": [0, 1], "mods": [[2, 0, warble]],
            "pitch_env": {"start": rise, "end": 1.0, "time": glide, "curve": 3.0},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def pad(hz, dur, a, d, cutoff=1400, sweep=(0.8, 1.1, 0.15)):
    hz = hz * 1.5
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(a, d, 0.12)}, {"ratio": 1.005, "level": 0.6, "env": env(a * 1.2, d, 0.12)},
                          {"ratio": 2.0, "level": 0.2, "env": env(a, d * 0.7, 0.12)}],
            "carriers": [0, 1, 2], "pitch_env": {"start": sweep[0], "end": sweep[1], "time": sweep[2], "curve": 2.5},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.7}}


def L(off, level, patch):
    return {"offset": off, "level": level, "patch": patch}


def snd(sid, dur, layers, rms=-28):
    return {"id": sid, "alias": "cand6/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = [
    # x1: three bubbles in a row, a little different from each other, over a soft low swell
    snd("shield_hit2__x1", 0.38, [L(0.0, 1.0, bubble(170, 0.2)), L(0.07, 0.8, bubble(215, 0.2)), L(0.14, 0.7, bubble(190, 0.2)),
                                  L(0.0, 0.5, pad(110, 0.38, 0.05, 0.2))]),
    # x2: one deep, round bubble with a soft layered swell and a slower second bubble
    snd("shield_hit2__x2", 0.40, [L(0.0, 1.0, bubble(140, 0.28, rise=0.5, glide=0.08, decay=0.16, warble=0.4)),
                                  L(0.0, 0.6, pad(105, 0.4, 0.06, 0.22)), L(0.1, 0.5, bubble(210, 0.24, decay=0.12))]),
    # x3: a quick cluster of small bubbles, descending
    snd("shield_hit2__x3", 0.34, [L(0.0, 0.9, bubble(260, 0.16, decay=0.07)), L(0.045, 0.8, bubble(220, 0.16, decay=0.07)),
                                  L(0.09, 0.7, bubble(185, 0.18, decay=0.08)), L(0.14, 0.6, bubble(150, 0.2, decay=0.1)),
                                  L(0.0, 0.4, pad(120, 0.34, 0.04, 0.18))]),
    # x4: a deeper "bloom": a rising glide with FM, then a bubble tail
    snd("shield_hit2__x4", 0.42, [L(0.0, 0.9, bubble(150, 0.3, rise=0.4, glide=0.14, decay=0.2, warble=0.6)),
                                  L(0.12, 0.7, bubble(200, 0.22, decay=0.1)), L(0.0, 0.5, pad(95, 0.42, 0.08, 0.24))]),
    # x5: bubbles plus a faint higher shimmer for a little sparkle (still low-passed)
    snd("shield_hit2__x5", 0.36, [L(0.0, 1.0, bubble(175, 0.22)), L(0.06, 0.8, bubble(230, 0.2)),
                                  L(0.0, 0.35, pad(350, 0.36, 0.03, 0.16, cutoff=1800)), L(0.0, 0.4, pad(105, 0.36, 0.05, 0.2))]),
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "shield_hit2_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2033, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
