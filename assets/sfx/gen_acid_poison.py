"""Acid and Poison upgrade cues: quiet, soft, rounded; noise-and-low-tone based (no clicks, no FM zips, no vocal tones).

Run:  python assets/sfx/gen_acid_poison.py
Then: python -m doomcreator audition assets/sfx/acid_poison_candidates.json -o audition_acid_poison.html

Played once from the affected enemy at discrete events, within ~20 m, gated per element (see gen_fire_lightning.py).
  acid/spray       - Acid Spray splashes: a tonal sizzle of tiny soft pentatonic pings over a faint low hum (round 3, no noise).
  acid/embrittle   - Embrittlement shatters an enemy: soft tones stepping down while fading and thinning out (a tonal disintegration).
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
    return {"id": sid, "alias": "cand13/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


def ping(hz, dur, decay, ratio=2.76, metal=0.5, cutoff=3500):
    """A short inharmonic glassy tick (a chip of something brittle), not a drum."""
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.001, decay, 0.01)}, {"ratio": ratio, "level": metal, "env": env(0.001, decay * 0.5, 0.01)}],
            "carriers": [0, 1], "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def spray(sid, seed, dur, density, lo, hi, tail):
    """Round 3: a TONAL sizzle, like fizzing sparkles: many tiny soft sine pings on pentatonic notes (1.2-3.5 kHz), dense
    first then sparser, each only 20-45 ms with a rounded attack. A faint low 'acid' hum underneath. No noise at all."""
    rng = random.Random(seed)
    pen = [1.0, 9 / 8, 5 / 4, 3 / 2, 5 / 3]
    layers = [L(0.0, 0.3, tone(lo / 6, dur, 0.03, dur * tail, cutoff=900, partial=0.0, chorus=0.9, detune=1.015))]
    for _ in range(density):
        t = rng.random() ** 1.6 * dur * 0.8
        hz = rng.uniform(lo, hi)
        hz = lo * pen[rng.randrange(5)] * rng.choice([1.0, 1.0, 2.0]) if rng.random() < 0.7 else hz
        layers.append(L(t, rng.uniform(0.25, 0.8), tone(min(hz, 4200), 0.07, 0.003, rng.uniform(0.012, 0.03), cutoff=4500, partial=0.0, chorus=0.0)))
    return snd(sid, dur, layers)


def embrittle(sid, seed, dur, top, steps, low):
    """Round 3: a tonal DISINTEGRATION: soft rounded tones stepping down in pitch (top -> low) while getting shorter, quieter
    and sparser, each slightly detuned, like something crumbling away. Sine/FM-free, low-passed, no glass, no thump."""
    rng = random.Random(seed)
    layers = []
    t = 0.0
    for i in range(steps):
        f = i / max(1, steps - 1)
        hz = top * (low / top) ** f * rng.uniform(0.97, 1.03)
        d = 0.09 * (1.0 - 0.6 * f)
        layers.append(L(t, 0.9 * (1.0 - 0.7 * f), tone(hz, 0.2, 0.005, d, glide=(1.05, 0.05), cutoff=1500, partial=0.1, chorus=0.7, detune=1.012)))
        t += rng.uniform(0.03, 0.05) * (1.0 + 1.5 * f)
    return snd(sid, dur, layers)


def trippy(hz, dur, a, d, ratio, depth, glide=None, cutoff=2600, detune=1.007):
    """Inharmonic FM shimmer pair: a slightly off-harmonic modulator makes a glassy, bending, 'wrong but pretty' tone."""
    p = {"duration": dur, "pitch": hz,
         "operators": [{"ratio": 1.0, "level": 1.0, "env": env(a, d)}, {"ratio": detune, "level": 0.7, "env": env(a, d)},
                       {"ratio": ratio, "level": 1.0, "env": env(a, d * 0.8)}],
         "carriers": [0, 1], "mods": [[2, 0, depth], [2, 1, depth * 0.8]],
         "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}
    if glide:
        p["pitch_env"] = {"start": glide[0], "end": 1.0, "time": glide[1], "curve": 2.0}
    return p


def hallucinate(sid, seed, dur, root, ratio, depth, echoes, rms=-25):
    """Round 2: psychedelic and a little confusing, pleasant: a rising lydian run of bending inharmonic shimmer tones,
    each answered by a quieter, detuned, pitch-bent echo of itself (a smeared, doubled feeling). Deliberately the most
    prominent of the element cues (louder, longer, more layers)."""
    rng = random.Random(seed)
    scale = [1.0, 9 / 8, 5 / 4, 45 / 32, 3 / 2, 5 / 3, 15 / 8, 2.0]      # C lydian-ish
    layers = [L(0.0, 0.25, trippy(root / 2, dur, 0.1, dur * 0.7, 1.5, 0.6, cutoff=900))]
    idx = sorted(rng.sample(range(8), 4))
    t = 0.0
    for k, i in enumerate(idx):
        hz = root * scale[i]
        layers.append(L(t, 0.9 - 0.1 * k, trippy(hz, 0.45, 0.006, 0.2, ratio, depth, glide=(rng.choice([0.94, 1.06]), 0.12))))
        for e in range(echoes):
            layers.append(L(t + 0.09 * (e + 1) + rng.uniform(0, 0.02), (0.55 - 0.15 * e) * 0.9, trippy(hz * rng.choice([1.0, 1.0, 2.0]) * rng.choice([0.99, 1.01]), 0.4, 0.01, 0.18, ratio * 1.01, depth * 0.8, glide=(rng.choice([0.9, 1.1]), 0.15), detune=1.015)))
        t += rng.uniform(0.07, 0.1)
    return snd(sid, dur, layers, rms=rms)


def blorp(hz, dur, decay, rise=0.55, cutoff=1400):
    """A liquid bubble: a sine whose pitch rises quickly (the pop of a gas bubble), a touch of upper partial."""
    return {"duration": dur, "pitch": hz,
            "operators": [{"ratio": 1.0, "level": 1.0, "env": env(0.004, decay, 0.02)}, {"ratio": 2.0, "level": 0.15, "env": env(0.004, decay * 0.6, 0.02)}],
            "carriers": [0, 1], "pitch_env": {"start": rise, "end": 1.0, "time": decay * 0.9, "curve": 2.5},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.9}}


def putrefy(sid, seed, dur, bubbles, base, spread):
    """Round 2: chemical bubbling like a beaker: liquid 'blorp' bubbles (fast rising pitch, different sizes), a couple of
    tiny glassy ticks for the surface popping. No noise bed, so no whoosh."""
    rng = random.Random(seed)
    layers = []
    t = 0.0
    for _ in range(bubbles):
        hz = base * rng.uniform(1.0, spread)
        layers.append(L(t, rng.uniform(0.6, 1.0), blorp(hz, 0.14, rng.uniform(0.05, 0.1), rise=rng.uniform(0.45, 0.7))))
        if rng.random() < 0.5:
            layers.append(L(t + 0.01, 0.25, ping(hz * 6, 0.06, 0.015, metal=0.3, cutoff=3000)))
        t += rng.uniform(0.05, 0.11)
    return snd(sid, dur, layers)


sounds = [
    spray("acid_spray__c1", 81, 0.4, 36, 1300, 3000, 0.5),
    spray("acid_spray__c2", 82, 0.5, 44, 1000, 2600, 0.6),
    spray("acid_spray__c3", 83, 0.35, 28, 1500, 3500, 0.4),
    spray("acid_spray__c4", 84, 0.45, 40, 1200, 2800, 0.5),
    embrittle("acid_embrittle__d1", 91, 0.55, 520, 9, 130),
    embrittle("acid_embrittle__d2", 92, 0.65, 440, 11, 110),
    embrittle("acid_embrittle__d3", 93, 0.5, 600, 8, 150),
    embrittle("acid_embrittle__d4", 94, 0.6, 480, 10, 120),
    hallucinate("poison_hallucinate__y1", 61, 0.9, 330, 1.414, 1.2, 2),
    hallucinate("poison_hallucinate__y2", 62, 1.0, 262, 1.618, 1.5, 3),
    hallucinate("poison_hallucinate__y3", 63, 0.85, 392, 1.272, 1.0, 2),
    hallucinate("poison_hallucinate__y4", 64, 1.0, 294, 1.5, 1.8, 3),
    putrefy("poison_putrefy__b1", 71, 0.5, 5, 260, 1.8),
    putrefy("poison_putrefy__b2", 72, 0.6, 6, 200, 2.0),
    putrefy("poison_putrefy__b3", 73, 0.45, 4, 320, 1.6),
    putrefy("poison_putrefy__b4", 74, 0.6, 6, 230, 1.9),
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "acid_poison_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2041, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
