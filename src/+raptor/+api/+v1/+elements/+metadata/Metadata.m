classdef Metadata < handle
    %LIMITS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name            raptor.api.v1.elements.metadata.SingleMetadata
        unit            raptor.api.v1.elements.metadata.SingleMetadata
        label           raptor.api.v1.elements.metadata.SingleMetadata
        startIntegrator string = "none";
        coordinateChange function_handle = @(inputData) [];
    end
    
    methods
        function obj = Metadata(nStates, nControls, nLocalParameters)
            % constructor
            import raptor.api.v1.elements.metadata.*

            % set the time metadata
            obj.name(1).time = "time";
            obj.unit(1).time = "-";
            obj.label(1).time = "t";
            
            % set the default states metadata
            for ss = 1 : nStates
                obj.name.states(ss) = strcat("state ", string(ss));
                obj.unit.states(ss) = "-";
                obj.label.states(ss) = strcat("$x_{", string(ss), "}$");
            end

            % set the default controls metadata
            for cc = 1 : nControls
                obj.name.controls(cc) = strcat("control ", string(cc));
                obj.unit.controls(cc) = "-";
                obj.label.controls(cc) = strcat("$u_{", string(cc), "}$");
            end

            % set the default local parameters metadata
            for ll = 1 : nLocalParameters
                obj.name.localParameters(ll) = strcat("localParameter ", string(ll));
                obj.unit.localParameters(ll) = "-";
                obj.label.localParameters(ll) = strcat("$lp_{", string(ll), "}$");
            end
        end
        
    end
end

