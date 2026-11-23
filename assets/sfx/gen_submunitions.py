"""Submunitions: a rhythmic LOOP of several small metal balls pinging, matched to how the bomblets really bounce.

Run:  python assets/sfx/gen_submunitions.py      (needs the toolkit with up to 96 layers)
Then: python -m doomcreator audition assets/sfx/submunitions_candidates.json -o audition_submunitions.html

What the game does (measured with the Live Tester, `watch` op on TFLV_Upgrade_Submunitions_Grenade): the bomblets
spawn within 4 tics of each other 7 tics after the kill, drop 32 units, rebound ELASTICALLY (BounceFactor 1.0, so
no energy is lost) and land again every 17 tics (0.486 s), almost together, until they explode (about 5-6 s at
Submunitions level 1, longer at higher levels: level x 5 s). So the right sound is not a decaying cascade but a
steady rhythm: a small chord of dings every 0.486 s.

Design: one loop of exactly 12 beats (12 x 17 tics = 5.829 s). On every beat each ball pings its own fixed
pentatonic note (so no random note clusters), a few tens of ms apart like the real near-simultaneous landings,
with a tiny timing jitter, plus one very quiet soft thump per beat. A ball or two drops out toward the end, like
bomblets exploding. The loop starts with its first beat 0.10 s in; the in-game sound source starts 12 tics after the
kill, so the first beat lands about 15 tics after the kill, when the first bomblets land. Every ding is
shorter than the gap after the last beat so the loop point is clean. The game stops the loop when the last
bomblet has exploded. Quiet (-28 dBFS), low-passed, pleasant.
"""
import json
import os
import random

RATE = 44100
PERIOD = 17 / 35.0          # seconds between landings (measured)
BEATS = 12
LOOP = round(PERIOD * BEATS, 4)
FIRST = 0.10                # first beat inside the loop


def env(a, d, r=0.04):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def ding(hz, decay, metal, cutoff=3000):
    return {"duration": decay * 1.6 + 0.04, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.002, decay)}, {"ratio": 2.76, "level": metal, "env": env(0.002, decay * 0.4)},
                          {"ratio": 1.004, "level": 0.4, "env": env(0.003, decay)}],
            "carriers": [0, 1, 2], "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def thump(hz, decay=0.05):
    return {"duration": 0.1, "pitch": hz, "operators": [{"level": 1.0, "env": env(0.002, decay, 0.02)}], "carriers": [0],
            "pitch_env": {"start": 1.6, "end": 1.0, "time": 0.03, "curve": 5.0}}


def L(off, level, patch):
    return {"offset": round(off, 4), "level": round(level, 4), "patch": patch}


NOTES = [392.0, 440.0, 523.25, 587.33, 659.25, 783.99]     # G4 A4 C5 D5 E5 G5


def loop(sid, seed, balls, spread, metal, thump_lv, dropouts, decay, rms=-28):
    rng = random.Random(seed)
    notes = rng.sample(NOTES, balls)
    offs = sorted(rng.uniform(0.0, spread) for _ in range(balls))          # when each ball lands within a beat
    lv = [rng.uniform(0.75, 1.0) for _ in range(balls)]
    # which ball drops out at which beat (late in the loop); never below two balls
    drop = {}
    for b in rng.sample(range(balls), min(dropouts, balls - 2)):
        drop[b] = rng.randint(8, BEATS - 1)
    layers = []
    for k in range(BEATS):
        t0 = FIRST + k * PERIOD
        for b in range(balls):
            if b in drop and k >= drop[b]:
                continue
            jitter = rng.uniform(-0.008, 0.008)
            layers.append(L(max(0.0, t0 + offs[b] + jitter), lv[b] * rng.uniform(0.88, 1.0), ding(notes[b], decay, metal)))
        if thump_lv:
            layers.append(L(t0 + 0.01, thump_lv * rng.uniform(0.85, 1.0), thump(rng.choice([100, 115]))))
    return {"id": sid, "alias": "cand9/" + sid.replace("__", "/"),
            "fm": {"duration": LOOP, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = [
    loop("cluster__q1", 21, 5, 0.07, 0.2, 0.12, 1, 0.15),    # five balls, balanced
    loop("cluster__q2", 22, 6, 0.08, 0.15, 0.1, 2, 0.14),    # six balls, softer metal
    loop("cluster__q3", 23, 4, 0.06, 0.3, 0.14, 1, 0.16),    # four balls, more ring and thump, sparser
    loop("cluster__q4", 24, 5, 0.09, 0.12, 0.08, 1, 0.17),   # five, loosest landings, mellow
    loop("cluster__q5", 25, 6, 0.05, 0.25, 0.16, 2, 0.13),   # six, tight landings, firmer
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "submunitions_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2037, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds, loop", LOOP, "s,", max(len(s["fm"]["layers"]) for s in sounds), "layers max")
