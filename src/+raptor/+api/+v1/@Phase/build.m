function corePhase = build(phase, trajectories, ocp, postProcessing)
% method that fully builds the core representation of the phase object and
% populates the trajectories objects

import raptor.core.problem.descriptors.*
import raptor.core.enumerations.*

% build the core phase descriptor
corePhase = raptor.core.problem.Phase(phase.idx);

% build variable metadata
phase.build_metadata(ocp, postProcessing);

% build phase collocation
[discretizedTimeIdxs, collocatedTimeIdxs] = phase.build_collocation(corePhase);

% build initial guess
phase.build_initialGuess(ocp, corePhase, trajectories);

% build box constraints
phase.build_boxConstraints(ocp, corePhase, trajectories, discretizedTimeIdxs);

% build boundary conditions
phase.build_boundaryConditions(corePhase);

% bulid the dynamics constraints
phase.build_differentialConstraints(corePhase, postProcessing, discretizedTimeIdxs, ...
    collocatedTimeIdxs, trajectories);

% build path constraints
phase.build_pathConstraints(corePhase, discretizedTimeIdxs, trajectories);

% build boundary constraints
phase.build_boundaryConstraints(corePhase, trajectories);

% build costs
phase.build_costs(corePhase, collocatedTimeIdxs, trajectories);

end