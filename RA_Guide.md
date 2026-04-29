## GeoView Guide

Hi! Thank you for helping me out with collecting data :)

Before you start running the experiment, please put the relevant information on the Log table and later update it with information regarding the current session (e.g., is there a particularly bad electrode, did you re-gel an electrode, did sth else go wrong, was it a particularly successful session of data collection?).

Please let me know if there is an update required in this guide. 

### Running the experiment

1. In MATLAB, navigate to the `GEO_View/` directory.
2. Open `experiment.m`
3. Set `participant_id` to the participant's number (line 12):
   ```matlab
   participant_id = 10;   % Change per participant
   ```
4. Run the script
5. If the participant folder already exists, MATLAB will ask:
   ```
   Participant exists. Overwrite [y/n]?
   ```
   - Type `n` and update the `participant_id` if this is a new participant.
   - Type `y` only if you intentionally want to overwrite (e.g. re-running a test).

### Information on the experiment

This is a passive view experiment. 150 images will repeat 16 (number of block) times in different order. Most of the time participants just look at the images. As an attention check, participants should press 'Space' when they see one of the three specific images. 

These images will be shown on the first instruction screen and during block breaks. Attention check images are also the same across different blocks. 

The experiment runs 16 blocks. A break screen appears between blocks — the participant presses 'Space' to continue. You can see the current trial and block break on the command window. 

This is a relatively long experiment (around 80 mins). If the time is running out, you can stop the experiment during block break by pressing ESC. In this case don't forget to manually save the EEG data. Behavioral data should be automatically saved. 

### Important output files (saved in `Participants/sub_N/`)

| File             | Contents                                        |
|------------------|-------------------------------------------------|
| `GEO_View_N.mat` | Trial-by-trial data (updated after every trial) |
| `GEO_View_N.csv` | Trial-by-trial data (updated after every block) |


### Resuming after a crash

1. Set `crash_restart = 1` in `experiment_new.m` (line 15).
2. Keep `participant_id` the same as the crashed session.
3. Run `experiment`. It will reload the saved log and resume from the next trial.
4. Set `crash_restart` back to `0` when done.

###  Troubleshooting

####  MATLAB cannot find Psychtoolbox functions
Run `PsychtoolboxVersion` in the Command Window. If it errors, Psychtoolbox is not on the path. Add it with:

```matlab
addpath(genpath('/path/to/Psychtoolbox'))
```
####  Screen opens on the wrong display
Change the first argument of `set_screen` — `1` for the experimenter display, `2` for the participant display.

####  "Image file not found" error
The stimuli folder structure is wrong or incomplete. Check that:
- `Stimuli/stimuli_all/` exists with subfolders `bedrooms`, `kitchens`, `living_rooms`, `Attention`
- Each category folder has subfolders `1` through `10`, each containing 5 `.png` images
- The 3 attention-check images are in `Stimuli/stimuli_all/Attention/`

####  "Participant exists. Overwrite?" appears unexpectedly
You are re-using a participant ID. Double-check `participant_id` and type `n`. Update the ID and run again.

####  Experiment crashed mid-session
Do not change the `participant_id`. Set `crash_restart = 1` and run again. The session will resume from the trial after the last saved one.

