function nz = loadFactor(inputData)
% function that computes the load factor during the entry phase

% preamble
r = inputData.states(1, :);
v = inputData.states(4, :);
aux = inputData.auxdata;

% dimensionalize states
r_dim = r * aux.scaling.l;
v_dim = v * aux.scaling.v;

% compute aerodynamic coefficients
alpha_deg = angleOfAttackProfile(v_dim);
[Cl, Cd] = aerodynamicsCoefficients(alpha_deg);

% compute altitude and density
h_dim = r_dim - aux.Re;
rho = atmosphericDensity(h_dim, aux);

% compute the aerodynamic accelerations and load factor
L = 0.5 * rho .* v_dim.^2 .* aux.S/aux.m .* Cl;
D = 0.5 * rho .* v_dim.^2 .* aux.S/aux.m .* Cd;
nz = sqrt(L.^2 + D.^2) ./ (aux.g0);
end

