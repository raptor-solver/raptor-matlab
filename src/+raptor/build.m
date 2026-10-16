function RAPTOR = build(ocp)
% function that builds the core representation of the optimal control
% problem and related trajectories, the instantiates the default config for
% the solver routines

% build the core problem representation
[coreOcp, coreTrajectories, postProcessing] = ocp.build();

% validate the core problem representation
coreOcp.validate(coreTrajectories);

% instantiate the raptor object
RAPTOR = raptor.RAPTOR(coreOcp, coreTrajectories, postProcessing);
end

