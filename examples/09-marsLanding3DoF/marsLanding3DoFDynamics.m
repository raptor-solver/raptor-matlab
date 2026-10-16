function f = marsLanding3DoFDynamics(inputData)
% function computing the dynamics of the 3 DoF Mars landing problem

% preamble
x = inputData.states(1, :);
y = inputData.states(2, :);
z = inputData.states(3, :);
vx = inputData.states(4, :);
vy = inputData.states(5, :);
vz = inputData.states(6, :);
logM = inputData.states(7, :);
alpha = inputData.auxdata.alpha;
g = inputData.auxdata.g;
kD0 = inputData.auxdata.kD0;
ux = inputData.controls(1, :);
uy = inputData.controls(2, :);
uz = inputData.controls(3, :);
sigma = inputData.controls(4, :);

% intermediate quantities
m = exp(logM);
speed = sqrt(vx .^2 + vy.^2 + vz.^2);
fAx = - kD0 .* speed .* vx ./ m;
fAy = - kD0 .* speed .* vy ./ m;
fAz = - kD0 .* speed .* vz ./ m;

% assemble derivative
xDot = vx;
yDot = vy;
zDot = vz;
vxDot = ux - g + fAx;
vyDot = uy + fAy;
vzDot = uz + fAz;
logmDot = - alpha .* sigma;
f = [xDot; yDot; zDot; vxDot; vyDot; vzDot; logmDot];
end

