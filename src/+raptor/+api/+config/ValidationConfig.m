classdef ValidationConfig < handle
    % ValidationConfig  Config class for the RAPTOR validation routines
    %
    %   ValidationConfig stores the parameters required for the validation
    %   of the optimal control solution
    %
    %
    % -------------------------------------------------------------------------
    % PROPERTIES:
    %
    %
    % -------------------------------------------------------------------------
    % USAGE:
    %   cfg = raptor.api.config.ValidationConfig(); relTol = cfg.relTol;
    %
    % -------------------------------------------------------------------------
    % NOTES:
    %   - The class is purely used as data storage for parameter values. In
    %   the case of method-specific information, the methodSpecific
    %   structure is left as a flexible way to define parameters that only
    %   concern specific solvers (and thus do not fall into the
    %   cathegorization provided by other properties of this class).
    %
    % -------------------------------------------------------------------------
    % SEE ALSO:
    %   raptor.api.config.ScalingConfig, raptor.api.config.TranscriptionConfig,
    %   raptor.api.config.CollocationConfig, raptor.api.config.SolverConfig

    properties (SetAccess = public, GetAccess = public)
        method  {mustBeMember(method, ["RungeKutta45"])} = "RungeKutta45";
        relTol  {mustBePositive} = 1e-8;
        absTol  {mustBePositive} = 1e-6;
    end

    methods

        function obj = ValidationConfig(method)
            % input validation to get default parameter values
            arguments
                method  {mustBeMember(method, ["RungeKutta45"])} = "RungeKutta45";
            end
            % build object
            obj.method = method;
        end

    end
end