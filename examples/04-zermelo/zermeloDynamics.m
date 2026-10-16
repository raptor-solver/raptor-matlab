function f = zermeloDynamics(inputData)
% function that computes the dynamics for the Zermelo problem

% preamble
x = inputData.states(1, :);
y = inputData.states(2, :);
u1 = inputData.controls(1, :);
u2 = inputData.controls(2, :);
p = inputData.auxdata.p;

% derivatives
xdot = p .* y.^3 + u1;
ydot = u2;
f = [xdot; ydot];
end

