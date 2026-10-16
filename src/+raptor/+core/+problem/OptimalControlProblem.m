classdef OptimalControlProblem < handle
    %OPTIMALCONTROLPROBLEM  core optimal control problem descriptor
    %
    % Core optimal control problem descriptor, only assuming canonical
    % problem variables. No property validation is implemented to add
    % minimal overhead when moving the object around during the solution
    % process SOURCES:
    % https://nl.mathworks.com/matlabcentral/answers/2098431-class-array-property-with-size-validation-is-slow

    properties (GetAccess = public, ...
            SetAccess = public)

        % variable sizes
        nPhases
        nGlobalParameters

        % problem functions and data
        auxdata
        linkageConditions = []

        % phase descriptors
        phases = raptor.core.problem.Phase.empty(0, 0);
    end

    methods
        function validate(obj, trajectories)
            % method that checks the full definition of the optimal control
            % problem to ensure that it is consistent and stored correctly

            % check that upper and lower bounds on global parameters are
            % consistent
            if ~isempty(trajectories.initialGuess(1).globalParameters)
                ub = trajectories.upperBound(1).globalParameters;
                lb = trajectories.lowerBound(1).globalParameters;

                % check that they are numeric and not nan
                if ~isnumeric(ub) || any(isnan(ub), "all")
                    raptor.core.utils.Logger.err_inconsistentBounds("_all_", ...
                        "upper bound", "globalParameters", "not a numeric value");
                end
                if ~isnumeric(lb) || any(isnan(lb), "all")
                    raptor.core.utils.Logger.err_inconsistentBounds("_all_", ...
                        "lower bound", "globalParameters", "not a numeric value");
                end

                % check that they have the same size
                if size(ub, 1) ~= obj.nGlobalParameters || ...
                        size(lb, 1) ~= obj.nGlobalParameters
                    raptor.core.utils.Logger.err_inconsistentBounds("_all_", ...
                        "upper/lower bound", "globalParameters", ...
                        "different size from specified variable size");
                end

                % check that they define a feasible search space
                if any(lb > ub, "all")
                    raptor.core.utils.Logger.err_inconsistentBounds("_all_", ...
                        "upper/lower bounds", "globalParameters", ...
                        "infeasible search space (ub < lb)");
                end
            end

            % loop over and validate all phases
            for pp = 1 : obj.nPhases
                obj.phases(pp).validate(trajectories);
            end
        end

    end

end