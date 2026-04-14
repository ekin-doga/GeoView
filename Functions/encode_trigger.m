function trigger = encode_trigger(repetition, category, type_val)
% ENCODE_TRIGGER Convert (repetition, category, type) to 3-digit trigger ID
%
% INPUT:
%   repetition : 1 = new
%                2 = old
%
%   category   : 1 = bedrooms
%                2 = kitchens
%                3 = living_rooms
%
%   type_val   : 1 = target
%                2 = catch
%                3 = foil
%
% OUTPUT:
%   trigger    : 3-digit code [repetition][category][type]
%                Range: 111-233
%                0 is reserved for no-trigger / pixel reset
%
% EXAMPLE:
%   encode_trigger(1, 1, 1) = 111  (new, bedrooms, target)
%   encode_trigger(2, 3, 3) = 233  (old, living_rooms, foil)

    % Repetition is the hundreds digit (step size = 100)
    % Category is the tens digit       (step size = 10)
    % Type is the ones digit           (step size = 1)
    trigger = repetition * 100 + category * 10 + type_val;

end
