function inputData = assembleInputData(obj, Z, phase_idxs)
% function to assemble the inputData object for the current phase(s)

% initialize the inputData object and retrieve the current phases
inputData = raptor.inputData(Z(obj.var_idx(phase_idxs(1)).globalParameters)', obj.ocp.auxdata);
phase1 = obj.ocp.phases(phase_idxs(1));
phase2 = obj.ocp.phases(phase_idxs(2));

% assign the extremal states
inputData.initialStates = reshape(Z(obj.var_idx(phase2.idx).initialStates), [], 1);
inputData.finalStates = reshape(Z(obj.var_idx(phase1.idx).finalStates), [], 1);

% assign the extremal controls
inputData.initialControls = reshape(Z(obj.var_idx(phase2.idx).initialControls), [], 1);
inputData.finalControls = reshape(Z(obj.var_idx(phase1.idx).finalControls), [], 1);

% assign the time extremes
inputData.initialTime = Z(obj.var_idx(phase2.idx).initialTime);
inputData.finalTime = Z(obj.var_idx(phase1.idx).finalTime);

% assign the local parameters
inputData.localParameters = Z(obj.var_idx(phase2.idx).localParameters)';
inputData.upstreamParameters = Z(obj.var_idx(phase1.idx).localParameters)';

% assign the dynamics quantities (time vector first)
inputData.time = phase1.collocation.getDiscretizedTime(inputData);

% assign the state and control vectors
inputData.states = reshape(Z(obj.var_idx(phase1.idx).discretized.states), phase1.nStates, []);
inputData.controls = reshape(Z(obj.var_idx(phase1.idx).discretized.controls), phase1.nControls, []);
end