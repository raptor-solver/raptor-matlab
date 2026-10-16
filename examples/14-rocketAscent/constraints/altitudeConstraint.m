function h = altitudeConstraint(inputData)
% function that computes the altitude for the ascent problem to apply a
% path constraint to its value

% preamble
r = inputData.states(1 : 3, :);
R0 = inputData.auxdata.R0;

% compute altitude
h = vecnorm(r) - R0;
end

