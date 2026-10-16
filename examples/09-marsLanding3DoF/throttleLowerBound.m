function val = throttleLowerBound(inputData)
% function that computes the lower bound on the throttle

% preamble
logM = inputData.states(7, :);
mu1 = inputData.auxdata.mu1;

% compute the lower bound
val = mu1 .* logM;% + 0.5 .* (logM - z0).^2);
end

