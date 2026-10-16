function build_boxConstraints(phase, ocp, corePhase, trajectories, discretizedTimeIdxs)
% instantiate the inputdata object from the constant box constraints
lowerBox = raptor.inputData(ocp.box.lower.globalParameters, ocp.auxdata);
upperBox = raptor.inputData(ocp.box.upper.globalParameters, ocp.auxdata);

% populate the lower bounds
lowerBox.initialTime = phase.box.lower.initialTime;
lowerBox.finalTime = phase.box.lower.finalTime;
lowerBox.time = [lowerBox.initialTime lowerBox.finalTime];
lowerBox.states = repmat(phase.box.lower.states, 1, discretizedTimeIdxs(end));
lb = [phase.box.lower.controls; -inf(corePhase.nControls - phase.nControls, 1)];
lowerBox.controls = repmat(lb, 1, discretizedTimeIdxs(end));
lowerBox.localParameters = phase.box.lower.localParameters;

% populate the upper bounds
upperBox.initialTime = phase.box.upper.initialTime;
upperBox.finalTime = phase.box.upper.finalTime;
upperBox.time = [upperBox.initialTime upperBox.finalTime];
upperBox.states = repmat(phase.box.upper.states, 1, discretizedTimeIdxs(end));
ub = [phase.box.upper.controls; inf(corePhase.nControls - phase.nControls, 1)];
upperBox.controls = repmat(ub, 1, discretizedTimeIdxs(end));
upperBox.localParameters = phase.box.upper.localParameters;

% assign to the trajectory object
trajectories.lowerBound(phase.idx) = lowerBox;
trajectories.upperBound(phase.idx) = upperBox;
end

