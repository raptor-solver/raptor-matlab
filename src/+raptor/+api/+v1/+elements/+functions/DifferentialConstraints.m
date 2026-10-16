classdef DifferentialConstraints < dynamicprops
    %CONSTRAINT Summary of this class goes here
    %   Detailed explanation goes here

    properties (Hidden = true)
        evaluationDomain
        phase
    end

    methods
        function obj = DifferentialConstraints(phase)
            % constructor
            obj.evaluationDomain = raptor.core.enumerations.EvaluationDomain.path;
            obj.phase = phase;
        end

        function constraintObject = stack(obj, name, lowerBound, upperBound)
            % method that stacks a path constraint to the current phase
            constraintObject = raptor.api.v1.elements.functions.Constraint(...
                lowerBound, upperBound, ...
                raptor.core.enumerations.EvaluationDomain.path, obj.phase);
            addprop(obj.phase.constraints.differential, char(name));
            obj.phase.constraints.differential.(name) = constraintObject;
        end
    end
end

