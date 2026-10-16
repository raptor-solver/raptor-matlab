classdef Limits < handle
    %LIMITS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lower   raptor.api.v1.elements.limits.SingleLimit
        upper   raptor.api.v1.elements.limits.SingleLimit
    end
    
    methods
        function obj = Limits(nStates, nControls, nLocalParameters)
            % constructor
            import raptor.api.v1.elements.limits.*
            
            % set the lower and upper box constraints
            obj.lower = SingleLimit(true, nStates, nControls, nLocalParameters);
            obj.upper = SingleLimit(false, nStates, nControls, nLocalParameters);
        end
        
    end
end

