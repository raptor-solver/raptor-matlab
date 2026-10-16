function Q = compute_Q_matrix(obj)
% function that computes the Q factorization matrix for the Birkhoff
% integration matrix B = SQ

% retrieve nodes and weights
N = obj.n_coll - 1;
tau = obj.tau_coll;
weights = obj.w;

% initialize the Q matrix
Q = zeros(N + 1, obj.n_coll);

% check for a Gaussian grid
if isa(obj, "raptor.core.collocation.nodes.GaussRadau") || ...
        isa(obj, "raptor.core.collocation.nodes.GaussLobatto")

    % compute the n = 0 : N - 1 part of the Q matrix using Proposition 7
    % (eq. 39) from 'A universal Birkhoff pseudospectral method for solving
    % boundary value problems'
    for n = 0 : N - 1
        Q(n + 1, :) = raptor.core.utils.legendre(n, tau) .* weights';
    end

else
    % trigger an error for unsupported grids
    raptor.core.utils.Logger.errUndefinedCollocationProperty("Birkhoff " + ...
        "collocation method", "a Gaussian grid (only GaussRadau, " + ...
        "fGaussRadau, GaussLobatto are supported)");
end

% compute the final row of Q depending on the node family
if isa(obj, "raptor.core.collocation.polynomials.Legendre")
    % check only for Jacobi polynomials
    if  isa(obj, "raptor.core.collocation.nodes.GaussRadau")
        % use Corollary 2 (eq. 39) from 'A universal Birkhoff
        % pseudospectral method for solving boundary value problems'
        % The highest mode in the cardinal basis is P_N.  At flipped
        % (right) Radau nodes P_{N+1} = P_N, which made the previous
        % expression appear correct there.  At ordinary (left) Radau
        % nodes P_{N+1} = -P_N, however, so using P_{N+1} reverses this
        % entire mode and B is no longer an integration inverse of D.
        Q(N + 1, :) = raptor.core.utils.legendre(N, tau) .* weights';

    elseif isa(obj, "raptor.core.collocation.nodes.GaussLobatto")
        % use Theorem 2 (eq. 44) from 'A universal Birkhoff pseudospectral
        % method for solving boundary value problems'
        Q(N + 1, :) = raptor.core.utils.legendre(N, tau) .* weights' * N / (2 * N + 1);
    end
else
    raptor.core.utils.Logger.errUndefinedCollocationProperty("Birkhoff " + ...
        "collocation method", "a Jacobi polynomial (only Legendre " + ...
        "polynomials are supported)");
end
end
