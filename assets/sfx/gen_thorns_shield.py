"""Thorns (reflect damage) and melee Shield sounds.

Run:  python assets/sfx/gen_thorns_shield.py
Then: python -m doomcreator audition assets/sfx/thorns_shield_candidates.json -o audition_ts.html \
        --reference "Doom oof=-18.3" --reference "Doom item pickup=-25.3"

Character, chosen so the cues are told apart by ear:
* thorns__*   reflected damage: a short percussive spark: a crackle of noise, a fast falling electronic zip and
              (in some) a small bright tick. Percussive, not tonal, quiet. Played from the attacker that got hit.
* shield_up__*   the melee shield switching on: a soft tonal force-field swell rising in pitch.
* shield_down__* it fading out: a softer, darker fall.
* shield_hit__*  the shield absorbing a blow: a very short muted tonal pulse.
The tonal ones share the ECM tone family's softness (sine + detuned copy, low-passed) but sit lower and swell.
"""
import json
import os

RATE = 44100


def env(a, d, r=0.05):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def noisy(dur, a, d, cutoff, kind="lp", r=0.02):
    return {"duration": dur, "pitch": 440, "operators": [{"level": 0.0, "env": env(0, 0.01)}], "carriers": [0],
            "noise": {"level": 1.0, "env": {"a": a, "d": d, "s": 0.0, "r": r}},
            "filter": {"type": kind, "cutoff": cutoff, "q": 0.8}}


def zip_fm(dur, hz, ratio, depth, sweep, decay, cutoff=4000):
    return {"duration": dur, "pitch": hz,
            "operators": [{"level": 1.0, "env": env(0.002, decay, 0.02)}, {"ratio": ratio, "level": 1.0, "env": env(0.002, decay * 0.7, 0.02)}],
            "carriers": [0], "mods": [[1, 0, depth]],
            "pitch_env": {"start": sweep[0], "end": sweep[1], "time": sweep[2], "curve": 4.0},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def tick(dur, hz, decay):
    return {"duration": dur, "pitch": hz, "operators": [{"level": 1.0, "env": env(0.001, decay, 0.01)},
                                                        {"ratio": 2.7, "level": 0.5, "env": env(0.001, decay * 0.7, 0.01)}],
            "carriers": [0, 1], "filter": {"type": "lp", "cutoff": 5000, "q": 0.8}}


def swell(dur, hz, a, d, sweep, cutoff, partial=0.3, chorus=0.6, r=0.12):
    """soft tonal pad note with a pitch sweep: sine + octave partial + detuned copy"""
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(a, d, r)}, {"ratio": 2.0, "level": partial, "env": env(a, d * 0.8, r)},
                          {"ratio": 1.005, "level": chorus, "env": env(a * 1.2, d, r)}],
            "carriers": [0, 1, 2], "pitch_env": {"start": sweep[0], "end": sweep[1], "time": sweep[2], "curve": 2.5},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.7}}


def L(off, level, patch):
    return {"offset": off, "level": level, "patch": patch}


def snd(sid, dur, rms, layers):
    return {"id": sid, "alias": "cand4/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = []


# ---- THORNS: spark -------------------------------------------------------------------------------------
def thorns(name, dur, crackle, zip_lv, tick_lv, zip_hz, bursts, rms=-26):
    layers = [L(0.0, zip_lv, zip_fm(0.14, zip_hz, 1.6, 1.8, (2.4, 0.6, 0.06), 0.06))]
    for i in range(bursts):
        layers.append(L(0.004 + 0.018 * i, crackle * (0.7 ** i), noisy(0.04, 0.0, 0.012, 3200 - 400 * i, kind="hp" if i == 0 else "lp")))
    if tick_lv:
        layers.append(L(0.0, tick_lv, tick(0.06, 1900, 0.03)))
    return snd(name, dur, rms, layers)


sounds += [
    thorns("thorns__v1", 0.22, 0.6, 0.8, 0.15, 900, 3),    # balanced spark
    thorns("thorns__v2", 0.18, 0.4, 1.0, 0.0, 1100, 2),    # mostly zip
    thorns("thorns__v3", 0.24, 1.0, 0.5, 0.2, 800, 4),     # crackly static
    thorns("thorns__v4", 0.20, 0.5, 0.7, 0.35, 1400, 2),   # with a bright tick
    thorns("thorns__v5", 0.26, 0.7, 0.9, 0.1, 700, 3),     # lower, fuller
    thorns("thorns__v6", 0.16, 0.5, 0.6, 0.25, 1600, 1),   # very short snap
]


# ---- SHIELD up / down / hit ---------------------------------------------------------------------------
def up(name, dur, hz, a, sweep, cutoff, air, rms=-25):
    layers = [L(0.0, 1.0, swell(dur, hz, a, dur * 0.5, sweep, cutoff)),
              L(0.0, air, noisy(dur * 0.7, 0.05, dur * 0.3, 1400, r=0.1))]
    return snd(name, dur, rms, layers)


sounds += [
    up("shield_up__s1", 0.42, 220, 0.12, (0.6, 1.5, 0.3), 2600, 0.15),
    up("shield_up__s2", 0.50, 180, 0.18, (0.5, 1.8, 0.4), 2200, 0.2),     # slower, lower swell
    up("shield_up__s3", 0.34, 260, 0.08, (0.7, 1.4, 0.2), 3000, 0.1),     # quicker
    up("shield_up__s4", 0.46, 200, 0.14, (0.6, 1.6, 0.35), 2400, 0.0),    # pure tone, no air
]


def down(name, dur, hz, sweep, cutoff, rms=-28):
    return snd(name, dur, rms, [L(0.0, 1.0, swell(dur, hz, 0.03, dur * 0.55, sweep, cutoff, partial=0.2, r=0.15))])


sounds += [
    down("shield_down__t1", 0.40, 330, (1.3, 0.55, 0.3), 2000),
    down("shield_down__t2", 0.46, 260, (1.2, 0.5, 0.4), 1800),
    down("shield_down__t3", 0.32, 380, (1.4, 0.7, 0.22), 2200),
]


def hit(name, dur, hz, cutoff, noise_lv, rms=-28):
    layers = [L(0.0, 1.0, swell(dur, hz, 0.004, dur * 0.5, (1.2, 0.85, 0.05), cutoff, partial=0.4, chorus=0.4, r=0.04))]
    if noise_lv:
        layers.append(L(0.0, noise_lv, noisy(dur * 0.5, 0.0, 0.03, 1500)))
    return snd(name, dur, rms, layers)


sounds += [
    hit("shield_hit__u1", 0.16, 300, 2400, 0.2),
    hit("shield_hit__u2", 0.18, 240, 2000, 0.0),       # purely tonal
    hit("shield_hit__u3", 0.14, 380, 2800, 0.3),       # slightly brighter
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "thorns_shield_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2031, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
