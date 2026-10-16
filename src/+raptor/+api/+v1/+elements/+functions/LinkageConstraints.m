classdef LinkageConstraints < dynamicprops
    %CONSTRAINT Summary of this class goes here
    %   Detailed explanation goes here

    properties (Hidden = true)
        evaluationDomain
        ocp
    end

    methods
        function obj = LinkageConstraints(ocp)
            % constructor
            obj.evaluationDomain = raptor.core.enumerations.EvaluationDomain.boundary;
            obj.ocp = ocp;
        end

        function constraintObject = stack(obj, name, phase1, phase2, lowerBound, upperBound)
            % method that stacks a path constraint to the current phase
            constraintObject = raptor.api.v1.elements.functions.Constraint(...
                lowerBound, upperBound, ...
                raptor.core.enumerations.EvaluationDomain.boundary, phase1, phase2);
            addprop(obj.ocp.linkage, char(name));
            obj.ocp.linkage.(name) = constraintObject;
        end

        function constraintObject = continuity(obj, phase1, phase2, coordinateChange)
            % default method that links the specified phases together (in
            % the provided order)

            % check that the coordinate change function is defined
            if nargin == 3 || isempty(coordinateChange)
                coordinateChange = @(inputData) inputData.finalStates(1 : phase1.nStates);
                functionType = "linear";
            else
                functionType = "nonlinear";
            end

            % check that the variable sizes of the two phases match
            if phase1.nStates ~= phase2.nStates
                raptor.core.utils.Logger.err_interPhaseMismatch(phase1.name, ...
                    phase2.name, "states");
            elseif phase1.nControls ~= phase2.nControls
                raptor.core.utils.Logger.err_interPhaseMismatch(phase1.name, ...
                    phase2.name, "controls");
            elseif phase1.nLocalParameters ~= phase2.nLocalParameters
                raptor.core.utils.Logger.err_interPhaseMismatch(phase1.name, ...
                    phase2.name, "localParameters");
            end

            % set the metadata for the second phase to those of the first
            % phase
            raptor.core.utils.Logger.info(strcat("Copying metadata " + ...
                "properties of\nphase '", phase1.name, "' to phase '", ...
                phase2.name, "'."));
            % this is done property-wise to avoid copying references to
            % handle objects
            phase2.metadata.unit = phase1.metadata.unit;
            phase2.metadata.label = phase1.metadata.label;
            phase2.metadata.name = phase1.metadata.name;
            phase2.metadata.startIntegrator = phase1.name;
            phase2.metadata.coordinateChange = coordinateChange;

            % set the variable bounds for the second phase to those of the
            % first phase
            raptor.core.utils.Logger.info(strcat("Copying variable bounds " + ...
                "properties of\nphase '", phase1.name, "' to phase '", ...
                phase2.name, "'."));
            phase2.box.lower.states = phase1.box.lower.states;
            phase2.box.upper.states = phase1.box.upper.states;
            phase2.box.lower.controls = phase1.box.lower.controls;
            phase2.box.upper.controls = phase1.box.upper.controls;
            phase2.box.lower.localParameters = phase1.box.lower.localParameters;
            phase2.box.upper.localParameters = phase1.box.upper.localParameters;
            phase2.box.lower.initialTime = phase1.box.lower.finalTime;
            phase2.box.upper.initialTime = phase1.box.upper.finalTime;

            % setting the initial guess for time and states
            raptor.core.utils.Logger.info(strcat("Copying final conditions of" + ...
                "\nphase '", phase1.name, "' to initial conditions of phase '", ...
                phase2.name, "'."));
            % check that phase1 has a fully generated initial guess
            if phase1.initialGuess.isBuilt
                phase2.initialGuess.initial.time = phase1.initialGuess.continuous.time(end);
                phase2.initialGuess.initial.states = phase1.initialGuess.continuous.states(:, end);
            else
                raptor.core.utils.Logger.err("interphase:guess", strcat("To" + ...
                    " correctly link\nphase '", phase1.name, "' to phase '", phase2.name, "',\n" + ...
                    "the initial guess for phase '", phase1.name, "' needs to be correctly built\n" + ...
                    "(use one of the initialGuess.linear(), " + ...
                    "initialGuess.fromControl(), ... methods).\n"));
            end

            % instantiate the actual constraint
            constraintName = strcat(phase1.name, "_to_", phase2.name);
            constraintSize = 1 + phase1.nStates;
            constraintObject = obj.ocp.linkage.stack(constraintName, phase1, phase2, ...
                zeros(constraintSize, 1), zeros(constraintSize, 1));
            link = obj.ocp.linkage.(constraintName).add(@(inputData) ...
                [inputData.initialStates(1 : phase2.nStates); inputData.initialTime] - ...
                [coordinateChange(inputData); inputData.finalTime]);
            link.functionType = functionType;
	    link.jacobian.pattern.initialControls = [];
        end
    end
end

