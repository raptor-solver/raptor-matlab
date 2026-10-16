classdef SingleOcpLimit < handle
    %STATEBOUNDARY Handle object for a single state boundary.
    %
    %   Stores fixed value, lower and upper bounds, and fixed flag.
    %
    %   METHODS:
    %       value(val) : set equality constraint lower(val) : set lower
    %       bound upper(val) : set upper bound

    properties
        globalParameters    (:, 1) double
    end

    properties (Hidden = true)
        isLower
    end

    methods
        function obj = SingleOcpLimit(isLower, nGlobalParameters)
            % set the utility property
            obj.isLower = isLower;

            % set the default values for the box constraints
            if obj.isLower
                obj.globalParameters = - inf(nGlobalParameters, 1);
            else
                obj.globalParameters = inf(nGlobalParameters, 1);
            end
        end

    end
end