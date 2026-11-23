"""Thorns, round 2: tonal, pleasant, a little magical and strange, never harsh.

Run:  python assets/sfx/gen_thorns2.py
Then: python -m doomcreator audition assets/sfx/thorns2_candidates.json -o audition_thorns2.html \
        --reference "Doom item pickup=-25.3"

Feedback that shaped this: the spark/crackle thorns were tinny and harsh, and Thorns is heard on EVERY hit taken.
So: no noise at all, everything low-passed (<= 3 kHz), soft glassy tones built from sine + detuned copies and a
touch of gentle FM, pitch glides and slow swells for the "psychedelic" feel, short (0.28-0.42 s), quiet (-28 dBFS
audible RMS). Pleasantness over punch. Variants sit on different pentatonic notes so repeated hits do not
sound like the same tone over and over.
"""
import json
import os

RATE = 44100


def env(a, d, r=0.1):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def tone(hz, dur, a, d, cutoff=2600, fm_ratio=0.0, fm_depth=0.0, sweep=None, partial=0.2, chorus=0.5, detune=1.006, r=0.12):
    ops = [{"ratio": 1.0, "level": 1.0, "env": env(a, d, r)},
           {"ratio": 2.0, "level": partial, "env": env(a, d * 0.7, r)},
           {"ratio": detune, "level": chorus, "env": env(a * 1.3, d, r)}]
    mods = []
    if fm_ratio:
        ops.append({"ratio": fm_ratio, "level": 1.0, "env": env(a, d * 0.45, r)})
        mods = [[3, 0, fm_depth], [3, 2, fm_depth * 0.7]]
    p = {"duration": dur, "pitch": hz, "operators": ops, "carriers": [0, 1, 2], "filter": {"type": "lp", "cutoff": cutoff, "q": 0.7}}
    if mods:
        p["mods"] = mods
    if sweep:
        p["pitch_env"] = {"start": sweep[0], "end": sweep[1], "time": sweep[2], "curve": 2.5}
    return p


def L(off, level, patch):
    return {"offset": off, "level": level, "patch": patch}


def snd(sid, dur, layers, rms=-28):
    return {"id": sid, "alias": "cand5/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


C5, D5, E5, G5, A5, A4, G4, D4 = 523.25, 587.33, 659.25, 783.99, 880.0, 440.0, 392.0, 293.66
sounds = [
    # w1: a glassy "bloop": a tone that glides down a little, soft FM shimmer on the attack
    snd("thorns2__w1", 0.36, [L(0, 1.0, tone(G5, 0.5, 0.008, 0.2, fm_ratio=2.0, fm_depth=0.9, sweep=(1.35, 1.0, 0.1)))]),
    # w2: a quick three-note pentatonic flick, rising
    snd("thorns2__w2", 0.40, [L(0.0, 1.0, tone(C5, 0.4, 0.01, 0.16)), L(0.055, 0.9, tone(D5, 0.4, 0.01, 0.16)),
                              L(0.11, 0.8, tone(G5, 0.4, 0.01, 0.2))]),
    # w3: warm marimba-like bell: gentle FM, no high partials
    snd("thorns2__w3", 0.38, [L(0, 1.0, tone(A4, 0.5, 0.004, 0.22, cutoff=2200, fm_ratio=3.5, fm_depth=0.55, partial=0.1))]),
    # w4: a reversed swell into a soft note (magical "whoom-ting")
    snd("thorns2__w4", 0.42, [L(0, 0.7, tone(D5, 0.45, 0.14, 0.2, cutoff=2000, chorus=0.7, r=0.1)),
                              L(0.14, 0.9, tone(A5, 0.3, 0.006, 0.18, cutoff=2400))]),
    # w5: wide detuned pair: slow beating shimmer, "psychedelic" but smooth
    snd("thorns2__w5", 0.44, [L(0, 1.0, tone(E5, 0.5, 0.03, 0.26, cutoff=2300, chorus=1.0, detune=1.011, partial=0.1)),
                              L(0.0, 0.5, tone(E5 * 1.5, 0.5, 0.05, 0.22, cutoff=2300, chorus=0.8, detune=1.009, partial=0.0))]),
    # w6: a falling "sigh" glide with an octave halo
    snd("thorns2__w6", 0.40, [L(0, 1.0, tone(A5, 0.45, 0.01, 0.24, sweep=(1.0, 0.75, 0.2), partial=0.35))]),
    # w7: low, round, warm: the gentlest
    snd("thorns2__w7", 0.38, [L(0, 1.0, tone(D4, 0.45, 0.012, 0.24, cutoff=1800, fm_ratio=2.0, fm_depth=0.4, partial=0.15, chorus=0.7))]),
    # w8: two notes together (a suspended pair), glassy, slightly strange
    snd("thorns2__w8", 0.40, [L(0, 1.0, tone(D5, 0.45, 0.01, 0.22, fm_ratio=2.0, fm_depth=0.5)),
                              L(0.0, 0.8, tone(G5, 0.45, 0.012, 0.2, fm_ratio=2.0, fm_depth=0.5))]),
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "thorns2_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2032, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
