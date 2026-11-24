"""Elemental Synthesis cue (Beam / Blast / Wave copying elemental effects to more enemies): a soft, wide, tonal shimmer.

Run:  python assets/sfx/gen_synthesis.py
Then: python -m doomcreator audition assets/sfx/synthesis_candidates.json -o audition_synthesis.html

synth/spread - three or four soft glassy pentatonic notes that fan upward (root, fifth, octave, ninth) a few tens of ms apart,
each a gently chorused tone with a slow-ish attack and a faint rising glide, so it reads as something spreading outward. No noise,
no bass, no sharp attack. Quiet (about -30 dBFS), 0.5-0.65 s.
"""
import json
import os

RATE = 44100


def env(a, d, r=0.06):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def glass(hz, dur, a, d, cutoff=3200, partial=0.18, chorus=0.7, detune=1.006):
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(a, d)}, {"ratio": 2.0, "level": partial, "env": env(a, d * 0.5)},
                          {"ratio": detune, "level": chorus, "env": env(a * 1.2, d)}],
            "carriers": [0, 1, 2], "pitch_env": {"start": 0.96, "end": 1.0, "time": 0.12, "curve": 2.0},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


def shimmer(sid, dur, root, ratios, gap):
    layers = []
    for i, r in enumerate(ratios):
        layers.append(L(i * gap, 0.9 - 0.12 * i, glass(root * r, dur - i * gap, 0.03, dur * 0.45)))
    layers.append(L(0.0, 0.3, glass(root * 0.5, dur, 0.06, dur * 0.5, cutoff=900, partial=0.0, chorus=0.0)))
    return {"id": sid, "alias": "cand16/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": -30, "layers": layers}}


sounds = [
    shimmer("synth_spread__s1", 0.6, 220.0, [1.0, 1.5, 2.0, 2.25], 0.07),
    shimmer("synth_spread__s2", 0.55, 196.0, [1.0, 1.25, 1.5, 2.0], 0.08),
    shimmer("synth_spread__s3", 0.65, 262.0, [1.0, 1.5, 2.0], 0.09),
    shimmer("synth_spread__s4", 0.5, 294.0, [1.0, 1.335, 1.5, 2.0], 0.06),
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "synthesis_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2045, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
