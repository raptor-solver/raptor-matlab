classdef RaptorConfig < handle
    % RaptorConfig  Config superclass for the RAPTOR software
    %
    %   RaptorConfig stores all the parameters required to run RAPTOR
    %
    %
    % -------------------------------------------------------------------------
    % PROPERTIES:
    %   collocation     - CollocationConfig
    %
    %   transcription   - TranscriptionConfig
    %
    %   scaling         - ScalingConfig
    %
    %   solver          - SolverConfig
    %
    %   validation      - ValidationConfig
    %
    % -------------------------------------------------------------------------
    % USAGE:
    %   cfg = raptor.api.config.RaptorConfig(); iterLimit =
    %   cfg.solver.iter_limit;
    %
    % -------------------------------------------------------------------------
    % NOTES:
    %   - The class is the collection of parameter values for the
    %   different parts of the RAPTOR software.
    %
    % -------------------------------------------------------------------------
    % SEE ALSO:
    %   raptor.api.config.ScalingConfig, raptor.api.config.TranscriptionConfig,
    %   raptor.api.config.CollocationConfig, raptor.api.config.SolverConfig,
    %   raptor.api.config.ValidationConfig

    properties (SetAccess = public, GetAccess = public)
        transcription   raptor.api.config.TranscriptionConfig = raptor.api.config.TranscriptionConfig();
        scaling         raptor.api.config.ScalingConfig = raptor.api.config.ScalingConfig();
        solver          raptor.api.config.SolverConfig = raptor.api.config.SolverConfig();
        postprocessing  raptor.api.config.PostProcessingConfig = raptor.api.config.PostProcessingConfig();
    end

    methods
        function cfg = RaptorConfig()
            % constructor
            cfg.transcription   = raptor.api.config.TranscriptionConfig();
            cfg.scaling         = raptor.api.config.ScalingConfig();
            cfg.solver          = raptor.api.config.SolverConfig();
            cfg.postprocessing  = raptor.api.config.PostProcessingConfig();
        end
    end
end