function val = glideSlopeConstraint(inputData)
% function computing the value of the glide slope constraint for the 3D Mars
% landing problem

% preamble
x = inputData.states(1, :);
y = inputData.states(2, :);
z = inputData.states(3, :);
thetags = inputData.auxdata.theta_gs;

% intermediate quantities
ryz = sqrt(y.^2 + z.^2);
tanTheta = tan(thetags);

% compute value of the glide slope constraint
val = ryz - x .* tanTheta;
end

