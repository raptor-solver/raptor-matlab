classdef PathPatternContainer < handle
    %PATHPATTERNCONTAINER Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % variables
        time
        states
        controls
        localParameters
        globalParameters
    end

    properties(Hidden = true)
        % parent function reference
        parentFunction
    end

    methods
        function obj = PathPatternContainer(parentFunction)
            % constructor
            obj.parentFunction = parentFunction;
        end

    end
end

