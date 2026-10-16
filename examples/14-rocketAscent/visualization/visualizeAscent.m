function visualizeAscent(sol, videoFile)
% auxiliary plotting function to visualize the ascent trajectory, including
% the vertical lift-off propagated before the optimization: if videoFile is
% specified, the dashboard animation is also saved to that video file
if nargin < 2
    videoFile = "";
end

% retrieve solution (with the lift-off data at the start)
aux = sol.ascent.discretized.auxdata;
data = sol.ascent.discretized;

% with Gauss-Radau nodes the final control does not enter the dynamics (it
% is only bound by the path constraints), so it is extrapolated from the
% previous nodes to avoid a spurious jump at the end of the plots
u = data.controls(1 : 3, :);
u(:, end) = interp1(data.time(1 : end - 1), u(:, 1 : end - 1)', data.time(end), "linear", "extrap")';
u(:, end) = u(:, end) / norm(u(:, end));

data.time = [aux.takeOff.time data.time];
data.states = [aux.takeOff.states data.states];
data.controls = [aux.takeOff.controls u];
t = data.time;
r = data.states(1 : 3, :);
v = data.states(4 : 6, :);
That = data.controls(1 : 3, :);

% environment parameters
R0 = aux.R0;
we = aux.we;

% ecef quantities
we = repmat(we, 1, size(v, 2));
v_rel_eci = v - cross(we, r);
r_ecef =    [cos(we(3) * t) .* r(1, :) + sin(we(3) * t) .* r(2, :); ...
    - sin(we(3) * t) .* r(1, :) + cos(we(3) * t) .* r(2, :); ...
    r(3, :)];
v_ecef =    [cos(we(3) * t) .* v_rel_eci(1, :) + sin(we(3) * t) .* v_rel_eci(2, :); ...
    - sin(we(3) * t) .* v_rel_eci(1, :) + cos(we(3) * t) .* v_rel_eci(2, :); ...
    v_rel_eci(3, :)];
That_ecef = [cos(we(3) * t) .* That(1, :) + sin(we(3) * t) .* That(2, :); ...
    - sin(we(3) * t) .* That(1, :) + cos(we(3) * t) .* That(2, :); ...
    That(3, :)];
lon = atan2(r_ecef(2, :), r_ecef(1, :));
lat = atan2(r_ecef(3, :), sqrt(r_ecef(1, :).^2 + r_ecef(2, :).^2));
dr = acos(sin(lat(1)) .* sin(lat) + cos(lat(1)) .* cos(lat) .* cos(lon - lon(1))) * R0;

% enu quantities
That_enu = [- sin(lon) .* That_ecef(1, :) + cos(lon) .* That_ecef(2, :); ...
    - sin(lat) .* cos(lon) .* That_ecef(1, :) - sin(lat) .* sin(lon) .* That_ecef(2, :) + cos(lat) .* That_ecef(3, :); ...
    cos(lat) .* cos(lon) .* That_ecef(1, :) +  cos(lat) .* sin(lon) .* That_ecef(2, :) + sin(lat) .* That_ecef(3, :)];
v_enu = [- sin(lon) .* v_ecef(1, :) + cos(lon) .* v_ecef(2, :); ...
    - sin(lat) .* cos(lon) .* v_ecef(1, :) - sin(lat) .* sin(lon) .* v_ecef(2, :) + cos(lat) .* v_ecef(3, :); ...
    cos(lat) .* cos(lon) .* v_ecef(1, :) +  cos(lat) .* sin(lon) .* v_ecef(2, :) + sin(lat) .* v_ecef(3, :)];

% additional plotting quantities
h = vecnorm(r) - R0;
gamma = atan2(v_enu(3,:), sqrt(v_enu(1,:).^2 + v_enu(2,:).^2));
theta = atan2(That_enu(3,:), sqrt(That_enu(1,:).^2 + That_enu(2,:).^2));
alpha = acos(sum((That ./ vecnorm(That)) .* (v_rel_eci ./ vecnorm(v_rel_eci)), 1));
q = dynamicPressure(data);
qalpha = dynamicPressureTimesAoA(data);

% print results
table([t(end); h(end)/1000; norm(v(:, end))/1000; rad2deg(gamma(end))], ...
    'VariableNames', {'Final Value'}, ...
    'RowNames', {'t [sec]', 'h [km]', 'v [km/s]', '\gamma [deg]'})

% altitude over time/downrange/speed
figure("Name","FirstStage:ascent:auxiliary:altitude", "NumberTitle","off");
tiledlayout(2, 2, "TileSpacing","tight", "Padding","tight");
nexttile(1);
plot(t, h / 1000, "-b", "LineWidth",1.2);
xlabel("time [s]");
ylabel("altitude [km]");
grid on
title("Altitude over time");
nexttile(2);
plot(t, vecnorm(v) / 1000, "-b", "LineWidth",1.2);
xlabel("time [s]");
ylabel("velocity [km/s]");
grid on
title("Velocity over time");
nexttile(3);
plot(dr / 1000, h / 1000, "-b", "LineWidth",1.2);
xlabel("downrange [km]");
ylabel("altitude [km]");
grid on
title("Altitude vs Downrange");
nexttile(4);
plot(vecnorm(v) / 1000, h / 1000, "-b", "LineWidth",1.2);
xlabel("speed [km/s]");
ylabel("altitude [km]");
grid on
title("Altitude vs Speed");

% visualize the ascent dashboard
ascentDashboard(t, rad2deg(lat), rad2deg(lon), h, gamma, theta, alpha, q, qalpha, That_enu, vecnorm(v), ...
    aux.hf, aux.vf, aux.qMax, aux.qAlphaMax, "FirstStage", videoFile);
end
