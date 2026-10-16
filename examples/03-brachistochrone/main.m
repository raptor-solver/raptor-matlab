if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "A primer on Pontryagin's principle in
% optimal control", with figures on page 138

%% Constants
aux.g = 9.8; aux.a = 1; aux.b = 1.5;
x0 = 0; y0 = 0; v0 = 0; t0 = 0;
xf = 10; yf = 10;
tf_guess = 2; vf_guess = 50; u_guess = 0.5;

%% Problem definition
% start timing the build process
tic

% instantiate the problem object
ocp = raptor.api.v1.OptimalControlProblem("brachistochrone", aux, 0);

% set the single phase
phase = ocp.addPhase("descent", 3, 1, 0);

% metadata
phase.metadata.name.time = "time";
phase.metadata.label.time = "t";
phase.metadata.unit.time = "s";
phase.metadata.name.states = ["horizontal position" "vertical position" "velocity"];
phase.metadata.label.states = ["x" "y" "v"];
phase.metadata.unit.states = ["m" "m" "m/s"];
phase.metadata.name.controls = "inclination";
phase.metadata.label.controls = "u";
phase.metadata.unit.controls = "rad";

% dynamics functions
dyn = phase.dynamics.add(@brachistochroneDynamics);

% path constraints
phase.constraints.path.stack("slope", -inf, aux.b);
phase.constraints.path.slope.label = "$dy/dx$";
f = phase.constraints.path.slope.add(@brachistochroneSlopeConstraint);
f.functionType = "linear";

% cost function f = phase.costs.lagrange.add(@(inputData)
% inputData.states(1, :) .* 0 + 1); f.functionType = "linear";

% equivalent cost function
f = phase.costs.mayer.add(@(inputData) inputData.finalTime);
f.functionType = "linear";

% boundary conditions
phase.boundaryConditions.initial.time = t0;
phase.boundaryConditions.initial.states = [x0 y0 v0];
phase.boundaryConditions.final.states(1 : 2) = [xf yf];

% initial guess
phase.initialGuess.final.time = tf_guess;
phase.initialGuess.final.states(3) = vf_guess;
phase.initialGuess.continuous.controls = u_guess;
phase.initialGuess.linear();

% box constraints
phase.box.lower.finalTime = 0.1;
phase.box.upper.finalTime = 5;
phase.box.upper.states = [xf 100 100];
phase.box.lower.states = [0 0 -100];
phase.box.lower.controls = 0;
phase.box.upper.controls = pi/2;

% collocation parameters
phase.collocation.interpolant = "Lagrange";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "Gauss-Radau";
phase.collocation.nNodes = 49;

% build the problem
problem = raptor.build(ocp);

% adjust the solver configuration if needed
problem.config.transcription.method = "NLP";
problem.config.scaling.method = ["BoundsProjection" "JacobianRowNormalization"];
problem.config.transcription.numericalJacobian = "ComplexStepDifferences";
problem.config.transcription.finiteStep = 1e-10;
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-8;
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
if showPlots
    problem.config.postprocessing.plotting.auxiliaryFunction = @visualizeBrachistochroneSolution;
end

% display the build time
buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

%% Solve the problem
sol = problem.solve();

function visualizeBrachistochroneSolution(sol)
% auxiliary function to visualize the solution to the brachistochrone
% problem

% solution with constraint
figure
x = sol.descent.discretized.states(1, :);
y = sol.descent.discretized.states(2, :);
aux = sol.descent.discretized.auxdata;
slope = aux.a .* x + aux.b;
plot(x, y, "-b", "LineWidth", 1.2, "DisplayName", "brachistochrone curve");
ylim0 = ylim; y0 = ylim0(2);
hold on
fill([x fliplr(x)], [slope repmat(y0, size(slope))], "r", "FaceAlpha", 0.25, "EdgeColor", "none", "DisplayName", "slope constraint");
ax = gca;
set(ax, "YDir", "reverse");
xlim(ax, [x(1) x(end)]); ylim(ax, ylim0);
legend("Location","best");
title("Brachistochrone solution");
grid on
hold off
axis equal

% costates analysis
t_disc = sol.descent.discretized.time;
a = aux.a;
mu = @(t) interp1(t_disc, sol.descent.discretized.covectors.slope, t, "linear", "extrap");
u = @(t) interp1(t_disc, sol.descent.discretized.controls(1, :), t, "linear", "extrap");
lambda_0 = sol.descent.discretized.costates(:, 1); % reasonably far from the initial value to avoid Gibbs phenomenon
dlambdadt = @(t, lambda) [a * mu(t); - mu(t); - lambda(1) * sin(u(t)) - lambda(2) * cos(u(t))];
[~, lambda_analytical] = ode45(dlambdadt, t_disc, lambda_0);
lambda_analytical = lambda_analytical';
figure
hold on
plot(t_disc, lambda_analytical(1, :), "-k", "LineWidth",1.2, "DisplayName","\lambda_x analytical");
plot(t_disc, lambda_analytical(2, :), "-k", "LineWidth",1.2, "DisplayName","\lambda_y analytical");
plot(t_disc, lambda_analytical(3, :), "-k", "LineWidth",1.2, "DisplayName","\lambda_v analytical");
plot(t_disc, sol.descent.discretized.costates(1, :), "--r", "LineWidth",1.2, "DisplayName","\lambda_x CMT");
plot(t_disc, sol.descent.discretized.costates(2, :), "--g", "LineWidth",1.2, "DisplayName","\lambda_y CMT");
plot(t_disc, sol.descent.discretized.costates(3, :), "--b", "LineWidth",1.2, "DisplayName","\lambda_v CMT");
plot(t_disc, mu(t_disc), "--k", "LineWidth",1.2, "DisplayName","\mu slope constraint");
grid on
xlabel("t [-]"); ylabel("costate [-]");
grid on; legend("Location","best");
title("Brachistochrone analytical costates comparison");
end
