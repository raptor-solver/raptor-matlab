classdef PlottingConfig < handle
    %PLOTTINGCONFIG Summary of this class goes here
    %   Detailed explanation goes here

    properties
        primal      double = true;
        dual        double = true;
        validation  double = true;

        % phases plotted individually ("all" by default), and sets of
        % phases plotted together in the same figures (e.g.,
        % {["ascent" "coast"], ["descent" "landing"]})
        phases          string = "all";
        combinedPhases  cell = {};

        auxiliaryFunction   function_handle ...
            {raptor.api.utils.input_validation.mustBeFunctionWithNinputs(auxiliaryFunction, 1)} ...
            = @(solution) fprintf("\nNo auxiliary plotting function specified.\n");
    end

    methods
        function obj = PlottingConfig()
            % constructor
            obj.primal = true;
            obj.dual = true;
            obj.validation = true;
            obj.phases = "all";
            obj.combinedPhases = {};
            obj.auxiliaryFunction = @(solution) ...
                fprintf("\nNo auxiliary plotting function specified.\n");
        end

    end
end

