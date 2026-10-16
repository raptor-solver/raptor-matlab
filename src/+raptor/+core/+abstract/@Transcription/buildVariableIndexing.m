function buildVariableIndexing(obj)
% build the indexing for the global decision vector

% initialize the starting index
start_idx = 0;

% loop over all phases
for phase = obj.ocp.phases

    % get the time indexes for continuous variables
    discretizedTimes = 1 : phase.collocation.n_disc;
    collocatedTimes = discretizedTimes(phase.collocation.coll_mask == 1);

    % set the indexing for the state variables
    obj.var_idx(phase.idx).discretized.states = reshape((start_idx + (1 : phase.nStates) + (phase.nStates * (discretizedTimes - 1)'))', 1, []);
    obj.var_idx(phase.idx).collocated.states = reshape((start_idx + (1 : phase.nStates) + (phase.nStates * (collocatedTimes - 1)'))', 1, []);
    obj.var_idx(phase.idx).initialStates = obj.var_idx(phase.idx).discretized.states(1 : phase.nStates);
    obj.var_idx(phase.idx).finalStates = obj.var_idx(phase.idx).discretized.states(end - phase.nStates + 1 : end);
    start_idx = obj.var_idx(phase.idx).discretized.states(end);

    % set the indexing for the control variables
    obj.var_idx(phase.idx).discretized.controls = reshape((start_idx + (1 : phase.nControls) + (phase.nControls * (discretizedTimes - 1)'))', 1, []);
    obj.var_idx(phase.idx).collocated.controls = reshape((start_idx + (1 : phase.nControls) + (phase.nControls * (collocatedTimes - 1)'))', 1, []);
    obj.var_idx(phase.idx).initialControls = obj.var_idx(phase.idx).discretized.controls(1 : phase.nControls);
    obj.var_idx(phase.idx).finalControls = obj.var_idx(phase.idx).discretized.controls(end - phase.nControls + 1 : end);
    start_idx = obj.var_idx(phase.idx).discretized.controls(end);

    % set the indexing for the time extremes
    obj.var_idx(phase.idx).initialTime = start_idx + 1;
    obj.var_idx(phase.idx).finalTime = start_idx + 2;
    start_idx = start_idx + 2;

    % set the indexing for the local parameters
    obj.var_idx(phase.idx).localParameters = start_idx + (1 : phase.nLocalParameters);
    start_idx = start_idx + phase.nLocalParameters;
end

% set the indexing for the global parameters to all phases indexing
for phase = obj.ocp.phases
    obj.var_idx(phase.idx).globalParameters = start_idx + (1 : obj.ocp.nGlobalParameters);
    obj.var_idx(phase.idx).totalVariables = start_idx + obj.ocp.nGlobalParameters;
    obj.var_idx(phase.idx).auxdata = obj.ocp.auxdata;
end
end

% reworked indexes for block diagonal jacobian (NOT WORKING)
% % set the indexing for the state variables
% obj.var_idx(phase.idx).discretized.states = reshape(start_idx + ((1 : phase.nStates)' - 1) * numel(discretizedTimes) + discretizedTimes, 1, []);
% obj.var_idx(phase.idx).collocated.states = reshape(start_idx + ((1 : phase.nStates)' - 1) * numel(collocatedTimes) + collocatedTimes, 1, []);
% obj.var_idx(phase.idx).initialStates = ((1 : phase.nStates) - 1) * numel(discretizedTimes) + 1;
% obj.var_idx(phase.idx).finalStates = (1 : phase.nStates) * numel(discretizedTimes);
% start_idx = obj.var_idx(phase.idx).discretized.states(end);
%
% % set the indexing for the control variables
% obj.var_idx(phase.idx).discretized.controls = reshape(start_idx + ((1 : phase.nControls)' - 1) * numel(discretizedTimes) + discretizedTimes, 1, []);
% obj.var_idx(phase.idx).collocated.controls = reshape(start_idx + ((1 : phase.nControls)' - 1) * numel(collocatedTimes) + collocatedTimes, 1, []);
% obj.var_idx(phase.idx).initialControls = ((1 : phase.nControls) - 1) * numel(discretizedTimes) + 1;
% obj.var_idx(phase.idx).finalControls = (1 : phase.nControls) * numel(discretizedTimes);
% start_idx = obj.var_idx(phase.idx).discretized.controls(end);