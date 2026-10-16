classdef OcpGuess < handle
    %GUESS Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % guess objects
        globalParameters (1, :) double
    end

    methods
        function obj = OcpGuess(nGlobalParameters)
            % constructor
            import raptor.api.v1.elements.guess.*
            obj.globalParameters = nan(nGlobalParameters, 1);
        end

    end
end

