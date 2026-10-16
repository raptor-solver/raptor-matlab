classdef (Abstract) Legendre < raptor.core.abstract.Collocation
    %  partial implementation of a collocation class, implementing the
    %  behavior characteristic of Legendre polynomials

    methods

        function obj = Legendre(cfg)
            % superclass constructor
            if nargin == 0
                super_args = {};
            else
                super_args = {cfg};
            end
            obj@raptor.core.abstract.Collocation(super_args{:});

        end

    end

    methods (Access = protected)

        function build(obj)
            % function that sets collocation nodes and integration weights
            % depending on the specified type of nodes

            % switch behavior depending on the kind of nodes adopted
            if isa(obj, "raptor.core.collocation.nodes.GaussRadau")
                % newtown-raphson iterations to find roots
                N = obj.n_nodes - 1;
                Nm1 = N - 1;
                tau = - cos(2 * pi * (0 : Nm1) / (2 * Nm1 + 1))';

                % initialize the Legendre Vandermonde matrix
                P = zeros(N, N + 1);
                xold = 2;

                % root solve to machine precision
                Nindex = 2 : N;
                while max(abs(tau - xold)) > eps
                    xold = tau;
                    P(1 , :) = (- 1) .^ (0 : N);
                    P(Nindex, 1) = 1;
                    P(Nindex, 2) = tau(Nindex);
                    for k = Nindex
                        P(Nindex, k + 1) = ((2 * k - 1) * tau(Nindex) .* P(Nindex, k) - (k - 1) * P(Nindex, k - 1)) / k;
                    end
                    tau(Nindex) = xold(Nindex) - ((1 - xold(Nindex)) / N) .* (P(Nindex, N) + P(Nindex, N + 1)) ./ (P(Nindex, N) - P(Nindex, N + 1));
                end

                % set the collocated and discretized nodes
                obj.tau_coll = tau';
                obj.tau_disc = [obj.tau_coll 1];

                % set the integration weights
                weights = zeros(N, 1);
                weights(1) = 2 / N^2;
                weights(Nindex) = (1 - tau(Nindex)) ./ (N * P(Nindex, N)).^2;
                obj.w = weights;

            elseif isa(obj, "raptor.core.collocation.nodes.GaussLobatto")
                % initialize the matrix with eigenvalues equal to the
                % Lobatto pseudospectral roots
                N = obj.n_nodes;
                k   = 2 : N;
                a   = 0.5 * ones( N, 1 );
                b   = sqrt( ( k - 1 ) .* ( k - 3 ) ./ ( 2 * k - 3 ) ./ ( 2 * k - 5 ) ) / 2;
                J   = diag(a) + diag(b,1) + diag(b,-1);

                % Compute the roots of the tridiagonal matrix J
                [~,L] = eig(J);
                tau   = 2 * diag(L) - 1;

                % correct for numerical errors and set the nodes
                tau(1) = -1; tau(end) = 1;
                obj.tau_coll = tau'; obj.tau_disc = obj.tau_coll;

                % get the legendre polynomials
                L = legendre(N - 1,tau(2 : end - 1));
                L = L(1,:);

                % compute and set the quadrature weights
                weights = zeros(N,1);
                weights(2 : N - 1, 1) = 2 ./ (((N - 1) * N) * L.^2);
                weights(1) = 2 / ((N - 1) * N);
                weights(end) = weights(1);
                obj.w = weights;
            end
        end

    end
end