function [f, T] = ascentDynamics(inputData)
% function that computes the vehicle dynamics during the ascent

% preamble
r = inputData.states(1 : 3, :);
v = inputData.states(4 : 6, :);
m = inputData.states(7, :);
That = inputData.controls(1 : 3, :);

% environment parameters
we = inputData.auxdata.we;
we = repmat(we, 1, size(v, 2));

% vehicle parameters
cd = inputData.auxdata.cd;
Sref = inputData.auxdata.Sref;
Ae = inputData.auxdata.Ae;
Tvac = inputData.auxdata.Tvac;
cvac = inputData.auxdata.cvac;

% compute aerodynamic drag acceleration
vrel = v - cross(we, r);
[rho, p] = computeAtmosphericQuantities(inputData);
D = - 0.5 * Sref * cd * rho .* vecnorm(vrel) .* vrel ./ m;

% compute thrust acceleration
T = (Tvac - p * Ae) .* That ./ m;

% compute gravitational acceleration
g = computeGravity(inputData);

% assemble the dynamics
rDot = v;
vDot = T + D + g;
mDot = - Tvac / cvac + m .* 0;
f = [rDot; vDot; mDot];
end