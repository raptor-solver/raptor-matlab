if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "Implementations of the Universal Birkhoff
% Theory for Fast Trajectory Optimization", Eq. 40

% definition constants
x0 = 0; v0 = 1; t0 = 0;
xf = 0; vf = -1; tf = 1;
l = 0.1; ug = - 3;

%% Problem definition
% start timing the build process
tic

% instantiate single phase problem
ocp = raptor.api.v1.OptimalControlProblem("breakwell1D", [], 0);
phase = ocp.addPhase("single", 2, 1, 0);

% metadata
phase.metadata.name.time = "time";
phase.metadata.label.time = "t";
phase.metadata.name.states = ["position" "velocity"];
phase.metadata.label.states = ["x" "v"];
phase.metadata.name.controls = "acceleration";
phase.metadata.label.controls = "u";

% dynamics function
f = phase.dynamics.add(@doubleIntegrator);
f.functionType = "linear";

% control effort cost
c = phase.costs.lagrange.add(@controlEffortCost);

% boundary conditions
phase.boundaryConditions.initial.time = t0;
phase.boundaryConditions.initial.states = [x0 v0];
phase.boundaryConditions.final.time = tf;
phase.boundaryConditions.final.states = [xf vf];

% box constraints
phase.box.upper.states(1) = l;

% initial guess
phase.initialGuess.continuous.controls = 0;
phase.initialGuess.linear();

% collocation config
phase.collocation.interpolant = "Birkhoff_a";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "flipped-Gauss-Radau";
phase.collocation.nNodes = 149;

% build the problem
problem = raptor.build(ocp);

% adjust the solver configuration if needed
problem.config.transcription.method = "NLP";
problem.config.transcription.numericalJacobian = "ComplexStepDifferences";
problem.config.transcription.finiteStep = 1e-10;
problem.config.scaling.method = "NoScaling";
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-8;
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
if showPlots
    problem.config.postprocessing.plotting.auxiliaryFunction = @plotCostatesAndUpperBoundCovector;
end

% display the build time
buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

%% Solve the problem
sol = problem.solve();

function plotCostatesAndUpperBoundCovector(sol)
% auxiliary function to plot the costates and the covector associated to
% the upper bound on the state

% costates
figure
lambda_x = sol.single.discretized.costates(1, :);
lambda_v = sol.single.discretized.costates(2, :);
t = sol.single.discretized.time;
plot(t, lambda_x, "-r", "LineWidth",1.2, "DisplayName","\lambda_x");
hold on
plot(t, lambda_v, "--b", "LineWidth",1.2, "DisplayName","\lambda_v");
hold off
grid on
xlabel("t [-]"); ylabel("\lambda [-]");
legend;
title("Breakwell costates");

% upper bound covector
figure
mu = sol.single.discretized.covectors.upperBound.states(1, :);
plot(t, mu, "*b", "DisplayName","\mu");
grid on
xlabel("t [-]"); ylabel("\mu [-]");
title("Breakwell upper bound covector");
end
