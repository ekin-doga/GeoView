function show_break_generater(window, presenttext, deviceIndex, trig_codes)
% SHOW_BREAK_GENERATER - Display a centred text message and wait for a key press.
% Uses ViewPixxTriggerGenerater directly instead of ViewPixxTrigger class.
% If ESC is pressed, the experiment is terminated safely.
%
% INPUTS:
%   window      - PTB window pointer
%   presenttext - Text string to display
%   deviceIndex - Keyboard device index ([] for any)
%   trig_codes  - Trigger code values struct (cfg.triggers)

% Draw centered text
Screen('TextSize', window, 24);
DrawFormattedText(window, presenttext, 'center', 'center', [0 0 0], 60);
if trig_codes.enabled
    ViewPixxTriggerGenerater(window, trig_codes.block_text);
end
fprintf('Block text is up — trigger %d\n', trig_codes.block_text);
Screen('Flip', window);

% Wait for key press
if nargin < 3 || isempty(deviceIndex)
    deviceIndex = [];
end

KbReleaseWait(deviceIndex);

while true
    [keyIsDown, ~, keyCode] = KbCheck(deviceIndex);

    if keyIsDown
        pressedKeys = find(keyCode);
        key = pressedKeys(1);

        if trig_codes.enabled
            ViewPixxTriggerGenerater(window, trig_codes.key_press);
            Screen('Flip', window);
            WaitSecs(0.010);
            ViewPixxTriggerGenerater(window, 0);
            Screen('Flip', window);
        end
        fprintf('Key pressed — trigger %d\n', trig_codes.key_press);

        if key == KbName('ESCAPE')
            if trig_codes.enabled
                ViewPixxTriggerGenerater(window, trig_codes.ESC);
                Screen('Flip', window);
                WaitSecs(0.010);
                ViewPixxTriggerGenerater(window, 0);
                Screen('Flip', window);
            end
            sca;
            ShowCursor;
            error('Experiment terminated by user');
        else
            break;
        end
    end

    WaitSecs(0.001);
end

end
