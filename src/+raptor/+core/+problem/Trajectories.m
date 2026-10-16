classdef Trajectories < handle
    %TRAJECTORIES  data class to store trajectory objects
    %
    % data class storing trajectory objects for the initial guess, lower
    % and upper bounds for all phases. No property valdation on size or
    % type is performed to improve speed 
    % SOURCES:
    % https://nl.mathworks.com/matlabcentral/answers/2098431-class-array-property-with-size-validation-is-slow

    properties (GetAccess = public, ...
            SetAccess = {?raptor.api.ApiToCoreInterface, ...
            ?raptor.core.abstract.Collocation, ...
            ?raptor.RAPTOR})
        
        % trajectory objects (follow the same indexing as the respective
        % phase)
        initialGuess    = raptor.inputData.empty(0);
    end

    properties (Access = public)
        lowerBound      = raptor.inputData.empty(0);
        upperBound      = raptor.inputData.empty(0);
    end
end
