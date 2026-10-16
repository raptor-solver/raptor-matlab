function fromControl(obj)
% simple method to define the initial guess from a control law to generate
% a dynamically feasible trajectory

% initialize the states to be used for propagation
initialStates = nan(obj.phase.nStates, 1);

% reshape the continuous guess for states and controls, if any
obj.continuous.states = reshape(obj.continuous.states, ...
    obj.phase.nStates, []);
obj.continuous.controls = reshape(obj.continuous.controls, ...
    obj.phase.nControls, []);

% check if the guess has already been built
if obj.isBuilt
    obj.rebuildAttemptError();
else
    obj.isBuilt = true;
end

% define the initial time for the guess time grid
if ~isnan(obj.phase.boundaryConditions.initial.time)
    t0 = obj.phase.boundaryConditions.initial.time;
elseif ~isnan(obj.initial.time)
    t0 = obj.initial.time;
else
    raptor.core.utils.Logger.err_valueNotAssigned(obj.phase.name, ...
        "initial guess", "INITIAL TIME");
end

% define the final time for the guess time grid
if ~isnan(obj.phase.boundaryConditions.final.time)
    tf = obj.phase.boundaryConditions.final.time;
elseif ~isnan(obj.final.time)
    tf = obj.final.time;
else
    raptor.core.utils.Logger.err_valueNotAssigned(obj.phase.name, ...
        "initial guess", "FINAL TIME");
end

% get the continuous time grid if available
if all(~isnan(obj.continuous.time))
    tGrid = obj.continuous.time;
else
    tGrid = [t0 tf];
end

% get the initial states
for ss = 1 : obj.phase.nStates

    % define the initial state
    if ~isnan(obj.phase.boundaryConditions.initial.states(ss))
        x0 = obj.phase.boundaryConditions.initial.states(ss);
    elseif ~isnan(obj.initial.states(ss))
        x0 = obj.initial.states(ss);
    elseif ~isnan(obj.continuous.states(ss, 1))
        x0 = obj.continuous.states(ss, 1);
    else
        raptor.core.utils.Logger.err_valueNotAssigned(obj.phase.name, ...
            "initial guess", strcat("INITIAL STATE ", string(ss)));
    end

    % assign the extremes corresponding to the specified time grid
    initialStates(ss) = x0;
end

% define the guess for the local parameters
for ll = 1 : obj.phase.nLocalParameters

    % look for the guess value in any of the initial/final/continuous parts
    if ~isnan(obj.initial.localParameters(ll))
        lp = obj.initial.obj.localParameters(ll);
    elseif ~isnan(obj.final.localParameters(ll))
        lp = obj.final.localParameters(ll);
    elseif ~isnan(obj.continuous.localParameters(ll))
        lp = obj.continuous.localParameters(ll);
    else
        raptor.core.utils.Logger.err_valueNotAssigned(obj.phase.name, ...
            "initial guess", strcat("LOCAL PARAMETER ", string(ll)));
    end

    % assign the guess value of the local parameter
    obj.continuous.localParameters(ll) = lp;
end

% require the continuous controls to be defined
if any(isnan(obj.continuous.controls))
    raptor.core.utils.Logger.err("guess:undefinedControl", strcat("The " + ...
        "continuous controls for phase '", obj.phase.name, "' are not fully" + ...
        " defined.\nWhen using the 'fromControl()' method to build the " + ...
        "initial guess,\nthe property 'guess.continuous.controls' needs" + ...
        " to be defined.\n"));
end

% store the continuous controls, making sure they have the correct size
if size(obj.continuous.controls, 1) ~= obj.phase.nControls
    raptor.core.utils.Logger.err("guess:incorrectSize", strcat("The " + ...
        "continuous controls for phase", obj.phase.name, "' have " + ...
        "inconsistent size.\nPhase '", obj.phase.name, "' admits ", ...
        string(obj.phase.nControls), " controls: the continuous " + ...
        "controls matrix shall have a matching number of rows.\n"));
end
if size(obj.continuous.controls, 2) == 1
    controlData = repmat(obj.continuous.controls, 1, 2);
else
    controlData = obj.continuous.controls;
end

% check the consistency between time grid and control data
nDataPoints = size(controlData, 2);
if nDataPoints ~= length(tGrid) && nDataPoints ~= 2 && length(tGrid) ~= 2
    raptor.core.utils.Logger.err("guess:inconsistentGrids", "The continous" + ...
        " time and control grids provided for the guess of phase '", ...
        obj.phase.name, "'\nhave inconsistent sizes. To build the initial " + ...
        "guess\nusing the 'fromControl()' method, the provided grids must" + ...
        "\nhave matching sizes, or either of the two\n(controls OR time)" + ...
        " must have only 2 columns.");

elseif nDataPoints ~= length(tGrid) && nDataPoints ~= 2 && length(tGrid) == 2
    % assume that the provided data points are equispaced in time
    tGrid = linspace(tGrid(1), tGrid(end), nDataPoints);
    raptor.core.utils.Logger.warn("guess:equispacedControlData", strcat("The" + ...
        " continuous control guess for phase '", obj.phase.name, "' is " + ...
        "assumed to be\nequispaced within the provided time grid.\n"));

elseif nDataPoints ~= length(tGrid) && nDataPoints == 2 && length(tGrid) ~= 2
    % interpolate the provided control data on the specified time grid
    controlData = interp1([tGrid(1) tGrid(end)], controlData', tGrid, "pchip")';
    raptor.core.utils.Logger.warn("guess:interpolatedControlData", strcat("The" + ...
        " continuous controls guess for phase '", obj.phase.name, "'\n" + ...
        "is interpolated on the provided continuous time grid.\n"));
end

% require the phase dynamics to be defined
if isempty(obj.phase.dynamics.terms)
    raptor.core.utils.Logger.err("guess:undefinedDynamics", strcat("The " + ...
        "dynamics for phase '", obj.phase.name, "' are not defined.\nWhen " + ...
        "using the 'fromControl()' method to build the initial guess,\nthe " + ...
        "property 'phase.dynamics' needs to be defined\nby adding " + ...
        "('phase.dynamics.add(@dynamicsFcn)') at least one dynamics term.\n"));
end

% local wrapper to evaluate the dynamics
    function f = evalDynamics(t, x)
        % assemble inputdata
        inputData = raptor.inputData(obj.phase.ocp.initialGuess.globalParameters,...
            obj.phase.ocp.auxdata);
        inputData.states = x;
        inputData.time = t;
        inputData.localParameters = obj.continuous.localParameters;
        inputData.controls = interp1(tGrid, controlData', t, "pchip")';

        % evaluate the dynamics
        f = zeros(obj.phase.nStates, 1);
        for term = [obj.phase.dynamics.terms]
            f = f + term.functionHandle(inputData);
        end
    end

% propagate the dynamics
options = odeset();
options.RelTol = 1e-6;
options.Vectorized = true;
[tCont, xCont] = ode45(@evalDynamics, tGrid, initialStates, options);

% assign the continous data functions
obj.continuous.time = tCont;
obj.continuous.states = xCont';
obj.continuous.controls = interp1(tGrid, controlData', tCont, "pchip")';

end