function build_initialGuess(phase, ocp, corePhase, trajectories)
% instantiate the inputdata object from the defined initial guess
initialGuess = raptor.inputData(ocp.initialGuess.globalParameters(:), ocp.auxdata);
initialGuess.initialTime = phase.initialGuess.continuous.time(1);
initialGuess.finalTime = phase.initialGuess.continuous.time(end);
initialGuess.time = phase.initialGuess.continuous.time;
initialGuess.localParameters = phase.initialGuess.continuous.localParameters;
initialGuess.states = phase.initialGuess.continuous.states;
initialGuess.controls = [phase.initialGuess.continuous.controls; ...
    zeros(corePhase.nControls - phase.nControls, size(phase.initialGuess.continuous.controls, 2))];

% trigger errors if the size of the state and controls vectors is
% inconsistent
if size(initialGuess.states, 2) ~= size(initialGuess.controls, 2)
    raptor.core.utils.Logger.err_inconsistentLength(phase.name, ...
        "initial guess states", "initial guess controls");
end

% retrieve the discretized times
tDiscrete = corePhase.collocation.getDiscretizedTime(initialGuess);

% interpolate the initial guess on the discretized times
initialGuess = corePhase.collocation.interpolateTrajectory(initialGuess, tDiscrete);

% correct the initial/final quantities
initialGuess.initialStates = initialGuess.states(:, 1);
initialGuess.finalStates = initialGuess.states(:, end);
initialGuess.initialControls = initialGuess.controls(:, 1);
initialGuess.finalControls = initialGuess.controls(:, end);

% assign to the trajectory object
trajectories.initialGuess(phase.idx) = initialGuess;
end

