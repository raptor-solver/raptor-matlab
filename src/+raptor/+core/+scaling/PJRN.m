classdef PJRN < raptor.core.scaling.CompositeLinearScaling
    %PJRN Projected Jacobian row normalization.
    %
    % PJRN is the named composite scaling
    %
    %   BoundsProjection -> JacobianRowNormalization.
    %
    % Bounds projection defines the affine variable map and therefore the
    % projected Jacobian J*A_inv. Jacobian row normalization then constructs
    % the constraint scaling from the row norms of that projected Jacobian.

    methods
        function obj = PJRN(cfg)
            if nargin == 0
                cfg = PJRN.defaultConfig();
            end
            obj@raptor.core.scaling.CompositeLinearScaling(cfg);
        end
    end

    methods (Static, Access = private)
        function cfg = defaultConfig()
            % Field insertion order defines the composite application order.
            cfg.BoundsProjection = ...
                raptor.api.config.method_settings.no_settings();
            cfg.JacobianRowNormalization = ...
                raptor.api.config.method_settings.no_settings();
        end
    end
end
