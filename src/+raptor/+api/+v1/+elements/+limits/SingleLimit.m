classdef SingleLimit < handle
    %STATEBOUNDARY Handle object for a single state boundary.
    %
    %   Stores fixed value, lower and upper bounds, and fixed flag.
    %
    %   METHODS:
    %       value(val) : set equality constraint lower(val) : set lower
    %       bound upper(val) : set upper bound

    properties
        initialTime     (1, 1) double
        finalTime       (1, 1) double
        states          (:, 1) double
        controls        (:, 1) double
        localParameters (:, 1) double
    end

    properties (Hidden = true)
        isLower
    end

    methods
        function obj = SingleLimit(isLower, nStates, nControls, nLocalParameters)
            % set the utility property
            obj.isLower = isLower;

            % set the default values for the box constraints
            if obj.isLower
                obj.states = - inf(nStates, 1);
                obj.controls = - inf(nControls, 1);
                obj.localParameters = - inf(nLocalParameters, 1);
                obj.initialTime = - Inf;
                obj.finalTime = - Inf;
            else
                obj.states = inf(nStates, 1);
                obj.controls = inf(nControls, 1);
                obj.localParameters = inf(nLocalParameters, 1);
                obj.initialTime = Inf;
                obj.finalTime = Inf;
            end
        end

    end
end