classdef Constraint < handle
    %CONSTRAINT Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % constraint definition
        terms   raptor.api.v1.elements.functions.FunctionTerm

        % metadata properties
        unit    string = "-";
        label   string = "";
    end

    properties (Hidden = true)
        % size information
        lowerBound
        upperBound
        evaluationDomain
        phase1
        phase2
    end

    methods
        function obj = Constraint(lowerBound, upperBound, evaluationDomain, phase1, phase2)
            % constructor
            obj.lowerBound = lowerBound;
            obj.upperBound = upperBound;
            obj.evaluationDomain = evaluationDomain;
            obj.phase1 = phase1;
            if nargin == 5
                obj.phase2 = phase2;
            end
        end

        function functionObject = add(obj, functionHandle)
            % method that adds a function term to the current constraint
            if isempty(obj.phase2)
                functionObject = raptor.api.v1.elements.functions.FunctionTerm(...
                    functionHandle, length(obj.lowerBound), obj.evaluationDomain, obj.phase1);
            else
                functionObject = raptor.api.v1.elements.functions.FunctionTerm(...
                    functionHandle, length(obj.lowerBound), obj.evaluationDomain, obj.phase1, obj.phase2);
            end
            obj.terms = [obj.terms functionObject];
        end
    end
end

