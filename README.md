# Experiment_View

A MATLAB/Psychtoolbox visual recognition experiment studying scene typicality perception using a continuous recognition paradigm.

---

## Overview

Participants view a rapid stream of scene images (bedrooms, kitchens, living rooms) and press **SPACE** whenever they detect a repeating image. The experiment probes how quickly/accurately people recognise repeated images across different **typicality bins** (how representative an image is of its category).

Embedded within each block are **attention-check trials** (bathroom images) that repeat predictably — these serve as a performance validity check and provide feedback to the experimenter and, via fixation color, to the participant.

---

## Paradigm Design

### Stimuli

| Set | Description | Count per block |
|-----|-------------|-----------------|
| **Set 1** | Scene images: 3 categories × 10 typicality bins × 5 images/bin | 150 |
| **Set 2** | Attention-check images: 3 fixed bathroom photos | ~13 insertions (~10% of trials) |

- **Categories (Set 1):** `bedrooms`, `kitchens`, `living_rooms`
- **Typicality bins:** 1–10 (1 = atypical, 10 = highly typical)
- Set 1 images are the **same across all blocks**, reshuffled each block
- Set 2 bathroom images repeat within each block (targets for the SPACE response)

### Trial Structure (per trial)

```
Fixation (ISI: 900/1000/1100 ms jittered)
  → Image (500 ms)
  → Feedback fixation (color reflects outcome)
  → [next trial]
```

### Feedback (fixation color)
- **Black** — correct rejection (no press, non-target) or block start
- **Green** — hit (pressed for attention-check image)
- **Red** — miss or false alarm

### Blocks

- **16 blocks** total
- Between blocks, a break screen shows the block number and a visual reminder of the 3 attention-check images
- Block boundary is detected by comparing `Info.block(trial)` vs `Info.block(trial-1)` at the start of each trial
- Trial/block data saved after **every trial** (crash-safe)

---

## Task (Participant Instructions)

Shown on a single screen together with the three attention-check images:

> Images will appear one at a time.
>
> Only these three images will repeat.
>
> Press SPACE as fast as possible when you see one of them.
>
> For all other images, do nothing.
>
> After each response, the fixation dot will change color:
> Green = correct.   Red = incorrect.
>
> If you need to blink, please do so during the fixation cross.
>
> *[3 bathroom images displayed here]*
>
> Press SPACE to begin.

At each **block break**, participants see:

> Block N complete. Take a short break.
>
> Remember: press SPACE when you see one of these images.
>
> *[3 bathroom images displayed here]*
>
> Press SPACE to continue.

---

## Response Coding

| `report` value | Meaning |
|----------------|---------|
| `0` | No response (timeout) |
| `1` | SPACE pressed (within 500 ms window) |
| `99` | ESC pressed (quit) |

---

## Trigger IDs (EEG / ViewPixx)

Trigger encoding: `(presentation × 100) + (category × 10) + (image_type)`

| Field | Values |
|-------|--------|
| `presentation` | 1 = new, 2 = old/repeat |
| `category` | 1=bedrooms, 2=kitchens, 3=living_rooms, 4=Bathroom |
| `image_type` | 1 = Set 1, 2 = attention check |

Additional triggers: `fix_onset=3`, `block_text=1`, `key_press=2`, `answer_screen=4`, `ESC=5`, `experiment_start=6`, `experiment_end=7`

Triggers are **disabled by default** (`cfg.triggers.enabled = false`). Enable for EEG/MEG recordings.

---

## File Structure

```
Experiment_View/
├── experiment_new.m          # Main experiment script (entry point)
├── Functions/
│   ├── get_cfg.m             # All experiment parameters
│   ├── init_experiment_new.m # Fresh-start initialisation
│   ├── create_sequence_new.m # Trial sequence generation
│   ├── select_stimuli_new.m  # Stimulus selection (Set 1 & 2)
│   ├── get_response_timed.m  # Response polling within time window
│   ├── show_attn_check_demo.m # Displays instruction text + 3 attention-check images on one screen
│   └── [symlinks]            # Shared functions from Experiment_CRT:
│       ├── ViewPixxTrigger.m
│       ├── VisAng.m
│       ├── check_performance.m
│       ├── create_participant.m
│       ├── encode_trigger.m
│       ├── get_response.m
│       ├── my_optimal_fixationpoint.m
│       ├── one_image.m
│       ├── set_screen.m
│       ├── set_text.m
│       └── show_break.m
├── Stimuli/
│   ├── stimuli_experiment_22_per_bin.csv  # Stimulus database
│   ├── stimuli_all/                       # Set 1 images (by category/typicality)
│   └── stimuli_practise/                  # Set 2 attention-check images
│       └── Bathroom/
└── Participants/
    └── sub_<id>/             # Created per participant
        ├── set1_stimuli.csv
        ├── set2_stimuli.csv
        ├── all_trials.csv
        ├── Info_<id>.mat/.csv  # Trial-by-trial data (saved every trial)
        └── Log_<id>_experiment_.mat
```

> **Note:** `Functions/` and `Stimuli/` contain symlinks pointing to `../../Experiment_CRT/`. Both experiments must live as siblings in the same parent directory.

---

## Running the Experiment

### Prerequisites

- MATLAB with **Psychtoolbox-3** installed
- `Experiment_CRT/` repository present as a sibling directory (symlink dependencies)

### Steps

1. Open `experiment_new.m`
2. Set `participant_id` (integer, unique per participant)
3. Set `crash_restart = 0` for a fresh start
4. Run the script

```matlab
participant_id = 1;
crash_restart  = 0;
```

### Crash Recovery

If the experiment crashes mid-run, set `crash_restart = 1` and re-run. The experiment will reload from the last saved trial automatically.

```matlab
participant_id = 1;
crash_restart  = 1;
```

### Screen Setup

```matlab
[screen_cfg, window] = set_screen(screen_number, windowed, viewing_distance);
%   screen_number: 1 = primary display, 2 = extended display
%   windowed:      0 = fullscreen, 1 = windowed (use 1 for testing)
```

---

## Key Configuration (`get_cfg.m`)

| Parameter | Value | Description |
|-----------|-------|-------------|
| `n_categories` | 3 | bedrooms, kitchens, living_rooms |
| `n_bins` | 10 | typicality bins |
| `n_per_bin` | 5 | images selected per bin |
| `n_set1_per_block` | 150 | Set 1 trials per block |
| `n_attn_per_block` | ~13 | attention-check insertions per block |
| `n_blocks` | 16 | total blocks |
| `stim_dur` | 0.500 s | image display duration |
| `ISI_vals` | [0.9, 1.0, 1.1] s | jittered fixation durations |
| `vdist` | 55 cm | viewing distance |
| `h_img` / `w_img` | 512 × 512 px | image display size |
| `seed` | `participant_id × 1000` | RNG seed for reproducibility |

---

## Output Data (`Info` table)

Saved as both `.mat` and `.csv` in `Participants/sub_<id>/`.

| Column | Description |
|--------|-------------|
| `trial` | Global trial number |
| `block` | Block number (1–16) |
| `stimulus` | Image filename |
| `category` | Scene category |
| `p_typicality` | Typicality bin (1–10; 0 for attention checks) |
| `is_attn_check` | `true` for bathroom/attention-check trials |
| `presentation` | 1 = first time seen this block, 2+ = repeat |
| `ISI` | Jittered fixation duration used (s) |
| `ISI_measured` | Actual measured ISI (s) |
| `fixation_onset` | VBL timestamp of fixation flip |
| `stim_onset` | VBL timestamp of image flip |
| `stim_offset` | Nominal stimulus offset time |
| `report` | Response: 0=none, 1=space pressed |
| `RT` | Reaction time (s from stim onset); NaN if no response |
| `trigger_id` | EEG trigger code sent for this trial |

---

## Instruction & Break Screen (`show_attn_check_demo.m`)

All instruction and reminder screens are handled by a single function that renders text and images together in one flip — no separate screens.

**Layout (top → bottom, vertically centred):**
```
[instruction / reminder text]
[gap]
[ bathroom 1 ]   [ bathroom 2 ]   [ bathroom 3 ]
[gap]
[footer: "Press SPACE to begin." or "Press SPACE to continue."]
```

**Called from two places in `experiment_new.m`:**
1. **Before the first trial** — shows full task instructions + images + "Press SPACE to begin."
2. **At every block boundary** (`Info.block(trial) ~= Info.block(trial-1)`) — shows break message + images + "Press SPACE to continue."

The footer text is passed as an optional 6th argument; it defaults to `'Press SPACE to begin.'`

---

## Relationship to `Experiment_CRT`

This experiment (`Experiment_View`) is a variant of `Experiment_CRT`. The `_new` suffix on several files (`experiment_new.m`, `create_sequence_new.m`, etc.) marks the updated design. Shared utility functions are symlinked from `Experiment_CRT/Functions/` rather than duplicated.

Key differences from CRT:
- No same/different judgment — participants only detect **repeats** (spacebar paradigm)
- Set 1 images are **fixed** (same pool every block, reshuffled), not varied across blocks
- Attention-check images are **bathroom photos** (not from the main category pool)
- Response window is bounded to stimulus duration (500 ms), not open-ended
