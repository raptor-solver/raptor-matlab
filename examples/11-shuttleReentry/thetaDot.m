function f = thetaDot(inputData)
% function that computes the theta derivative for the space shuttle problem

% preamble
[h, ~, ~, v, gamma, psi, ~, ~] = preamble(inputData);
r = h + inputData.auxdata.parameters.Re;

% derivative
f = (v ./ r) .* cos(gamma) .* cos(psi);
end

