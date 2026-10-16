function inc = inclination(inputData)
% function that computes the current inclindation of the ascent trajectory

% preamble
r = inputData.finalStates(1 : 3, :);
v = inputData.finalStates(4 : 6, :);

% compute inclination
h = cross(r, v);
cos_i = h(3,:) ./ vecnorm(h);
cos_i = max(min(cos_i, 1, "includemissing"), -1, "includemissing");
inc = acos(cos_i);
end

