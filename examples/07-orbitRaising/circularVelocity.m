function c = circularVelocity(inputData)
% function that computes the circular velocity 

% preamble
vthetaf = inputData.finalStates(4);
rf = inputData.finalStates(1);

% constraint value
c = vthetaf - 1 / sqrt(rf);
end

