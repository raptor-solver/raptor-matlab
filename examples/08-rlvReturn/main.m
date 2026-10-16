if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "Minimum-Fuel Optimal Trajectory for
% Reusable First-Stage Rocket Landing Using Particle Swarm Optimization"

% environment
aux.g0 = 9.80665;
aux.rho0 = 1.225;
aux.h0 = 7500;

% vehicle
aux.Isp = 282;
aux.T1 = 5886e3 * 1 / 3;
aux.T2 = 5886e3;
aux.T3 = 5886e3 * 1 / 9;
aux.cD = 0.75;
aux.d = 3.66;
aux.A = pi * (0.5 * aux.d)^2;
aux.beta = 0.5 * aux.cD * aux.A * aux.rho0;
aux.vExhaust = aux.Isp * aux.g0;

% mission
aux.m0 = 76501;
aux.mDry = 25600;
aux.X0 = [36022; 60708; 1052; 1060; aux.m0];
aux.Xf = [0; 0; 0; 0; aux.mDry];
aux.t0 = 0;
aux.tbb = 40.8;
aux.tWidth = 20;
aux.tff = 220;
aux.tf = 300;

% =========================================================================
%% Problem Definition
% =========================================================================

% Start build timer
tic

% Instantiate OCP
ocp = raptor.api.v1.OptimalControlProblem("2DRLV", aux, 0);
boostback = ocp.addPhase("boostback", 5, 2, 0);
freefall = ocp.addPhase("freefall", 5, 2, 0);
landing = ocp.addPhase("landing", 5, 2, 0);

%% First phase
% ---------------------- Metadata -----------------------------------------
boostback.metadata.name.time = "time";
boostback.metadata.unit.time = "s";
boostback.metadata.label.time = "t";
boostback.metadata.name.states = ["downrange" "altitude" "downrange rate" "altitude rate" "mass"];
boostback.metadata.unit.states = ["m" "m" "m/s" "m/s" "kg"];
boostback.metadata.label.states = ["x" "y" "$v_x$" "$v_y$" "m"];
boostback.metadata.name.controls = ["throttle" "gimbal angle"];
boostback.metadata.unit.controls = ["-" "rad"];
boostback.metadata.label.controls = ["$\frac{T}{T_{max}}$" "$\theta$"];

% ---------------------- Dynamics -----------------------------------------
dyn = boostback.dynamics.add(@boostbackDynamics);

% ------------------ Boundary Conditions ----------------------------------
boostback.boundaryConditions.initial.time = aux.t0;
boostback.boundaryConditions.initial.states = aux.X0;
boostback.boundaryConditions.final.time = aux.tbb;

% ---------------------- Initial Guess ------------------------------------
boostback.initialGuess.continuous.controls = [1; pi];
boostback.initialGuess.fromControl();

% ---------------------- Box Constraints ----------------------------------
boostback.box.lower.states = [-1e3; 0e3; -2e3; -2e3; 25600];
boostback.box.upper.states = [60e3; 120e3; 2e3; 2e3; 76501];
% sideways full thrust during boostback
boostback.box.lower.controls = [1 pi];
boostback.box.upper.controls = [1 pi];

% ------------------- Collocation Settings --------------------------------
boostback.collocation.interpolant = "Lagrange";
boostback.collocation.polynomials = "Legendre";
boostback.collocation.nodes = "flipped-Gauss-Radau";
boostback.collocation.nNodes = 10;

%% Second phase
ocp.linkage.continuity(boostback, freefall);

% ---------------------- Dynamics -----------------------------------------
dyn = freefall.dynamics.add(@freefallDynamics);

% ---------------------- Initial Guess ------------------------------------
% initial time and states are already taken from boostback object
freefall.initialGuess.final.time = aux.tff;
freefall.initialGuess.continuous.controls = [0; 0];
freefall.initialGuess.fromControl();

% ---------------------- Box Constraints ----------------------------------
% state and control box constraints are already taken from boostack object
freefall.box.lower.finalTime = aux.tff - aux.tWidth;
freefall.box.upper.finalTime = aux.tff + aux.tWidth;
% uncontrolled descent during free fall
freefall.box.lower.controls = [0 0];
freefall.box.upper.controls = [0 0];

% ------------------- Collocation Settings --------------------------------
freefall.collocation.interpolant = "Lagrange";
freefall.collocation.polynomials = "Legendre";
freefall.collocation.nodes = "Gauss-Radau";
freefall.collocation.nNodes = 8;

%% Third phase
ocp.linkage.continuity(freefall, landing);

% ---------------------- Dynamics -----------------------------------------
dyn = landing.dynamics.add(@landingDynamics);

% ------------------------- Costs -----------------------------------------
% Mayer term
f = landing.costs.mayer.add(@(inputData) - inputData.finalStates(5));
f.functionType = "linear";

% ------------------ Boundary Conditions ----------------------------------
landing.boundaryConditions.final.states(1 : 4) = aux.Xf(1 : 4);

% ---------------------- Initial Guess ------------------------------------
% initial time and states are already taken from freefall object
landing.initialGuess.final.time = aux.tf;
landing.initialGuess.continuous.controls = [1; pi/2];
landing.initialGuess.fromControl();

% ---------------------- Box Constraints ----------------------------------
% state and control box constraints are already taken from boostack object
landing.box.lower.finalTime = aux.tf - aux.tWidth;
landing.box.upper.finalTime = aux.tf + aux.tWidth;
% full throttle during landing
landing.box.lower.controls = [1 0];
landing.box.upper.controls = [1 pi];

% ------------------- Collocation Settings --------------------------------
landing.collocation.interpolant = "Lagrange";
landing.collocation.polynomials = "Legendre";
landing.collocation.nodes = "flipped-Gauss-Radau";
landing.collocation.nNodes = 12;

%% Build problem
problem = raptor.build(ocp);

% Optional: solver configuration
problem.config.transcription.method = "NLP";
problem.config.transcription.numericalJacobian = "ComplexStepDifferences";
problem.config.transcription.finiteStep = 1e-8;
problem.config.scaling.method = ["BoundsProjection" "JacobianRowNormalization"];
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-6;
problem.config.solver.iter_limit = 200;
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
problem.config.postprocessing.plotting.phases = [];
problem.config.postprocessing.plotting.combinedPhases = {["boostback" "freefall" "landing"]};
if showPlots
    problem.config.postprocessing.plotting.auxiliaryFunction = @visualizeSolution;
end

buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

% =========================================================================
%% Problem Solution
% =========================================================================
sol = problem.solve();

% visualize the full solution
function visualizeSolution(sol)
% preamble
whichTraj = "propagated";
aux = sol.boostback.discretized.auxdata;
x = [sol.boostback.(whichTraj).states(1, :) ...
    sol.freefall.(whichTraj).states(1, :) ...
    sol.landing.(whichTraj).states(1, :)];
y = [sol.boostback.(whichTraj).states(2, :) ...
    sol.freefall.(whichTraj).states(2, :) ...
    sol.landing.(whichTraj).states(2, :)];
m = [sol.boostback.(whichTraj).states(5, :) ...
    sol.freefall.(whichTraj).states(5, :) ...
    sol.landing.(whichTraj).states(5, :)];
K = 100 .* [sol.boostback.(whichTraj).controls(1, :) ...
    sol.freefall.(whichTraj).controls(1, :) ...
    sol.landing.(whichTraj).controls(1, :)];
t = [sol.boostback.(whichTraj).time(1, :) ...
    sol.freefall.(whichTraj).time(1, :) ...
    sol.landing.(whichTraj).time(1, :)];

% store the indexes for each phase
bb = 1 : length(sol.boostback.(whichTraj).time);
ff = bb(end) + 1 : bb(end) + length(sol.freefall.(whichTraj).time);
ll = ff(end) + 1 : ff(end) + length(sol.landing.(whichTraj).time);

finalMass = m(end)

% plot the full trajectory
figure;
hold on;
plot(x(bb), y(bb), "-b", "LineWidth",1.2, "DisplayName","boostback");
plot(x(ff), y(ff), "--k", "LineWidth",1.2, "DisplayName","freefall");
plot(x(ll), y(ll), "-r", "LineWidth",1.2, "DisplayName","landing");
title("RTLS trajectory");
xlabel("x [m]"); ylabel("y [m]");
grid on
legend("Location","best");
axis equal;

% plot the thrust profile
figure;
hold on;
plot(t(bb), K(bb), "-b", "LineWidth",1.2, "DisplayName","boostback");
plot(t(ff), K(ff), "--k", "LineWidth",1.2, "DisplayName","freefall");
plot(t(ll), K(ll), "-r", "LineWidth",1.2, "DisplayName","landing");
title("Thrust profile");
xlabel("t [s]"); ylabel("K [%]");
grid on
legend("Location","best");
ylim([-10 110]);
end
