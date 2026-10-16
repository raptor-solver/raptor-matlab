classdef ScalingConfig < handle
    % ScalingConfig  Config class for all the RAPTOR scaling routines
    %
    %   ScalingConfig stores the parameters required for the scaling and
    %   de-scaling of the optimal control problem and its solution
    %
    %
    % -------------------------------------------------------------------------
    % PROPERTIES:
    %
    %
    % -------------------------------------------------------------------------
    % USAGE:
    %   cfg = raptor.api.config.ScalingConfig();
    %
    % -------------------------------------------------------------------------
    % NOTES:
    %   - The class is purely used as data storage for parameter values. In
    %   the case of method-specific information, the methodSpecific
    %   structure is left as a flexible way to define parameters that only
    %   concern specific scaling methods (and thus do not fall into the
    %   cathegorization provided by other properties of this class).
    %
    % -------------------------------------------------------------------------
    % SEE ALSO:
    %   raptor.api.config.SolverConfig, raptor.api.config.TranscriptionConfig,
    %   raptor.api.config.CollocationConfig, raptor.api.config.ValidationConfig

    properties (Access = public)
        method      {mustBeMember(method, ["BoundsProjection", "NoScaling", ...
            "CompositeLinearScaling", "RuizStatic", ...
            "JacobianRowNormalization", "PJRN", ...
            "Permutation", "Manual"])} = "NoScaling";
        settings    = raptor.api.config.method_settings.no_settings();
    end

    properties (Hidden, SetAccess = protected)
        composableMethods = ["BoundsProjection", "RuizStatic", ...
            "JacobianRowNormalization", "Permutation", "Manual"];
    end

    properties (Hidden, SetAccess = ?raptor.RAPTOR)
        % names of the problem phases and of their constraints, used to
        % preset the manual scaling settings
        phaseNames = string.empty
        constraintNames = {}
    end

    methods

        function obj = ScalingConfig(method)
            % input validation to get default parameter values
            arguments
                method  {mustBeMember(method, ["BoundsProjection", ...
                    "NoScaling", "CompositeLinearScaling", "RuizStatic", ...
                    "JacobianRowNormalization", "PJRN", ...
                    "Permutation", "Manual"])} = "NoScaling";
            end
            % build object
            obj.method = method;
        end

        function set.method(obj, method)
            % method setter which replaces/defines the settings struct with
            % the correct settings for the chosen solver method
            if length(method) == 1 && method ~= "CompositeLinearScaling"
                obj.method = method;

                % set the settings for the current method
                obj.settings = obj.getCorrectConfig(method);
            elseif length(method) > 1
                % check that every method is composable before touching
                % the object, so that a rejected array leaves the previous
                % configuration in place
                method = string(method(:)');
                invalidMethods = method(~ismember(method, obj.composableMethods));
                if ~isempty(invalidMethods)
                    raptor.core.utils.Logger.err("config:invalidScalingMethod", "%s", ...
                        "The scaling methods " + join("'" + invalidMethods + "'", ", ") + ...
                        " cannot be composed. An array of scaling methods can only " + ...
                        "contain: " + join(obj.composableMethods, ", ") + ".");
                end

                obj.method = "CompositeLinearScaling";
                obj.settings = [];

                % loop over all methods to assign the correct settings
                % object
                for m = method
                    obj.settings.(m) = obj.getCorrectConfig(m);
                end
            else
                raptor.core.utils.Logger.err("config:invalidScalingMethod", "%s", ...
                    "'CompositeLinearScaling' cannot be selected directly: assign " + ...
                    "an array of composable scaling methods instead, e.g. " + ...
                    "[""BoundsProjection"", ""RuizStatic""]. The composable methods " + ...
                    "are: " + join(obj.composableMethods, ", ") + ".");
            end

        end

    end

    methods (Hidden)
        function cfg = getCorrectConfig(obj, method)
            % function that outputs the correct config object for the
            % specified method
            switch method
                case "Manual"
                    cfg = raptor.api.config.method_settings.Manual_settings(...
                        obj.phaseNames, obj.constraintNames);
                case "RuizStatic"
                    cfg = raptor.api.config.method_settings.Ruiz_settings;
                case "Permutation"
                    cfg = raptor.api.config.method_settings.Permutation_settings;
                case "PJRN"
                    cfg.BoundsProjection = ...
                        raptor.api.config.method_settings.no_settings();
                    cfg.JacobianRowNormalization = ...
                        raptor.api.config.method_settings.no_settings();
                case {"BoundsProjection" "JacobianRowNormalization" "NoScaling"}
                    cfg = raptor.api.config.method_settings.no_settings;
            end
        end
    end
end
