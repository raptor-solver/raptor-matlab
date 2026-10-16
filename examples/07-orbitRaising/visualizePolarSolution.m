function visualizePolarSolution(sol)
% auxiliary function to plot the solution in polar dynamics together with
% the discrete collocation points

% visualize solution
t = sol.raising.discretized.time;
r = sol.raising.discretized.states(1, :);
r_prop = sol.raising.propagated.states(1, :);
theta = sol.raising.discretized.states(2, :);
theta_prop = sol.raising.propagated.states(2, :);
figure
polarplot(theta_prop, r_prop, "-b", "LineWidth",1.2, "DisplayName","propagated");
hold on
polarplot(theta, r, "or", "MarkerSize",3, "DisplayName","collocated");
hold off
rlim([0.9 1.1 * max([r(end) r_prop(end)])]);
grid on
legend("Location","best");
sgtitle("OrbitRaising2D solution");
end
