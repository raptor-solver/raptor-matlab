classdef RAPTOR < handle
    % Top-level class of the raptor optimal control solver

    properties
        % canonical problem representation
        ocp
        trajectories

        % solver configuration
        config raptor.api.config.RaptorConfig

        % solver sub-routines
        transcription
        solver
        scaling
        postProcessing
    end

    methods
        function obj = RAPTOR(coreOcp, coreTrajectories, postProcessing)
            % assign the core problem
            obj.ocp = coreOcp;
            obj.trajectories = coreTrajectories;

            % assign the default config
            obj.config = raptor.api.config.RaptorConfig();

            % assign the post processing object
            obj.postProcessing = postProcessing;

            % store the phase and constraint names, used to preset the
            % manual scaling settings
            obj.config.scaling.phaseNames = postProcessing.getPhaseNames();
            for pp = 1 : length(coreOcp.phases)
                obj.config.scaling.constraintNames{pp} = ...
                    string({coreOcp.phases(pp).constraints.name});
            end
        end

        function solution = solve(obj)
            % method to solve the full optimal control problem defined by
            % the ocp and trajectories objects

            % construct the objects implementing each of the sub-routines
            % of the solution process
            obj.transcription = raptor.core.transcription.(obj.config.transcription.method)(obj.config.transcription);
            obj.solver = raptor.core.solvers.(obj.config.solver.method)(obj.config.solver);
            obj.scaling = raptor.core.scaling.(obj.config.scaling.method)(obj.config.scaling.settings);
            obj.postProcessing.numericalValidation = raptor.core.postprocessing.validation.(obj.config.postprocessing.validation.method)(obj.config.postprocessing.validation);
            obj.postProcessing.setConfigOptions(obj.config.postprocessing);

            % build the subroutine objects
            obj.transcription.build(obj.ocp, obj.trajectories);
            obj.scaling.build(obj.transcription, obj.trajectories);

            % run the solver
            [solution, Z, lambda, zl, zu] = obj.solver.solve(obj.ocp, obj.trajectories, ...
                obj.transcription, obj.scaling, []);

            % perform the full post processing
            solution = obj.postProcessing.perform(solution, Z, lambda, zl, ...
                zu, obj.transcription, obj.trajectories);
        end

        function rePlot(obj, solution)
            % method that regenerates the automatic plots from the
            % specified solution structure plot the primal solution if
            % needed
            if obj.postProcessing.plotPrimalSolution
                try
                    obj.postProcessing.plotPrimal(solution, obj.trajectories, obj.transcription);
                catch ME
                    raptor.core.utils.Logger.warn_failedPostProcessing(ME, ...
                        "primal solution plotting");
                end
            end

            % plot the dual solution if needed
            if obj.postProcessing.plotDualSolution
                try
                    obj.postProcessing.plotDual(solution);
                catch ME
                    raptor.core.utils.Logger.warn_failedPostProcessing(ME, ...
                        "dual solution plotting");
                end
            end

            % plot the numerical validation if needed
            if obj.postProcessing.plotValidationErrors
                try
                    obj.postProcessing.plotValidation(solution, obj.trajectories, obj.transcription);
                catch ME
                    raptor.core.utils.Logger.warn_failedPostProcessing(ME, ...
                        "numerical validation plotting");
                end
            end

            % generate plots through the auxiliary function if specified
            if ~isempty(obj.postProcessing.auxiliaryFunction)
                try
                    obj.postProcessing.auxiliaryFunction(solution);
                catch ME
                    raptor.core.utils.Logger.warn_failedPostProcessing(ME, ...
                        "auxiliary plotting function");
                end
            end
        end

        function solution = reConverge(obj, previousSolution)
            % method to re-solve the optimal control problem defined by the
            % ocp and with a new trajectories object built from a
            % previoulsy obtained solution to the same problem

            % check that the previous solution is consistent with the
            % defined ocp object
            %% TODO: add here some consistency checks

            % instantiate the new trajectories object
            phaseIdx = 0;
            for phase = [obj.postProcessing.variableMetadata.auxdata.phaseName]
                phaseIdx = phaseIdx + 1;

                % create the new initial guess trajectory object
                ig = raptor.inputData(previousSolution.(phase).discretized.globalParameters, ...
                    previousSolution.(phase).discretized.auxdata);
                ig.time = previousSolution.(phase).discretized.time;
                ig.states = previousSolution.(phase).discretized.states;
                ig.controls = previousSolution.(phase).discretized.controls;
                ig.localParameters = previousSolution.(phase).discretized.localParameters;
                ig.initialTime = previousSolution.(phase).discretized.initialTime;
                ig.finalTime = previousSolution.(phase).discretized.finalTime;
                ig.initialStates = previousSolution.(phase).discretized.initialStates;
                ig.finalStates = previousSolution.(phase).discretized.finalStates;
                ig.initialControls = previousSolution.(phase).discretized.initialControls;
                ig.finalControls = previousSolution.(phase).discretized.finalControls;
                obj.trajectories.initialGuess(phaseIdx) = ig;
            end

            % reconstruct the internal routines from the new config
            obj.transcription = raptor.core.transcription.(obj.config.transcription.method)(obj.config.transcription);
            obj.solver = raptor.core.solvers.(obj.config.solver.method)(obj.config.solver);
            obj.scaling = raptor.core.scaling.(obj.config.scaling.method)(obj.config.scaling.settings);
            obj.postProcessing.numericalValidation = raptor.core.postprocessing.validation.(obj.config.postprocessing.validation.method)(obj.config.postprocessing.validation);
            obj.postProcessing.setConfigOptions(obj.config.postprocessing);

            % rebuild the transcription and scaling
            obj.transcription.build(obj.ocp, obj.trajectories);
            obj.scaling.build(obj.transcription, obj.trajectories);

            % run the solver with a warm start now
            [solution, Z, lambda, zl, zu] = obj.solver.solve(obj.ocp, obj.trajectories, ...
                obj.transcription, obj.scaling, previousSolution.raw);

            % perform the full post processing
            solution = obj.postProcessing.perform(solution, Z, lambda, zl, ...
                zu, obj.transcription, obj.trajectories);
        end

        function solution = warmStart(obj, previousSolution)
            % method to re-solve the optimal control problem defined by the
            % ocp using the solution and internal routines defined for the
            % previous solve iteration

            % check that the previous solution is consistent with the
            % defined ocp object
            %% TODO: add here some consistency checks

            % instantiate the new trajectories object
            phaseIdx = 0;
            for phase = [obj.postProcessing.variableMetadata.auxdata.phaseName]
                phaseIdx = phaseIdx + 1;

                % create the new initial guess trajectory object
                ig = raptor.inputData(previousSolution.(phase).discretized.globalParameters, ...
                    previousSolution.(phase).discretized.auxdata);
                ig.time = previousSolution.(phase).discretized.time;
                ig.states = previousSolution.(phase).discretized.states;
                ig.controls = previousSolution.(phase).discretized.controls;
                ig.localParameters = previousSolution.(phase).discretized.localParameters;
                ig.initialTime = previousSolution.(phase).discretized.initialTime;
                ig.finalTime = previousSolution.(phase).discretized.finalTime;
                ig.initialStates = previousSolution.(phase).discretized.initialStates;
                ig.finalStates = previousSolution.(phase).discretized.finalStates;
                ig.initialControls = previousSolution.(phase).discretized.initialControls;
                ig.finalControls = previousSolution.(phase).discretized.finalControls;
                obj.trajectories.initialGuess(phaseIdx) = ig;
            end

            % run the solver with a warm start now
            obj.transcription.build(obj.ocp, obj.trajectories);
            obj.solver = raptor.core.solvers.(obj.config.solver.method)(obj.config.solver);
            [solution, Z, lambda, zl, zu] = obj.solver.solve(obj.ocp, obj.trajectories, ...
                obj.transcription, obj.scaling, previousSolution.raw);

            % perform the full post processing
            solution = obj.postProcessing.perform(solution, Z, lambda, zl, ...
                zu, obj.transcription, obj.trajectories);
        end
    end
end

