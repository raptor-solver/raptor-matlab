function m = getMaxInCell(C)
% function that outputs the maximum value in a matlab structure

% initialize output
m = -inf;

% loop over all elements
for k = 1:numel(C)
    v = C{k};

    % update output or recurse search
    if isnumeric(v) && ~isempty(v)
        m = max(m, max(v(:)));
    elseif isstruct(v)
        m = max(m, raptor.core.utils.getMaxInStruct(v));
    elseif iscell(v)
        m = max(m, raptor.core.utils.getMaxInCell(v));
    end
end
end
