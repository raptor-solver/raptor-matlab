if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "Convex Programming Approach to Powered
% Descent Guidance for Mars Landing", augmented with free final time and
% aerodynamic drag

% boundary conditions
aux.initial.r = [1500; 0; 2000];
aux.initial.v = [-75; 0; 100];
aux.final.r = [0; 0; 0];
aux.final.v = [0; 0; 0];
aux.initial.t = 0;

% environment
aux.g = 3.7114;
aux.mDry = 1405;
aux.mWet = 1905;
aux.Isp = 225;
aux.ge = 9.807;
aux.kD0 = 0.1;
aux.phi = deg2rad(27);
aux.alpha = 1 / (aux.Isp * aux.ge * cos(aux.phi));
aux.n = 6;
aux.theta_gs = deg2rad(90 - 4);

% derived quantities
zm = 0.5 * (log(aux.mWet) + log(aux.mDry));
aux.zm = zm;
Tmax = 3100 * aux.n * cos(aux.phi);
aux.Tmax = Tmax;
aux.Tl = 0.3 * Tmax;
aux.Tu = 0.8 * Tmax;
aux.mu1 = aux.Tl * exp(- zm);
aux.mu2 = aux.Tu * exp(- zm);

% assembled variables
X0 = [aux.initial.r; aux.initial.v; log(aux.mWet)];
Xf = [aux.final.r; aux.final.v];

% guesses
tmin = (aux.mDry) * norm(aux.initial.v) / aux.Tu;
tmax = (aux.mWet - aux.mDry) / (aux.alpha * aux.Tl);
tguess = 0.5 * (tmin + tmax);

% =========================================================================
%% Problem Definition
% =========================================================================

% Start build timer
tic

% Instantiate OCP
ocp = raptor.api.v1.OptimalControlProblem("MarsLanding3DoF", aux, 0);

% Add phase
phase = ocp.addPhase("landing", 7, 4, 0);

% ---------------------- Metadata -----------------------------------------
phase.metadata.name.time = "time";
phase.metadata.label.time = "t";
phase.metadata.unit.time = "s";

phase.metadata.label.states = ["x" "y" "z" "$v_x$" "$v_y$" "$v_z$" "log(m)"];
phase.metadata.unit.states = ["m" "m" "m" "m/s" "m/s" "m/s" "log(kg)"];
phase.metadata.name.states = ["x" "y" "z" "v_x" "v_y" "v_z" "log mass"];

phase.metadata.name.controls = ["u_x" "u_y" "u_z" "throttle"];
phase.metadata.unit.controls = ["$m/s^2$" "$m/s^2$" "$m/s^2$" "$m/s^2$"];
phase.metadata.label.controls = ["$u_x$" "$u_y$" "$u_z$" "$\sigma$"];

% ---------------------- Dynamics -----------------------------------------
dyn = phase.dynamics.add(@marsLanding3DoFDynamics);

% ------------------- Path Constraints ------------------------------------
% norm of thrust vector lower or equal to throttle
phase.constraints.path.stack("thrustNorm", -Inf, 0);
phase.constraints.path.thrustNorm.label = "$\|\mathbf{u} \|$";
f = phase.constraints.path.thrustNorm.add(@thrustNorm);
f = phase.constraints.path.thrustNorm.add(@(inputData) - inputData.controls(4, :));
f.functionType = "linear";

% lower bound on throttle
phase.constraints.path.stack("throttleLowerBound", aux.mu1 * (1 + zm), Inf);
phase.constraints.path.throttleLowerBound.label = "$\mu_1 [...] \leq \sigma$";
f = phase.constraints.path.throttleLowerBound.add(@throttleLowerBound);
f = phase.constraints.path.throttleLowerBound.add(@(inputData) inputData.controls(4, :));
f.functionType = "linear";

% upper bound on throttle
phase.constraints.path.stack("throttleUpperBound", -Inf, aux.mu2 * (1 + zm));
phase.constraints.path.throttleUpperBound.label = "$\mu_2 [...] \geq \sigma$";
f = phase.constraints.path.throttleUpperBound.add(@throttleUpperBound);
f = phase.constraints.path.throttleUpperBound.add(@(inputData) inputData.controls(4, :));
f.functionType = "linear";

% glideslope angle
phase.constraints.path.stack("glideSlope", -Inf, 0);
phase.constraints.path.glideSlope.label = "$\theta_{alt} - \tilde{\theta}_{alt}$";
f = phase.constraints.path.glideSlope.add(@glideSlopeConstraint);

% ------------------------- Costs -----------------------------------------
% Lagrange term
f = phase.costs.lagrange.add(@(inputData) inputData.controls(4, :));
f.functionType = "linear";

% ------------------ Boundary Conditions ----------------------------------
phase.boundaryConditions.initial.time = 0;
phase.boundaryConditions.initial.states = X0;
phase.boundaryConditions.final.states(1 : 6) = Xf;

% ---------------------- Initial Guess ------------------------------------
phase.initialGuess.final.states(7) = log(aux.mDry);
phase.initialGuess.continuous.controls = [1 0 0 1] .* aux.g;
phase.initialGuess.final.time = tguess;
phase.initialGuess.linear();

% ---------------------- Box Constraints ----------------------------------
phase.box.lower.states = [0 -2000 -2000 -200 -200 -200 log(aux.mDry)];
phase.box.upper.states = [2000 2000 4000 200 200 200 log(aux.mWet)];
phase.box.lower.finalTime = tmin;
phase.box.upper.finalTime = tmax;

% ------------------- Collocation Settings --------------------------------
phase.collocation.interpolant = "Lagrange";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "Gauss-Radau";
phase.collocation.nNodes = 49;

% Build problem
problem = raptor.build(ocp);

% Optional: solver configuration
problem.config.transcription.method = "NLP";
problem.config.scaling.method = ["BoundsProjection" "JacobianRowNormalization"];
problem.config.transcription.numericalJacobian = "ComplexStepDifferences";
problem.config.transcription.finiteStep = 1e-12;
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-8;
problem.config.solver.iter_limit = 1000;
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
if showPlots
    problem.config.postprocessing.plotting.auxiliaryFunction = @visualizeSolution;
end

buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

% =========================================================================
%% Problem Solution
% =========================================================================
sol = problem.solve();

function visualizeSolution(sol)
% auxiliary plotting function to visualize the solution and compare it to
% the paper results

% store state variables
t = sol.landing.discretized.time;
x = sol.landing.discretized.states(1, :);
y = sol.landing.discretized.states(2, :);
z = sol.landing.discretized.states(3, :);
vx = sol.landing.discretized.states(4, :);
vy = sol.landing.discretized.states(5, :);
vz = sol.landing.discretized.states(6, :);
m = exp(sol.landing.discretized.states(7, :));
theta = rad2deg(atan(sqrt(y.^2 + z.^2) ./ x));

% store control variables
tax = sol.landing.discretized.controls(1, :);
tay = sol.landing.discretized.controls(2, :);
taz = sol.landing.discretized.controls(3, :);
Tacc = sol.landing.discretized.controls(4, :);
tx = tax .* m;
ty = tay .* m;
tz = taz .* m;
T = Tacc .* m;

% store auxiliary scaling to use during plots
Tl = sol.landing.discretized.auxdata.Tl;
Tu = sol.landing.discretized.auxdata.Tu;
Tmax = sol.landing.discretized.auxdata.Tmax;

% create the figure
figure
tiledlayout(3, 2, "TileSpacing","compact", "Padding","compact");
nexttile(1)
hold on
plot(t, x, "-r", "LineWidth",1.2, "DisplayName","$r_1$");
plot(t, y, "-g", "LineWidth",1.2, "DisplayName","$r_2$");
plot(t, z, "-b", "LineWidth",1.2, "DisplayName","$r_3$");
xlabel("time [s]");
ylabel("position [m]");
grid on
legend("Location","best", "Interpreter","latex");

nexttile(2)
hold on
plot(t, vx, "-r", "LineWidth",1.2, "DisplayName","$\dot{r}_1$");
plot(t, vy, "-g", "LineWidth",1.2, "DisplayName","$\dot{r}_2$");
plot(t, vz, "-b", "LineWidth",1.2, "DisplayName","$\dot{r}_3$");
xlabel("time [s]");
ylabel("velocity [m/s]");
grid on
legend("Location","best", "Interpreter","latex");

nexttile(3)
hold on
plot(t, tax, "-r", "LineWidth",1.2, "DisplayName","$u_1$");
plot(t, tay, "-g", "LineWidth",1.2, "DisplayName","$u_2$");
plot(t, taz, "-b", "LineWidth",1.2, "DisplayName","$u_3$");
xlabel("time [s]");
ylabel("thrust acceleration [m/s^2]");
grid on
legend("Location","best", "Interpreter","latex");

nexttile(4)
hold on
plot(t, tx ./ 1000, "-r", "LineWidth",1.2, "DisplayName","$T_1$");
plot(t, ty ./ 1000, "-g", "LineWidth",1.2, "DisplayName","$T_2$");
plot(t, tz ./ 1000, "-b", "LineWidth",1.2, "DisplayName","$T_3$");
xlabel("time [s]");
ylabel("thrust force [kN]");
grid on
legend("Location","best", "Interpreter","latex");

nexttile(5)
plot(t, T ./ Tmax, "-r", "LineWidth",1.2);
xlabel("time [s]");
grid on
ylabel("throttle level [-]");

nexttile(6)
plot(t, theta, "-r", "LineWidth",1.2);
xlabel("time [s]");
ylabel("glide slope angle [deg]");
grid on
sgtitle("Mars 3 DoF landing results");

% one more figure for the down/crossrange profile
figure
z = vecnorm(sol.landing.discretized.states(2:3, :)); % downrange
plot(z./1000, x./1000, "-b", "LineWidth",1.2, "DisplayName","trajectory");
hold on
x0 = sol.landing.discretized.auxdata.initial.r(1);
z0 = norm(sol.landing.discretized.auxdata.initial.r(2:3));
xf = sol.landing.discretized.auxdata.final.r(1);
zf = norm(sol.landing.discretized.auxdata.final.r(2:3));
scatter(z0/1000, x0/1000, "green", "filled", "o", "DisplayName","start");
scatter(zf/1000, xf/1000, "red", "x", "DisplayName", "target");
plot(z ./ 1000, tan(pi/2 - sol.landing.discretized.auxdata.theta_gs) .* z ./ 1000, "--k", "DisplayName","glide slope constraint");
legend("Location","best");
xlabel("downrange [km]");
ylabel("altitude [km]");
grid on
title("Mars 3 DoF landing profile");

% print the fuel consumption
mFuel = sol.landing.discretized.auxdata.mWet - m(end)
end
