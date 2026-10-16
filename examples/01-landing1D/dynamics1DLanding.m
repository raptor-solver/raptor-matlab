function Xdot = dynamics1DLanding(inputData)
% function to compute the 1D landing dynamics

% set the altitude rate
hdot = inputData.states(2, :);

% set the velocity rate
vdot = inputData.auxdata.env.g + inputData.controls(1, :) ./ inputData.states(3, :);

% set the mass rate
mdot = - inputData.controls(1, :) ./ inputData.auxdata.scaling.T;

% assemble output
Xdot = [hdot; vdot; mdot];
end

