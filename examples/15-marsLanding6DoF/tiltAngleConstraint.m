function val = tiltAngleConstraint(inputData)
% function computing the value of the tilt angle constraint for the 6DoF
% landing problem

% preamble
q3 = inputData.states(10, :);
q4 = inputData.states(11, :);
thetaMax = inputData.auxdata.thetaMax;

% intermediate quantities
cosThetaMax = cos(thetaMax);

% compute value of the glide slope constraint
val = cosThetaMax - (1 - 2 * (q3.^2 + q4.^2));
end

