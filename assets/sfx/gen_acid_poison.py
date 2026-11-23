"""Acid and Poison upgrade cues: quiet, soft, rounded; noise-and-low-tone based (no clicks, no FM zips, no vocal tones).

Run:  python assets/sfx/gen_acid_poison.py
Then: python -m doomcreator audition assets/sfx/acid_poison_candidates.json -o audition_acid_poison.html

Played once from the affected enemy at discrete events, within ~20 m, gated per element (see gen_fire_lightning.py).
  acid/spray       - Acid Spray splashes: a soft fizz, low-passed noise with a gentle swell and a low wet tone.
  acid/embrittle   - Embrittlement shatters an enemy: a dull crumble, low thump with a slow low-passed noise tail.
  poison/hallucinate - Hallucinogens turn an enemy friendly: a woozy slow-wobbling low tone pair gliding up.
  poison/putrefy   - Putrefaction bursts a corpse: three or four soft low bubbles over a quiet wet noise bed.
Quiet (about -30 dBFS), 0.35-0.7 s.
"""
import json
import os
import random

RATE = 44100


def env(a, d, r=0.04):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def noisy(dur, a, d, cutoff, r=0.04, kind="lp"):
    return {"duration": dur, "pitch": 440, "operators": [{"level": 0.0, "env": env(0, 0.01)}], "carriers": [0],
            "noise": {"level": 1.0, "env": {"a": a, "d": d, "s": 0.0, "r": r}},
            "filter": {"type": kind, "cutoff": cutoff, "q": 0.8}}


def tone(hz, dur, a, d, glide=None, cutoff=1400, partial=0.05, chorus=0.8, detune=1.01):
    p = {"duration": dur, "pitch": hz,
         "operators": [{"ratio": 1.0, "level": 1.0, "env": env(a, d)}, {"ratio": 2.0, "level": partial, "env": env(a, d * 0.6)},
                       {"ratio": detune, "level": chorus, "env": env(a * 1.2, d)}],
         "carriers": [0, 1, 2], "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}
    if glide:
        p["pitch_env"] = {"start": glide[0], "end": 1.0, "time": glide[1], "curve": 3.0}
    return p


def wobble(hz, dur, a, d, rate_ratio, depth, glide=None, cutoff=1300):
    """Slow FM wobble: a low modulator (hz * rate_ratio) bends the carrier pair, giving a woozy sway."""
    p = {"duration": dur, "pitch": hz,
         "operators": [{"ratio": 1.0, "level": 1.0, "env": env(a, d)}, {"ratio": 1.012, "level": 0.8, "env": env(a, d)},
                       {"ratio": rate_ratio, "level": 1.0, "env": env(a, d)}],
         "carriers": [0, 1], "mods": [[2, 0, depth], [2, 1, depth]],
         "filter": {"type": "lp", "cutoff": cutoff, "q": 0.7}}
    if glide:
        p["pitch_env"] = {"start": glide[0], "end": 1.0, "time": glide[1], "curve": 2.0}
    return p


def thump(hz, dur, decay, drop=1.6):
    return {"duration": dur, "pitch": hz, "operators": [{"level": 1.0, "env": env(0.003, decay, 0.05)}], "carriers": [0],
            "pitch_env": {"start": drop, "end": 1.0, "time": 0.05, "curve": 4.0}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


def snd(sid, dur, layers, rms=-30):
    return {"id": sid, "alias": "cand11/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


def spray(sid, seed, dur, hz, cut, swell):
    return snd(sid, dur, [
        L(0.0, 1.0, noisy(dur, swell, dur * 0.55, cut, r=0.12)),
        L(0.0, 0.5, tone(hz, dur, 0.04, dur * 0.5, glide=(1.4, 0.15), cutoff=1000, partial=0.0)),
        L(0.0, 0.25, noisy(dur * 0.6, 0.01, dur * 0.3, cut * 2.0, r=0.1)),
    ])


def embrittle(sid, seed, dur, hz, cut):
    return snd(sid, dur, [
        L(0.0, 1.0, thump(hz, dur * 0.7, dur * 0.25, drop=1.9)),
        L(0.02, 0.9, noisy(dur, 0.01, dur * 0.5, cut, r=0.15)),
        L(0.0, 0.4, tone(hz * 2.5, dur * 0.5, 0.02, 0.15, glide=(0.7, 0.2), cutoff=900, partial=0.0)),
    ])


def hallucinate(sid, seed, dur, hz, rate_ratio, depth, glide):
    return snd(sid, dur, [
        L(0.0, 1.0, wobble(hz, dur, 0.08, dur * 0.55, rate_ratio, depth, glide=glide)),
        L(0.05, 0.4, wobble(hz * 1.5, dur * 0.8, 0.1, dur * 0.45, rate_ratio * 1.3, depth * 0.8, glide=glide, cutoff=1100)),
        L(0.0, 0.25, tone(hz / 2, dur, 0.1, dur * 0.5, cutoff=600, partial=0.0)),
    ])


def putrefy(sid, seed, dur, bubbles, base, cut):
    rng = random.Random(seed)
    layers = [L(0.0, 0.6, noisy(dur, 0.05, dur * 0.6, cut, r=0.15))]
    t = 0.0
    for _ in range(bubbles):
        hz = base * rng.uniform(0.8, 1.5)
        layers.append(L(t, rng.uniform(0.7, 1.0), tone(hz, 0.16, 0.008, 0.07, glide=(0.6, 0.07), cutoff=900, partial=0.0, chorus=0.3)))
        t += rng.uniform(0.07, 0.13)
    return snd(sid, dur, layers)


sounds = [
    spray("acid_spray__a1", 1, 0.4, 260, 1400, 0.04),
    spray("acid_spray__a2", 2, 0.5, 200, 1100, 0.06),
    spray("acid_spray__a3", 3, 0.35, 330, 1700, 0.03),
    spray("acid_spray__a4", 4, 0.45, 230, 1250, 0.05),
    embrittle("acid_embrittle__e1", 11, 0.5, 80, 700),
    embrittle("acid_embrittle__e2", 12, 0.6, 65, 550),
    embrittle("acid_embrittle__e3", 13, 0.45, 95, 850),
    embrittle("acid_embrittle__e4", 14, 0.55, 72, 620),
    hallucinate("poison_hallucinate__h1", 21, 0.65, 220, 0.04, 1.5, (0.8, 0.4)),
    hallucinate("poison_hallucinate__h2", 22, 0.7, 175, 0.05, 2.0, (0.75, 0.45)),
    hallucinate("poison_hallucinate__h3", 23, 0.6, 262, 0.035, 1.2, (0.85, 0.35)),
    hallucinate("poison_hallucinate__h4", 24, 0.7, 196, 0.06, 1.8, (0.8, 0.5)),
    putrefy("poison_putrefy__p1", 31, 0.5, 3, 200, 900),
    putrefy("poison_putrefy__p2", 32, 0.6, 4, 160, 700),
    putrefy("poison_putrefy__p3", 33, 0.45, 3, 240, 1000),
    putrefy("poison_putrefy__p4", 34, 0.6, 4, 180, 800),
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "acid_poison_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2039, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
