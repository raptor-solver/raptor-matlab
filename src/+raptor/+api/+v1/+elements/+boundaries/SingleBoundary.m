classdef SingleBoundary
    %STATEBOUNDARY Handle object for a single state boundary.
    %
    %   Stores fixed value, lower and upper bounds, and fixed flag.
    %
    %   METHODS:
    %       value(val) : set equality constraint lower(val) : set lower
    %       bound upper(val) : set upper bound

    properties
        time        (1, 1) double
        states      (:, 1) double
        controls    (:, 1) double
    end

    methods
        function obj = SingleBoundary(nStates, nControls)
            obj.time = NaN;
            obj.states = nan(nStates, 1);
            obj.controls = nan(nControls, 1);
        end

    end
end