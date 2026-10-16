function l = cost1DLanding(inputData)
% function to compute the running cost term in the 1D landing problem

l = inputData.controls(1, :) ./ inputData.auxdata.scaling.T;
end

