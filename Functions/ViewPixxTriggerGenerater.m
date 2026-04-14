function [window] = ViewPixxTriggerGenerater(window, PutVal, BiosemiCableInUse)
%   Calculates the color that should be drawn on the top left pixel of the
%   ViewPixx/EEG display, in order to trigger a value PUTVAL to the EEG
%   recording.
%
%   NOTE: LEAVE THE MS-WINDOWS DESKTOP-BACKGROUND BLACK! This way, the trigger that's
%   sent once PTB closes is always 0.
%
%   NOTE2: This function only draws on the buffer. The actual trigger is not
%   sent until you subsequently flip the screen and it is triggered for as
%   long as this screen is presented. (You'd need to re-flip, to null it)
%
%   INPUT:
%   window            = PTB-window-pointer
%   PutVal            = 0-255, the trigger value you want to send
%   BiosemiCableInUse = Optional argument (default=1). Set to 1 if using the
%                       Biosemi Presentation cable or AE Busch specialized cable.
%                       These db25->db37 adapters have pins 2-9 on db25 side
%                       soldered to pins 1-8 on db37 side.


% Input validation
if PutVal > 255
    warning('PixxPut:TriggerTooLarge', ...
        'The code you sent requests more than 8 pins. Are you sure that is correct?');
end

if PutVal < 0
    error('PixxPut:NegativeTrigger', 'Trigger value must be between 0 and 255');
end

% Default to using Biosemi cable pin mapping
if ~exist('BiosemiCableInUse', 'var')
    BiosemiCableInUse = 1;
end

% Convert PutVal to 24-bit binary code
binaryCode = dec2bin(PutVal, 24);
binaryCode = str2num(binaryCode(:)); 

if BiosemiCableInUse
    % Shift for cables that have Pins 2-9 on input side soldered to Pins 1-8 on output side
    % This shifts all bits left by 1 position
    binaryCode = [binaryCode(2:end)' 0];
end

% Create mapping matrices for RGB channels
% Pin mappings: [pin_numbers; bit_values]
redval   = [25 - [1, 13, 2, 14, 3, 15, 4, 16]; [1, 2, 4, 8, 16, 32, 64, 128]];
greenval = [25 - [5, 17, 6, 18, 7, 19, 8, 20]; [1, 2, 4, 8, 16, 32, 64, 128]];
blueval  = [25 - [9, 21, 10, 22, 11, 23, 12, 24]; [1, 2, 4, 8, 16, 32, 64, 128]];

% Calculate red value
for i = redval(1, :)
    if ~binaryCode(i)
        % If binary code doesn't have a 1 at this pin position, set value to 0
        redval(2, redval(1, :) == i) = 0;
    end
end

% Calculate green value
for i = greenval(1, :)
    if ~binaryCode(i)
        greenval(2, greenval(1, :) == i) = 0;
    end
end

% Calculate blue value
for i = blueval(1, :)
    if ~binaryCode(i)
        blueval(2, blueval(1, :) == i) = 0;
    end
end

% Sum to get final RGB values (0-255 range)
RGBvals = [sum(redval(2, :)), sum(greenval(2, :)), sum(blueval(2, :))];

% Draw trigger pixel at (0,0)
Screen('FillRect', window, RGBvals, [0, 0, 1, 1]);

end
