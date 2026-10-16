classdef L_LGR < raptor.core.collocation.interpolants.Lagrange & ...
        raptor.core.collocation.polynomials.Legendre & ...
        raptor.core.collocation.nodes.GaussRadau
    % concrete implementation of the Legendre Gauss Radau collocation
    % scheme, implemented through composition with the Lagrange interpolant

    methods
        function obj = L_LGR(cfg)
            % superclass constructor
            if nargin == 0
                super_args = {};
            else
                super_args = {cfg};
            end
            obj@raptor.core.collocation.interpolants.Lagrange(super_args{:});
        end
    end

    methods (Access = protected)
        function build(obj)
            % setup method that defines the pseudospectral operators and
            % the collocation nodes in pseudotime

            % set the polynomial basis
            build@raptor.core.collocation.polynomials.Legendre(obj);

            % set the collocation nodes
            build@raptor.core.collocation.nodes.GaussRadau(obj);

            % set the differentiation matrix
            build@raptor.core.collocation.interpolants.Lagrange(obj);
        end
    end
end