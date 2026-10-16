classdef OcpMetadata < handle
    %LIMITS Summary of this class goes here
    %   Detailed explanation goes here

    properties
        name            raptor.api.v1.elements.metadata.SingleOcpMetadata
        unit            raptor.api.v1.elements.metadata.SingleOcpMetadata
        label           raptor.api.v1.elements.metadata.SingleOcpMetadata
    end

    methods
        function obj = OcpMetadata(nGlobalParameters)
            % constructor
            import raptor.api.v1.elements.metadata.*

            % set the default global parameters metadata
            for gg = 1 : nGlobalParameters
                obj.name.globalParameters(gg) = strcat("globalParameter ", string(gg));
                obj.unit.globalParameters(gg) = "-";
                obj.label.globalParameters(gg) = strcat("$gp_{", string(gg), "}$");
            end
        end
    end

end

