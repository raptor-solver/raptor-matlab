function solution = assemblePrimalSolution(obj, solution, Z, transcription)
% method that populates the solution structure with the primal variables
% and their related functions
import raptor.core.enumerations.*

% loop over all phases
for phase = transcription.ocp.phases
    % store the solution trajectory
    inputData = transcription.assembleInputData(Z, [phase.idx phase.idx]);

    % retrieve the phase name
    phaseName = obj.variableMetadata(phase.idx).auxdata.phaseName;

    % store the discretized and collocated trajectories as structs
    warning('off', 'MATLAB:structOnObject');
    solution.(phaseName).discretized = struct(inputData);
    warning('on', 'MATLAB:structOnObject');

    % extrapolate the controls that are not defined by the NLP (e.g., on
    % the non collocated node) from the defined ones of the same component
    undefinedControls = transcription.undefined_controls(phase.idx);
    for cc = unique(undefinedControls.component(:))'
        undefinedNodes = undefinedControls.timeNode(undefinedControls.component == cc);
        definedNodes = setdiff(1 : phase.collocation.n_disc, undefinedNodes);
        if length(definedNodes) > 1
            solution.(phaseName).discretized.controls(cc, undefinedNodes) = phase.collocation.interpolateQuantity(...
                solution.(phaseName).discretized.time(definedNodes), ...
                solution.(phaseName).discretized.controls(cc, definedNodes), ...
                solution.(phaseName).discretized.time(undefinedNodes));
        end
    end
    solution.(phaseName).discretized.initialControls = solution.(phaseName).discretized.controls(:, 1);
    solution.(phaseName).discretized.finalControls = solution.(phaseName).discretized.controls(:, end);
    solution.(phaseName).collocated = solution.(phaseName).discretized;
    [~, collocatedIdxs] = phase.collocation.getLocalTimeIdxs();
    solution.(phaseName).collocated.states = solution.(phaseName).collocated.states(:, collocatedIdxs);
    solution.(phaseName).collocated.controls = solution.(phaseName).collocated.controls(:, collocatedIdxs);
    solution.(phaseName).collocated.time = solution.(phaseName).collocated.time(collocatedIdxs);

    % evaluate the dynamics on the collocated and discretized trajectories
    dDynamics = zeros(phase.nStates, phase.collocation.n_disc);
    cDynamics = zeros(phase.nStates, phase.collocation.n_coll);
    for func = phase.dynamics
        dDynamics = dDynamics + func.fcnHandle(solution.(phaseName).discretized);
        cDynamics = cDynamics + func.fcnHandle(solution.(phaseName).collocated);
    end
    solution.(phaseName).discretized.dynamics = dDynamics;
    solution.(phaseName).collocated.dynamics = cDynamics;

    % evaluate the constraints on the collocated and discretized
    % trajectories
    for constraint = phase.constraints

        % evaluate path constraints
        if constraint.outputNodes == OutputNodes.discretized

            % initialize the discretized and collocated constraint
            constraint.functionsTypesToExclude = [];

            % evaluate the constraint
            dCon = constraint.evaluateConstraint(solution.(phaseName).discretized);
            dCon = reshape(dCon, constraint.outputDim, []);

            % assign the collocated portion of the constraint
            cCon = dCon(:, collocatedIdxs);

            % assign to the solution structure
            solution.(phaseName).collocated.(constraint.name) = cCon;
            solution.(phaseName).discretized.(constraint.name) = dCon;

            % evaluate differential constraints
        elseif constraint.outputNodes == OutputNodes.collocated

            % initialize the discretized and collocated constraint
            constraint.functionsTypesToExclude = [];

            % evaluate constraint
            cCon = constraint.evaluateConstraint(solution.(phaseName).discretized);
            cCon = reshape(cCon, constraint.outputDim, []);

            % extrapolate to the non collocated nodes
            dCon = phase.collocation.interpolateQuantity(solution.(phaseName).collocated.time, ...
                cCon, solution.(phaseName).discretized.time);

            % assign to the solution structure
            solution.(phaseName).collocated.(constraint.name) = cCon;
            solution.(phaseName).discretized.(constraint.name) = dCon;

        elseif constraint.outputNodes == OutputNodes.collocatedWithoutInitial

            constraint.functionsTypesToExclude = [];
            cCon = constraint.evaluateConstraint(solution.(phaseName).discretized);
            cCon = reshape(cCon, constraint.outputDim, []);

            % The omitted relations at the initial node of each segment
            % are the identity 0 = 0.
            fullCon = zeros(constraint.outputDim, phase.collocation.n_coll);
            fullCon(:, ~phase.collocation.getSegmentInitialMask()) = cCon;
            cCon = fullCon;
            dCon = phase.collocation.interpolateQuantity(solution.(phaseName).collocated.time, ...
                cCon, solution.(phaseName).discretized.time);

            solution.(phaseName).collocated.(constraint.name) = cCon;
            solution.(phaseName).discretized.(constraint.name) = dCon;

            % evaluate the boundary constraints
        elseif constraint.outputNodes == OutputNodes.single

            % initialize the constraint (doesnt matter if discretized or
            % collocated)
            constraint.functionsTypesToExclude = [];
            con = constraint.evaluateConstraint(solution.(phaseName).discretized);

            % assign to the solution structure
            solution.(phaseName).collocated.(constraint.name) = con;
            solution.(phaseName).discretized.(constraint.name) = con;
        end

    end

end

end
