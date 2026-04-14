function [cfg] = get_cfg(participant_id)

% GET_CFG - Returns experiment configuration for the new experiment
%
% DESIGN:
%   Set 1: 120 images from 3 categories × 10 typicality bins × 4 per bin
%          Shown once per block (always "new" — no repeats)
%   Set 2: 3 manually-selected attention-check images (bathroom images)
%          Shown repeatedly throughout each block at ~10% of total trials
%
% USAGE:
%   cfg = get_cfg(participant_id)
%   cfg = get_cfg()   % uses default seed (for testing)

%% Paths (derived from this file's location - portable)
this_file = mfilename('fullpath');
functions_dir = fileparts(this_file);
cfg.experiment_root = fileparts(functions_dir);  % Parent of Functions/

cfg.stimuli_dir       = fullfile(cfg.experiment_root, 'Stimuli');
cfg.participants_dir  = fullfile(cfg.experiment_root, 'Participants');

% Stimulus database (same pool as original experiment)
cfg.path_to_table    = fullfile(cfg.stimuli_dir, 'stimuli_experiment_22_per_bin.csv');
cfg.stimuli_subfolder = 'stimuli_all';

% Attention-check images (Set 2) — 3 bathroom images, manually chosen
cfg.attn_check_images = {
    '99-films-9K-rMgWLCYM-unsplash_resized.jpg',
    'alex-tyson-trSptCbWxAo-unsplash_resized.jpg',
    'alexander-fife-6fWlqSqzWus-unsplash_resized.jpg'
};
cfg.attn_check_category = 'Bathroom';
cfg.attn_check_subfolder = 'stimuli_practise';  % lives in Stimuli/stimuli_practise/Bathroom/

%% Experiment settings

% Set 1 composition: 3 categories × 10 bins × 4 per bin = 120 per block
cfg.n_categories      = 3;          % bedrooms, kitchens, living_rooms
cfg.n_bins            = 10;         % typicality bins 1–10
cfg.n_per_bin         = 5;          % images per category per bin
cfg.n_set1_per_block  = cfg.n_categories * cfg.n_bins * cfg.n_per_bin;  % 120

% Set 2: attention-check images
cfg.n_attn_images     = 3;          % number of distinct attention-check images

% Attention-check target rate: ~10% of total trials per block
% Total trials = set1 + attn_checks => attn ≈ 10% of total
%   Let n_set1 = 120, target_rate = 0.10
%   n_attn / (120 + n_attn) = 0.10  => n_attn ≈ 13.3, round to 13
cfg.attn_check_rate   = 0.10;       % desired fraction of total trials

% Number of attention-check insertions per block (derived at init time
% from n_set1_per_block and attn_check_rate — stored here for reference)
%   n_attn = round(n_set1 * rate / (1 - rate))
cfg.n_attn_per_block  = round(cfg.n_set1_per_block * cfg.attn_check_rate / ...
                              (1 - cfg.attn_check_rate));   % ≈ 13

cfg.n_blocks          = 16;          % number of blocks

%% Timing
cfg.stim_dur  = 0.500;              % stimulus duration (s)
cfg.ISI_vals  = [0.900, 1.000, 1.100];  % possible ISI durations (s), sampled randomly per trial

%% Display
cfg.vdist  = 55;    % viewing distance (cm)
cfg.h_img  = 512;   % image height (px)
cfg.w_img  = 512;   % image width (px)

%% Response keys
cfg.keys.Quit     = KbName('ESCAPE');
cfg.keys.respond  = KbName('space');  % press space to indicate repeating image

%% Trigger settings
cfg.triggers.enabled       = false;
cfg.triggers.block_text    = 1;
cfg.triggers.key_press     = 2;
cfg.triggers.fix_onset     = 3;
cfg.triggers.answer_screen = 4;
cfg.triggers.answer_M      = 10;
cfg.triggers.answer_H      = 11;
cfg.triggers.answer_FA     = 20;
cfg.triggers.answer_CR     = 21;
cfg.triggers.ESC           = 5;
cfg.triggers.experiment_start = 6;
cfg.triggers.experiment_end   = 7;

%% Participant seed
if nargin >= 1 && ~isempty(participant_id)
    cfg.seed           = participant_id * 1000;
    cfg.participant_id = participant_id;
else
    cfg.seed           = 1000;
    cfg.participant_id = NaN;
end

cfg.deviceIndex = [];

end
