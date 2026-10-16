classdef (Abstract) GaussLobatto < raptor.core.abstract.Collocation
    %  partial implementation of a collocation class, implementing on the
    %  definition of the Gauss-Lobatto collocation nodes

    methods

        function obj = GaussLobatto(cfg)
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
            % function that sets metadata properties after the polynomials
            % class defines the nodes
            obj.n_coll = length(obj.tau_coll);
            obj.n_disc = length(obj.tau_disc);
            obj.coll_mask = obj.tau_disc <= 1;  
        end

    end
end