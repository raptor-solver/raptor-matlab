function f = polarDynamics(inputData)
% function that computes the spacecraft dynamics in polar coordinates

% preamble
r = inputData.states(1, :);
theta = inputData.states(2, :);
vr = inputData.states(3, :);
vtheta = inputData.states(4, :);
alpha = inputData.controls(1, :);
T = inputData.auxdata.T;

% derivatives
rdot = vr;
thetadot = vtheta ./ r;
vrdot = (vtheta .^ 2) ./ r - 1 ./ (r .^ 2) + T .* sin(alpha);
vthetadot = - (vtheta .* vr) ./ r + T .* cos(alpha);
f = [rdot; thetadot; vrdot; vthetadot];
end

