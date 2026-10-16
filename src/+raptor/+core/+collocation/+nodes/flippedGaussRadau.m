classdef (Abstract) flippedGaussRadau < raptor.core.collocation.nodes.GaussRadau
    %  partial implementation of a collocation class, implementing on the
    %  definition of the flipped Gauss-Radau collocation nodes

    methods
        function obj = flippedGaussRadau(cfg)
            % superclass constructor
            if nargin == 0
                super_args = {};
            else
                super_args = {cfg};
            end
            obj@raptor.core.collocation.nodes.GaussRadau(super_args{:});

        end
    end

    methods (Access = protected)

        function build(obj)
            % function that sets the GaussRadau nodes and then flips nodes
            % and weights
            build@raptor.core.collocation.nodes.GaussRadau(obj);

            % flip the collocation scheme
            obj.tau_coll = flip(- obj.tau_coll);
            obj.tau_disc = [-1 obj.tau_coll];
            obj.coll_mask = flip(obj.coll_mask);
            obj.w = flip(obj.w);
        end
    end
end