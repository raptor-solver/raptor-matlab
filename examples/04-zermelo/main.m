if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "Unscented Optimal Control for
% Orbital and Proximity Operations in an Uncertain Environment: A New
% Zermelo Problem", Eq. 25

% definition constants
aux.p = 10;
aux.x0 = 2.25;
aux.y0 = 1;
aux.xf = 0;
aux.yf = 0;
aux.t0 = 0;

%% Problem definition
% start timing the build process
tic

% instantiate single phase problem
ocp = raptor.api.v1.OptimalControlProblem("Zermelo", aux, 0);
phase = ocp.addPhase("single", 2, 2, 0);

% metadata
phase.metadata.name.time = "time";
phase.metadata.label.time = "t";
phase.metadata.name.states = ["horizontal position" "vertical position"];
phase.metadata.label.states = ["x" "y"];
phase.metadata.name.controls = ["horizontal control" "vertical control"];
phase.metadata.label.controls = ["$u_1$" "$u_2$"];

% dynamics function
f = phase.dynamics.add(@zermeloDynamics);

% unit norm constraint
phase.constraints.path.stack("unitNorm", 1, 1);
phase.constraints.path.unitNorm.label = "$||\mathbf{u}||$";
c = phase.constraints.path.unitNorm.add(@unitNormConstraint);

% cost function
c = phase.costs.mayer.add(@(inputData) inputData.finalTime);
c.functionType = "linear";

% boundary conditions
phase.boundaryConditions.initial.time = aux.t0;
phase.boundaryConditions.initial.states = [aux.x0 aux.y0];
phase.boundaryConditions.final.states = [aux.xf aux.yf];

% box constraints
phase.box.lower.finalTime = 0.1;
phase.box.upper.finalTime = 100;

% initial guess
phase.initialGuess.final.time = 5;
phase.initialGuess.initial.controls(2) = -1;
phase.initialGuess.final.controls(2) = 1;
phase.initialGuess.continuous.controls(1) = 0;
phase.initialGuess.linear();

% collocation config
phase.collocation.interpolant = "Birkhoff_a";
phase.collocation.nodes = "Gauss-Radau";
phase.collocation.nNodes = 99;

% build the problem
problem = raptor.build(ocp);

% adjust the solver configuration if needed
problem.config.transcription.method = "NLP";
problem.config.transcription.numericalJacobian = "ComplexStepDifferences";
problem.config.transcription.finiteStep = 1e-12;
problem.config.scaling.method = ["BoundsProjection" "JacobianRowNormalization"];
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-6;
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
if showPlots
    problem.config.postprocessing.plotting.auxiliaryFunction = @visualizeZermeloSolution;
end

% display the build time
buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

%% Solve the problem
sol = problem.solve();

function visualizeZermeloSolution(sol)
% auxiliary function to visualize the Zermelo solution as specified in the
% reference paper

t = sol.single.discretized.time;
u1 = sol.single.discretized.controls(1, :);
u2 = sol.single.discretized.controls(2, :);
x = sol.single.discretized.states(1, :);
y = sol.single.discretized.states(2, :);
figure
subplot(1, 2, 1)
plot(t, u1, "--b", "LineWidth",1.2, "DisplayName","u_1");
hold on
plot(t, u2, "-g", "LineWidth",1.2, "DisplayName","u_2");
grid on
legend("Location","best");
xlabel("time [-]"); ylabel("control component [-]");
title("Zermelo control components");
hold off
subplot(1, 2, 2)
plot(x, y, "-r", "LineWidth",1.2);
xlabel("x [-]");
ylabel("y [-]");
xlim([0 5]); ylim([-1 1]);
grid on
title("Zermelo trajectory");
sgtitle("Zermelo problem results");
end
