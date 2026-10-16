classdef Scaling < handle
    % Base class defining the interface method for concrete scaling
    % implementations

    properties (SetAccess = protected, GetAccess = public)
        cfg
    end

    methods
        function obj = Scaling(cfg)
            % class constructor

            % store config for potential future use in composite scaling
            % frameworks
            if nargin > 0
                obj.cfg = cfg;
            end
        end

    end

    methods (Abstract)
        % build method to pre-compute scaling factors
        build(obj)

        % mapping for the decision vector
        Z = descaleDecisionVector(obj, Z_scaled)
        Z_scaled = scaleDecisionVector(obj, Z)

        % mapping for the problem functions
        c_scaled = scaleObjective(obj, c)
        g_scaled = scaleGradient(obj, g)
        f_scaled = scaleConstraint(obj, f)
        j_scaled = scaleJacobian(obj, j)
        lambda = descaleMultipliers(obj, lambda_scaled)
        z = descaleBoxMultipliers(obj, z_scaled)
        c = descaleObjective(obj, c_scaled)
    end
end

