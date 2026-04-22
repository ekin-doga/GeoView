# Trigger Implementation — Summary, Diagnosis & Fix

## Context

The `GEO_View` experiment sends EEG markers to a BioSemi amplifier via a ViewPixx/EEG display. The ViewPixx reads a single pixel at screen coordinate (0,0) and translates its RGB value into the state of the parallel port lines feeding BioSemi.

## Files involved

- `Functions/ViewPixxTrigger.m` — class currently used in the experiment.
- `Functions/ViewPixxTrigger2.m` — alternative class with named `Constant` properties; not wired in.
- `Functions/ViewPixxTriggerGenerater.m` — older function-style equivalent.
- `Functions/encode_trigger.m` — helper that builds 3-digit codes `rep*100 + cat*10 + type` (unused by the active pipeline, which uses the 1–50 scheme defined in `get_cfg.m` / `trigger_codes.txt`).
- `Functions/get_cfg.m` — defines `cfg.triggers.*` codes (1–50).
- `experiment_new2.m` — main script; uses both `sendTrigger` and `drawTriggerPixel`.

## How the pixel encoding works

`drawTriggerPixelInternal(triggerCode)`:
1. Validates `0 ≤ code ≤ 255`.
2. Converts to 24-bit binary.
3. Applies BioSemi cable shift (pins 2–9 → 1–8).
4. Maps binary bits to R / G / B pin groups.
5. `Screen('FillRect', window, [R G B], [0 0 1 1])` — paints a single pixel at (0,0).

Nothing else in the back buffer is touched.

## Two delivery methods

### `drawTriggerPixel(code)`
- Only draws the trigger pixel; does **not** flip.
- Caller follows with their own `Screen('Flip')`, so the trigger is synchronous with whatever stimulus the caller also drew.
- Used at `experiment_new2.m:122` (fixation onset) and `experiment_new2.m:155` (stimulus onset).

### `sendTrigger(code)`
- Self-contained pulse:
  1. Draws trigger pixel.
  2. `Screen('Flip')` (pulse ON).
  3. `WaitSecs(0.010)` (10 ms).
  4. Draws trigger=0 pixel.
  5. `Screen('Flip')` (pulse OFF).
- Used at `experiment_new2.m:91` (experiment start) and `experiment_new2.m:199` (experiment end).

## Current usage pattern

| Line | Event | Method | Trigger code |
|------|-------|--------|--------------|
| 91 | Experiment start | `sendTrigger` | `cfg.triggers.experiment_start` (1) |
| 122 | Fixation onset | `drawTriggerPixel` | `cfg.triggers.fix_onset` (6) |
| 155 | Stimulus onset | `drawTriggerPixel` | `Info.trigger_id(trial)` (11–40 or 50) |
| 184 | Stimulus offset | (no trigger call) | — |
| 199 | Experiment end | `sendTrigger` | `cfg.triggers.experiment_end` (2) |

The asymmetry is intentional: `sendTrigger` where nothing visual matters, `drawTriggerPixel` where the trigger must be locked to a visible frame.

## The problem: trigger bleeding across phases

Each flip sets the trigger pixel to a specific RGB value. The pixel is *held* on screen until the next flip overwrites it. The current code has three flips per trial and only two of them explicitly set a trigger code:

| Flip | Line | What's drawn before flip | Trigger pixel after flip |
|------|------|--------------------------|--------------------------|
| 1 | 123 | fixation + `drawTriggerPixel(6)` | 6 (held through ISI) |
| 2 | 158 | stimulus + `drawTriggerPixel(stim_code)` | 11–50 (held through stim_dur) |
| 3 | 184 | feedback fixation only, **no trigger call** | whatever the gray clear-color decodes to |

Because the Status channel transitions directly between non-zero values (`0 → 6 → stim_code → gray_code → 6 → ...`), there is no return-to-zero between fixation onset and stimulus onset, and the flip-3 gray value contaminates the inter-trial period.

## Empirical diagnosis

Confirmed on a pilot BDF file loaded with `pop_fileio`:

### Gray decodes to 6

The background clear color (`white/2` ≈ gray 128,128,128) at flip 3 produces a trigger-channel transition to value **6** — the same code as `cfg.triggers.fix_onset`.

This was determined by measuring stim → "6" latencies:

```
stim 23 → 6: 0.525 s
stim 14 → 6: 0.524 s
stim 11 → 6: 0.525 s
...
```

All ~525 ms ≈ `cfg.stim_dur` (500 ms) + a frame or two. The "6" is the flip-3 gray artifact, not a real fix_onset.

### Real fix_onset events are invisible

Because the channel is already at 6 when flip 1 of the next trial draws code 6, there is no transition. `pop_fileio` logs no event at the real fix_onset. Every "6" in `EEG.event` is actually the stimulus-offset gray pixel from the previous trial.

Stim → next-stim latencies:
```
6 → stim 23: 1.100 s
6 → stim 14: 1.000 s
6 → stim 11: 0.900 s
...
```

These ~1 s latencies correspond to `stim_offset → stim_onset of next trial` = ITI + ISI, with the real fix_onset flip hidden inside.

### Other observed codes

- **170** at session start and end — decoded form of `sendTrigger(1)` / `sendTrigger(2)` pulses for experiment_start / experiment_end. The value differs from the trigger_code because `sendTrigger`'s two flips and the pixel encoding combine differently than the held `drawTriggerPixel` case.
- **3, 4, 7** between blocks — block-boundary / attention-check related.
- **54, 46** — appear as stim codes. 54 is outside the intended 11–50 range; likely an `Info.trigger_id` assignment issue or additional cable decoding artifact. Worth investigating separately.

## Does this affect stimulus-onset timing?

**No.** `pop_fileio` detects transitions (not rises-from-zero). The transition at flip 2 — from 6 to `stim_code` — is sample-accurate and timestamped at the correct vsync. Stimulus-locked epochs via `pop_epoch(EEG, {'11','12',...,'50'}, ...)` work correctly.

The bleed only hides the fix_onset events; the stimulus-onset events are fine.

## What's preserved vs. lost

| Information | Status |
|-------------|--------|
| Stim-onset timing on EEG channel | ✓ Correct (transition at flip 2) |
| Stim-onset code identity | ✓ Correct (11–50, 54) |
| Fix-onset timing on EEG channel | ✗ Missing (no transition recorded) |
| Fix-onset timing in `Info.fixation_onset(trial)` | ✓ Available from saved .mat |
| ISI per trial | ✓ Available from `Info.ISI` / `Info.ISI_measured` |

## The fix

Add **one line** before the flip at line 184:

```matlab
my_optimal_fixationpoint(window, screen_cfg.center_X, screen_cfg.center_Y, ...
    0.6, fix_color, screen_cfg.white/2, screen_cfg.pixperdeg);
trigger.drawTriggerPixel(0);                 % ← NEW: clear trigger pixel
Screen('Flip', window, vbl + cfg.stim_dur);
```

### Why this works

- `drawTriggerPixel(0)` only modifies the back buffer (sub-millisecond CPU operation); it does not flip.
- The existing scheduled flip at `vbl + cfg.stim_dur` is unchanged — same timing, same `vbl` chain, same number of flips per trial (3).
- The trigger pixel at (0,0) is now explicitly drawn as code 0 instead of relying on the gray background, so flip 3 produces a clean transition to 0 on the Status channel.

### Post-fix event sequence per trial

| Flip | Line | Trigger pixel | Channel event |
|------|------|---------------|---------------|
| 1 | 123 | 6 (fix_onset) | 0 → 6 transition ✓ real fix_onset logged |
| 2 | 158 | stim_code | 6 → stim_code transition ✓ stim_onset logged |
| 3 | 184 | 0 | stim_code → 0 transition ✓ stim_offset logged |

After the fix, re-running the latency check should show:
- `6 → stim_code` latency ≈ `Info.ISI(trial)` (real fix-onset to stim-onset)
- `stim_code → 0` latency ≈ `cfg.stim_dur` (stim duration)
- Real fix_onset events now appear in `EEG.event`

## Why not use the `sendTrigger` / Block2 pattern for fixation?

The `ConRecProto` prototype uses `sendTrigger` for both fixation onset and offset, producing clean 10 ms pulses. However, `sendTrigger`:
- Flips immediately (no `when` argument) → incompatible with `vbl + Info.ISI(trial)` scheduling
- Does not return `vbl` → breaks the chain used at line 184 (`vbl + cfg.stim_dur`)
- Adds 2 extra flips per pulse → ~33 ms at 60 Hz (or ~17 ms at 120 Hz) of unaccounted wall time

The prototype accepts this because it uses `WaitSecs` / `GetSecs` polling for timing, not `vbl`-scheduled flips. `experiment_new2.m` relies on scheduled flips for per-trial jittered ISI and frame-accurate stimulus duration, which would be lost.

The one-line `drawTriggerPixel(0)` fix preserves all of `experiment_new2.m`'s timing guarantees while producing clean trigger transitions.

## Alternative (no code change)

If the code cannot be modified, the bleed is tolerable as long as analysis:
1. Uses stim_code events (11–50, 54) for stimulus-locked epoching — these are correct.
2. Uses `Info.fixation_onset(trial)` from the saved .mat file for fix-onset timing.
3. Ignores the "6" events in `EEG.event` (or treats them as stim-offset markers, which they effectively are).
4. Filters `EEG.event` to known valid codes before any analysis that enumerates event types.

## Summary

- The bleed is real and causes real fix_onset events to be lost from the EEG event channel, because the gray clear-color at flip 3 decodes to the same value (6) as `cfg.triggers.fix_onset`.
- Stimulus-onset timing is unaffected; stim codes are logged correctly at the right latencies.
- The fix is a single `drawTriggerPixel(0)` call before the existing flip at line 184. No extra flips, no timing change, no `vbl` chain disruption.
- After the fix, both fix_onset and stim_offset produce clean transitions on the Status channel.
