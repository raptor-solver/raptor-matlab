function tNorm = thrustVectorNorm(inputData)
% function that computes the norm of the thrust direction for the ascent
% problem

% preamble
That = inputData.controls(1 : 3, :);

% compute the norm of the thrust direction components
tNorm = vecnorm(That);
end

