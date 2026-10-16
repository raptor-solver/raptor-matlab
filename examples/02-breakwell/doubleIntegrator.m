function xdot = doubleIntegrator(inputData)
% function defining the state derivative for the 1D double integrator
xdot = [inputData.states(2, :); inputData.controls(1, :)];
end

