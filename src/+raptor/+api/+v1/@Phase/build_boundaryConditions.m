function build_boundaryConditions(phase, corePhase)
import raptor.core.problem.descriptors.*
import raptor.core.enumerations.*

% asemble the variable sizes object
varSizes = VariableSizes(corePhase.collocation.n_disc, corePhase.nStates, ...
    corePhase.nControls, corePhase.nLocalParameters, corePhase.nGlobalParameters);

% initialize boundary conditions dependency idxs and values
initialStatesIdxs = [];
initialStatesValues = [];
initialControlsIdxs = [];
initialControlsValues = [];
initialTimeIdx = [];
initialTimeValue = [];
finalStatesIdxs = [];
finalStatesValues = [];
finalControlsIdxs = [];
finalControlsValues = [];
finalTimeIdx = [];
finalTimeValue = [];
nBoundaryConditions = 0;

% loop over all state components
for ss = 1 : length(phase.boundaryConditions.initial.states)

    % get the current initial and final conditions
    initialCondition = phase.boundaryConditions.initial.states(ss);
    finalCondition = phase.boundaryConditions.final.states(ss);

    % instantiate the initial condition constraint if needed
    if ~isnan(initialCondition)

        % store the index and value of the current initial condition
        initialStatesIdxs = [initialStatesIdxs; ss];
        initialStatesValues = [initialStatesValues; initialCondition];
        nBoundaryConditions = nBoundaryConditions + 1;
    end

    % instantiate the final condition constraint if needed
    if ~isnan(finalCondition)

        % store the index and value of the current final condition
        finalStatesIdxs = [finalStatesIdxs; ss];
        finalStatesValues = [finalStatesValues; finalCondition];
        nBoundaryConditions = nBoundaryConditions + 1;
    end
end

% loop over all control components
for cc = 1 : length(phase.boundaryConditions.initial.controls)

    % get the current initial and final conditions
    initialCondition = phase.boundaryConditions.initial.controls(cc);
    finalCondition = phase.boundaryConditions.final.controls(cc);

    % instantiate the initial condition constraint if needed
    if ~isnan(initialCondition)

        % store the index and value of the current initial condition
        initialControlsIdxs = [initialControlsIdxs; cc];
        initialControlsValues = [initialControlsValues; initialCondition];
        nBoundaryConditions = nBoundaryConditions + 1;
    end

    % instantiate the final condition constraint if needed
    if ~isnan(finalCondition)

        % store the index and value of the current final condition
        finalControlsIdxs = [finalControlsIdxs; cc];
        finalControlsValues = [finalControlsValues; finalCondition];
        nBoundaryConditions = nBoundaryConditions + 1;
    end
end

% assign only the equality initial conditions on time
initialCondition = phase.boundaryConditions.initial.time;
if ~isnan(initialCondition)

    % store the initial time value
    initialTimeValue = initialCondition;
    initialTimeIdx = 1;
    nBoundaryConditions = nBoundaryConditions + 1;
end

% assign only the equality final conditions on time
finalCondition = phase.boundaryConditions.final.time;
if ~isnan(finalCondition)

    % store the final time value
    finalTimeValue = finalCondition;
    finalTimeIdx = 1;
    nBoundaryConditions = nBoundaryConditions + 1;
end

% instantiate the boundary conditions function and related jacobian
boundaryFcn = Function(@(inputData) ...
    [inputData.initialStates(initialStatesIdxs); ...
    inputData.initialControls(initialControlsIdxs); ...
    inputData.finalStates(finalStatesIdxs); ...
    inputData.finalControls(finalControlsIdxs); ...
    inputData.initialTime(initialTimeIdx); ...
    inputData.finalTime(finalTimeIdx)], nBoundaryConditions, FunctionType.linear, ...
    EvaluationDomain.boundary, OperatorType.none, varSizes, 1);
boundaryFcn.jacobianValue.initialStates = zeros(nBoundaryConditions, varSizes.states);
boundaryFcn.jacobianValue.initialStates(1 : length(initialStatesIdxs), initialStatesIdxs) = eye(length(initialStatesIdxs));
boundaryFcn.jacobianPattern.initialStates = boundaryFcn.jacobianValue.initialStates;
start_idx = length(initialStatesIdxs);
boundaryFcn.jacobianValue.initialControls = zeros(nBoundaryConditions, varSizes.controls);
boundaryFcn.jacobianValue.initialControls(start_idx + 1 : start_idx + length(initialControlsIdxs), initialControlsIdxs) = eye(length(initialControlsIdxs));
boundaryFcn.jacobianPattern.initialControls = boundaryFcn.jacobianValue.initialControls;
start_idx = start_idx + length(initialControlsIdxs);
boundaryFcn.jacobianValue.finalStates = zeros(nBoundaryConditions, varSizes.states);
boundaryFcn.jacobianValue.finalStates(start_idx + 1: start_idx + length(finalStatesIdxs), finalStatesIdxs) = eye(length(finalStatesIdxs));
boundaryFcn.jacobianPattern.finalStates = boundaryFcn.jacobianValue.finalStates;
start_idx = start_idx + length(finalStatesIdxs);
boundaryFcn.jacobianValue.finalControls = zeros(nBoundaryConditions, varSizes.controls);
boundaryFcn.jacobianValue.finalControls(start_idx + 1: start_idx + length(finalControlsIdxs), finalControlsIdxs) = eye(length(finalControlsIdxs));
boundaryFcn.jacobianPattern.finalControls = boundaryFcn.jacobianValue.finalControls;
start_idx = start_idx + length(finalControlsIdxs);
boundaryFcn.jacobianValue.initialTime = zeros(nBoundaryConditions, 1);
boundaryFcn.jacobianValue.initialTime(start_idx + 1 : start_idx + length(initialTimeIdx), initialTimeIdx) = eye(length(initialTimeIdx));
boundaryFcn.jacobianPattern.initialTime = boundaryFcn.jacobianValue.initialTime;
boundaryFcn.jacobianValue.finalTime = zeros(nBoundaryConditions, 1);
start_idx = start_idx + length(initialTimeIdx);
boundaryFcn.jacobianValue.finalTime(start_idx + 1 : start_idx + length(finalTimeIdx), finalTimeIdx) = eye(length(finalTimeIdx));
boundaryFcn.jacobianPattern.finalTime = boundaryFcn.jacobianValue.finalTime;

% instantiate the boundary conditions constraint
boundaryConditionsVector = [initialStatesValues; initialControlsValues; ...
    finalStatesValues; finalControlsValues; initialTimeValue; finalTimeValue];
if ~isempty(boundaryConditionsVector)
    boundaryConditions = Constraint("boundaryConditions", {boundaryFcn}, nBoundaryConditions, ...
        OutputNodes.single, boundaryConditionsVector, boundaryConditionsVector, ...
        corePhase.collocation);
    corePhase.constraints = [corePhase.constraints boundaryConditions];
end
end

