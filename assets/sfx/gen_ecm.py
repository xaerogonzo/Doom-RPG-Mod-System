"""ECM feedback sounds: "hacked" (a missile was redirected or reprogrammed) and "failed" (the hack did not work).

Run:  python assets/sfx/gen_ecm.py
Then: python -m doomcreator audition assets/sfx/ecm_candidates.json -o audition_ecm.html \
        --reference "Doom oof=-18.3" --reference "Doom item pickup=-25.3"

Brief: gentle, harmonic, tonal, easy to listen to; subtle, not harsh or alarm-like, quiet.
Design: soft synth notes (a sine, a quiet octave partial and a slightly detuned copy for a little chorus),
slow-ish attack, low-passed, staggered by layer offsets into a short two- or three-note figure.
"hacked" rises (a consonant, "confirmed" interval); "failed" falls and is softer and darker.
Loudness: audible RMS -26 to -28 dBFS, a little under Doom's item pickup (-25).
"""
import json
import os

RATE = 44100


def env(a, d, r=0.12):
    return {"a": a, "d": d, "s": 0.0, "r": r}


def note(hz, dur, a, d, cutoff, partial=0.25, chorus=0.5):
    """one soft synth note: sine + quiet octave partial + slightly detuned copy"""
    ops = [{"ratio": 1.0, "level": 1.0, "env": env(a, d)},
           {"ratio": 2.0, "level": partial, "env": env(a, d * 0.7)},
           {"ratio": 1.004, "level": chorus, "env": env(a * 1.2, d)}]
    return {"duration": dur, "pitch": hz, "operators": ops, "carriers": [0, 1, 2],
            "filter": {"type": "lp", "cutoff": cutoff, "q": 0.7}}


def L(off, level, patch):
    return {"offset": off, "level": level, "patch": patch}


def figure(sid, notes, step, rms, cutoff=3200, a=0.015, d=0.2, partial=0.25, chorus=0.5, dur=None, falloff=0.85):
    """notes: list of Hz, played step seconds apart, each a little quieter than the last"""
    total = dur or (step * (len(notes) - 1) + d + 0.25)
    layers = [L(step * i, falloff ** i, note(hz, d + 0.3, a, d, cutoff, partial, chorus)) for i, hz in enumerate(notes)]
    return {"id": sid, "alias": "cand3/" + sid.replace("__", "/"),
            "fm": {"duration": total, "sample_rate": RATE, "gain": 0.9, "target_rms_dbfs": rms, "layers": layers}}


C5, D5, E5, G5, A5, C6 = 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5
E4, G4, A4, C4, D4 = 329.63, 392.0, 440.0, 261.63, 293.66

sounds = [
    # hacked: rising, consonant
    figure("hacked__a1", [C5, G5], 0.10, -27),                                  # rising fifth
    figure("hacked__a2", [C5, E5, G5], 0.08, -27, falloff=0.9),                 # soft rising arpeggio
    figure("hacked__a3", [E5, A5], 0.11, -27, cutoff=2800, chorus=0.7),         # rising fourth, warmer
    figure("hacked__a4", [G5, C6], 0.09, -28, cutoff=3800, partial=0.15, d=0.16),   # lighter, higher, quicker
    figure("hacked__a5", [C5, G5, C6], 0.075, -27, d=0.22, chorus=0.6),         # fifth + octave, fuller
    # failed: falling, softer and darker
    figure("failed__b1", [G5, E5], 0.11, -28, cutoff=2200, d=0.22),             # falling minor third
    figure("failed__b2", [E5, C5], 0.12, -28, cutoff=2000, d=0.24, chorus=0.7),     # falling major third, darker
    figure("failed__b3", [A4, E4], 0.13, -28, cutoff=1800, d=0.26),             # lower falling fifth
    figure("failed__b4", [G5, E5, C5], 0.09, -29, cutoff=2200, d=0.2, falloff=0.8),    # three-step sigh
    figure("failed__b5", [E5, D5], 0.10, -28, cutoff=2100, d=0.2, partial=0.15),    # a small falling step, the gentlest
]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ecm_candidates.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"schema_version": 1, "seed": 2030, "sounds": sounds}, f, indent=1)
print("wrote", out, len(sounds), "sounds")
