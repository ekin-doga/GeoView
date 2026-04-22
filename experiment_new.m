%% Clear workspace and setup
close all; clear; clc; sca;

addpath('Functions/')
addpath('Participants/')
addpath(genpath('Stimuli/'))

%----------------------------------------------------------------------
% Setup new run of the study
%----------------------------------------------------------------------

participant_id = 10;   % Change per participant

% Set to 1 if the experiment crashed and needs to resume
crash_restart = 0;

%----------------------------------------------------------------------
% Create subject folder
%----------------------------------------------------------------------

participant_dir = create_participant(participant_id, crash_restart, 'experiment');

%----------------------------------------------------------------------
% Retrieve configuration
%----------------------------------------------------------------------

cfg = get_cfg(participant_id);

%----------------------------------------------------------------------
% Screen setup
% set_screen(screen_number, windowed, viewing_distance)
%   screen_number: 1 = native, 2 = extended display
%   windowed:      0 = fullscreen, 1 = windowed
%----------------------------------------------------------------------

[screen_cfg, window] = set_screen(1, 1, cfg.vdist);

Screen('Preference', 'SkipSyncTests', 1);

%----------------------------------------------------------------------
% Trigger setup
%----------------------------------------------------------------------

trigger = ViewPixxTrigger(window, cfg.triggers.enabled);

%----------------------------------------------------------------------
% Image position on screen
%----------------------------------------------------------------------

screen_cfg.Pos = CenterRectOnPointd([0 0 cfg.h_img cfg.w_img], ...
    screen_cfg.center_X, screen_cfg.center_Y);

%----------------------------------------------------------------------
% Experiment initialisation (fresh start or crash recovery)
%----------------------------------------------------------------------

if crash_restart == 0

    [start_trial, instructions, Info, Log] = ...
        init_experiment_new(cfg, participant_dir, participant_id, screen_cfg);

elseif crash_restart == 1

    % Resume: reload saved Info and Log
    log_file  = fullfile(participant_dir, ['Log_', num2str(participant_id), '_experiment_.mat']);
    info_file = fullfile(participant_dir, ['Info_', num2str(participant_id), '.mat']);

    if ~isfile(log_file) || ~isfile(info_file)
        error('Cannot resume: log or info file not found in %s', participant_dir);
    end

    load(log_file, 'Log');
    load(info_file, 'Info');

    start_trial  = Log.lastTrial + 1;
    instructions = sprintf('Fortsetzen ab Durchgang %d.\n\nDrücke die LEERTASTE, wenn du ein wiederholendes Bild siehst.\n\nDrücke eine beliebige Taste, um fortzufahren.', start_trial);

    fprintf('Resuming experiment from trial %d\n', start_trial);

end

%% ======================================================================
%  Start experiment
% =======================================================================


try
    vbl = Screen('Flip', window);

    % Send experiment-start trigger
    trigger.sendTrigger(cfg.triggers.experiment_start);


    % Show instructions + attention-check images together on one screen
    show_attn_check_demo(window, screen_cfg, cfg, trigger, instructions);

    % Fixation color: updated after each trial based on response outcome
    % Black = default (no feedback yet / correct rejection)
    % Green = hit, Red = miss or false alarm
    fix_color = [0 0 0];

    for trial = start_trial:height(Info)

        Log.lastTrial = trial;

        %% -- Block break (between blocks, not after the last) --
        if trial > 1 && Info.block(trial) ~= Info.block(trial - 1)
            completedBlock = Info.block(trial - 1);
            fprintf('\n===== BREAK: Block %d complete =====\n\n', completedBlock);
            break_text = sprintf([...
                'Block %d abgeschlossen. Mach eine kurze Pause.\n\n' ...
                'Denke daran: Drücke die LEERTASTE, wenn du eines dieser Bilder siehst.'], ...
                completedBlock);
            show_attn_check_demo(window, screen_cfg, cfg, trigger, break_text, 'Press SPACE to continue.');

            fix_color = [0 0 0];  % Reset feedback color at block boundary
        end

        %% -- Per-trial progress print --
        current_block   = Info.block(trial);
        trials_in_block = sum(Info.block == current_block);
        trial_in_block  = sum(Info.block(1:trial) == current_block);
        fprintf('Block %d — trial %d / %d\n', current_block, trial_in_block, trials_in_block);

        %% -- Fixation (ISI) --
        my_optimal_fixationpoint(window, screen_cfg.center_X, screen_cfg.center_Y, ...
            0.6, fix_color, screen_cfg.white/2, screen_cfg.pixperdeg);
        trigger.drawTriggerPixel(cfg.triggers.fix_onset);
        vbl = Screen('Flip', window);
        Info.fixation_onset(trial) = vbl;

        %% -- Load image --
        if iscell(Info.stimulus)
            stim_path = Info.stimulus{trial};
        else
            stim_path = char(Info.stimulus(trial));
        end
        [~, file_name, ext] = fileparts(stim_path);

        if iscell(Info.category)
            trial_category = Info.category{trial};
        else
            trial_category = char(Info.category(trial));
        end

        is_attn = Info.is_attn_check(trial);

        if is_attn
            % Attention-check image: stimuli_practise/Bathroom/filename
            ImgTex = one_image([file_name, ext], cfg.stimuli_dir, window, ...
                cfg.attn_check_subfolder, cfg.attn_check_category);
        else
            % Set 1 image: stimuli_all/category/typicality/filename
            trial_typicality = Info.p_typicality(trial);
            ImgTex = one_image([file_name, ext], cfg.stimuli_dir, window, ...
                cfg.stimuli_subfolder, trial_category, trial_typicality);
        end

        %% -- Draw stimulus --
        Screen('DrawTexture', window, ImgTex, [], screen_cfg.Pos);
        trigger.drawTriggerPixel(Info.trigger_id(trial));

        % Show image after ISI (per-trial jittered duration)
        vbl = Screen('Flip', window, vbl + Info.ISI(trial));
        Info.stim_onset(trial)     = vbl;
        Info.ISI_measured(trial)   = Info.stim_onset(trial) - Info.fixation_onset(trial);

        %% -- Response window: poll for key press during the 500 ms image --
        [Report, RT] = get_response_timed(vbl, cfg.stim_dur, cfg.deviceIndex, cfg.keys);
        Info.report(trial) = Report;
        Info.RT(trial)     = RT;

        % Determine outcome and update fixation color
        % Any bathroom image is a target; all Set 1 images are non-targets
        is_target = Info.is_attn_check(trial);
        pressed   = Report == 1;
        if is_target && pressed          % Hit
            fix_color = [0 200 0];
        elseif is_target && ~pressed     % Miss
            fix_color = [200 0 0];
        elseif ~is_target && pressed     % False alarm
            fix_color = [200 0 0];
        else                             % Correct rejection
            fix_color = [0 0 0];
        end

        % Draw feedback fixation and flip at stimulus offset
        my_optimal_fixationpoint(window, screen_cfg.center_X, screen_cfg.center_Y, ...
            0.6, fix_color, screen_cfg.white/2, screen_cfg.pixperdeg);
        Screen('Flip', window, vbl + cfg.stim_dur);
        Info.stim_offset(trial) = vbl + cfg.stim_dur;

        Screen('Close', ImgTex);

        %% -- Save after every trial --
        save(fullfile(participant_dir, Log.logfilename), 'Log');
        save(fullfile(participant_dir, ['Info_', num2str(participant_id), '.mat']), 'Info');

    end

    % Write final CSV
    writetable(Info, fullfile(participant_dir, ['Info_', num2str(participant_id), '.csv']));

    % Send experiment-end trigger
    trigger.sendTrigger(cfg.triggers.experiment_end);

    end_message = 'Das Experiment ist nun abgeschlossen. Vielen Dank! Drücke eine beliebige Taste zum Beenden.';
    show_break(window, end_message, cfg.deviceIndex, trigger, cfg.triggers);

catch ME

    if exist('ImgTex', 'var') && ~isempty(ImgTex)
        try Screen('Close', ImgTex); catch; end
    end

    sca;
    ShowCursor;
    rethrow(ME);

end

sca;
ShowCursor;
     