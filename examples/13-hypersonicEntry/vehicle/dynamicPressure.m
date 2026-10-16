function q = dynamicPressure(inputData)
% function computing the dynamic pressure during the entry phase

% preamble
r = inputData.states(1, :);
v = inputData.states(4, :);
aux = inputData.auxdata;

% dimensionalize states
r_dim = r * aux.scaling.l;
v_dim = v * aux.scaling.v;

% compute density and dynamic pressure
h_dim = r_dim - aux.Re;
rho = atmosphericDensity(h_dim, aux);
q = 0.5 .* rho .* v_dim.^2;
end

