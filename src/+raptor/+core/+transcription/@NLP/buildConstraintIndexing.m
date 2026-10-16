function buildConstraintIndexing(obj)
% function to bulid the indexing structure for the problem functions
import raptor.core.enumerations.*

% initialize the starting index for each constraint block
start_idx = 0;

% loop over all phases to set the correct constraint indexes
for phase = obj.ocp.phases

    % loop over all constraints
    for constraint = phase.constraints

        % determine the number of points on which the constraint is
        % evaluated
        switch constraint.outputNodes
            case OutputNodes.discretized
                n_repeated_evaluations = phase.collocation.n_disc;
            case OutputNodes.collocated
                n_repeated_evaluations = phase.collocation.n_coll;
            case OutputNodes.collocatedWithoutInitial
                n_repeated_evaluations = phase.collocation.n_coll - phase.collocation.n_seg;
            case OutputNodes.single
                n_repeated_evaluations = 1;
        end
        obj.con_idx(phase.idx).(constraint.name) = start_idx + (1 : constraint.outputDim * n_repeated_evaluations);
        start_idx = start_idx + constraint.outputDim * n_repeated_evaluations;
        % reworked indexing for block diagonal matrices (NOT WORKING)
        % obj.con_idx(phase.idx).(constraint.name) = reshape(start_idx + ((1 : constraint.outputDim)' - 1) * n_repeated_evaluations + (1 : n_repeated_evaluations), 1, []);
        % start_idx = start_idx + constraint.outputDim * n_repeated_evaluations;
    end
end

% store the linkage conditions
for linkage = obj.ocp.linkageConditions
    obj.con_idx(end).(linkage.name) = start_idx +(1 : linkage.outputDim);
    start_idx = start_idx + linkage.outputDim;
end

% store the full size of the constraints vector
for phase = obj.ocp.phases
    obj.con_idx(phase.idx).totalConstraints = start_idx;
end
end
