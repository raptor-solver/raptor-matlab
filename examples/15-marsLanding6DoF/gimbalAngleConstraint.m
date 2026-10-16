function val = gimbalAngleConstraint(inputData)
% function computing the value of the gimbal angle constraint for the 6DoF
% landing problem

% preamble
u = inputData.controls(1 : 3, :);
ux = u(1, :);
deltaMax = inputData.auxdata.deltaMax;

% intermediate quantities
cosDeltaMax = cos(deltaMax);

% compute value of the glide slope constraint
val = cosDeltaMax * vecnorm(u) - ux;
end

