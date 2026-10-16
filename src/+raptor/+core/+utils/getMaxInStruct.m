function m = getMaxInStruct(S)
% function that outputs the maximum value in a matlab structure

% initialize output
m = -inf;

% loop over all fields
fn = fieldnames(S);
for k = 1:numel(fn)
    v = S.(fn{k});

    % update the output value or recurse search
    if isnumeric(v) && ~isempty(v)
        m = max(m, max(v(:)));
    elseif isstruct(v)
        m = max(m, raptor.core.utils.getMaxInStruct(v));
    elseif iscell(v)
        m = max(m, raptor.core.utils.getMaxInCell(v));
    end
end
end
