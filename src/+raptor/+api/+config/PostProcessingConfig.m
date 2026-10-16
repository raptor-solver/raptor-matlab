classdef PostProcessingConfig < handle
    %POSTPROCESSING Summary of this class goes here
    %   Detailed explanation goes here

    properties (SetAccess = public, GetAccess = public)
        validation  raptor.api.config.ValidationConfig
        plotting    raptor.api.config.PlottingConfig
    end

    methods
        function obj = PostProcessingConfig()
            % deafult config values
            obj.validation = raptor.api.config.ValidationConfig("RungeKutta45");
            obj.plotting = raptor.api.config.PlottingConfig();
        end

    end
end