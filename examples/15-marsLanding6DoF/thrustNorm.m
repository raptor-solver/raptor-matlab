function val = thrustNorm(inputData)
% function that computes the norm of the control vector

% preamble
u = inputData.controls(1 : 3, :);

% compute norm
val = vecnorm(u);
end

