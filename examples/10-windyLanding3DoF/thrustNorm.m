function val = thrustNorm(inputData)
% fucntion that computes the value of the thrust norm constraint for the
% non autonomous landing problem

% preamble
u = inputData.controls(1 : 3, :);
Gamma = inputData.controls(4, :);

% compute constraint value (not compatible with complex steps)
% val = vecnorm(u) - Gamma;

% compute constraint value (compatible with complex steps)
ux = u(1, :);
uy = u(2, :);
uz = u(3, :);
val = sqrt(ux.^2 + uy.^2 + uz.^2) - Gamma;
end

