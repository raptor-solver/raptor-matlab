classdef JacobianContainer < handle
    %JACOBIANCONTAINER Summary of this class goes here
    %   Detailed explanation goes here

    properties
        value
        pattern
    end

    methods
        function obj = JacobianContainer(parentFunction, evaluationDomain)
            % constructor
            import raptor.core.enumerations.EvaluationDomain
            import raptor.api.v1.elements.functions.jacobians.*
            if evaluationDomain == EvaluationDomain.path
                obj.value = PathValueContainer(parentFunction);
                obj.pattern = PathPatternContainer(parentFunction);
            elseif evaluationDomain == EvaluationDomain.boundary
                obj.value = BoundaryValueContainer(parentFunction);
                obj.pattern = BoundaryPatternContainer(parentFunction);
            end
        end

    end
end

