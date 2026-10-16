function val = throttleUpperBound(inputData)
% function that computes the upper bound on the throttle

% preamble
logM = inputData.states(7, :);
mu2 = inputData.auxdata.mu2;

% compute the upper bound
val = mu2 .* logM;
end

