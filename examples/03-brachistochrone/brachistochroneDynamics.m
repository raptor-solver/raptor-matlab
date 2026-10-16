function stateDot = brachistochroneDynamics(inputData)
% function that computes the state derivative for the Brachistochrone
% problem

% retrieve the states, controls, and gravity
% x = inputData.states(1, :);
% y = inputData.states(2, :);
v = inputData.states(3, :);
u = inputData.controls(1, :);
g = inputData.auxdata.g;

% compute the state derivatives for each component
xDot = v .* sin(u);
yDot = v .* cos(u);
vDot = g .* cos(u);
stateDot = [xDot; yDot; vDot];
end

