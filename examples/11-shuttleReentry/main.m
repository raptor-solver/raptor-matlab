if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "Practical Methods for Optimal Control
% and Estimation Using Nonlinear Programming", page 247 (example 6.1)

% Constants initial conditions
aux.initial.h = 260000;
aux.initial.phi = 0 * pi / 180;
aux.initial.theta = 0 * pi / 180;
aux.initial.v = 25600;
aux.initial.gamma = -1 * pi / 180;
aux.initial.psi = 90 * pi / 180;
X0 = [aux.initial.h; aux.initial.phi; aux.initial.theta; ...
    aux.initial.v; aux.initial.gamma; aux.initial.psi];

% final conditions
aux.final.h = 80000;
aux.final.v = 2500;
aux.final.gamma = -5 * pi / 180;
Xf = [aux.final.h; aux.final.v; aux.final.gamma];

% parameters
aux.parameters.rho0 = 0.002378;
aux.parameters.hr = 23800;
aux.parameters.Re = 20902900;
aux.parameters.S = 2690;
aux.parameters.a0 = -0.20704;
aux.parameters.a1 = 0.029244;
aux.parameters.mu = 0.14076539 * 1e17;
aux.parameters.b0 = 0.07854;
aux.parameters.b1 = -0.61592 * 1e-2;
aux.parameters.b2 = 0.621408 * 1e-3;
aux.parameters.c0 = 1.0672181;
aux.parameters.c1 = -0.19213774 * 1e-1;
aux.parameters.c2 = 0.21286289 * 1e-3;
aux.parameters.c3 = - 0.10117249 * 1e-5;
aux.parameters.w = 203000;
aux.parameters.g0 = 32.174;
aux.parameters.m = aux.parameters.w / aux.parameters.g0;

% constraint bounds
qU = 70;
deg89 = 89 * pi / 180;
deg90 = pi / 2;
deg30 = 30 * pi / 180;
deg1 = pi / 180;

% =========================================================================
%% Problem Definition
% =========================================================================

% Start build timer
tic

% Instantiate OCP
ocp = raptor.api.v1.OptimalControlProblem("SpaceShuttle", aux, 0);

% Add phase
phase = ocp.addPhase("entry", 6, 2, 0);

% ---------------------- Metadata -----------------------------------------
phase.metadata.name.time = "time";
phase.metadata.unit.time = "sec";
phase.metadata.label.time = "t";

phase.metadata.name.states([1 2 3]) = ["altitude", "longitude", "latitude"];
phase.metadata.name.states([4 5 6]) = ["velocity", "flight path", "azimuth"];
phase.metadata.label.states = ["h" "$\phi$" "$\theta$" "v" "$\gamma$" "$\psi$"];
phase.metadata.unit.states = ["ft" "rad" "rad" "ft/sec" "rad" "rad"];

phase.metadata.name.controls = ["angle of attack", "bank angle"];
phase.metadata.label.controls = ["$\alpha$" "$\beta$"];
phase.metadata.unit.controls = ["rad" "rad"];

% ---------------------- Dynamics -----------------------------------------
dyn = phase.dynamics.add(@shuttleDynamics);

% ------------------- Path Constraints ------------------------------------
phase.constraints.path.stack("heating", -Inf, qU);
f = phase.constraints.path.heating.add(@heating);
phase.constraints.path.heating.unit = "$BTU/(ft^2sec)$";
phase.constraints.path.heating.label = "q";

% ------------------------- Costs -----------------------------------------
% Mayer term
f = phase.costs.mayer.add(@(inputData) - inputData.finalStates(3));
f.functionType = "linear";

% ------------------ Boundary Conditions ----------------------------------
phase.boundaryConditions.initial.time = 0;
phase.boundaryConditions.initial.states = X0;
phase.boundaryConditions.final.states([1 4 5]) = Xf;

% ---------------------- Initial Guess ------------------------------------
phase.initialGuess.final.states([2 3 6]) = [deg90 deg30 -deg90];
phase.initialGuess.continuous.controls = [0 0];
phase.initialGuess.final.time = 2300;
phase.initialGuess.linear();

% ---------------------- Box Constraints ----------------------------------
phase.box.lower.states([1 3 4 5]) = [0 -deg89 1 -deg89];
phase.box.upper.states([3 5]) = [deg89 deg89];
phase.box.lower.controls = [-deg90 -deg89];
phase.box.upper.controls = [deg90 deg1];
phase.box.lower.finalTime = 800;
phase.box.upper.finalTime = 2500;

% added for scaling/adimensionalization
phase.box.lower.states([2 6]) = [0 -pi];
phase.box.upper.states([1 2 4 6]) = [aux.initial.h 2*pi aux.initial.v pi];
phase.box.lower.initialTime = 0;
phase.box.upper.initialTime = 10;

% ------------------- Collocation Settings --------------------------------
phase.collocation.interpolant = "Lagrange";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "flipped-Gauss-Radau";
phase.collocation.nNodes = [27 27];
phase.collocation.dynamicsTolerance = 0;

% Build problem
problem = raptor.build(ocp);

% Optional: solver configuration
problem.config.transcription.method = "NLP";
problem.config.transcription.numericalJacobian = "ComplexStepDifferences";
problem.config.transcription.finiteStep = 1e-12;
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-6;
problem.config.scaling.method = ["BoundsProjection" "JacobianRowNormalization"];
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
if showPlots
    problem.config.postprocessing.plotting.auxiliaryFunction = @visualizeShuttleSolution;
end

buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

% =========================================================================
%% Problem Solution
% =========================================================================
sol = problem.solve();
