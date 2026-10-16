function dxdt = landingDynamics(inputData)
% function implementing the dynamics function for the non autonomous
% landing problem

% preamble
t = inputData.time;
x = inputData.states(1 : 3, :);
v = inputData.states(4 : 6, :);
u = inputData.controls(1 : 3, :);

% compute external perturbation
w = inputData.auxdata.w(t);

% assemble derivative
dx = v;
dv = - inputData.auxdata.g + u + w;
dxdt = [dx; dv];
end

