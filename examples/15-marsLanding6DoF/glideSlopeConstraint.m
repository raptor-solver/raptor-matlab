function val = glideSlopeConstraint(inputData)
% function computing the value of the glide slope constraint for the 6DoF
% landing problem

% preamble
x = inputData.states(1, :);
y = inputData.states(2, :);
z = inputData.states(3, :);
gammaMax = inputData.auxdata.gammaMax;

% intermediate quantities
ryz = sqrt(y.^2 + z.^2);
tanGammaMax = tan(gammaMax);

% compute value of the glide slope constraint
val = ryz .* tanGammaMax - x;
end

