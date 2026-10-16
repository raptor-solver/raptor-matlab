if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "Optimal Control with Aerospace
% Applications", page 234 (example C.1)

% Constants
aux.T = 4 * 1e-4;
aux.t0 = 0;
aux.r0 = 1;
aux.theta0 = 0;
aux.vr0 = 0;
aux.vtheta0 = 1;
aux.X0 = [aux.r0 aux.theta0 aux.vr0 aux.vtheta0];
aux.vrf = 0;

% problem parameters
nRevs = 20;
rf = aux.r0 + nRevs / 1;
thetaf = 2 * pi * nRevs;
vthetaf = 1 / sqrt(rf);

% =============================================================
%% Problem Definition
% =============================================================

% Start build timer
tic

% Instantiate OCP
ocp = raptor.api.v1.OptimalControlProblem("orbitRaising2D", aux, 0);

% Add phase
phase = ocp.addPhase("raising", 4, 1, 0);

% metadata
phase.metadata.name.time = "time";
phase.metadata.unit.time = "-";
phase.metadata.label.time = "t";
phase.metadata.label.states = ["r", "$\theta$", "$v_r$", "$v_t$"];
phase.metadata.name.states = ["radius" "true anomaly" "radial velocity" "tangential velocity"];
phase.metadata.unit.states(2) = "rad";
phase.metadata.name.controls = "thrust angle";
phase.metadata.label.controls = "$\alpha$";
phase.metadata.unit.controls = "rad";

% ---------------------- Dynamics -----------------------------------------
dyn = phase.dynamics.add(@polarDynamics);

% ------------------- Boundary Constraints --------------------------------
phase.constraints.boundary.stack("c2c", 0, 0);
f = phase.constraints.boundary.c2c.add(@circularVelocity);

% ------------------------- Costs -----------------------------------------
% Mayer term
f = phase.costs.mayer.add(@(inputData) - inputData.finalStates(1));
f.functionType = "linear";

% ------------------ Boundary Conditions ----------------------
phase.boundaryConditions.initial.time = 0;
phase.boundaryConditions.initial.states = aux.X0;
phase.boundaryConditions.final.time = 2 * pi * nRevs;
phase.boundaryConditions.final.states(3) = aux.vrf;

% ---------------------- Initial Guess ------------------------
phase.initialGuess.final.states([1 2 4]) = [rf thetaf vthetaf];
phase.initialGuess.continuous.controls = 0;
phase.initialGuess.final.time = thetaf;
phase.initialGuess.fromControl();

% ---------------------- Box Constraints ----------------------
phase.box.lower.states(1) = 0.9 * aux.r0;
phase.box.lower.controls = - pi;
phase.box.upper.controls = pi;

% ------------------- Collocation Settings --------------------
phase.collocation.interpolant = "Birkhoff_a";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "Gauss-Radau";
phase.collocation.nNodes = 249;

% Build problem
problem = raptor.build(ocp);

% Optional: solver configuration
problem.config.transcription.method = "NLP";
problem.config.scaling.method = "NoScaling";
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.validation.relTol = 1e-12;
problem.config.postprocessing.validation.absTol = 1e-12;
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-6;
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
if showPlots
    problem.config.postprocessing.plotting.auxiliaryFunction = @visualizePolarSolution;
end

buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

% =============================================================
%% Problem Solution
% =============================================================
sol = problem.solve();
