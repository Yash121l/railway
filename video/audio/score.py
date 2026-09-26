"""Synthesizes the launch score to public/score.wav, locked to src/timeline.json's beat grid."""

import json
from pathlib import Path

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, fftconvolve, sosfilt

ROOT = Path(__file__).resolve().parent.parent
TL = json.loads((ROOT / "src/timeline.json").read_text())
SR = 48000
B = 60.0 / TL["bpm"]
DUR = TL["totalBeats"] * B + 0.5
N = int(DUR * SR)
rng = np.random.default_rng(7)

SCENE = {s["id"]: s["from"] for s in TL["scenes"]}


def buf():
    return np.zeros((N, 2))


drums, bass, pad, keys, fx, send = buf(), buf(), buf(), buf(), buf(), buf()


def t_(n):
    return np.arange(n) / SR


def add(bus, at, sig, gain=1.0, pan=0.0, rev=0.0):
    i = int(at * SR)
    if i >= N or i + len(sig) <= 0:
        return
    if sig.ndim == 1:
        l, r = np.sqrt(0.5 * (1 - pan)), np.sqrt(0.5 * (1 + pan))
        sig = np.stack([sig * l, sig * r], axis=1) * np.sqrt(2)
    j = min(N, i + len(sig))
    bus[i:j] += sig[: j - i] * gain
    if rev:
        send[i:j] += sig[: j - i] * gain * rev


def lp(x, fc, order=2):
    return sosfilt(butter(order, min(fc, SR * 0.45), "low", fs=SR, output="sos"), x, axis=0)


def hp(x, fc, order=2):
    return sosfilt(butter(order, fc, "high", fs=SR, output="sos"), x, axis=0)


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, min(hi, SR * 0.45)], "band", fs=SR, output="sos"), x, axis=0)


def note(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# ---------- instruments ----------


def kick(gain=1.0):
    t = t_(int(0.5 * SR))
    f = 44 + 110 * np.exp(-t / 0.03)
    ph = 2 * np.pi * np.cumsum(f) / SR
    body = np.sin(ph) * np.exp(-t / 0.28)
    click = hp(rng.standard_normal(len(t)), 2000) * np.exp(-t / 0.004) * 0.25
    return np.tanh((body + click) * 1.6) * gain


def clap():
    n = int(0.35 * SR)
    t = t_(n)
    noise = bp(rng.standard_normal(n), 900, 5000)
    env = np.zeros(n)
    for k, d in enumerate([0.0, 0.011, 0.022]):
        i = int(d * SR)
        env[i:] += np.exp(-(t[: n - i]) / (0.008 if k < 2 else 0.12))
    return noise * env * 0.5


def hat(open_=False):
    n = int((0.25 if open_ else 0.06) * SR)
    t = t_(n)
    return hp(rng.standard_normal(n), 7000) * np.exp(-t / (0.08 if open_ else 0.014)) * 0.35


def clack(gain=1.0):
    n = int(0.12 * SR)
    t = t_(n)
    metal = bp(rng.standard_normal(n), 1800, 4200) * np.exp(-t / 0.012)
    thunk = np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.03) * 0.6
    return (metal * 0.8 + thunk) * gain


def flap_clatter(length=0.42, gain=1.0):
    n = int(length * SR)
    out = np.zeros(n)
    pos = 0.0
    while pos < length - 0.02:
        i = int(pos * SR)
        m = int(0.012 * SR)
        tick = bp(rng.standard_normal(m), 2500, 7500) * np.exp(-t_(m) / 0.0025)
        tick += np.sin(2 * np.pi * rng.uniform(900, 1400) * t_(m)) * np.exp(-t_(m) / 0.003) * 0.3
        out[i : i + m] += tick * (1 - pos / length) ** 0.5
        pos += rng.uniform(0.012, 0.03) * (1 + pos * 2)
    return out * gain


def supersaw(freq, dur, voices=5, detune=0.012, cutoff=1800):
    n = int(dur * SR)
    t = t_(n)
    out = np.zeros((n, 2))
    for v in range(voices):
        d = 1 + detune * (v - (voices - 1) / 2) / ((voices - 1) / 2)
        ph = rng.uniform(0, 1)
        saw = 2 * ((freq * d * t + ph) % 1) - 1
        pan = (v / (voices - 1)) * 2 - 1
        out[:, 0] += saw * np.sqrt(0.5 * (1 - pan))
        out[:, 1] += saw * np.sqrt(0.5 * (1 + pan))
    return lp(out / voices, cutoff, 4)


def pad_chord(at, notes, dur, gain=0.18, cutoff=1800, attack=0.25):
    n = int(dur * SR)
    t = t_(n)
    env = np.minimum(1, t / attack) * np.minimum(1, (dur - t) / 0.3)
    sig = sum(supersaw(note(m), dur, cutoff=cutoff) for m in notes)
    add(pad, at, sig * env[:, None], gain, rev=0.35)


def pluck(freq, dur=0.35, bright=4000):
    n = int(dur * SR)
    t = t_(n)
    saw = 2 * ((freq * t) % 1) - 1
    sq = np.sign(np.sin(2 * np.pi * freq * 2 * t)) * 0.3
    return lp(saw + sq, bright) * np.exp(-t / 0.09)


def bell(freq, dur=1.6):
    t = t_(int(dur * SR))
    partials = [(1, 1), (2.76, 0.4), (5.4, 0.2), (8.93, 0.1)]
    return sum(a * np.sin(2 * np.pi * freq * r * t) * np.exp(-t / (0.9 / r**0.5)) for r, a in partials) * 0.4


def bass_note(freq, dur):
    n = int(dur * SR)
    t = t_(n)
    saw = 2 * ((freq * t) % 1) - 1
    sub = np.sin(2 * np.pi * freq * t)
    env = np.minimum(1, t / 0.005) * np.exp(-t / 0.35) * np.minimum(1, (dur - t) / 0.02)
    return (lp(saw, 520) * 0.6 + sub) * env


def riser(dur, gain=0.3):
    n = int(dur * SR)
    t = t_(n)
    x = t / dur
    noise = rng.standard_normal(n)
    out = np.zeros(n)
    seg = int(0.01 * SR)
    zi = np.zeros((2, 2))
    for i in range(0, n, seg):
        fc = 300 + 9000 * x[i] ** 2
        sos = butter(2, [fc * 0.7, min(fc * 1.3, SR * 0.45)], "band", fs=SR, output="sos")
        out[i : i + seg], zi = sosfilt(sos, noise[i : i + seg], zi=zi)
    tone = np.sin(2 * np.pi * np.cumsum(200 + 900 * x**2) / SR) * 0.15
    return (out + tone) * x**2 * gain


def whoosh(dur=0.5, gain=0.35):
    n = int(dur * SR)
    t = t_(n)
    x = t / dur
    env = np.sin(np.pi * x) ** 2
    noise = rng.standard_normal(n)
    lo = lp(noise, 1200)
    hi = bp(noise, 1500, 6000)
    mix = lo * (1 - x) + hi * x
    return mix * env * gain


def impact(gain=1.0):
    n = int(3.5 * SR)
    t = t_(n)
    f = 30 + 40 * np.exp(-t / 0.15)
    boom = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.9)
    crash = hp(rng.standard_normal(n), 3000) * np.exp(-t / 0.45) * 0.15
    return np.tanh((boom * 1.4 + crash)) * gain


def horn(dur, gain=0.4, cutoff=1400):
    n = int(dur * SR)
    t = t_(n)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t)
    sig = np.zeros(n)
    for f in (311.1, 392.0, 466.2):
        ph = np.cumsum(f * vib) / SR
        sig += (2 * (ph % 1) - 1) * 0.6 + np.sign(np.sin(2 * np.pi * ph)) * 0.25
    env = np.minimum(1, t / 0.08) * np.minimum(1, (dur - t) / 0.2)
    return lp(sig, cutoff, 3) * env * gain / 3


def rumble(dur, gain=0.5):
    n = int(dur * SR)
    brown = np.cumsum(rng.standard_normal(n))
    brown = hp(brown, 20)
    brown /= np.max(np.abs(brown)) + 1e-9
    x = t_(n) / dur
    return lp(brown, 180) * x**2.2 * gain


def ui_blip(up=True):
    t = t_(int(0.18 * SR))
    f = (600 + 900 * t / 0.18) if up else (1500 - 900 * t / 0.18)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.06) * 0.3


# ---------- harmony ----------

D3, F3, A3, Bb2, C3, E3, G3 = 50, 53, 57, 46, 48, 52, 55
PROG = [[D3, F3, A3], [Bb2, D3, F3], [F3 - 12 + 12, A3, C3 + 12], [C3, E3, G3]]
ROOTS = [38, 34, 41, 36]


def bar_of(beat):
    return int(beat // 4) % 4


def at(beat):
    return beat * B


# ---------- arrangement ----------

kicks = []

# hook: low drone, ticking clock, a flap clatter and thud on every word
drone_len = at(8)
t = t_(int(drone_len * SR))
drone = (np.sin(2 * np.pi * note(38) * t) + 0.4 * lp(2 * ((note(50) * t) % 1) - 1, 400)) * np.minimum(1, t / 1.2)
add(pad, 0, drone, 0.22)
for k in range(16):
    add(drums, at(k / 2), hat(), 0.25 if k % 2 else 0.4, pan=0.3)
for i in range(4):
    add(fx, at(i * 2) + 0.01, flap_clatter(0.5, 0.55), pan=-0.1, rev=0.15)
    add(drums, at(i * 2), kick(0.55))
pad_chord(at(4), [D3, A3], at(4), 0.10, cutoff=700, attack=1.5)

# headlights: distant horn, approaching rumble, accelerating rail joints, riser
hs = at(SCENE["headlights"])
add(fx, hs + 0.1, horn(1.1, 0.28, 900), rev=0.6)
add(fx, hs + 1.35, horn(0.5, 0.45, 1800), rev=0.5)
add(fx, hs, rumble(at(4), 0.9))
gap = 0.42
pos = hs + 0.2
while pos < hs + at(4) - 0.05:
    x = (pos - hs) / at(4)
    add(drums, pos, clack(0.35 + 0.6 * x), pan=-0.2)
    add(drums, pos + gap * 0.22, clack(0.3 + 0.5 * x), pan=0.2)
    pos += gap
    gap = max(0.14, gap * 0.9)
add(fx, hs + at(4) - 1.9, riser(1.9, 0.45))

# logo: impact, open pad, shimmering high plucks
ls = at(SCENE["logo"])
add(fx, ls, impact(1.0), rev=0.4)
kicks.append(ls)
pad_chord(ls, [D3, A3, D3 + 12, F3 + 12], at(8), 0.2, cutoff=2400, attack=0.05)
for k in range(16):
    m = [74, 77, 81, 86][k % 4]
    add(keys, ls + at(k / 2), pluck(note(m), 0.4, 6000), 0.10 * (0.5 + 0.5 * np.sin(k / 3)), pan=0.4 * np.sin(k), rev=0.5)
add(fx, ls + at(8) - 1.2, riser(1.2, 0.35))


def groove(b0, b1, arp=False, hats=True, clacks=True):
    for b in range(b0, b1):
        tb = at(b)
        add(drums, tb, kick(1.0))
        kicks.append(tb)
        if b % 2 == 1:
            add(drums, tb, clap(), 0.8, rev=0.2)
        if hats:
            add(drums, tb + B / 2, hat(open_=(b % 4 == 3)), 0.55, pan=0.25)
        if clacks:
            add(drums, tb + B * 0.25, clack(0.22), pan=-0.35)
            add(drums, tb + B * 0.375, clack(0.16), pan=-0.35)
        root = ROOTS[bar_of(b)]
        for e in range(2):
            add(bass, tb + e * B / 2, bass_note(note(root), B / 2 - 0.01), 0.55)
        if arp:
            chord = PROG[bar_of(b)]
            for s in range(4):
                m = chord[(b * 4 + s) % 3] + 24
                add(keys, tb + s * B / 4, pluck(note(m), 0.25, 3500), 0.085, pan=0.5 * np.sin(s * 1.7 + b), rev=0.3)
    for bar in range(b0 // 4, b1 // 4):
        pad_chord(at(bar * 4), PROG[bar % 4], at(4), 0.14, cutoff=2000)


groove(SCENE["network"], SCENE["home"], arp=False)
groove(SCENE["home"], SCENE["slam"] - 2, arp=True)
for b in (SCENE["home"], SCENE["fly"], SCENE["detail"], SCENE["pnr"], SCENE["add"], SCENE["live"], SCENE["passport"]):
    add(fx, at(b) - 0.25, whoosh(0.5, 0.35), rev=0.2)

CLIPS = TL["clips"]


def clip_moment(scene_id, clip_seconds):
    """Beat at which a moment `clip_seconds` into the trimmed clip plays."""
    return SCENE[scene_id] + (clip_seconds / CLIPS[scene_id]["rate"]) / B


def tap_click():
    t = t_(int(0.05 * SR))
    return (np.sin(2 * np.pi * 1800 * t) * np.exp(-t / 0.006) + hp(rng.standard_normal(len(t)), 3000) * np.exp(-t / 0.003) * 0.4) * 0.6


# fly: the tap, then the globe swoops to the route
tap_b = clip_moment("fly", CLIPS["fly"]["tapAt"])
add(fx, at(tap_b), tap_click(), 0.9)
add(fx, at(tap_b) + 0.05, whoosh(1.4, 0.45), pan=-0.2, rev=0.3)

# pnr: the status resolves to confirmed
res_b = clip_moment("pnr", CLIPS["pnr"]["resultAt"])
add(keys, at(res_b), bell(note(81)), 0.35, rev=0.5)
add(keys, at(res_b) + 0.12, bell(note(86)), 0.25, rev=0.5)

# add: the checkmark lands
add_b = clip_moment("add", CLIPS["add"]["addedAt"])
add(keys, at(add_b), bell(note(79)), 0.3, rev=0.5)
add(keys, at(add_b) + 0.1, bell(note(86)), 0.3, rev=0.5)

# live: island expands, lock-screen card arrives
add(fx, at(SCENE["live"] + 40 / 30), ui_blip(True), 0.8, rev=0.3)
add(fx, at(SCENE["live"] + 110 / 30), ui_blip(False), 0.5, rev=0.3)

# build into the slam
sb = SCENE["slam"]
for k in range(8):
    add(drums, at(sb - 2) + k * B / 4, clap(), 0.3 + k * 0.08)
add(fx, at(sb - 2), riser(at(2), 0.4))

for item in TL["slam"]:
    tb = at(sb + item["beat"])
    last = item is TL["slam"][-1]
    add(drums, tb, kick(1.1))
    add(fx, tb, impact(0.55 if not last else 1.0), rev=0.3)
    chord = PROG[bar_of(sb + item["beat"])]
    add(pad, tb, supersaw(note(chord[0]), 0.45, cutoff=3500) * np.exp(-t_(int(0.45 * SR)) / 0.15)[:, None], 0.35)
    add(pad, tb, supersaw(note(chord[2] + 12), 0.45, cutoff=3500) * np.exp(-t_(int(0.45 * SR)) / 0.15)[:, None], 0.25)
    kicks.append(tb)
for b in range(sb, SCENE["honest"]):
    add(drums, at(b) + B / 2, hat(), 0.45)
    add(bass, at(b), bass_note(note(ROOTS[bar_of(b)]), B - 0.02), 0.5)

# honest: breakdown, just pad and a sparse melody
hb = SCENE["honest"]
pad_chord(at(hb), [D3, F3, A3, D3 + 12], at(4), 0.16, cutoff=900, attack=0.6)
pad_chord(at(hb + 4), [Bb2, D3, F3, A3], at(4), 0.16, cutoff=900, attack=0.6)
for k, m in enumerate([81, 77, 76, 74, 72, 74]):
    add(keys, at(hb + 0.5 + k * 1.2), bell(note(m), 1.4), 0.2, pan=0.2 * np.sin(k), rev=0.6)
add(fx, at(SCENE["end"]) - 1.6, riser(1.6, 0.4))

# end: final impact, full chord, one bar of groove, then the train rolls to a stop
eb = SCENE["end"]
add(fx, at(eb), impact(1.0), rev=0.5)
kicks.append(at(eb))
pad_chord(at(eb), [D3, A3, D3 + 12, F3 + 12, A3 + 12], at(12), 0.2, cutoff=2600, attack=0.03)
add(bass, at(eb), bass_note(note(38), 2.5), 0.6)
for k in range(24):
    m = [74, 77, 81, 86, 81, 77][k % 6]
    add(keys, at(eb + 1 + k / 2), pluck(note(m), 0.4, 5000), 0.09 * (1 - k / 30), pan=0.4 * np.sin(k), rev=0.5)
gap = 0.16
pos = at(eb + 2)
while pos < at(eb + 11):
    add(drums, pos, clack(0.3), pan=-0.2)
    add(drums, pos + gap * 0.3, clack(0.25), pan=0.2)
    pos += gap
    gap *= 1.12
add(keys, at(eb + 8), bell(note(74), 3.0), 0.25, rev=0.7)

# ---------- mix ----------

tt = t_(N)
duck = np.ones(N)
for k in sorted(kicks):
    i = int(k * SR)
    m = min(N - i, int(0.3 * SR))
    if m > 0:
        duck[i : i + m] = np.minimum(duck[i : i + m], 1 - 0.55 * np.exp(-t_(m) / 0.09))
pad *= duck[:, None]
bass *= duck[:, None] ** 0.5

ir_n = int(2.4 * SR)
irt = t_(ir_n)
ir = rng.standard_normal((ir_n, 2)) * np.exp(-irt / 0.55)[:, None]
ir = lp(ir, 5000)
ir /= np.sqrt(np.sum(ir**2, axis=0))
wet = np.stack([fftconvolve(send[:, c], ir[:, c])[:N] for c in range(2)], axis=1)

mix = drums * 0.9 + bass * 0.8 + pad * 1.0 + keys * 1.0 + fx * 0.9 + wet * 0.35
mix = hp(mix, 28)
mix = np.tanh(mix * 1.15) / np.tanh(1.15)
mix *= 0.93 / np.max(np.abs(mix))
fade = np.minimum(1, (DUR - tt) / 0.6)
mix *= fade[:, None]

out = ROOT / "public/score.wav"
wavfile.write(out, SR, (mix * 32767).astype(np.int16))
print(f"wrote {out} ({DUR:.1f}s)")
