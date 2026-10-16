classdef SolverConfig < handle
    % SolverConfig  Config class for all the RAPTOR solver routines
    %
    %   SolverConfig stores the parameters required for the solution of the
    %   required optimal control problem.
    %
    %
    % -------------------------------------------------------------------------
    % PROPERTIES:
    %
    %
    % -------------------------------------------------------------------------
    % USAGE:
    %   cfg = raptor.api.config.SolverConfig("Worhp"); iterLimit =
    %   cfg.iter_limit;
    %
    % -------------------------------------------------------------------------
    % NOTES:
    %   - The class is purely used as data storage for parameter values. In
    %   the case of solver-specific information, the solverSpecific
    %   structure is left as a flexible way to define parameters that only
    %   concern specific solvers (and thus do not fall into the
    %   cathegorization provided by other properties of this class).
    %
    % -------------------------------------------------------------------------
    % SEE ALSO:
    %   raptor.api.config.ScalingConfig, raptor.api.config.TranscriptionConfig,
    %   raptor.api.config.CollocationConfig, raptor.api.config.ValidationConfig

    properties (Access = public)
        method          {mustBeMember(method, ["Ipopt", "Snopt", "Worhp"])} = "Ipopt";
        tol             double = 1e-6
        iter_limit      double {mustBeInteger} = 3000;
        settings        = raptor.api.config.method_settings.no_settings();
    end

    methods

        function obj = SolverConfig(method)
            % build object
            if nargin == 1
                obj.method = method;
            else
                obj.method = "Ipopt";
            end
        end

        function set.method(obj, method)
            % method setter which replaces/defines the settings struct with
            % the correct settings for the chosen solver method
            arguments
                obj
                method {mustBeMember(method, ["Ipopt", "Snopt", "Worhp"])}
            end
            obj.method = method;

            % define here the different default structs for each solver
            switch method
                case "Ipopt"
                    obj.settings = raptor.api.config.method_settings.Ipopt_settings();
                case "Snopt"
                    obj.settings = raptor.api.config.method_settings.Snopt_settings();
                case "Worhp"
                    obj.settings = raptor.api.config.method_settings.Worhp_settings();
            end
        end

    end
end