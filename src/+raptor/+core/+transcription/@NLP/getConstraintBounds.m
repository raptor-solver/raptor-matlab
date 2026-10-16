function bound = getConstraintBounds(obj, whichBound)
% function that sets the bound vector for the problem constraints

% input validation
arguments
    obj         raptor.core.transcription.NLP
    whichBound  {mustBeMember(whichBound, ["lowerBound", "upperBound"])}
end

% initialize the bound vector
switch whichBound
    case "lowerBound"
        bound = - inf(size(obj.jacobian, 1), 1);
    case "upperBound"
        bound = inf(size(obj.jacobian, 1), 1);
end

% loop over all phases
for phase = obj.ocp.phases

    % loop over all constraints
    for constraint = phase.constraints

        % get the size of the constraint
        outputDim = constraint.outputDim;

        % get the size of the global constraint rows assigned to this
        % constraint
        jacobianRowIdxs = obj.con_idx(phase.idx).(constraint.name);
        nRows = jacobianRowIdxs(end) - jacobianRowIdxs(1) + 1;

        % assign the correct portion of the bound vector
        bound(jacobianRowIdxs) = repmat(constraint.(whichBound), nRows / outputDim, 1);
    end
end

% loop over all linkage conditions
for linkage = obj.ocp.linkageConditions

    % assign the linkage constraint correct bound
    bound(obj.con_idx(end).(linkage.name)) = linkage.(whichBound);
end

end