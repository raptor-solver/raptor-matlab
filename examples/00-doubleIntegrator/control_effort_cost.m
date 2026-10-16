function L = control_effort_cost(inputData)
% function defining the lagrange cost for the double integrator
w = inputData.auxdata.control_weight;
L = w * sum(inputData.controls(1 : 3, :) .^2, 1);

end

