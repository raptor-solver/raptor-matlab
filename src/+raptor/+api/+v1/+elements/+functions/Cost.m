classdef Cost < handle
    %COST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % constraint definition
        terms   raptor.api.v1.elements.functions.FunctionTerm

        % size information
        evaluationDomain
        phase
    end
    
    methods
        function obj = Cost(evaluationDomain, phase)
            % constructor
            obj.evaluationDomain = evaluationDomain;
            obj.phase = phase;
        end
        
        function functionObject = add(obj, functionHandle)
            % method that adds a function term to the current constraint
            functionObject = raptor.api.v1.elements.functions.FunctionTerm(...
                functionHandle, 1, obj.evaluationDomain, obj.phase);
            obj.terms = [obj.terms functionObject];
        end
    end
end

