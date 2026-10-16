function L = controlEffortCost(inputData)
% function defining the lagrange cost for the double integrator
L = 0.5 * inputData.controls(1, :) .^ 2;

end

