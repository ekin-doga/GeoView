%% Dummy experiment — black box instead of images/fixation cross
close all; clear; clc; sca;

addpath('Functions/')

%----------------------------------------------------------------------
% Settings
%----------------------------------------------------------------------

n_trials         = 20;
stim_dur         = 0.500;               % box visible (s)
ISI_vals         = [0.900, 1.000, 1.100];  % jittered blank interval (s)
box_size         = 40;                  % side length of the black box (px)
vdist            = 55;                  % viewing distance (cm)
triggers_enabled = false;               % set true when EEG hardware is connected

%----------------------------------------------------------------------
% Trigger codes  (mirror real experiment codes)
%----------------------------------------------------------------------

trig.experiment_start = 1;
trig.experiment_end   = 2;
trig.blank_onset      = 6;   % same as fix_onset in real experiment
trig.box_onset        = 10;  % analogous to stimulus trigger

%----------------------------------------------------------------------
% Screen setup
%----------------------------------------------------------------------

[screen_cfg, window] = set_screen(1, 1, vdist);

Screen('Preference', 'SkipSyncTests', 1);

cx = screen_cfg.center_X;
cy = screen_cfg.center_Y;
half = box_size / 2;
box_rect = [cx - half, cy - half, cx + half, cy + half];

%----------------------------------------------------------------------
% Trigger object  (pass false to disable without touching trial code)
%----------------------------------------------------------------------

trigger = ViewPixxTrigger(window, triggers_enabled);

%----------------------------------------------------------------------
% Key setup
%----------------------------------------------------------------------

KbName('UnifyKeyNames');
quit_key = KbName('ESCAPE');

%----------------------------------------------------------------------
% Run trials
%----------------------------------------------------------------------

try
    % Start with a blank grey screen
    Screen('FillRect', window, screen_cfg.white / 2);
    vbl = Screen('Flip', window);

    trigger.sendTrigger(trig.experiment_start);

    for trial = 1:n_trials

        ISI = ISI_vals(randi(numel(ISI_vals)));

        %% -- Blank ISI --
        Screen('FillRect', window, screen_cfg.white / 2);
        trigger.drawTriggerPixel(trig.blank_onset);
        vbl = Screen('Flip', window, vbl + ISI);

        % Clear trigger pixel one frame later
        Screen('FillRect', window, screen_cfg.white / 2);
        Screen('Flip', window);

        %% -- Black box --
        Screen('FillRect', window, screen_cfg.white / 2);
        Screen('FillRect', window, [0 0 0], box_rect);
        trigger.drawTriggerPixel(trig.box_onset);
        vbl = Screen('Flip', window);

        %% -- Hold for stim_dur, check for quit --
        t_end = vbl + stim_dur;
        while GetSecs < t_end
            [~, ~, keyCode] = KbCheck;
            if keyCode(quit_key)
                error('Experiment aborted by user.');
            end
        end

        fprintf('Trial %d / %d\n', trial, n_trials);
    end

    % Final blank
    Screen('FillRect', window, screen_cfg.white / 2);
    Screen('Flip', window);

    trigger.sendTrigger(trig.experiment_end);

    WaitSecs(0.5);

catch ME
    sca;
    ShowCursor;
    rethrow(ME);
end

sca;
ShowCursor;
