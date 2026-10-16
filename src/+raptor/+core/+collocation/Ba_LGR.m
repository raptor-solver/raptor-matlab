classdef Ba_LGR < raptor.core.collocation.interpolants.Birkhoff_a & ...
    raptor.core.collocation.polynomials.Legendre & ...
    raptor.core.collocation.nodes.GaussRadau
    % % concrete implementation of the Legendre Gauss Radau collocation
    % scheme using the Birkhoff 'a' integration matrix

    methods

        function obj = Ba_LGR(cfg)
            % superclass constructor
            if nargin == 0
                super_args = {};
            else
                super_args = {cfg};
            end
            obj@raptor.core.collocation.interpolants.Birkhoff_a(super_args{:});
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
            build@raptor.core.collocation.interpolants.Birkhoff_a(obj);
        end

    end

end