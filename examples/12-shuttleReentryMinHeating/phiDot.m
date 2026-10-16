function f = phiDot(inputData)
% function that computes the phi derivative for the space shuttle problem

% preamble
[h, ~, theta, v, gamma, psi, ~, ~] = preamble(inputData);
r = h + inputData.auxdata.parameters.Re;

% derivative
f = ((v ./ r) .* cos(gamma) .* sin(psi)) ./ cos(theta);

end

