classdef FunctionTerm < handle
    %FUNCTIONTERM Summary of this class goes here
    %   Detailed explanation goes here

    properties
        functionHandle
        functionType    {mustBeMember(functionType, ["linear", "nonlinear", "conic"])} = "nonlinear";
        jacobian        raptor.api.v1.elements.functions.jacobians.JacobianContainer
    end

    methods
        function obj = FunctionTerm(functionHandle, outputSize, evaluationDomain, phase1, phase2)
            % constructor
            import raptor.core.enumerations.EvaluationDomain

            % instantiate the jacobian container
            obj.jacobian = raptor.api.v1.elements.functions.jacobians.JacobianContainer(obj, evaluationDomain);

            % check the evaluation domain of the function and assign the
            % correct values
            if evaluationDomain == EvaluationDomain.path
                % path-specific quantities
                obj.jacobian.pattern.time = NaN(outputSize, 1);
                obj.jacobian.pattern.states = NaN(outputSize, phase1.nStates);
                obj.jacobian.value.states = NaN;
                obj.jacobian.pattern.controls = NaN(outputSize, phase1.nControls);
                obj.jacobian.value.controls = NaN;

            elseif evaluationDomain == EvaluationDomain.boundary
                % boundary specific quantities
                obj.jacobian.pattern.initialStates = NaN(outputSize, phase1.nStates);
                obj.jacobian.value.initialStates = NaN;
                obj.jacobian.pattern.finalStates = NaN(outputSize, phase1.nStates);
                obj.jacobian.value.finalStates = NaN;
                obj.jacobian.pattern.initialControls = NaN(outputSize, phase1.nControls);
                obj.jacobian.value.initialControls = NaN;
                obj.jacobian.pattern.finalControls = NaN(outputSize, phase1.nControls);
                obj.jacobian.value.finalControls = NaN;
                obj.jacobian.pattern.initialTime = NaN(outputSize, 1);
                obj.jacobian.value.initialTime = NaN;
                obj.jacobian.pattern.finalTime = NaN(outputSize, 1);
                obj.jacobian.value.finalTime = NaN;
                if nargin == 5
                    obj.jacobian.pattern.upstreamParameters = NaN(outputSize, phase2.nLocalParameters);
                    obj.jacobian.value.upstreamParameters = NaN;
                    obj.jacobian.pattern.initialStates = NaN(outputSize, phase2.nStates);
                    obj.jacobian.pattern.initialControls = NaN(outputSize, phase2.nControls);
                    obj.jacobian.pattern.initialTime = NaN(outputSize, 1);
                end

            end

            % quantities present in both path and boundary functions
            obj.jacobian.pattern.localParameters = NaN(outputSize, phase1.nLocalParameters);
            obj.jacobian.value.localParameters = NaN;
            obj.jacobian.pattern.globalParameters = NaN(outputSize, phase1.nGlobalParameters);
            obj.jacobian.value.globalParameters = NaN;

            % assign the function handle
            obj.functionHandle = functionHandle;
        end

    end
end

