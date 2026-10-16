classdef BoundaryPatternContainer < handle
    %BOUNDARYPATTERNCONTAINER Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % variables
        initialTime
        finalTime
        initialStates
        finalStates
        initialControls
        finalControls
        localParameters
        globalParameters
        upstreamParameters
    end

    properties(Hidden = true)
        % parent function reference
        parentFunction
    end

    methods
        function obj = BoundaryPatternContainer(parentFunction)
            % constructor
            obj.parentFunction = parentFunction;
        end

    end
end

