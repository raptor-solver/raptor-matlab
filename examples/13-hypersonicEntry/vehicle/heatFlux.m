function Q = heatFlux(inputData)
% function that computes the heat flux during the entry phase

% preamble
r = inputData.states(1, :);
v = inputData.states(4, :);
aux = inputData.auxdata;

% dimensionalize states
r_dim = r * aux.scaling.l;
v_dim = v * aux.scaling.v;

% compute the density and the heat flux
h_dim = r_dim - aux.Re;
rho = atmosphericDensity(h_dim, aux);
Q = aux.kq * sqrt(rho) .* v_dim.^3.15;
end

