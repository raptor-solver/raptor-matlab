function Z = getGlobalVariable(obj, trajectories)
% function that builds the global vector of the specified trajectory type
% from the provided optimal control problem description

% input validation
arguments
    obj             raptor.core.abstract.Transcription
    trajectories    raptor.inputData
end

% initialize the decision variable
Z = [];

% loop over all phases
for pp = 1 : length(trajectories)
    traj = trajectories(pp);

    % append the reshaped variables
    Z = [Z; reshape(traj.states, [], 1); reshape(traj.controls, [], 1); traj.initialTime; traj.finalTime; traj.localParameters];
end

% append global problem parameters
Z = [Z; traj.globalParameters];
end