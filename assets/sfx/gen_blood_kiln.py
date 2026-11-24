"""Blood and Infernal Kiln cues: quiet, tonal, pleasant, no noise (so no whoosh, no static), no drum thumps.

Run:  python assets/sfx/gen_blood_kiln.py
Then: python -m doomcreator audition assets/sfx/blood_kiln_candidates.json -o audition_blood_kiln.html

  blood/exsanguinate - heal burst on a kill: a warm low "heartbeat" of two soft rounded tones (lub-dub, slow attack so
                       it is a pulse, not a drum) with a gentle rising tone over it. From the dead enemy.
  blood/vitaldrain   - armour gained: a soft bright two-note "plate" tone (low-passed, a hint of metal). From the player.
  fire/kiln          - Infernal Kiln lights up: a warm low rising two-tone glow, like a furnace catching. From the player.
Quiet (about -30 dBFS), 0.3-0.7 s.
"""
import json
import os

RATE = 44100


def env(a, d, r=0.05):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def tone(hz, dur, a, d, glide=None, cutoff=1600, partial=0.1, chorus=0.7, detune=1.008):
    p = {"duration": dur, "pitch": hz,
         "operators": [{"ratio": 1.0, "level": 1.0, "env": env(a, d)}, {"ratio": 2.0, "level": partial, "env": env(a, d * 0.6)},
                       {"ratio": detune, "level": chorus, "env": env(a * 1.2, d)}],
         "carriers": [0, 1, 2], "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}
    if glide:
        p["pitch_env"] = {"start": glide[0], "end": 1.0, "time": glide[1], "curve": 2.5}
    return p


def plate(hz, dur, decay, metal=0.35, cutoff=3000):
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.004, decay)}, {"ratio": 2.0, "level": metal, "env": env(0.004, decay * 0.6)},
                          {"ratio": 1.005, "level": 0.5, "env": env(0.005, decay)}],
            "carriers": [0, 1, 2], "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


def snd(sid, dur, layers, rms=-30):
    return {"id": sid, "alias": "cand14/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


def exsang(sid, dur, hz, gap, rise):
    return snd(sid, dur, [
        L(0.0, 1.0, tone(hz, 0.28, 0.025, 0.14, glide=(1.12, 0.06), cutoff=900, partial=0.05, chorus=0.8)),
        L(gap, 0.8, tone(hz * 0.85, 0.3, 0.025, 0.16, glide=(1.1, 0.06), cutoff=800, partial=0.05, chorus=0.8)),
        L(gap + 0.06, 0.45, tone(hz * rise, dur - gap - 0.06, 0.06, dur * 0.4, glide=(0.9, 0.2), cutoff=1800, partial=0.1)),
    ])


def vital(sid, dur, hz, ratio, gap, metal):
    return snd(sid, dur, [
        L(0.0, 0.9, plate(hz, 0.3, 0.12, metal=metal)),
        L(gap, 1.0, plate(hz * ratio, dur - gap, 0.16, metal=metal)),
        L(gap, 0.3, tone(hz * ratio * 2, dur - gap, 0.01, 0.1, cutoff=3200, partial=0.0, chorus=0.3)),
    ])


def kiln(sid, dur, hz, ratio, gap):
    return snd(sid, dur, [
        L(0.0, 0.9, tone(hz, dur, 0.06, dur * 0.55, glide=(0.8, 0.25), cutoff=1100, partial=0.15, chorus=0.9, detune=1.012)),
        L(gap, 0.8, tone(hz * ratio, dur - gap, 0.06, dur * 0.45, glide=(0.85, 0.2), cutoff=1300, partial=0.15, chorus=0.9, detune=1.012)),
        L(gap, 0.3, tone(hz * ratio * 2, dur - gap, 0.08, dur * 0.35, cutoff=2000, partial=0.0, chorus=0.5)),
        L(0.0, 0.25, tone(hz / 2, dur, 0.1, dur * 0.5, cutoff=500, partial=0.0, chorus=0.0)),
    ])


sounds = [
    exsang("blood_exsanguinate__x1", 0.6, 110, 0.18, 3.0),
    exsang("blood_exsanguinate__x2", 0.65, 98, 0.2, 3.4),
    exsang("blood_exsanguinate__x3", 0.55, 123, 0.16, 2.7),
    exsang("blood_exsanguinate__x4", 0.6, 104, 0.22, 3.0),
    vital("blood_vitaldrain__v1", 0.4, 523.25, 1.5, 0.09, 0.3),
    vital("blood_vitaldrain__v2", 0.45, 440.0, 1.5, 0.1, 0.25),
    vital("blood_vitaldrain__v3", 0.38, 587.33, 1.335, 0.08, 0.35),
    vital("blood_vitaldrain__v4", 0.42, 392.0, 1.5, 0.1, 0.2),
    kiln("fire_kiln__k1", 0.6, 165, 1.5, 0.12),
    kiln("fire_kiln__k2", 0.7, 147, 1.5, 0.15),
    kiln("fire_kiln__k3", 0.55, 185, 1.335, 0.1),
    kiln("fire_kiln__k4", 0.65, 131, 1.5, 0.14),
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "blood_kiln_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2042, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
