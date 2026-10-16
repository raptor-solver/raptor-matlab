function q = dynamicPressure(inputData)
% function that computes the dynamic pressure for the ascent problem

% preamble
r = inputData.states(1 : 3, :);
v = inputData.states(4 : 6, :);

% environment parameters
we = inputData.auxdata.we;
we = repmat(we, 1, size(v, 2));

% compute the dynamic pressure
vrel = v - cross(we, r);
[rho, ~] = computeAtmosphericQuantities(inputData);
q = 0.5 * rho .* vecnorm(vrel) .^2;
end

