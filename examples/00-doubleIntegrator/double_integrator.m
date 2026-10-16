function xdot = double_integrator(inputData)
% function defining the state derivative for the 1D double integrator

% get the mass (just to test that the auxdata is passed correctly)
m = inputData.auxdata.mass;
xdot = [inputData.states(4 : 6, :); inputData.controls(1 : 3, :) ./ m];
end

