function solution = covectorMappingTheorem(obj, solution, transcription, Z, lambda, zl, zu)
% method that populates the solution structure with the dual variables
import raptor.core.enumerations.*

% loop over all phases
for phase = transcription.ocp.phases
    [~, collocatedIdxs] = phase.collocation.getLocalTimeIdxs();
    phaseName = obj.variableMetadata(phase.idx).auxdata.phaseName;

    % Build the corrections required by the covector mapping theorem.
    % Dynamics multipliers map to physical-time costates through the
    % quadrature weights alone. Multipliers associated with path
    % constraints and path-variable bounds additionally contain the time
    % dilation introduced by the physical-time integral.
    wCostate = phase.collocation.w';
    timeDilation = phase.collocation.timeDilation.evaluateFunction(...
        solution.(phaseName).discretized);
    wPathCovector = wCostate .* timeDilation;

    % retrieve the multipliers associated with the dynamics
    if isa(phase.collocation, "raptor.core.collocation.interpolants.Birkhoff_a")
        % the states virtual controls are the first block of V
        first = phase.nControls - phase.collocation.nV + 1;
        idxString = first + "to" + (first + phase.nStates - 1);
        cIdx = transcription.con_idx(phase.idx);

        % interpolation multipliers (initial node not counted for LGR)
        Lambda = zeros(phase.nStates, phase.collocation.n_coll);
        rows = true(1, phase.collocation.n_coll);
        if numel(cIdx.("BirkhoffAinterpolation" + idxString)) < numel(Lambda)
            rows = ~phase.collocation.getSegmentInitialMask();
        end
        Lambda(:, rows) = reshape(lambda(cIdx.("BirkhoffAinterpolation" + idxString)), phase.nStates, []);
        costates = Lambda * phase.collocation.B;

        % calculus-theorem multipliers
        for k = 1 : phase.collocation.n_seg
            name = "BirkhoffAcalculus" + idxString;
            if phase.collocation.n_seg > 1
                name = name + "segment" + k;
            end
            % check for missing calculus constraint from fLGR
            if isfield(cIdx, name)
                cols = phase.collocation.seg_coll == k;
                costates(:, cols) = costates(:, cols) + lambda(cIdx.(name)) * wCostate(cols);
            end
        end
    else
        % Lagrange formulation takes multipliers directly from residuals
        costates = reshape(lambda(transcription.con_idx(phase.idx).ResidualsDynamics), phase.nStates, []);
    end

    % apply the covector mapping theorem
    costates = costates ./ wCostate;
    solution.(phaseName).collocated.costates = costates;

    % extrapolate to the non collocated nodes
    solution.(phaseName).discretized.costates = phase.collocation.interpolateQuantity(...
        solution.(phaseName).collocated.time, costates, solution.(phaseName).discretized.time);

    % initialize the hamiltonian and populate it with the lagrange costs
    cHam = zeros(1, phase.collocation.n_coll);
    for func = phase.cost.fcnDescriptors
        if func{1}.operatorType == OperatorType.integration
            cHam = cHam + func{1}.baseFunction.evaluateFunction(solution.(phaseName).discretized);
        end
    end

    % add the dynamics terms, extrapolate on discretized nodes, and assign
    % outputs
    cHam = cHam + sum(solution.(phaseName).collocated.costates .* solution.(phaseName).collocated.dynamics, 1);
    dHam = phase.collocation.interpolateQuantity(solution.(phaseName).collocated.time, cHam, solution.(phaseName).discretized.time);
    solution.(phaseName).discretized.hamiltonian = dHam;
    solution.(phaseName).collocated.hamiltonian = cHam;

    % store the covectors associated with variable boundaries
    listOfBoundedVariables = ["initialTime", "finalTime", "initialStates", "finalStates", ...
        "initialControls", "finalControls", "localParameters", "globalParameters"];
    for var = listOfBoundedVariables
        % adjust the multipliers according to the covector mapping theorem
        solution.(phaseName).collocated.covectors.upperBound.(var) = zu(transcription.var_idx(phase.idx).(var)) ./ wCostate;
        solution.(phaseName).collocated.covectors.lowerBound.(var) = zl(transcription.var_idx(phase.idx).(var)) ./ wCostate;
        solution.(phaseName).discretized.covectors.upperBound.(var) = solution.(phaseName).collocated.covectors.upperBound.(var);
        solution.(phaseName).discretized.covectors.lowerBound.(var) = solution.(phaseName).collocated.covectors.lowerBound.(var);
    end

    % store the box covectors associated to dynamic variables
    tmpStates = reshape(zu(transcription.var_idx(phase.idx).discretized.states), phase.nStates, []);
    solution.(phaseName).collocated.covectors.upperBound.states = tmpStates(:, phase.collocation.coll_mask == 1) ./ wPathCovector;
    tmpStates = reshape(zl(transcription.var_idx(phase.idx).discretized.states), phase.nStates, []);
    solution.(phaseName).collocated.covectors.lowerBound.states = tmpStates(:, phase.collocation.coll_mask == 1) ./ wPathCovector;
    solution.(phaseName).collocated.covectors.upperBound.controls = reshape(zu(transcription.var_idx(phase.idx).collocated.controls), phase.nControls, []) ./ wPathCovector;
    solution.(phaseName).collocated.covectors.lowerBound.controls = reshape(zl(transcription.var_idx(phase.idx).collocated.controls), phase.nControls, []) ./ wPathCovector;

    % extrapolate to non-collocated nodes
    solution.(phaseName).discretized.covectors.upperBound.states = phase.collocation.interpolateQuantity(...
        solution.(phaseName).collocated.time, solution.(phaseName).collocated.covectors.upperBound.states, ...
        solution.(phaseName).discretized.time);
    solution.(phaseName).discretized.covectors.lowerBound.states = phase.collocation.interpolateQuantity(...
        solution.(phaseName).collocated.time, solution.(phaseName).collocated.covectors.lowerBound.states, ...
        solution.(phaseName).discretized.time);
    solution.(phaseName).discretized.covectors.upperBound.controls = phase.collocation.interpolateQuantity(...
        solution.(phaseName).collocated.time, solution.(phaseName).collocated.covectors.upperBound.controls, ...
        solution.(phaseName).discretized.time);
    solution.(phaseName).discretized.covectors.lowerBound.controls = phase.collocation.interpolateQuantity(...
        solution.(phaseName).collocated.time, solution.(phaseName).collocated.covectors.lowerBound.controls, ...
        solution.(phaseName).discretized.time);

    % loop over all constraints
    for constraint = phase.constraints

        % assign the covector for collocated constraints
        if constraint.outputNodes == OutputNodes.collocated
            solution.(phaseName).collocated.covectors.(constraint.name) = reshape(...
                lambda(transcription.con_idx(phase.idx).(constraint.name)), ...
                constraint.outputDim, []) ./ wPathCovector;
            solution.(phaseName).discretized.covectors.(constraint.name) = phase.collocation.interpolateQuantity(...
                solution.(phaseName).collocated.time, solution.(phaseName).collocated.covectors.(constraint.name), ...
                solution.(phaseName).discretized.time);

        elseif constraint.outputNodes == OutputNodes.collocatedWithoutInitial
            interiorCovector = reshape(...
                lambda(transcription.con_idx(phase.idx).(constraint.name)), ...
                constraint.outputDim, []);
            fullCovector = zeros(constraint.outputDim, phase.collocation.n_coll);
            fullCovector(:, ~phase.collocation.getSegmentInitialMask()) = interiorCovector;
            solution.(phaseName).collocated.covectors.(constraint.name) = fullCovector ./ wPathCovector;
            solution.(phaseName).discretized.covectors.(constraint.name) = phase.collocation.interpolateQuantity(...
                solution.(phaseName).collocated.time, solution.(phaseName).collocated.covectors.(constraint.name), ...
                solution.(phaseName).discretized.time);

            % assign the covector for discretized constraints
        elseif constraint.outputNodes == OutputNodes.discretized
            disc_covector = reshape(lambda(transcription.con_idx(phase.idx).(constraint.name)), ...
                constraint.outputDim, []);
            solution.(phaseName).collocated.covectors.(constraint.name) = disc_covector(:, collocatedIdxs) ./ wPathCovector;
            solution.(phaseName).discretized.covectors.(constraint.name) = phase.collocation.interpolateQuantity(...
                solution.(phaseName).collocated.time, solution.(phaseName).collocated.covectors.(constraint.name), ...
                solution.(phaseName).discretized.time);

            % assign the covector for boundary constraints
        elseif constraint.outputNodes == OutputNodes.single
            solution.(phaseName).collocated.covectors.(constraint.name) = reshape(...
                lambda(transcription.con_idx(phase.idx).(constraint.name)), [], 1);
            solution.(phaseName).discretized.covectors.(constraint.name) = solution.(phaseName).collocated.covectors.(constraint.name);
        end
    end

end
