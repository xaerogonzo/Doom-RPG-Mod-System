"""Generates assets/sfx/stage_b_candidates.json: several variants of each Hyper-V movement sound.

Run:  python assets/sfx/gen_stage_b.py
Then: python -m doomcreator audition assets/sfx/stage_b_candidates.json -o audition.html \
        --reference DSPISTOL=-12.2 --reference DSOOF=-18.3 --reference DSITEMUP=-25.3

Design notes (what the ear is asked to judge, since the author cannot listen):
* No synthetic vocal tones and no click. "Human" comes from noise-shaped layers: a boot push-off thump,
  cloth/gear rustle, short exhaled air; "jumping" comes from the push and a little rising air.
* Every sound has target_rms_dbfs so loudness is set deliberately, not by peak normalisation. Reference
  audible RMS of Doom sounds: pistol -12.2, player pain -14.1, oof -18.3, item pickup -25.3.
* The climb loop is silent at both ends so the repeat is clean.
"""
import json
import os

RATE = 44100


def env(a, d, r=0.02):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def noisy(dur, a, d, cutoff, r=0.02, kind="lp"):
    return {"duration": dur, "pitch": 440, "operators": [{"level": 0.0, "env": env(0, 0.01)}], "carriers": [0],
            "noise": {"level": 1.0, "env": {"a": a, "d": d, "s": 0.0, "r": r}},
            "filter": {"type": kind, "cutoff": cutoff, "q": 0.8}}


def thump(dur, hz, decay, drop=1.8, r=0.03):
    return {"duration": dur, "pitch": hz, "operators": [{"level": 1.0, "env": env(0.001, decay, r)}], "carriers": [0],
            "pitch_env": {"start": drop, "end": 1.0, "time": 0.04, "curve": 5.0}}


def L(off, level, patch):
    return {"offset": off, "level": level, "patch": patch}


def snd(sid, dur, rms, layers):
    return {"id": sid, "alias": "cand/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = []

# ---- JUMP: boot push-off + rustle + a little air; no vocal tone, no click ---------------------------
def jump(name, dur, thump_hz, thump_lv, rustle_lv, air_lv, breath_lv, rustle_cut, rms):
    layers = [
        L(0.0, thump_lv, thump(0.1, thump_hz, 0.05)),
        L(0.0, thump_lv * 0.7, noisy(0.1, 0.0, 0.045, 500)),                  # soft body of the push
        L(0.012, rustle_lv, noisy(0.18, 0.015, 0.09, rustle_cut, r=0.05)),    # cloth / gear
        L(0.06, rustle_lv * 0.6, noisy(0.14, 0.01, 0.06, rustle_cut * 0.7, r=0.04)),
        L(0.03, air_lv, noisy(0.22, 0.04, 0.12, 1300, r=0.08)),               # air lifted by the push
    ]
    if breath_lv:
        layers.append(L(0.015, breath_lv, noisy(0.16, 0.02, 0.07, 1700, r=0.06)))   # short exhale, noise only
    return snd(name, dur, rms, layers)


sounds += [
    jump("jump__a1", 0.30, 110, 1.0, 0.35, 0.25, 0.0, 2400, -22),   # push-led
    jump("jump__a2", 0.30, 120, 0.5, 0.7, 0.3, 0.0, 2800, -22),     # rustle-led
    jump("jump__a3", 0.32, 105, 0.8, 0.45, 0.3, 0.3, 2400, -22),    # with a short exhale
    jump("jump__a4", 0.22, 130, 0.9, 0.5, 0.15, 0.0, 3000, -22),    # snappier, shorter
    jump("jump__a5", 0.40, 100, 0.7, 0.5, 0.45, 0.2, 2200, -23),    # softer, airier
]

# ---- DOUBLE JUMP: a mid-air push: airy whump + cloth flutter + rising air ----------------------------
def djump(name, dur, whump_lv, flutter_lv, rise_lv, flutter_n, rms):
    layers = [
        L(0.0, whump_lv, thump(0.12, 85, 0.06, drop=1.6)),
        L(0.0, whump_lv * 0.9, noisy(0.14, 0.004, 0.07, 700)),
        L(0.03, rise_lv, noisy(0.24, 0.1, 0.13, 2300, r=0.08)),                # air rushing up
    ]
    for i in range(flutter_n):
        layers.append(L(0.02 + 0.032 * i, flutter_lv * (0.85 ** i), noisy(0.06, 0.004, 0.03, 3200, r=0.02)))
    return snd(name, dur, rms, layers)


sounds += [
    djump("doublejump__b1", 0.34, 0.9, 0.5, 0.5, 4, -21),    # more flutter
    djump("doublejump__b2", 0.34, 1.2, 0.25, 0.4, 2, -21),   # more whump
    djump("doublejump__b3", 0.30, 0.8, 0.45, 0.25, 3, -21),  # snappier
    djump("doublejump__b4", 0.40, 0.7, 0.35, 0.8, 3, -22),   # airier, longer
    djump("doublejump__b5", 0.34, 1.0, 0.4, 0.5, 3, -20),    # balanced, a touch louder
]

# ---- DASH: a little whoosh, not a car: low swell, quiet air layer, faint synthetic sweep -------------
def dash(name, dur, swell, body_lv, air_lv, synth_lv, push_lv, rms):
    layers = [
        L(0.0, body_lv, noisy(dur, swell, dur * 0.55, 1300, r=0.08)),
        L(0.0, air_lv, noisy(dur, swell * 0.8, dur * 0.5, 2800, r=0.07)),
        L(0.0, synth_lv, {"duration": dur, "pitch": 500, "operators": [{"level": 1.0, "env": env(swell * 0.6, dur * 0.5, 0.08)},
                                                                       {"ratio": 2.01, "level": 0.3, "env": env(swell * 0.6, dur * 0.4, 0.08)}],
                          "carriers": [0, 1], "pitch_env": {"start": 2.2, "end": 0.8, "time": dur * 0.8, "curve": 3.0},
                          "filter": {"type": "lp", "cutoff": 2500, "q": 0.8}}),
        L(0.0, push_lv, thump(0.12, 120, 0.06, drop=1.8)),
    ]
    return snd(name, dur, rms, layers)


sounds += [
    dash("dash__c1", 0.30, 0.06, 0.5, 0.15, 0.05, 0.3, -24),   # barely a whoosh
    dash("dash__c2", 0.32, 0.06, 0.8, 0.25, 0.07, 0.3, -23),
    dash("dash__c3", 0.34, 0.07, 1.0, 0.35, 0.08, 0.25, -23),
    dash("dash__c4", 0.28, 0.05, 0.9, 0.3, 0.0, 0.4, -23),     # no synthetic layer
    dash("dash__c5", 0.38, 0.08, 1.0, 0.45, 0.1, 0.2, -22),    # fuller whoosh, still moderate
    dash("dash__c6", 0.30, 0.05, 0.7, 0.2, 0.12, 0.5, -23),    # more push, more synthetic
]

# ---- LEDGE CLIMB loop (silent at both ends) and the top scuff ----------------------------------------
def pulse(off, cut, hz, scrape_lv, thump_lv, tick_lv):
    return [L(off, scrape_lv, noisy(0.2, 0.004, 0.07, cut, r=0.05)),
            L(off, thump_lv, thump(0.1, hz, 0.045, drop=1.5)),
            L(off + 0.004, tick_lv, noisy(0.03, 0.0, 0.01, 2600, r=0.01, kind="hp"))]


sounds += [
    snd("climb__d1", 0.64, -25, pulse(0.0, 1500, 95, 0.7, 0.4, 0.1) + pulse(0.32, 1200, 80, 0.7, 0.4, 0.1)),
    # irregular three-pulse hand-over-hand rhythm, less metronomic
    snd("climb__d2", 0.84, -25, pulse(0.0, 1600, 95, 0.7, 0.4, 0.1) + pulse(0.27, 1250, 82, 0.6, 0.45, 0.08)
        + pulse(0.55, 1450, 90, 0.65, 0.4, 0.1)),
    snd("climb__d3", 0.64, -24, pulse(0.0, 1100, 85, 0.5, 0.8, 0.06) + pulse(0.32, 1000, 75, 0.5, 0.8, 0.06)),   # heavier
    snd("climb__d4", 0.64, -25, pulse(0.0, 2200, 105, 0.9, 0.25, 0.12) + pulse(0.32, 1900, 95, 0.9, 0.25, 0.12)),  # scrapier
    snd("climbtop__e1", 0.30, -22, [L(0.0, 0.6, noisy(0.2, 0.01, 0.09, 1500, r=0.05)), L(0.02, 0.7, thump(0.14, 85, 0.06, drop=1.6)),
                                    L(0.06, 0.25, noisy(0.2, 0.02, 0.08, 3500, r=0.06))]),
    snd("climbtop__e2", 0.34, -22, [L(0.0, 0.7, noisy(0.22, 0.01, 0.11, 1200, r=0.06)), L(0.02, 0.9, thump(0.16, 75, 0.07, drop=1.5)),
                                    L(0.05, 0.3, noisy(0.24, 0.02, 0.1, 2500, r=0.07))]),
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "stage_b_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2028, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
