function g = brachistochroneSlopeConstraint(inputData)
% funciton that computes the brachistochrone slope constraint applied to
% the states x and y

% retrieve the states and parameters
x = inputData.states(1, :);
y = inputData.states(2, :);
a = inputData.auxdata.a;

% compute the pointwise distance from the slope
g = y - a .* x;
end

