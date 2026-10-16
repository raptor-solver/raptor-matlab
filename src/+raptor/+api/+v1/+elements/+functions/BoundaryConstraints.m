classdef BoundaryConstraints < dynamicprops
    %CONSTRAINT Summary of this class goes here
    %   Detailed explanation goes here

    properties (Hidden = true)
        evaluationDomain
        phase
    end

    methods
        function obj = BoundaryConstraints(phase)
            % constructor
            obj.evaluationDomain = raptor.core.enumerations.EvaluationDomain.boundary;
            obj.phase = phase;
        end

        function constraintObject = stack(obj, name, lowerBound, upperBound)
            % method that stacks a path constraint to the current phase
            constraintObject = raptor.api.v1.elements.functions.Constraint(...
                lowerBound, upperBound, ...
                raptor.core.enumerations.EvaluationDomain.boundary, obj.phase);
            addprop(obj.phase.constraints.boundary, char(name));
            obj.phase.constraints.boundary.(name) = constraintObject;
        end
    end
end

