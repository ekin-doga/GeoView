function [set_text_cfg] = set_text(window, windowRect, Pos, center_X, center_Y, text_present)
% this positions the text response relative to the image

if text_present == 1
    mem_response1 = 'alt';
    mem_response2 = 'neu';
    % Key mapping for text_present == 1
    set_text_cfg.key_r1 = 'Alt';
    set_text_cfg.key_r2 = 'Neu';

    % Position: OLD on LEFT, NEW on RIGHT
    leftText = mem_response1;   % old
    rightText = mem_response2;  % new

elseif text_present == 2
    mem_response1 = 'neu';
    mem_response2 = 'alt';
    % Key mapping for text_present == 2
    set_text_cfg.key_r1 = 'Neu';
    set_text_cfg.key_r2 = 'Alt';

    % Position: NEW on LEFT, OLD on RIGHT
    leftText = mem_response1;   % new
    rightText = mem_response2;  % old
end

% Set text size
Screen('TextSize', window, 30);

% Extract image rectangle edges
imgBottom = Pos(4);

% Measure text bounding boxes
leftBounds = Screen('TextBounds', window, leftText);
rightBounds = Screen('TextBounds', window, rightText);

% Margins relative to the image edges
xMargin = round(0.15 * windowRect(3));  % horizontal offset from center
yMargin = 60;    % vertical offset below image

% Calculate positions relative to center
leftX = center_X - leftBounds(3) - xMargin;   % LEFT side
leftY = center_Y + yMargin;

rightX = center_X + xMargin;                   % RIGHT side
rightY = center_Y + yMargin;

% Store positions with meaningful names
set_text_cfg.leftX = leftX;
set_text_cfg.leftY = leftY;
set_text_cfg.rightX = rightX;
set_text_cfg.rightY = rightY;
set_text_cfg.leftText = leftText;
set_text_cfg.rightText = rightText;

% Also store as old/new for backward compatibility if needed
set_text_cfg.mem_response1 = mem_response1;
set_text_cfg.mem_response2 = mem_response2;

end