function show_attn_check_demo_generater(window, screen_cfg, cfg, header_text, footer_text)
% SHOW_ATTN_CHECK_DEMO_GENERATER - Display instructions and attention-check
% images, then wait for a key press. Uses ViewPixxTriggerGenerater directly.
%
% INPUTS:
%   window      - PTB window pointer
%   screen_cfg  - Screen configuration struct (from set_screen)
%   cfg         - Experiment configuration struct (from get_cfg)
%   header_text - Instruction / reminder string shown above the images
%   footer_text - (optional) Prompt shown below the images.
%                 Defaults to 'Press SPACE to begin.'

if nargin < 5 || isempty(footer_text)
    footer_text = 'Press SPACE to begin.';
end

n_imgs   = length(cfg.attn_check_images);
img_size = cfg.h_img;
gap      = 40;

% Load all textures first
textures = zeros(1, n_imgs);
for i = 1:n_imgs
    textures(i) = one_image( ...
        cfg.attn_check_images{i}, ...
        cfg.stimuli_dir, ...
        window, ...
        cfg.attn_check_subfolder, ...
        cfg.attn_check_category);
end

% Layout
wrap_cols     = 70;
text_height   = 320;
img_gap       = 30;
footer_gap    = 30;
footer_height = 30;

content_height = text_height + img_gap + img_size + footer_gap + footer_height;
content_top    = screen_cfg.center_Y - content_height / 2;

text_margin = content_top;
img_top     = content_top + text_height + img_gap;
img_bottom  = img_top + img_size;
footer_y    = img_bottom + footer_gap;

total_w   = n_imgs * img_size + (n_imgs - 1) * gap;
img_row_x = screen_cfg.center_X - total_w / 2;

% Draw header text
Screen('TextSize', window, 24);
DrawFormattedText(window, header_text, 'center', text_margin, [0 0 0], wrap_cols);

% Draw attention-check images
for i = 1:n_imgs
    x_left    = img_row_x + (i - 1) * (img_size + gap);
    dest_rect = [x_left, img_top, x_left + img_size, img_bottom];
    Screen('DrawTexture', window, textures(i), [], dest_rect);
end

% Draw footer prompt
Screen('TextSize', window, 24);
DrawFormattedText(window, footer_text, 'center', footer_y, [0 0 0]);

% Draw trigger pixel and flip
if cfg.triggers.enabled
    ViewPixxTriggerGenerater(window, cfg.triggers.block_text);
end
fprintf('Attn-check demo up — trigger %d\n', cfg.triggers.block_text);
Screen('Flip', window);

% Release textures
for i = 1:n_imgs
    Screen('Close', textures(i));
end

% Wait for key press
KbReleaseWait(cfg.deviceIndex);
while true
    [keyIsDown, ~, keyCode] = KbCheck(cfg.deviceIndex);
    if keyIsDown
        pressedKeys = find(keyCode);
        key = pressedKeys(1);
        if cfg.triggers.enabled
            ViewPixxTriggerGenerater(window, cfg.triggers.key_press);
            Screen('Flip', window);
            WaitSecs(0.010);
            ViewPixxTriggerGenerater(window, 0);
            Screen('Flip', window);
        end
        fprintf('Key pressed — trigger %d\n', cfg.triggers.key_press);
        if key == KbName('ESCAPE')
            if cfg.triggers.enabled
                ViewPixxTriggerGenerater(window, cfg.triggers.ESC);
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
