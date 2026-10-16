function build_jacobians(coreFunc, apiFunc, corePhase1, trajectories, phase1, phase2)
% function that maps the api jacobian container to the corresponding core
% function descriptor, optionally adjusting according to the core phase
% descriptor
import raptor.core.enumerations.FunctionType

% assemble here the guess trajectory object
guessTrajectory = trajectories.initialGuess(phase1.idx);
if nargin == 6
    % adjust for linkage constraint
    guessTrajectory.initialTime = trajectories.initialGuess(phase2.idx).initialTime;
    guessTrajectory.initialStates = trajectories.initialGuess(phase2.idx).initialStates;
    guessTrajectory.initialControls = trajectories.initialGuess(phase2.idx).initialControls;
    guessTrajectory.upstreamParameters = trajectories.initialGuess(phase2.idx).localParameters;
end

% adjust the controls jacobians if more have been added to the corePhase
% object (i.e.: add non-dependency from the Birkhoff virtual controls)
if isprop(apiFunc.jacobian.pattern, 'states')
    if ~isempty(apiFunc.jacobian.pattern.controls) &&...
            size(apiFunc.jacobian.pattern.controls, 2) ~= corePhase1.nControls
        nRows = size(apiFunc.jacobian.pattern.controls, 1);
        apiFunc.jacobian.pattern.controls = ...
            [apiFunc.jacobian.pattern.controls zeros(nRows, corePhase1.nControls)];
    end
    if ~isempty(apiFunc.jacobian.value.controls) && ...
            isnumeric(apiFunc.jacobian.value.controls) && ...
            size(apiFunc.jacobian.value.controls, 2) ~= corePhase1.nControls
        nRows = size(apiFunc.jacobian.value.controls, 1);
        apiFunc.jacobian.value.controls = ...
            [apiFunc.jacobian.value.controls zeros(nRows, corePhase1.nControls)];
    end
end

% loop through all properties of the current jacobian container
allVars = string(fieldnames(apiFunc.jacobian.pattern));
for var = allVars(:)'
    % assign the jacobian pattern if provided
    if ~any(isnan(apiFunc.jacobian.pattern.(var)))
        coreFunc.jacobianPattern.(var) = apiFunc.jacobian.pattern.(var);
    else
        % estimate pattern from initial guess
        coreFunc.jacobianPattern.(var) = estimatePattern(apiFunc.functionHandle, ...
            trajectories.initialGuess(phase1.idx), var);
    end
end

% loop through all properties again
for var = allVars(:)'
    % assign the jacobian value if provided
    if ~any(isnan(apiFunc.jacobian.value.(var)))
        coreFunc.jacobianValue.(var) = apiFunc.jacobian.value.(var);

        % estimate the jacobian if the function is linear and depends on
        % the variable
    elseif any(coreFunc.jacobianPattern.(var), "all") && ...
            apiFunc.functionType == FunctionType.linear
        coreFunc.jacobianValue.(var) = estimateJacobian(apiFunc.functionHandle, ...
            trajectories.initialGuess(phase1.idx), var, 1);
        % otherwise default value is used
    else
        % TODO: NO DEFAULT IS SPECIFIED, SINCE INTERNALLY ALL NONLINEAR
        % FUNCTIONS USE NUMERICAL DIFFERENTIATION TODO: GOING FORWARD, HERE
        % A NUMERICAL DIFFERENTIATION OBJECT COULD BE SPECIFIED (for each
        % function, one per variable with dependency)
    end

end
end

%% HELPER FUNCTIONS

function pattern = estimatePattern(funcHandle, guessTrajectory, whichVar)
% function that estimates the pattern of the current function, attempting
% first with NaN perturbation and then with finite difference

% default parameters for finite differences
tol = 1e-12;
pert = 1e-3;

% estimate the pattern
try
    jac = estimateJacobian(funcHandle, guessTrajectory, whichVar, NaN);
    pattern = isnan(jac);
catch
    jac = estimateJacobian(funcHandle, guessTrajectory, whichVar, pert);
    pattern = abs(jac) > tol;
end
end

function jac = estimateJacobian(funcHandle, guessTrajectory, whichVar, perturbation)
% function that estimates the jacobian pattern of the current function with
% respect to the specified variable on the initial guess

% get the required variable sizes
nVars = size(guessTrajectory.(whichVar), 1);
nTimes = size(guessTrajectory.time, 2);

% use vectorized computation
if whichVar == "states" || whichVar == "controls" || whichVar == "time"
    % replicate the trajectory over time
    guessTrajectory.time = repmat(guessTrajectory.time, 1, nVars + 1);
    guessTrajectory.states = repmat(guessTrajectory.states, 1, nVars + 1);
    guessTrajectory.controls = repmat(guessTrajectory.controls, 1, nVars + 1);

    % one-sided perturbation of the variable to estimate
    for vv = 1 : nVars
        cols = vv * nTimes + (1 : nTimes);
        guessTrajectory.(whichVar)(vv, cols) = ...
            guessTrajectory.(whichVar)(vv, cols) + perturbation;
    end

    % vectorized call to the function
    Y = funcHandle(guessTrajectory);

    % populate the jacobian pattern
    jac = zeros(size(Y, 1), nVars);
    Ybase = Y(:, 1 : nTimes);
    for vv = 1 : nVars
        cols = vv * nTimes + (1 : nTimes);
        Ycurrent = Y(:, cols);
        if ~isnan(perturbation)
            jac(:, vv) = mean((Ycurrent - Ybase) / perturbation, 2);
        else
            jac(:, vv) = mean(Ycurrent, 2);
        end
    end

    % % adjust the pattern for the time variable (treat it as single
    % % variable)
    % if whichVar == "time"
    %     jac = any(jac, 2);
    % end
else
    % compute base function evaluation
    Ybase = funcHandle(guessTrajectory);
    jac = zeros(size(Ybase, 1), nVars);

    % use component wise perturbation for static parameters
    for vv = 1 : nVars
        pertTrajectory = guessTrajectory;
        pertTrajectory.(whichVar)(vv) = guessTrajectory.(whichVar)(vv) + perturbation;

        % evaluate the function
        Ycurrent = funcHandle(pertTrajectory);
        if ~isnan(perturbation)
            jac(:, vv) = mean((Ycurrent - Ybase) / perturbation, 2);
        else
            jac(:, vv) = mean(Ycurrent, 2);
        end
    end
end
end