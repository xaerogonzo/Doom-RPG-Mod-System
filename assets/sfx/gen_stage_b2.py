"""Second round of Hyper-V movement sound candidates (jump, double jump, dash) after listening feedback.

Run:  python assets/sfx/gen_stage_b2.py
Then: python -m doomcreator audition assets/sfx/stage_b2_candidates.json -o audition2.html \
        --reference "Doom oof=-18.3" --reference "Doom item pickup=-25.3"

Feedback that shaped this round: the first jump/double-jump sounds were drum-like, clicky, tinny and read as
LANDING (the low thump). So: no thump layer at all; the jump is a soft cloth/gear rustle with a faint
exhale and (regular jump only) a tiny quiet click; the double jump has no click and is floaty (slow
airy swells, a little flutter, an optional very faint rising shimmer). The dash is layered: a modest
whoosh + a very faint electronic zip + a very muted breathy vocal; no strong whoosh.
Everything is darker than before (rustle low-pass 1400-2200 Hz) to avoid the tinny sound.
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


def sine(dur, hz, a, d, r=0.05, sweep=None, cutoff=2000):
    p = {"duration": dur, "pitch": hz, "operators": [{"level": 1.0, "env": env(a, d, r)}], "carriers": [0],
         "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}
    if sweep:
        p["pitch_env"] = {"start": sweep[0], "end": sweep[1], "time": sweep[2], "curve": 3.0}
    return p


def zip_fm(dur, hz, ratio, depth, sweep, decay, cutoff=3200):
    """a short electronic zip: FM pair with a pitch sweep"""
    return {"duration": dur, "pitch": hz,
            "operators": [{"level": 1.0, "env": env(0.003, decay, 0.03)}, {"ratio": ratio, "level": 1.0, "env": env(0.003, decay * 0.7, 0.02)}],
            "carriers": [0], "mods": [[1, 0, depth]],
            "pitch_env": {"start": sweep[0], "end": sweep[1], "time": sweep[2], "curve": 3.0},
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.8}}


def vowel(dur, f1, f2, a, d):
    """a muted breathy 'ah': two quiet low-passed formant sines"""
    return {"duration": dur, "pitch": f1,
            "operators": [{"level": 1.0, "env": env(a, d, 0.05)}, {"ratio": f2 / f1, "level": 0.6, "env": env(a, d, 0.05)}],
            "carriers": [0, 1], "filter": {"type": "lp", "cutoff": 1700, "q": 0.8}}


def L(off, level, patch):
    return {"offset": off, "level": level, "patch": patch}


def snd(sid, dur, rms, layers):
    return {"id": sid, "alias": "cand2/" + sid.replace("__", "/"),
            "fm": {"duration": dur, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


sounds = []


# ---- JUMP: rustle, faint exhale, optional tiny click; no thump --------------------------------------
def jump(name, dur, cut, rustle, exhale, click, soft_push, rms):
    layers = [
        L(0.0, rustle, noisy(0.22, 0.02, 0.1, cut, r=0.06)),
        L(0.05, rustle * 0.7, noisy(0.18, 0.015, 0.08, cut * 0.75, r=0.05)),
        L(0.09, rustle * 0.45, noisy(0.14, 0.012, 0.06, cut * 0.6, r=0.04)),
    ]
    if soft_push:
        layers.append(L(0.0, soft_push, noisy(0.08, 0.01, 0.035, 320, r=0.03)))      # a soft push, not a thud
    if exhale:
        layers.append(L(0.01, exhale, noisy(0.18, 0.03, 0.09, 1400, r=0.07)))
    if click:
        layers.append(L(0.0, click, noisy(0.02, 0.0, 0.004, 3000, r=0.004)))        # tiny, quiet
    return snd(name, dur, rms, layers)


sounds += [
    jump("jump__f1", 0.32, 1800, 1.0, 0.0, 0.12, 0.0, -24),            # rustle + tiny click
    jump("jump__f2", 0.32, 1600, 1.0, 0.35, 0.10, 0.15, -24),          # + faint exhale
    jump("jump__f3", 0.36, 1400, 0.9, 0.4, 0.12, 0.25, -24),           # darker, a little more body
    jump("jump__f4", 0.28, 2200, 1.0, 0.0, 0.0, 0.0, -25),             # no click at all
    jump("jump__f5", 0.34, 1600, 0.8, 0.5, 0.0, 0.1, -24),             # breathier, no click
]


# ---- DOUBLE JUMP: floaty, no click ------------------------------------------------------------------
def djump(name, dur, swell_lv, flutter_lv, shimmer_lv, exhale_lv, cut, rms):
    layers = [
        L(0.0, swell_lv, noisy(dur, 0.09, dur * 0.55, cut, r=0.1)),
        L(0.04, swell_lv * 0.5, noisy(dur, 0.12, dur * 0.45, cut * 1.5, r=0.1)),
    ]
    for i, off in enumerate((0.05, 0.1, 0.15)):
        layers.append(L(off, flutter_lv * (0.75 ** i), noisy(0.06, 0.006, 0.03, 1800, r=0.02)))
    if shimmer_lv:
        layers.append(L(0.0, shimmer_lv, sine(dur, 520, 0.12, dur * 0.5, r=0.12, sweep=(0.85, 1.35, dur * 0.7), cutoff=1800)))
    if exhale_lv:
        layers.append(L(0.02, exhale_lv, noisy(0.2, 0.05, 0.1, 1300, r=0.08)))
    return snd(name, dur, rms, layers)


sounds += [
    djump("doublejump__g1", 0.46, 1.0, 0.3, 0.0, 0.0, 1600, -24),
    djump("doublejump__g2", 0.50, 1.0, 0.25, 0.08, 0.0, 1500, -24),    # faint rising shimmer
    djump("doublejump__g3", 0.46, 0.9, 0.35, 0.0, 0.3, 1700, -24),     # + exhale
    djump("doublejump__g4", 0.56, 1.0, 0.2, 0.06, 0.25, 1400, -24),    # longest, floatiest
    djump("doublejump__g5", 0.40, 1.0, 0.4, 0.0, 0.0, 1900, -24),      # lighter, quicker
]


# ---- DASH: modest whoosh + faint electronic zip + very muted breath ----------------------------------
def dash(name, dur, whoosh, air, zip_lv, vocal_lv, zip_hz, rms):
    layers = [
        L(0.0, whoosh, noisy(dur, 0.07, dur * 0.5, 1200, r=0.08)),
        L(0.0, air, noisy(dur, 0.06, dur * 0.45, 2400, r=0.07)),
        L(0.0, zip_lv, zip_fm(dur * 0.6, zip_hz, 1.5, 1.6, (0.6, 2.0, dur * 0.35), dur * 0.3)),
        L(0.08, zip_lv * 0.5, zip_fm(dur * 0.5, zip_hz * 1.5, 2.0, 1.2, (2.0, 0.7, dur * 0.3), dur * 0.25)),
    ]
    if vocal_lv:
        layers.append(L(0.0, vocal_lv, vowel(dur, 520, 1150, 0.03, dur * 0.4)))
        layers.append(L(0.0, vocal_lv * 1.6, noisy(dur * 0.6, 0.03, dur * 0.3, 1100, r=0.06)))   # the breath itself
    return snd(name, dur, rms, layers)


sounds += [
    dash("dash__h1", 0.32, 0.6, 0.2, 0.1, 0.0, 600, -24),     # whoosh + electronic only
    dash("dash__h2", 0.32, 0.6, 0.2, 0.1, 0.1, 600, -24),     # + muted vocal breath
    dash("dash__h3", 0.34, 0.45, 0.15, 0.18, 0.1, 700, -24),  # more electronic
    dash("dash__h4", 0.34, 0.8, 0.25, 0.08, 0.14, 500, -23),  # more whoosh and vocal
    dash("dash__h5", 0.30, 0.5, 0.15, 0.14, 0.18, 650, -24),  # vocal-forward
    dash("dash__h6", 0.28, 0.35, 0.1, 0.22, 0.0, 800, -24),   # mostly electronic zip
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "stage_b2_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2029, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
