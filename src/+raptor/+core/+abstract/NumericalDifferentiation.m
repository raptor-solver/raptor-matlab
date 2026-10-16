classdef (Abstract) NumericalDifferentiation < handle
    %NUMERICALDIFFERENTIATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected, GetAccess = public)
        step_h
    end
    
    methods
        function obj = NumericalDifferentiation(step_h)
            % constructor
            obj.step_h = step_h;
        end
    end

    methods (Abstract)
        perform
    end
end

