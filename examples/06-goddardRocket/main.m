if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "Practical Methods for Optimal Control and
% Estimation Using Nonlinear Programming", page 213 (example 4.9), data
% from
% https://github.com/ImperialCollegeLondon/ICLOCS/tree/master/exampleProblems/GoddardRocket/SinglePhase
% for figure comparability

% Constants
aux.g = 32.174;
aux.Tm = 193;
aux.sigma = 5.4915 * 1e-5;
aux.c = 1580.9425;
aux.h0 = 23800;
aux.initial.h = 0;
aux.initial.v = 0;
aux.initial.m = 3;
X0 = [aux.initial.h; aux.initial.v; aux.initial.m];
vmin = - 10;
vmax = 900;
hfguess = 18000;
tfguess = 45;
mmin = 1;

% =========================================================================
%% Problem Definition
% =========================================================================

% Start build timer
tic

% Instantiate OCP
ocp = raptor.api.v1.OptimalControlProblem("Goddard", aux, 0);

% Add phase
phase = ocp.addPhase("ascent", 3, 1, 0);

% ---------------------- Metadata -----------------------------------------
phase.metadata.name.time = "time";
phase.metadata.unit.time = "s";
phase.metadata.label.time = "t";

phase.metadata.label.states = ["h" "v" "m"];
phase.metadata.name.states = ["altitude" "velocity" "mass"];
phase.metadata.unit.states = ["ft" "ft/s" "lbm"];

phase.metadata.name.controls = "thrust";
phase.metadata.unit.controls = "lbf";
phase.metadata.label.controls = "T";

% ---------------------- Dynamics -----------------------------------------
dyn = phase.dynamics.add(@goddardRocketDynamics);

% ------------------------- Costs -----------------------------------------
% Mayer term
f = phase.costs.mayer.add(@(inputData) - inputData.finalStates(1));
f.functionType = "linear";

% ------------------ Boundary Conditions ----------------------------------
phase.boundaryConditions.initial.time = 0;
phase.boundaryConditions.initial.states = X0;

% ---------------------- Initial Guess ------------------------------------
phase.initialGuess.final.states = [hfguess aux.initial.v mmin];
phase.initialGuess.initial.controls = aux.Tm;
phase.initialGuess.final.controls = 0;
phase.initialGuess.final.time = tfguess;
phase.initialGuess.linear();

% ---------------------- Box Constraints ----------------------------------
phase.box.lower.states = [aux.initial.h vmin mmin];
phase.box.upper.states = [aux.h0 vmax aux.initial.m];
phase.box.lower.controls = 0;
phase.box.upper.controls = aux.Tm;
phase.box.lower.finalTime = 0;
phase.box.upper.finalTime = 70;

% ------------------- Collocation Settings --------------------------------
phase.collocation.interpolant = "Lagrange";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "flipped-Gauss-Radau";
phase.collocation.nNodes = 49;

% Build problem
problem = raptor.build(ocp);

% Optional: solver configuration
problem.config.transcription.method = "NLP";
problem.config.transcription.numericalJacobian = "ComplexStepDifferences";
problem.config.transcription.finiteStep = 1e-12;
problem.config.scaling.method = ["BoundsProjection" "RuizStatic"];
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-8;
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;

buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

% =========================================================================
%% Problem Solution
% =========================================================================
sol = problem.solve();
