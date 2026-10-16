function val = thrustNorm(inputData)
% function that computes the norm of the first 3 elements
% of the control vector

% preamble
ux = inputData.controls(1, :);
uy = inputData.controls(2, :);
uz = inputData.controls(3, :);

% compute norm
val = sqrt(ux .^2 + uy.^2 + uz.^2);
end

