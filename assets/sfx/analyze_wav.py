"""Print a sound's energy per octave band over time, so two sounds can be compared by numbers instead of by ear.

Run:  python assets/sfx/analyze_wav.py a.wav [b.wav ...]
Each row is an octave band (centre Hz), each column a 50 ms frame, values are dB relative to the loudest cell of the
file (0 = loudest, -60 and below printed as '.'). Also prints total RMS, peak and the time the level falls 20 dB.
Use: render a reference (for example `python -m doomcreator sound explosion -o ref.wav`), then compare candidates:
a candidate that has the same shape (which bands carry the energy, and how long each band lasts) sounds similar.
"""
import sys
import wave

import numpy as np

BANDS = [(31, 62), (62, 125), (125, 250), (250, 500), (500, 1000), (1000, 2000), (2000, 4000), (4000, 8000), (8000, 16000)]
FRAME = 0.05


def load(path):
    w = wave.open(path)
    n, ch, rate = w.getnframes(), w.getnchannels(), w.getframerate()
    x = np.frombuffer(w.readframes(n), dtype="<i2").astype(np.float64) / 32768.0
    return x.reshape(-1, ch).mean(axis=1), rate


def analyze(path):
    x, rate = load(path)
    hop = int(rate * FRAME)
    frames = len(x) // hop
    grid = np.zeros((len(BANDS), frames))
    freqs = np.fft.rfftfreq(hop * 2, 1.0 / rate)
    win = np.hanning(hop * 2)
    for f in range(frames):
        seg = x[f * hop:f * hop + hop * 2]
        if len(seg) < hop * 2:
            seg = np.pad(seg, (0, hop * 2 - len(seg)))
        p = np.abs(np.fft.rfft(seg * win)) ** 2
        for b, (lo, hi) in enumerate(BANDS):
            grid[b, f] = p[(freqs >= lo) & (freqs < hi)].sum()
    db = 10 * np.log10(grid + 1e-12)
    db -= db.max()
    rms = 20 * np.log10(np.sqrt((x ** 2).mean()) + 1e-12)
    peak = 20 * np.log10(np.abs(x).max() + 1e-12)
    env = np.sqrt((x[:frames * hop].reshape(frames, hop) ** 2).mean(axis=1))
    env_db = 20 * np.log10(env / env.max() + 1e-12)
    fall = next((i * FRAME for i, v in enumerate(env_db) if i > env_db.argmax() and v < -20), frames * FRAME)
    print("%s  %.2fs  rms %.1f dB  peak %.1f dB  -20 dB at %.2fs" % (path, len(x) / rate, rms, peak, fall))
    for b in range(len(BANDS) - 1, -1, -1):
        cells = "".join("." if v < -60 else "%2d" % min(99, int(-v) // 6) for v in db[b])      # tens of... 0..9 = every 6 dB down
        print("%6d Hz | %s" % (int(np.sqrt(BANDS[b][0] * BANDS[b][1])), cells))
    print("          (digit = 6 dB steps below the loudest cell; '.' = below -60 dB)")


for p in sys.argv[1:]:
    analyze(p)
    print()
