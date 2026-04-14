function [startTrial, instructions, Info, Log] = init_experiment_new(cfg, participant_dir, participant_id, screen_cfg)
% INIT_EXPERIMENT_NEW - Initialises a fresh session of the new experiment
%
% INPUTS:
%   cfg             - Configuration struct from get_cfg()
%   participant_dir - Participant directory path
%   participant_id  - Participant ID number
%   screen_cfg      - Screen configuration (from set_screen)
%
% OUTPUTS:
%   startTrial    - Always 1 for fresh starts
%   instructions  - Instruction string
%   Info          - Trial table
%   Log           - Log structure

startTrial = 1;

%% Select stimuli
[set1, set2] = select_stimuli_new(cfg);

%% Generate trial sequence
Info = create_sequence_new(set1, set2, cfg);

fprintf('Participant seed: %d\n', cfg.seed);

%% Save participant-specific files
writetable(set1, fullfile(participant_dir, 'set1_stimuli.csv'),  'Delimiter', ',');
writetable(set2, fullfile(participant_dir, 'set2_stimuli.csv'),  'Delimiter', ',');
writetable(Info, fullfile(participant_dir, 'all_trials.csv'),    'Delimiter', ',');

%% Build instruction string
instructions = [...
    'Images will appear one at a time.\n\n' ...
    'Only these three images will repeat.\n\n' ...
    'Press SPACE as fast as possible when you see one of them.\n\n' ...
    'For all other images, do nothing.\n\n' ...
    'After each response, the fixation dot will change color:\n' ...
    'Green = correct.   Red = incorrect.\n\n' ...
    'If you need to blink, please do so during the fixation cross.'];

%% Initialise log
Log = struct();
Log.response_key  = 'space';
Log.name          = num2str(participant_id);
Log.logfilename   = ['Log_', Log.name, '_experiment_.mat'];
Log.date          = {datetime('now')};
Log.cfg           = cfg;
Log.screen_cfg    = screen_cfg;
Log.lastTrial     = 0;

end
