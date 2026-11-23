"""Bouncy Shots round 2: complex, organic, layered, still tonal and pleasant.

Run:  python assets/sfx/gen_bouncy2.py
Then: python -m doomcreator audition assets/sfx/bouncy2_candidates.json -o audition_bouncy2.html

Feedback: round 1 (single soft tones) sounded too much like the Thorns chimes. So each sound is now a real
layered effect with several different elements, none of them harsh:
  * a soft electric zap: a quick falling FM zip, low-passed so it is tonal, not a crackle
  * a hum: a low detuned pair with a little FM, beating slowly (the "energy field")
  * a soft thud: a low sine with a quick pitch drop (the field taking the impact), kept gentle
  * a few random notes: 2-4 quiet glassy pentatonic notes at varying moments (different in every variant)
  * a faint high shimmer
Longer (0.34-0.5 s) and lower than the Thorns chimes (centre of mass about 400-800 Hz), quiet (-28 dBFS).
A time gate in the script gives the sound to only about one projectile per 25 tics, so the extra length and
complexity is heard rarely.
"""
import json
import os
import random

RATE = 44100


def env(a, d, r=0.06):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def zap(hz, dur, decay, ratio, depth, sweep, cutoff=2600):
    return {"duration": dur, "pitch": hz,
            "operators": [{"level": 1.0, "env": env(0.002, decay, 0.03)}, {"ratio": ratio, "level": 1.0, "env": env(0.002, decay * 0.7, 0.03)}],
            "carriers": [0], "mods": [[1, 0, depth]],
            "pitch_env": {"start": sweep[0], "end": sweep[1], "time": sweep[2], "curve": 3.5},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def hum(hz, dur, a, d, fm_ratio=1.5, fm_depth=0.5, detune=1.011, cutoff=1500):
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(a, d, 0.1)}, {"ratio": detune, "level": 0.9, "env": env(a * 1.1, d, 0.1)},
                          {"ratio": 2.0, "level": 0.25, "env": env(a, d * 0.7, 0.1)}, {"ratio": fm_ratio, "level": 1.0, "env": env(a, d * 0.5, 0.1)}],
            "carriers": [0, 1, 2], "mods": [[3, 0, fm_depth], [3, 1, fm_depth * 0.8]],
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.7}}


def thud(hz, dur, decay, drop=1.7):
    return {"duration": dur, "pitch": hz, "operators": [{"level": 1.0, "env": env(0.002, decay, 0.03)}], "carriers": [0],
            "pitch_env": {"start": drop, "end": 1.0, "time": 0.04, "curve": 5.0}}


def note(hz, dur, decay, glide=None, cutoff=2400):
    p = {"duration": dur, "pitch": hz,
         "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.004, decay)}, {"ratio": 2.0, "level": 0.2, "env": env(0.004, decay * 0.6)},
                       {"ratio": 1.006, "level": 0.5, "env": env(0.005, decay)}],
         "carriers": [0, 1, 2], "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}
    if glide:
        p["pitch_env"] = {"start": glide[0], "end": 1.0, "time": glide[1], "curve": 3.0}
    return p


def L(off, level, patch):
    return {"offset": off, "level": level, "patch": patch}


PENTA = [392.0, 440.0, 523.25, 587.33, 659.25, 783.99, 880.0]   # G4 A4 C5 D5 E5 G5 A5 (consonant set)


def bounce(sid, seed, dur, hum_hz, hum_lv, zap_hz, zap_lv, thud_hz, thud_lv, n_notes, note_lv, shimmer, rms=-28):
    rng = random.Random(seed)
    layers = [L(0.0, hum_lv, hum(hum_hz, dur, 0.03, dur * 0.55)),
              L(0.0, zap_lv, zap(zap_hz, 0.14, 0.07, 1.5, 1.4, (1.8, 0.6, 0.08))),
              L(0.0, thud_lv, thud(thud_hz, 0.12, 0.06))]
    spots = sorted(rng.sample([0.03, 0.06, 0.09, 0.12, 0.15, 0.19, 0.23], n_notes))
    for off in spots:
        hz = rng.choice(PENTA)
        layers.append(L(off, note_lv * rng.uniform(0.7, 1.0), note(hz, 0.22, 0.12, glide=(rng.choice([0.85, 1.0, 1.15]), 0.04))))
    if shimmer:
        layers.append(L(0.02, shimmer, note(1760, 0.3, 0.2, cutoff=3000)))
    return {"id": sid, "alias": "cand8/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = [
    bounce("bouncy2__m1", 1, 0.40, 190, 1.0, 1100, 0.45, 110, 0.5, 3, 0.45, 0.06),
    bounce("bouncy2__m2", 2, 0.46, 160, 1.0, 1300, 0.35, 95, 0.6, 2, 0.5, 0.0),     # deeper hum, fewer notes
    bounce("bouncy2__m3", 3, 0.36, 220, 0.9, 1500, 0.6, 120, 0.4, 4, 0.4, 0.08),    # zippier, more notes
    bounce("bouncy2__m4", 4, 0.50, 175, 1.0, 900, 0.3, 105, 0.7, 3, 0.5, 0.05),     # long, thuddy
    bounce("bouncy2__m5", 5, 0.38, 205, 0.8, 1200, 0.5, 130, 0.35, 3, 0.55, 0.1),   # more notes up front
    bounce("bouncy2__m6", 6, 0.44, 150, 1.0, 1000, 0.4, 90, 0.55, 2, 0.4, 0.04),    # lowest, humming
    bounce("bouncy2__m7", 7, 0.42, 195, 0.9, 1400, 0.55, 115, 0.45, 4, 0.45, 0.0),
    bounce("bouncy2__m8", 8, 0.48, 180, 1.0, 1150, 0.4, 100, 0.5, 3, 0.6, 0.09),
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bouncy2_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2035, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
