function val = glideSlopeConstraint(inputData)
% function that computes the glide slope constraint for the non-autonomous
% landing problem

% preamble
range = inputData.states(1, :);
altitude = inputData.states(2, :);
thetaMin = inputData.auxdata.thetaMin;

% compute glideslope constraint
val = altitude - tan(thetaMin) .* range;
end

