function [Report, RT] = get_response(startTime, deviceIndex, Keys)

% Waits for a keypress and returns response code and RT
% startTime should be the time of stimulus offset (or any reference point)

KbName('UnifyKeyNames');    


%cfg.Keys.Response = {KbName('d'); KbName('f'); KbName('j'); KbName('k')};

Report = 0;
RT = 0;

if nargin < 2 || isempty(startTime)
    startTime = GetSecs;  % default to now if no startTime provided
end

if nargin < 3 || isempty(deviceIndex)
    deviceIndex = -1;     % default: any keyboard
end

% Make sure no key is held down from before
KbReleaseWait(deviceIndex);

while Report == 0
    [keyIsDown, keyTime, keyCode] = KbCheck(deviceIndex);

    if keyIsDown
        pressedKeys = find(keyCode);  % get all pressed key indices

        if ~isempty(pressedKeys)
            key = pressedKeys(1);     % take the first key pressed
            RT = keyTime - startTime; % reaction time

            if key == Keys.r1
                Report = 1;

            elseif key == Keys.r2
                Report = 2;

            elseif key == Keys.Quit
                Report = 99;
                sca;            % close screen
                ShowCursor;     % show mouse
                return;

            else
                % Ignore other keys and continue waiting
                continue;
            end

            break; % exit loop immediately after valid response
        end
    end

    WaitSecs(0.001); % avoid busy-wait
end
end

