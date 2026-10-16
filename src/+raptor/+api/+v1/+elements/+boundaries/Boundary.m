classdef Boundary < handle
    %BOUNDARY Summary of this class goes here
    %   Detailed explanation goes here

    properties
        initial raptor.api.v1.elements.boundaries.SingleBoundary
        final   raptor.api.v1.elements.boundaries.SingleBoundary
    end

    methods
        function obj = Boundary(nStates, nControls)
            % constructor
            import raptor.api.v1.elements.boundaries.*
            obj.initial = SingleBoundary(nStates, nControls);
            obj.final = SingleBoundary(nStates, nControls);
        end

    end
end

