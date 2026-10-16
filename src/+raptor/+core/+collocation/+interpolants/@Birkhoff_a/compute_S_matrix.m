function S = compute_S_matrix(obj)
% function that computes the S factorization matrix for the Birkhoff
% integration matrix B = SQ

% retrieve nodes
N = obj.n_coll - 1;
tau = obj.tau_coll;

% initialize the S matrix
S = zeros(obj.n_coll, N + 1);

% compute the integrals using Proposition 6 (eq. 36c) from 'A universal
% Birkhoff pseudospectral method for solving boundary value problems'
for n = 0 : N
    S(:, n + 1) = raptor.core.utils.legendreIntegral(n, tau);
end

% check the polynomial basis functions used for node generation
if isa(obj, "raptor.core.collocation.polynomials.Legendre")
    % use eq. 48 from 'A universal Birkhoff pseudospectral method for
    % solving boundary value problems'
    gamma = 2 ./ (2 * (0 : N) + 1);
    S = S ./ gamma;
else
    % trigger an error for unsupported grid
    raptor.core.utils.Logger.errUndefinedCollocationProperty("Birkhoff " + ...
        "collocation method", "Legendre polynomial basis " + ...
        "(only Legendre supported)");
end
end