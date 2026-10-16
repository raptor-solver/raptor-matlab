function xdot = goddardRocketDynamics(inputData)
% function implementing the dynamics of the Goddard rocket

% preamble
h = inputData.states(1, :);
v = inputData.states(2, :);
m = inputData.states(3, :);
T = inputData.controls(1, :);
g = inputData.auxdata.g;
h0 = inputData.auxdata.h0;
sigma = inputData.auxdata.sigma;
c = inputData.auxdata.c;

% intermediate quantities
rho = exp(- h ./ h0);

% compute derivatives
hDot = v;
vDot = (1 ./ m) .* (T - sigma .* v.^2 .* rho) - g;
mDot = - T ./ c;
xdot = [hDot; vDot; mDot];
end

