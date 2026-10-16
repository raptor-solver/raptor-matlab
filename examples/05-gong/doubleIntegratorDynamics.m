function xdot = doubleIntegratorDynamics(inputData)
% function implementing the double integrator dynamics for the Gong problem

% preamble
x = inputData.states(1, :);
v = inputData.states(2, :);
u = inputData.controls(1, :);

% assemble derivative
xDot = v;
vDot = - v + u;
xdot = [xDot; vDot];
end

