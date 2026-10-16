if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "Implementations of the Universal
% Birkhoff Theory  for Fast Trajectory Optimization", Eq.29

% definition constants
aux.scaling.T = 2.349;
aux.initial.h = 1;
aux.initial.v = - 0.783;
aux.initial.m = 1;
aux.final.h = 0;
aux.final.v = 0;
aux.env.g = - 1;
aux.lower_bound.T = 0;
aux.upper_bound.T = 1.227;
aux.guess.t0 = 0;
aux.guess.tf = 1;
aux.guess.T = 0.5;

% modify here the value for the maximum thrust rate
aux.rate.T = 2; % yields slope+bang profile
aux.rate.T = 4; % yields bang+slope+bang profile
% aux.rate.T = Inf; % classic bang+bang profile

%% Problem definition
% start timing the build process
tic

% instantiate single phase problem
ocp = raptor.api.v1.OptimalControlProblem("1DLanding", aux, 0);
phase = ocp.addPhase("landing", 3, 1, 0);

% metadata
phase.metadata.name.time = "time";
phase.metadata.label.time = "t";
phase.metadata.name.states = ["altitude" "velocity" "mass"];
phase.metadata.label.states = ["h" "v" "m"];
phase.metadata.name.controls = "thrust";
phase.metadata.label.controls = "T";

% dynamics function
f = phase.dynamics.add(@dynamics1DLanding);

% thrust rate limiter
c = phase.constraints.differential.stack("thrustRate", -aux.rate.T, aux.rate.T);
f = c.add(@(inputData) inputData.controls(1, :));
f.functionType = "linear";

% control effort cost
c = phase.costs.lagrange.add(@cost1DLanding);
c.functionType = "linear";

% boundary conditions
phase.boundaryConditions.initial.time = aux.guess.t0;
phase.boundaryConditions.initial.states = [aux.initial.h ...
    aux.initial.v aux.initial.m];
phase.boundaryConditions.final.states([1 2]) = [aux.final.h aux.final.v];

% box constraints
phase.box.upper.finalTime = 2;
phase.box.lower.finalTime = 0.2;
phase.box.lower.controls= aux.lower_bound.T;
phase.box.upper.controls = aux.upper_bound.T;
phase.box.lower.states([1 3]) = [0 0];
phase.box.upper.states([1 3]) = [aux.initial.h aux.initial.m];

% initial guess
phase.initialGuess.final.time = aux.guess.tf;
phase.initialGuess.continuous.controls = aux.guess.T;
phase.initialGuess.final.states(3) = aux.initial.m/2;
phase.initialGuess.linear();

% collocation config
phase.collocation.interpolant = "Birkhoff_a";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "flipped-Gauss-Radau";
phase.collocation.nNodes = 199;

% build the problem
problem = raptor.build(ocp);

% adjust the solver configuration if needed
problem.config.transcription.method = "NLP";
problem.config.scaling.method = "NoScaling";
problem.config.transcription.numericalJacobian = "ComplexStepDifferences";
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-8;
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
if showPlots
    problem.config.postprocessing.plotting.auxiliaryFunction = @plotMaxThrustCovector;
end

% display the build time
buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

%% Solve the problem
sol = problem.solve();

function plotMaxThrustCovector(sol)
% auxiliary plotting function that generates the figure for the thrust and
% the covector associated with its upper bound
figure
mu = sol.landing.discretized.covectors.upperBound.controls(1, :);
u = sol.landing.discretized.controls(1, :);
t = sol.landing.discretized.time;
ub = sol.landing.discretized.auxdata.upper_bound.T;
plot(t, u, "--b", "LineWidth",1.2, "DisplayName","T");
hold on
plot(t, mu, "-r", "LineWidth",1.2, "DisplayName","\mu");
yline(ub, "--k", "LineWidth",0.7, "DisplayName","T_U");
grid on
legend("Location","best");
ylim([-0.1 1.1 * ub]);
xlim([t(1) t(end)]);
xlabel("time [-]"); ylabel("thrust/covector [-]");
title("Thrust and upper bound covector");
end
