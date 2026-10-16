if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% Constants (none for this problem)
aux = struct();

% =========================================================================
%% Problem Definition
% =========================================================================

% Start build timer
tic

% Instantiate OCP
ocp = raptor.api.v1.OptimalControlProblem("Gong", aux, 0);

% Add phase
phase = ocp.addPhase("single", 2, 1, 1);

% ---------------------- Metadata -----------------------------------------
phase.metadata.name.time = "time";
phase.metadata.label.time = "t";
phase.metadata.label.states = ["x" "v"];
phase.metadata.name.states = ["position" "velocity"];
phase.metadata.name.controls = "acceleration";
phase.metadata.label.controls = "u";
phase.metadata.name.localParameters = "max effort";
phase.metadata.label.localParameters = "v*u";

% cost (the local parameter is the maximum of v*u, see the path constraint)
c = phase.costs.lagrange.add(@(inputData) inputData.time .* 0 + inputData.localParameters);
c.functionType = "linear";

% ---------------------- Dynamics -----------------------------------------
dyn = phase.dynamics.add(@doubleIntegratorDynamics);

% ------------------- Path Constraints ------------------------------------
phase.constraints.path.stack("uvOppositeSigns", -inf, 0);
phase.constraints.path.uvOppositeSigns.label = "vxu";
f = phase.constraints.path.uvOppositeSigns.add(@nonlinearPathConstraint);
f = phase.constraints.path.uvOppositeSigns.add(@(inputData) inputData.time .* 0 - inputData.localParameters);
f.functionType = "linear";

% ------------------ Boundary Conditions ----------------------------------
phase.boundaryConditions.initial.time = 0;
phase.boundaryConditions.final.time = 1;
phase.boundaryConditions.initial.states = [0 1];
phase.boundaryConditions.final.states = [1 1];

% ---------------------- Initial Guess ------------------------------------
phase.initialGuess.continuous.controls = 1;
phase.initialGuess.continuous.localParameters = 1;
phase.initialGuess.linear();

% ---------------------- Box Constraints ----------------------------------
phase.box.lower.states = [-2 -2];
phase.box.upper.states = [2 2];
phase.box.lower.controls = 0;
phase.box.upper.controls = 1;

% ------------------- Collocation Settings --------------------------------
phase.collocation.interpolant = "Birkhoff_a";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "Gauss-Radau";
phase.collocation.nNodes = 149;

% Build problem
problem = raptor.build(ocp);

% Optional: solver configuration
problem.config.transcription.method = "NLP";
problem.config.transcription.numericalJacobian = "ComplexStepDifferences";
problem.config.transcription.finiteStep = 1e-12;
problem.config.scaling.method = "NoScaling";
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-8;
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;

buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

% =========================================================================
%% Problem Solution
% =========================================================================
sol = problem.solve();
