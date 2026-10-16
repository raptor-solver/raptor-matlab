classdef PostProcessing < handle
    %POSTPROCESSING Summary of this class goes here
    %   Detailed explanation goes here

    %% TODO: this object must be built during the raptor.build step
    % so as the ocp gets translaed to a core ocp representation, while the
    % post processing gets instantiated with all the variable names and
    % units for plotting

    properties
        % validation object
        numericalValidation

        % plotting options
        plotPrimalSolution
        plotDualSolution
        plotValidationErrors
        auxiliaryFunction
        plottedPhases = {};

        % plotting metadata
        variableMetadata = raptor.inputData.empty(0);
    end

    %% REMEMBER: all the quantities that are plotted need to be stored
    % inside the solution structure, possibly under a field called plotting
    % (this is to include also the error metrics for the validation)

    methods
        function obj = PostProcessing()
            % constructor
        end

        function setConfigOptions(obj, cfg)
            % function that "freezes" the config options to be used
            % during/after the solution process

            % set the plot options
            obj.plotDualSolution = cfg.plotting.dual;
            obj.plotPrimalSolution = cfg.plotting.primal;
            obj.plotValidationErrors = cfg.plotting.validation;
            obj.auxiliaryFunction = cfg.plotting.auxiliaryFunction;

            % set the integrat reset flag on each phase
            for pp = 1 : length(obj.variableMetadata)
                obj.numericalValidation.resetIntegrator(pp) = obj.variableMetadata(pp).auxdata.startIntegrator;
                obj.numericalValidation.coordinateChange{pp} = obj.variableMetadata(pp).auxdata.coordinateChange;
                obj.numericalValidation.phaseNames(pp) = obj.variableMetadata(pp).auxdata.phaseName;
            end

            % set the phases plotted individually and in combination
            obj.setPlottedPhases(cfg.plotting.phases, cfg.plotting.combinedPhases);
        end

        function phaseNames = getPhaseNames(obj)
            % function that returns the names of all the problem phases
            phaseNames = strings(1, length(obj.variableMetadata));
            for pp = 1 : length(obj.variableMetadata)
                phaseNames(pp) = string(obj.variableMetadata(pp).auxdata.phaseName);
            end
        end

        function solution = perform(obj, solution, Z, lambda, zl, zu, transcription, trajectories)
            % method that performs and orchestrates the full post
            % processing routine

            % assemble the primal solution first
            try
                solution = obj.assemblePrimalSolution(solution, Z, transcription);
            catch ME
                raptor.core.utils.Logger.warn_failedPostProcessing(ME, ...
                    "primal solution assembly");
            end

            % assemble the dual solution
            try
                solution = obj.covectorMappingTheorem(solution, transcription, Z, lambda, zl, zu);
            catch ME
                raptor.core.utils.Logger.warn_failedPostProcessing(ME, ...
                    "covector mapping");
            end

            % perform the numerical propagation
            try
                solution = obj.numericalValidation.perform(solution, transcription.ocp);
            catch ME
                raptor.core.utils.Logger.warn_failedPostProcessing(ME, ...
                    "numerical propagation");
            end

            % plot the primal solution if needed
            if obj.plotPrimalSolution
                try
                    obj.plotPrimal(solution, trajectories, transcription);
                catch ME
                    raptor.core.utils.Logger.warn_failedPostProcessing(ME, ...
                        "primal solution plotting");
                end
            end

            % plot the dual solution if needed
            if obj.plotDualSolution
                try
                    obj.plotDual(solution);
                catch ME
                    raptor.core.utils.Logger.warn_failedPostProcessing(ME, ...
                        "dual solution plotting");
                end
            end

            % plot the numerical validation if needed
            if obj.plotValidationErrors
                try
                    obj.plotValidation(solution, trajectories, transcription);
                catch ME
                    raptor.core.utils.Logger.warn_failedPostProcessing(ME, ...
                        "numerical validation plotting");
                end
            end

            % generate plots through the auxiliary function if specified
            if ~isempty(obj.auxiliaryFunction)
                try
                    obj.auxiliaryFunction(solution);
                catch ME
                    raptor.core.utils.Logger.warn_failedPostProcessing(ME, ...
                        "auxiliary plotting function");
                end
            end
        end

        % defined in external files
        solution = assemblePrimalSolution(obj, solution, Z, transcription)
        solution = covectorMappingTheorem(obj, solution, transcription, Z, lambda, zl, zu)
        plotPrimal(obj, solution, trajectories, transcription)
        plotDual(obj, solution)
        plotValidation(obj, solution, trajectories, transcription)
        setPlottedPhases(obj, phases, combinedPhases)

    end

    methods (Static, Hidden)
        function values = concatenatePhases(phaseIdxs, getValues)
            % function that concatenates (along time) the values returned
            % by getValues for each of the specified phases, separating
            % them with a NaN column so that plotted lines are interrupted
            % at the phase boundaries
            values = getValues(phaseIdxs(1));
            for pp = phaseIdxs(2 : end)
                values = [values, NaN(size(values, 1), 1), getValues(pp)]; %#ok<AGROW>
            end
        end
    end
end