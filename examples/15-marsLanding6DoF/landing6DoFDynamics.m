function f = landing6DoFDynamics(inputData)
% function computing the dynamics of the 6 DoF landing problem

% preamble
g = inputData.auxdata.g;
alpha = inputData.auxdata.alpha;
J = inputData.auxdata.J;
Jinv = inputData.auxdata.Jinv;
leverArm = inputData.auxdata.leverArm;

v = inputData.states(4 : 6, :);
m = inputData.states(7, :);
q = inputData.states(8 : 11, :);
omg = inputData.states(12 : 14, :);

u = inputData.controls(1 : 3, :);

% intermediate quantities
nNodes = size(u, 2);

C_IB.r1 = [1 - 2 * (q(3, :).^2 + q(4, :).^2); 2 * (q(2, :) .* q(3, :) - q(1, :) .* q(4, :)); 2 * (q(2, :) .* q(4, :) + q(1, :) .* q(3, :))];
C_IB.r2 = [2 * (q(2, :) .* q(3, :) + q(1, :) .* q(4, :)); 1 - 2 * (q(2, :).^2 + q(4, :).^2); 2 * (q(3, :) .* q(4, :) - q(1, :) .* q(2, :))];
C_IB.r3 = [2 * (q(2, :) .* q(4, :) - q(1, :) .* q(3, :)); 2 * (q(3, :) .* q(4, :) + q(1, :) .* q(2, :)); 1 - 2 * (q(2, :).^2 + q(3, :).^2)];

omega_omg.r1 = [zeros(1, nNodes); -omg(1, :); -omg(2, :); -omg(3, :)];
omega_omg.r2 = [omg(1, :); zeros(1, nNodes); omg(3, :); -omg(2, :)];
omega_omg.r3 = [omg(2, :); -omg(3, :); zeros(1, nNodes); omg(1, :)];
omega_omg.r4 = [omg(3, :); omg(2, :); -omg(1, :); zeros(1, nNodes)];


Fx = dot(C_IB.r1, u, 1);
Fy = dot(C_IB.r2, u, 1);
Fz = dot(C_IB.r3, u, 1);

M = cross(repmat(leverArm, 1, nNodes), u, 1);

% assemble derivative
rDot = v;
vxDot = Fx ./ m + g(1);
vyDot = Fy ./ m + g(2);
vzDot = Fz ./ m + g(3);
mDot = - alpha .* vecnorm(u);
q1Dot = 0.5 * dot(omega_omg.r1, q, 1);
q2Dot = 0.5 * dot(omega_omg.r2, q, 1);
q3Dot = 0.5 * dot(omega_omg.r3, q, 1);
q4Dot = 0.5 * dot(omega_omg.r4, q, 1);
omgDot = Jinv * (M - cross(omg, (J * omg), 1));

f = [rDot; vxDot; vyDot; vzDot; mDot; q1Dot; q2Dot; q3Dot; q4Dot; omgDot];
end

