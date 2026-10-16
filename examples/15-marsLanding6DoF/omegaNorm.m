function val = omegaNorm(inputData)
% function that computes the norm of the angular velocity vector

% preamble
omg = inputData.states(12 : 14, :);

% compute norm
val = vecnorm(omg);
end

