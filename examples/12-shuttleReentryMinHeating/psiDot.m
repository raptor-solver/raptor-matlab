function f = psiDot(inputData)
% function that computes the psi derivative for the space shuttle problem

% preamble
[h, ~, theta, v, gamma, psi, alpha, beta] = preamble(inputData);
m = inputData.auxdata.parameters.m;
S = inputData.auxdata.parameters.S;
rho0 = inputData.auxdata.parameters.rho0;
hr = inputData.auxdata.parameters.hr;
a0 = inputData.auxdata.parameters.a0;
a1 = inputData.auxdata.parameters.a1;
r = inputData.auxdata.parameters.Re + h;
alphaHat = alpha .* 180 ./ pi;

% intermediate quantities
cL = a0 + a1 .* alphaHat;
rho = rho0 .* exp(- h ./ hr);
L = 0.5 .* cL .* S .* rho .* v.^2;

% derivative
f = (L .* sin(beta)) ./ (m .* v .* cos(gamma)) + (v .* cos(gamma) .* sin(psi) .* sin(theta)) ./ (r .* cos(theta));
end

