function dxdt = entryDynamics(inputData)
% function computing the full dynamics of the entry vehicle

% preamble
aux = inputData.auxdata;
r = inputData.states(1, :);
theta = inputData.states(2, :);
phi = inputData.states(3, :);
v = inputData.states(4, :);
gamma = inputData.states(5, :);
psi = inputData.states(6, :);
sigma = inputData.states(7, :);
sigmaDot = inputData.controls(1, :);

% dimensionalize the states
r_dim = r .* aux.scaling.l;
v_dim = v .* aux.scaling.v;

% compute aerodynamic coefficients
alpha_deg = angleOfAttackProfile(v_dim);
[Cl, Cd] = aerodynamicsCoefficients(alpha_deg);

% compute altitude and density
h_dim = r_dim - aux.Re;
rho = atmosphericDensity(h_dim, aux);

% compute the aerodynamic accelerations
L = 0.5 * aux.scaling.l * rho .* v.^2 .* aux.S/aux.m .* Cl;
D = 0.5 * aux.scaling.l * rho .* v.^2 .* aux.S/aux.m .* Cd;

% compute the full states derivative
Omg = aux.omega * aux.scaling.t;
dxdt(1, :) = v.*sin(gamma);
dxdt(2, :) = v.*cos(gamma).*sin(psi)./(r.*cos(phi));
dxdt(3, :) = v.*cos(gamma).*cos(psi)./r;
dxdt(4, :) = (-D-sin(gamma).*aux.scaling.a./r.^2+Omg^2*r.*cos(phi).*(sin(gamma).*cos(phi)-cos(gamma).*sin(phi).*cos(psi)));
dxdt(5, :) = (L.*cos(sigma)./v+(v.^2-aux.scaling.a./r).*cos(gamma)./(v.*r)+2*Omg*cos(phi).*sin(psi)+Omg.^2*r./v.*cos(phi).*(cos(gamma).*cos(phi) + sin(gamma).*sin(phi).*cos(psi)));
dxdt(6, :) = (L.*sin(sigma)./(v.*cos(gamma))+v./r.*cos(gamma).*sin(psi).*tan(phi)+2*Omg*(sin(phi)-cos(phi).*tan(gamma).*cos(psi))+Omg^2.*r./(v.*cos(gamma)).*(cos(phi).*sin(phi).*sin(psi)));
dxdt(7, :) = sigmaDot;
end

