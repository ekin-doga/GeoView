# Trigger Code Design — Smearing Fix

## The Problem

When fixation (code 6) was held on screen and the stimulus flip fired, the EEG briefly saw both codes active simultaneously. The bit-wise OR of the two codes produced a spurious event:

```
fix_onset  =  6 = 0b000110
stim_code  = 40 = 0b101000
smear      = 46 = 0b101110  ← spurious, not a real event
```

Sometimes the spurious code did not appear because the bits happened to overlap with the stimulus code already, making the problem inconsistent and hard to diagnose.

## The Solution

Design the codes so that `fix_onset OR stim_code = stim_code` always. If fix_onset's bits are already set in every stimulus code, the smear produces nothing new — the EEG just sees the stimulus code again.

The simplest way to guarantee this: make fix_onset a **single bit** and make all stimulus codes have that bit set.

```
fix_onset = 1 = 0b00000001

1 OR any_odd_number = any_odd_number  ✓
```

So fix_onset is set to **1** and all stimulus codes are made **odd**.

## Code Scheme

| Event | Code | Notes |
|---|---|---|
| fix_onset | 1 | Single LSB — subset of all stimulus codes |
| experiment_start | 2 | Even — distinct from stimulus codes |
| experiment_end | 4 | Even |
| block_text | 6 | Even |
| ESC | 10 | Even |
| Bedrooms bin 1–10 | 11, 13, 15, 17, 19, 21, 23, 25, 27, 29 | Odd |
| Kitchens bin 1–10 | 31, 33, 35, 37, 39, 41, 43, 45, 47, 49 | Odd |
| Living rooms bin 1–10 | 51, 53, 55, 57, 59, 61, 63, 65, 67, 69 | Odd |
| Attn check | 71 | Odd |

Stimulus codes are computed as `base + 2 * typicality_bin` in `create_sequence_new.m`.

## Why This Works

Any fix→stimulus smear now just reads the stimulus code again:

```
fix_onset  =  1 = 0b00000001
stim_code  = 40 = 0b00101001  (new odd code)
smear      = 41 = 0b00101001  = stim_code  ✓
```

No spurious events. Stimulus-onset timing and code identity are both preserved.
