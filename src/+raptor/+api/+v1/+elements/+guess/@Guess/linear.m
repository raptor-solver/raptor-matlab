function linear(obj)
% simple method to define a linear initial guess from the boundary
% conditions

% initialize the contiunuous grids for states and controls
statesContinuous = nan(obj.phase.nStates, 2);
controlsContinuous = nan(obj.phase.nControls, 2);

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
elseif ~isnan(obj.continuous.time(1))
    t0 = obj.continuous.time(1);
else
    raptor.core.utils.Logger.err_valueNotAssigned(obj.phase.name, ...
        "initial guess", "INITIAL TIME");
end

% define the final time for the guess time grid
if ~isnan(obj.phase.boundaryConditions.final.time)
    tf = obj.phase.boundaryConditions.final.time;
elseif ~isnan(obj.final.time)
    tf = obj.final.time;
elseif ~isnan(obj.continuous.time(end))
    tf = obj.continuous.time(end);
else
    raptor.core.utils.Logger.err_valueNotAssigned(obj.phase.name, ...
        "initial guess", "FINAL TIME");
end

% assign the time grid
tGrid = [t0 tf];
obj.continuous.time = tGrid;

% get the initial and final states
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

    % define the final state
    if ~isnan(obj.phase.boundaryConditions.final.states(ss))
        xf = obj.phase.boundaryConditions.final.states(ss);
    elseif ~isnan(obj.final.states(ss))
        xf = obj.final.states(ss);
    elseif ~isnan(obj.continuous.states(ss, end))
        xf = obj.continuous.states(ss, end);
    else
        raptor.core.utils.Logger.err_valueNotAssigned(obj.phase.name, ...
            "initial guess", strcat("FINAL STATE ", string(ss)));
    end

    % assign the extremes corresponding to the specified time grid
    xGrid = [x0 xf];
    statesContinuous(ss, :) = xGrid;
end

% interpolate the controls over the defined grid
for cc = 1 : obj.phase.nControls

    % define the initial control
    if ~isnan(obj.phase.boundaryConditions.initial.controls(cc))
        u0 = obj.phase.boundaryConditions.initial.controls(cc);
    elseif ~isnan(obj.initial.controls(cc))
        u0 = obj.initial.controls(cc);
    elseif ~isnan(obj.continuous.controls(cc, 1))
        u0 = obj.continuous.controls(cc, 1);
    else
        raptor.core.utils.Logger.err_valueNotAssigned(obj.phase.name, ...
            "initial guess", strcat("INITIAL CONTROL ", string(cc)));
    end

    % define the final control
    if ~isnan(obj.phase.boundaryConditions.final.controls(cc))
        uf = obj.phase.boundaryConditions.final.controls(cc);
    elseif ~isnan(obj.final.controls(cc))
        uf = obj.final.controls(cc);
    elseif ~isnan(obj.continuous.controls(cc, end))
        uf = obj.continuous.controls(cc, end);
    else
        raptor.core.utils.Logger.err_valueNotAssigned(obj.phase.name, ...
            "initial guess", strcat("FINAL CONTROL ", string(cc)));
    end

    % assign the extremes corresponding to the specified time grid
    xGrid = [u0 uf];
    controlsContinuous(cc, :) = xGrid;
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

% assign the continuous grids for states and controls
obj.continuous.states = statesContinuous;
obj.continuous.controls = controlsContinuous;

end