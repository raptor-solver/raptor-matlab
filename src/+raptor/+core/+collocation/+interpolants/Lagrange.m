classdef (Abstract) Lagrange < raptor.core.abstract.Collocation
    % partial implementation of collocation methods based on Lagrange
    % interpolation

    methods

        function obj = Lagrange(cfg)
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
            % function defining the differentiation matrix (after the
            % collocation nodes are defined)

            % check that the nodes have been defined
            if obj.tau_disc(1) == - 2
                raptor.core.utils.Logger.errUndefinedCollocationProperty("Legendre collocation object", "the collocation nodes");
            end

            % initialize the barycentric weights
            M = obj.n_disc; M1 = M + 1; M2 = M^2;
            Y = repmat(obj.tau_disc', 1, M);

            % compute the differentiation matrix
            Ydiff = Y - Y' + eye(M);
            WW = repmat(1 ./ prod(Ydiff, 2), 1, M);
            D = WW ./ (WW' .* Ydiff);
            D(1 : M1 : M2) = 1 - sum(D);
            D = -D';

            % set the collocated portion of the differentiation matrix
            obj.D = D(obj.coll_mask == 1, :);
        end

    end

    methods (Access = {?raptor.api.ApiToCoreInterface, ?raptor.core.abstract.Collocation})

        function wrapperFunc = applyDifferentiationWrapper(obj, func, ~, ~, ~)
            % function that creates the wrapper for a differentiated
            % function and optionally adjusts the phase descriptor and
            % guess object

            % instantiate the wrapper function
            wrapperFunc = raptor.core.collocation.wrappers.LagrangeDifferentiation(func, obj.D);
        end

        function wrapperFunc = applyIntegrationWrapper(obj, func, ~, ~)
            % function that creates the wrapper for an integrated function
            % and optionally adjusts the phase descriptor and guess object

            % instantiate the wrapper function
            wrapperFunc = raptor.core.collocation.wrappers.QuadratureIntegration(func, obj.w, obj.timeDilation);
        end

        function nExtraControls = getNumberOfExtraControls(~, ~)
            % function that outputs the number of extra controls required
            % by the collocation technique
            nExtraControls = 0;
        end

    end

end