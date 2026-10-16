if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% definition constants
auxdata.r0 = [1; 1; 1]; auxdata.v0 = [1; 1; 1];
auxdata.rf = [1; -1; 0]; auxdata.vf = [0; 0; 0];
auxdata.mass = 1; auxdata.control_weight = 1;
auxdata.t0 = 0; auxdata.tf = 11;

%% Problem definition
% start timing the build process
tic

% instantiate single phase problem
ocp = raptor.api.v1.OptimalControlProblem("doubleIntegrator", auxdata, 0);
phase = ocp.addPhase("single", 6, 3, 0);

% metadata
phase.metadata.name.time = "time";
phase.metadata.unit.time = "s";
phase.metadata.label.time = "t";

% dynamics function
f = phase.dynamics.add(@double_integrator);
f.functionType = "linear";

% control effort cost
c = phase.costs.lagrange.add(@control_effort_cost);

% boundary conditions
phase.boundaryConditions.initial.time = auxdata.t0;
phase.boundaryConditions.initial.states = [auxdata.r0; auxdata.v0];
phase.boundaryConditions.final.time = auxdata.tf;
phase.boundaryConditions.final.states = [auxdata.rf; auxdata.vf];

% initial guess
phase.initialGuess.continuous.controls = [0 0 0]';
phase.initialGuess.linear();

% collocation config
phase.collocation.interpolant = "Lagrange";
phase.collocation.nodes = "Gauss-Radau";
phase.collocation.nNodes = 24;

% build the problem
problem = raptor.build(ocp);

% adjust the solver configuration if needed
problem.config.transcription.method = "NLP";
problem.config.scaling.method = "NoScaling";
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-8;
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;

% display the build time
buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

%% Solve the problem
sol = problem.solve();