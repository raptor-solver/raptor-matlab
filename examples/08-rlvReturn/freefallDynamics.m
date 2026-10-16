function dxdt = freefallDynamics(inputData)
% function that computes the state derivative during the freefall phase

% preamble
aux = inputData.auxdata;
x = inputData.states(1, :);
y = inputData.states(2, :);
vx = inputData.states(3, :);
vy = inputData.states(4, :);
m = inputData.states(5, :);
K = inputData.controls(1, :);
theta = inputData.controls(2, :);

% intermediate quantities
V = sqrt(vx.^2 + vy.^2);
cosGamma = vx ./ (V);
sinGamma = vy ./ (V);
D = aux.beta * exp(- y ./ aux.h0) .* V.^2;

% assemble state derivative
dx = vx;
dy = vy;
dvx = (K .* aux.T2 .* cos(theta) - D .* cosGamma) ./ m;
dvy = (K .* aux.T2 .* sin(theta) - D .* sinGamma) ./ m - aux.g0;
dm = - K .* aux.T2 ./ aux.vExhaust;
dxdt = [dx; dy; dvx; dvy; dm];
end

