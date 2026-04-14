function [SM, performance] = check_performance(text_present, cur_presentation, cur_report, trigger, trig_codes)
% CHECK_PERFORMANCE - Evaluates recognition memory responses
%
% INPUTS:
%   text_present     - Response key mapping (1 or 2)
%                      1: d&f (1&2) -> old, j&k (3&4) -> new
%                      2: j&k (3&4) -> old, d&f (1&2) -> new
%   cur_presentation - Presentation number: 1 = first (new), 2 = repeat (old)
%   cur_report       - Participant's key press (1=d, 2=f, 3=j, 4=k)
%   trigger          - ViewPixxTrigger object
%   trig_codes       - Trigger code values struct (cfg.triggers)
%
% OUTPUTS:
%   performance  - 'H' (Hit), 'CR' (Correct Rejection),
%                  'FA' (False Alarm), or 'M' (Miss)
%   SM           - Subsequent memory: 1 = remembered, 0 = forgotten

% Define key mappings based on text_present
if text_present == 1
    old_keys = [1];  % d -> old
    new_keys = [2];  % j -> new
else
    old_keys = [2];  % j -> old
    new_keys = [1];  % d -> new
end

% Stimulus type
is_old = (cur_presentation == 2);  % repeat presentations
is_new = (cur_presentation == 1);  % first presentations or foils

% Response type
responded_old = ismember(cur_report, old_keys);
responded_new = ismember(cur_report, new_keys);

% Evaluate performance
if is_old && responded_old
    performance = 'H';
    SM = 1;
    trigger.sendTrigger(trig_codes.answer_H)
    fprintf('Hit (trigger %d)\n', trig_codes.answer_H)
elseif is_new && responded_new
    performance = 'CR';
    SM = 1;
    trigger.sendTrigger(trig_codes.answer_CR)
    fprintf('Correct rejection (trigger %d)\n', trig_codes.answer_CR)
elseif is_new && responded_old
    performance = 'FA';
    SM = 0;
    trigger.sendTrigger(trig_codes.answer_FA)
    fprintf('False alarm (trigger %d)\n', trig_codes.answer_FA)
elseif is_old && responded_new
    performance = 'M';
    SM = 0;
    trigger.sendTrigger(trig_codes.answer_M)
    fprintf('Miss (trigger %d)\n', trig_codes.answer_M)
else
    performance = [];
    SM = NaN;
    trigger.sendTrigger(trig_codes.ESC)
    fprintf('No valid response (trigger %d)\n', trig_codes.ESC)
end
end
