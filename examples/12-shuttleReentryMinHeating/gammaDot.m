function f = gammaDot(inputData)
% function that computes the gamma derivative for the space shuttle problem

% preamble
[h, ~, ~, v, gamma, ~, alpha, beta] = preamble(inputData);
m = inputData.auxdata.parameters.m;
S = inputData.auxdata.parameters.S;
rho0 = inputData.auxdata.parameters.rho0;
hr = inputData.auxdata.parameters.hr;
a0 = inputData.auxdata.parameters.a0;
a1 = inputData.auxdata.parameters.a1;
mu = inputData.auxdata.parameters.mu;
r = inputData.auxdata.parameters.Re + h;
alphaHat = alpha .* 180 ./ pi;

% initermediate quantities
cL = a0 + a1 .* alphaHat;
rho = rho0 .* exp(- h ./ hr);
L = 0.5 .* cL .* S .* rho .* v.^2;
g = mu ./ (r .^ 2);

% derivative
f = (L .* cos(beta)) ./ ( m .* v) + cos(gamma) .* (v ./ r - g ./ v);
end

