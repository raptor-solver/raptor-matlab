function f = vDot(inputData)
% function that computes the v derivative for the space shuttle problem

% preamble
[h, ~, ~, v, gamma, ~, alpha, ~] = preamble(inputData);
m = inputData.auxdata.parameters.m;
S = inputData.auxdata.parameters.S;
rho0 = inputData.auxdata.parameters.rho0;
hr = inputData.auxdata.parameters.hr;
b0 = inputData.auxdata.parameters.b0;
b1 = inputData.auxdata.parameters.b1;
b2 = inputData.auxdata.parameters.b2;
mu = inputData.auxdata.parameters.mu;
r = inputData.auxdata.parameters.Re + h;
alphaHat = alpha .* 180 ./ pi;

% intermediate quantitities
cD = b0 + b1 .* alphaHat + b2 .* alphaHat.^2;
rho = rho0 .* exp(- h ./ hr);
D = 0.5 .* S .* cD .* rho .* v.^2;
g = mu ./ (r .^ 2);

% derivative
f = - D ./ m - g .* sin(gamma);
end

