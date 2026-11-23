"""Fire and Lightning upgrade cues (Journeyman/Master tiers): quiet, short, tonal, one family per element.

Run:  python assets/sfx/gen_fire_lightning.py
Then: python -m doomcreator audition assets/sfx/fire_lightning_candidates.json -o audition_fire_lightning.html

Played once from the affected enemy at discrete events (never per tick, no loops), within ~20 m, gated per element.
FIRE (warm, low, soft; low-passed so it never hisses):
  fire/terror  - a low flare: soft rushing noise swelling under a falling warm tone with a faint upper octave.
  fire/spread  - a soft crackle: three or four tiny low-passed noise pops with a quiet ember tone.
LIGHTNING (brighter, glassy, but still low-passed, no harsh crackle):
  lightning/thunder - soft distant thunder: sub thump with a rumble of low noise and a faint zap on top.
  lightning/chain   - a bright arc: quick falling FM zip followed by a short pair of glassy notes.
  lightning/revive  - a rising three-note shimmer (Revivification brings an ally back).
Every sound is quiet (about -30 dBFS audible RMS) and 0.3-0.7 s long.
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


def tone(hz, dur, a, d, glide=None, cutoff=2400, partial=0.2, chorus=0.5, detune=1.006):
    p = {"duration": dur, "pitch": hz,
         "operators": [{"ratio": 1.0, "level": 1.0, "env": env(a, d)}, {"ratio": 2.0, "level": partial, "env": env(a, d * 0.6)},
                       {"ratio": detune, "level": chorus, "env": env(a * 1.2, d)}],
         "carriers": [0, 1, 2], "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}
    if glide:
        p["pitch_env"] = {"start": glide[0], "end": 1.0, "time": glide[1], "curve": 3.0}
    return p


def zip_(hz, dur, decay, depth=1.2, sweep=(2.0, 0.6, 0.08), cutoff=3000):
    return {"duration": dur, "pitch": hz,
            "operators": [{"level": 1.0, "env": env(0.002, decay, 0.03)}, {"ratio": 1.5, "level": 1.0, "env": env(0.002, decay * 0.7, 0.03)}],
            "carriers": [0], "mods": [[1, 0, depth]],
            "pitch_env": {"start": sweep[0], "end": sweep[1], "time": sweep[2], "curve": 3.5},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def thump(hz, dur, decay, drop=1.8):
    return {"duration": dur, "pitch": hz, "operators": [{"level": 1.0, "env": env(0.003, decay, 0.05)}], "carriers": [0],
            "pitch_env": {"start": drop, "end": 1.0, "time": 0.06, "curve": 4.0}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


def snd(sid, dur, layers, rms=-30):
    return {"id": sid, "alias": "cand10/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


def terror(sid, seed, dur, hz, swell, cut):
    rng = random.Random(seed)
    return snd(sid, dur, [
        L(0.0, 0.9, noisy(dur, swell, dur * 0.6, cut, r=0.12)),
        L(0.0, 1.0, tone(hz, dur, 0.04, dur * 0.55, glide=(1.35, 0.25), cutoff=1400, chorus=0.8, detune=1.012)),
        L(0.02, 0.3, tone(hz * 2, dur * 0.8, 0.05, dur * 0.4, glide=(1.2, 0.2), cutoff=1800)),
        L(rng.uniform(0.0, 0.03), 0.4, thump(hz / 2, 0.2, 0.09)),
    ])


def spread(sid, seed, dur, ember_hz, pops, cut):
    rng = random.Random(seed)
    layers = [L(0.0, 0.5, tone(ember_hz, dur, 0.02, dur * 0.6, cutoff=1500, partial=0.1))]
    spots = sorted(rng.uniform(0.0, dur * 0.6) for _ in range(pops))
    for s in spots:
        layers.append(L(s, rng.uniform(0.6, 1.0), noisy(0.07, 0.001, 0.025, rng.choice([cut, cut * 0.7, cut * 1.2]), r=0.02)))
        layers.append(L(s, 0.35, thump(rng.choice([120, 150, 180]), 0.08, 0.03, drop=1.4)))
    return snd(sid, dur, layers)


def thunder(sid, seed, dur, sub, rumble_cut, zap):
    return snd(sid, dur, [
        L(0.0, 1.0, thump(sub, dur * 0.8, dur * 0.3, drop=2.2)),
        L(0.0, 0.8, noisy(dur, 0.02, dur * 0.5, rumble_cut, r=0.15)),
        L(0.0, zap, zip_(900, 0.14, 0.06)),
    ])


def chain(sid, seed, dur, hz, n, cutoff):
    rng = random.Random(seed)
    pen = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]
    layers = [L(0.0, 0.9, zip_(hz, 0.16, 0.07, sweep=(2.2, 0.7, 0.09), cutoff=cutoff))]
    t = 0.05
    for _ in range(n):
        layers.append(L(t, rng.uniform(0.5, 0.8), tone(rng.choice(pen), 0.25, 0.003, 0.1, glide=(1.1, 0.04), cutoff=cutoff)))
        t += rng.uniform(0.03, 0.06)
    return snd(sid, dur, layers)


def revive(sid, seed, dur, base, ratios, step):
    layers = []
    for i, r in enumerate(ratios):
        layers.append(L(i * step, 0.9 - 0.1 * i, tone(base * r, 0.4, 0.01, 0.2, glide=(0.97, 0.05), cutoff=2600, chorus=0.7)))
    layers.append(L(0.0, 0.25, tone(base / 2, dur, 0.06, dur * 0.5, cutoff=900, partial=0.0)))
    return snd(sid, dur, layers)


sounds = [
    terror("fire_terror__f1", 1, 0.55, 150, 0.12, 1100),
    terror("fire_terror__f2", 2, 0.65, 120, 0.2, 900),
    terror("fire_terror__f3", 3, 0.5, 185, 0.08, 1300),
    spread("fire_spread__s1", 11, 0.4, 330, 3, 1500),
    spread("fire_spread__s2", 12, 0.45, 262, 4, 1200),
    spread("fire_spread__s3", 13, 0.35, 392, 3, 1800),
    thunder("lightning_thunder__t1", 21, 0.7, 60, 500, 0.25),
    thunder("lightning_thunder__t2", 22, 0.6, 75, 650, 0.2),
    thunder("lightning_thunder__t3", 23, 0.8, 50, 420, 0.3),
    chain("lightning_chain__c1", 31, 0.4, 1300, 2, 3000),
    chain("lightning_chain__c2", 32, 0.45, 1000, 3, 2600),
    chain("lightning_chain__c3", 33, 0.35, 1600, 2, 3400),
    revive("lightning_revive__r1", 41, 0.55, 392.0, [1.0, 1.25, 1.5], 0.09),
    revive("lightning_revive__r2", 42, 0.6, 440.0, [1.0, 1.5, 2.0], 0.1),
    revive("lightning_revive__r3", 43, 0.5, 349.23, [1.0, 1.2, 1.5, 2.0], 0.07),
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fire_lightning_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2038, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
