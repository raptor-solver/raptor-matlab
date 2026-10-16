classdef OcpLimits < handle
    %LIMITS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lower   raptor.api.v1.elements.limits.SingleOcpLimit
        upper   raptor.api.v1.elements.limits.SingleOcpLimit
    end
    
    methods
        function obj = OcpLimits(nGlobalParameters)
            % constructor
            import raptor.api.v1.elements.limits.*
            
            % set the lower and upper box constraints
            obj.lower = SingleOcpLimit(true, nGlobalParameters);
            obj.upper = SingleOcpLimit(false, nGlobalParameters);
        end
        
    end
end

