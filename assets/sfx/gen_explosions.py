"""Small-explosion sound for Explosive Shots and Submunitions bomblets (replaces the borrowed vanilla imp/shotx).

Run:  python assets/sfx/gen_explosions.py      (needs the toolkit with up to 96 layers)
Then: python -m doomcreator audition assets/sfx/explosions_candidates.json -o audition_explosions.html
Compare by numbers: python assets/sfx/analyze_wav.py candidate.wav

Round 6. Target: a SMALL explosion (an M80 firework, at most a grenade), not artillery. Feedback on rounds 1-5: a bass
drum, a snare, static over a drum, tones too prominent. The bass drum came from the tonal low body (sine or feedback FM
with a pitch drop); white noise itself has little bass, so this round has NO pitched low body at all. Anatomy of a
small blast, one layer group each, all noise except the last:
  1. crack     a very sharp, bright, high-passed burst (about 40 ms): the "bang"
  2. pop       a mid noise body (lp ~3 kHz, 100-150 ms): the body of the bang, with little weight below 150 Hz
  3. whump     a short low-passed noise (lp ~500 Hz, ~100 ms) at low level: a touch of chest, not a drum
  4. smear     copies of the pop at 8-60 ms offsets, falling levels: they are different noise, so this blurs the
               attack into a short room-like tail and blends the layers smoothly
  5. debris    sparse, quiet, high-passed crackle grains falling away over the tail
  6. edge      a few very quiet pentatonic pings (about -26 dB below the crack) around the tail onset, only to
               soften the corners of the noise
About 0.45-0.7 s, -24 dBFS RMS.
"""
import json
import math
import os
import random

RATE = 44100


def env(a, d, r=0.02):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def noise(dur, d, cutoff, kind="lp", a=0.0008, q=0.7):
    return {"duration": dur, "pitch": 100, "operators": [{"ratio": 1.0, "level": 0.0, "env": env(0.001, dur)}],
            "carriers": [0], "noise": {"level": 1.0, "env": env(a, d)},
            "filter": {"type": kind, "cutoff": cutoff, "q": q}}


def ping(hz, dur):
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.002, dur * 0.55)},
                          {"ratio": 2.01, "level": 0.2, "env": env(0.002, dur * 0.3)}],
            "carriers": [0, 1], "filter": {"type": "lp", "cutoff": 4500, "q": 0.7}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


PENTA = [1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0, 2349.3, 2637.0]


def blast(sid, seed, dur, crack_cut, pop_cut, pop_d, whump, tail, debris, edge, rms=-18):
    rng = random.Random(seed)
    layers = [L(0.0, 1.0, noise(0.12, 0.035, crack_cut, kind="hp", a=0.0004)),            # crack
              L(0.0, 0.9, noise(dur, pop_d, pop_cut)),                                    # pop
              L(0.0, whump, noise(0.2, 0.09, 500, a=0.003))]                              # whump
    for k, off in enumerate((0.008, 0.019, 0.034, 0.052)):                                # smear: blurs the attack into a tail
        layers.append(L(off, tail * (0.8 ** k), noise(dur, pop_d * (1.0 + 0.25 * k), pop_cut * (0.8 ** k))))
    for _ in range(int(10 + 22 * debris)):                                                # debris crackle
        t = 0.02 + min(-math.log(1 - rng.random()) * dur * 0.3, dur * 0.8)
        layers.append(L(t, debris * rng.uniform(0.3, 1.0) * (1 - 0.7 * t / dur), noise(0.03, 0.008, rng.choice([2000, 3000, 4500]), kind="hp", a=0.0005)))
    for _ in range(8):                                                                    # very quiet tonal edge
        t = rng.uniform(0.01, dur * 0.45)
        layers.append(L(t, edge * rng.uniform(0.5, 1.0), ping(rng.choice(PENTA), rng.uniform(0.08, 0.18))))
    return {"id": sid, "alias": "cand15/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = [
    blast("explosion__e1", 61, 0.45, 900, 3200, 0.09, 0.25, 0.5, 0.18, 0.05),   # M80: sharp and bright, little body
    blast("explosion__e2", 62, 0.6, 700, 2800, 0.13, 0.4, 0.6, 0.2, 0.05),      # small grenade: more body and tail
    blast("explosion__e3", 63, 0.55, 700, 2400, 0.11, 0.3, 0.6, 0.12, 0.08),    # softer pop, slightly more tonal edge
    blast("explosion__e4", 64, 0.7, 800, 3000, 0.15, 0.35, 0.7, 0.3, 0.06),     # longer tail, more crackle
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "explosions_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2043, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds,", max(len(s["fm"]["layers"]) for s in sounds), "layers max")
