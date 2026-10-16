function f = hDot(inputData)
% function that computes the h derivative for the space shuttle problem

% preamble
[~, ~, ~, v, gamma, ~, ~, ~] = preamble(inputData);

% derivative
f = v .* sin(gamma);
end

