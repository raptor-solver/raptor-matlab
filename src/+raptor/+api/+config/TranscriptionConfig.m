classdef TranscriptionConfig < handle
    % TranscriptionConfig  Config class for all the RAPTOR transcription
    % routines
    %
    %   TranscriptionConfig stores the parameters required for the
    %   transcription of the defined optimal control problem.
    %
    %
    % -------------------------------------------------------------------------
    % PROPERTIES:
    %
    %
    % -------------------------------------------------------------------------
    % USAGE:
    %   cfg = raptor.api.config.TranscriptionConfig(); jacMethod =
    %   cfg.numericalJacobian;
    %
    % -------------------------------------------------------------------------
    % NOTES:
    %   - The class is purely used as data storage for parameter values. In
    %   the case of method-specific information, the methodSpecific
    %   structure is left as a flexible way to define parameters that only
    %   concern specific transcription methods (and thus do not fall into
    %   the cathegorization provided by other properties of this class).
    %
    % -------------------------------------------------------------------------
    % SEE ALSO:
    %   raptor.api.config.ScalingConfig, raptor.api.config.SolverConfig,
    %   raptor.api.config.CollocationConfig, raptor.api.config.ValidationConfig

    properties (Access = public)
        method              {mustBeMember(method, ["NLP", "SCP"])} = "NLP";
        settings            = raptor.api.config.method_settings.no_settings();
        numericalJacobian   {mustBeMember(numericalJacobian, ...
            ["ComplexStepDifferences", "CentralDifferences"])} = "CentralDifferences";
        finiteStep          {mustBeScalarOrEmpty, mustBeNumeric} = 1e-5;
    end

    methods

        function obj = TranscriptionConfig(method)
            % input validation to get default parameter values
            arguments
                method  {mustBeMember(method, ["NLP", "SCP"])} = "NLP";
            end
            % build object
            obj.method = method;
        end

        function set.method(obj, method)
            % method setter which replaces/defines the settings struct with
            % the correct settings for the chosen solver method
            arguments
                obj
                method {mustBeMember(method, ["NLP", "SCP"])}
            end
            obj.method = method;

            % define here the different default structs for each solver
            switch method
                case "NLP"
                    obj.settings = raptor.api.config.method_settings.no_settings();
                case "SCP"
                    error("SCP not implemented yet");
            end
        end

    end
end