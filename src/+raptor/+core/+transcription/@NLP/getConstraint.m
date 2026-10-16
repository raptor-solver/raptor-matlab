function f = getConstraint(obj, Z)

% initialize output with the pre-computed linear jacobian
f = obj.jacobian * Z;

% loop over all phases
for phase = obj.ocp.phases

    % assemble trajectory for the current phase
    inputData = obj.assembleInputData(Z, [phase.idx phase.idx]);

    % loop over all constraint descriptors
    for constraint = phase.constraints

        % evaluate the constraint descriptor and assign it to the correct
        % rows of the output vector
        f(obj.con_idx(phase.idx).(constraint.name)) = f(obj.con_idx(phase.idx).(constraint.name)) + constraint.evaluateConstraint(inputData);
    end
end

% loop over all linkage conditions
for linkage = obj.ocp.linkageConditions
    % assemble the correct inputData structures
    inputData = obj.assembleInputData(Z, linkage.phaseIdxs);

    % evaluate the constraint descriptor and assign it to the correct rows
    % of the output vector
    f(obj.con_idx(end).(linkage.name)) = f(obj.con_idx(phase.idx).(linkage.name)) + linkage.evaluateConstraint(inputData);
end

end

