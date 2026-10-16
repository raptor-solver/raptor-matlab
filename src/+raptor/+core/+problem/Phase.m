classdef Phase < handle
    %PHASE  phase class descriptor
    %
    % Core phase class descriptor, only assuming the canonical problem
    % variables. No property validation is implemented to add minimal
    % overhead when moving the object around during the solution process
    % SOURCES:
    % https://nl.mathworks.com/matlabcentral/answers/2098431-class-array-property-with-size-validation-is-slow

    properties (GetAccess = public, ...
            SetAccess = {?raptor.api.ApiToCoreInterface, ...
            ?raptor.core.abstract.Collocation, ...
            ?raptor.core.abstract.Transcription})

        % phase index
        idx

        % variable sizes
        nStates
        nControls
        nLocalParameters
        nGlobalParameters

        % problem functions
        dynamics    = []
        cost        = []
        constraints = []

        % collocation object
        collocation
    end

    methods
        function obj = Phase(idx)
            % construct by assigning the index within the full problem
            obj.idx = idx;
        end

        function validate(obj, trajectories)
            % function that performs a full check of the defined problem
            % description to ensure that problem data is consistent and
            % correctly stored
            import raptor.core.enumerations.OutputNodes

            % validate all variable bounds
            allVars = ["states", "controls", "localParameters", ...
                "initialTime", "finalTime"];
            allVarSizes = [obj.nStates, obj.nControls, obj.nLocalParameters, 1, 1];
            for vv = 1 : length(allVars)
                if allVarSizes(vv) ~= 0
                    obj.validate_bounds(allVars(vv), allVarSizes(vv), ...
                        trajectories.upperBound(obj.idx).(allVars(vv)), ...
                        trajectories.lowerBound(obj.idx).(allVars(vv)));
                end
            end

            % validate all constraint bounds
            for con = obj.constraints
                obj.validate_bounds(con.name, con.outputDim, con.upperBound, ...
                    con.lowerBound);
            end

            % validate all single functions that compose the constraint
            for con = obj.constraints
                ig = trajectories.initialGuess(obj.idx);
                for func = con.fcnDescriptors
                    try
                        % evaluate function
                        val = func{1}.evaluateFunction(ig);
                    catch ME
                        % rethrow constraint evaluation error as warning
                        raptor.core.utils.Logger.err_testEvaluationFailed(ME, ...
                            string(obj.idx), con.name);
                    end

                    % check that the output size of the constraint is
                    % consistent with its bounds
                    constraintDim = con.outputDim;
                    if size(val, 1) ~= constraintDim
                        raptor.core.utils.Logger.err_inconsistentBounds(...
                            string(obj.idx), "lower/upper bound", con.name, ...
                            "bounds have different size from the constraint output");
                    end
                end
            end

            % test evaluation of all constraints on the provided initial
            % guess object
            ig = trajectories.initialGuess(obj.idx);
            for con = obj.constraints
                try
                    % evaluate constraint
                    val = con.evaluateConstraint(ig);
                catch ME
                    % rethrow constraint evaluation error as warning
                    raptor.core.utils.Logger.err_testEvaluationFailed(ME, ...
                        string(obj.idx), con.name);
                end

                % check that the output size of the constraint is
                % consistent with its bounds
                nTimes = obj.collocation.n_coll * ...
                    (con.outputNodes == OutputNodes.collocated) + ...
                    (obj.collocation.n_coll - obj.collocation.n_seg) * ...
                    (con.outputNodes == OutputNodes.collocatedWithoutInitial) + ...
                    (con.outputNodes == OutputNodes.single) + ...
                    obj.collocation.n_disc * ...
                    (con.outputNodes == OutputNodes.discretized);
                constraintDim = con.outputDim;
                if size(val, 1) ~= nTimes * constraintDim
                    raptor.core.utils.Logger.err_inconsistentBounds(...
                        string(obj.idx), "lower/upper bound", con.name, ...
                        "bounds have different size from the constraint output");
                end
            end

        end
    end

    methods (Access = protected)
        % internal methods to help in validation

        function validate_bounds(obj, name, dim, ub, lb)
            % function that performs all the necessary checks for the upper
            % and lower bounds on a specific variable/constraint

            % check that they are numeric and not nan
            if ~isnumeric(ub) || any(isnan(ub), "all")
                raptor.core.utils.Logger.err_inconsistentBounds(string(obj.idx), ...
                    "upper bound", name, "not a numeric value");
            end
            if ~isnumeric(lb) || any(isnan(lb), "all")
                raptor.core.utils.Logger.err_inconsistentBounds(string(obj.idx), ...
                    "lower bound", name, "not a numeric value");
            end

            % check that they have the same size
            if size(ub, 1) ~= dim || size(lb, 1) ~= dim
                raptor.core.utils.Logger.err_inconsistentBounds(string(obj.idx), ...
                    "upper/lower bound", name, ...
                    "different size from specified variable size");
            end

            % check that they define a feasible search space
            if any(lb > ub, "all")
                raptor.core.utils.Logger.err_inconsistentBounds(string(obj.idx), ...
                    "upper/lower bounds", name, ...
                    "infeasible search space (ub < lb)");
            end
        end

    end

end
