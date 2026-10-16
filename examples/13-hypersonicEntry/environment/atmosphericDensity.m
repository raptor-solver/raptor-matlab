function rho = atmosphericDensity(h_dim, aux)
% function that computes the atmospheric density from the (dimensional)
% altitude 

% preamble
Href = aux.hs;
rho0 = aux.rho0;

% compute density
rho = rho0 .* exp(- h_dim / Href);
end

