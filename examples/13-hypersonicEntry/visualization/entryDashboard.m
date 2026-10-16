function entryDashboard(time, lat, lon, alt, ...
                        sigma, alpha, ...
                        v_mag, ...
                        heat_rate, dyn_press, load_factor, ...
                        heat_rate_max, dyn_press_max, load_factor_max, ...
                        problemName, videoFile)
% animated dashboard of the entry: if videoFile is specified, the animation
% is also saved to that (MPEG-4) video file
if nargin < 15
    videoFile = "";
end

% =============================
% USER FLAGS / PARAMETERS
% =============================
frame_rate = 30;  % <-- video frame rate [fps]
duration   = 9;   % <-- animation duration [s] (plus 1 s on the last frame)

% =============================
% PREPROCESSING
% =============================
Re = 6378e3;
n_frames = duration * frame_rate;

% resample all the quantities on equally spaced times, so that the
% playback speed is proportional to the flight time (and not to the
% density of the collocation nodes)
[time, idx] = unique(time(:)');
t_anim = linspace(time(1), time(end), n_frames);
resample = @(x) interp1(time, x(:, idx)', t_anim(:))';
lat = resample(lat(:)'); lon = resample(lon(:)'); alt = resample(alt(:)');
sigma = rad2deg(resample(sigma(:)'));
alpha = rad2deg(resample(alpha(:)'));
v_mag = resample(v_mag(:)');
heat_rate = resample(heat_rate(:)');
dyn_press = resample(dyn_press(:)');
load_factor = resample(load_factor(:)');
time = t_anim;

% Downrange
dlat = deg2rad(lat - lat(1));
dlon = deg2rad(lon - lon(1));
downrange = Re * sqrt(dlat.^2 + (cosd(lat).*dlon).^2);

% path constraints as a percentage of their limits
heat_rate = 100 * heat_rate / heat_rate_max;
dyn_press = 100 * dyn_press / dyn_press_max;
load_factor = 100 * load_factor / load_factor_max;

% limits around the trajectory (with a 10% margin)
margin = @(x) [min(x) max(x)] + [-0.1 0.1] * (max(x) - min(x));

% =============================
% FIGURE
% =============================
fig = figure('Color','w','Position',[100 100 1400 850], "Name",problemName+":entry:auxiliary:dashboard", "NumberTitle","off");
tiledlayout(3,3,'Padding','compact','TileSpacing','compact')

% coastlines (Mapping Toolbox data), if available
C = struct("coastlon", NaN, "coastlat", NaN);
if exist("coastlines.mat", "file")
    C = load("coastlines");
end

% =============================
% 3D TRAJECTORY
% =============================
ax3d = nexttile([2 2]);
hold on; grid on
view(-35, 25)

title('3D Trajectory')
xlabel('Longitude [deg]')
ylabel('Latitude [deg]')
zlabel('Altitude [km]')

plot3(C.coastlon, C.coastlat, zeros(size(C.coastlat)), ...
      'Color',[0.5 0.5 0.5], "LineWidth",2)

plot3(lon, lat, alt/1e3, 'Color',[0.85 0.85 0.85])
plot3(lon, lat, zeros(size(lon)), ':', 'Color',[0.6 0.6 0.6], 'LineWidth',1.5)   % ground track shadow

traj3d = plot3(NaN,NaN,NaN,'r','LineWidth',2);
vehicle_plot = plot3(NaN,NaN,NaN,'ro','MarkerFaceColor','r');

xlim(margin(lon))
ylim(margin(lat))
zlim([0 1.05 * max(alt)/1e3])

% =============================
% GROUND TRACK
% =============================
axGT = nexttile;
hold on; grid on
title('Ground Track')

plot(C.coastlon, C.coastlat,'Color',[0.5 0.5 0.5], "LineWidth",2)
plot(lon, lat,'Color',[0.85 0.85 0.85])

gt_line = plot(NaN,NaN,'b','LineWidth',2);
gt_point = plot(NaN,NaN,'bo','MarkerFaceColor','b');

xlim(margin(lon))
ylim(margin(lat))
xlabel('Longitude [deg]')
ylabel('Latitude [deg]')

% =============================
% ALTITUDE vs DOWNRANGE
% =============================
axAlt = nexttile;
hold on; grid on
title('Altitude vs Downrange')

plot(downrange/1e3, alt/1e3,'Color',[0.85 0.85 0.85])

alt_line = plot(NaN,NaN,'r','LineWidth',2);
alt_point = plot(NaN,NaN,'ro','MarkerFaceColor','r');

xlim([0 max(downrange)/1e3])
ylim([0 1.05 * max(alt)/1e3])
xlabel('Downrange [km]')
ylabel('Altitude [km]')

% =============================
% ALTITUDE vs VELOCITY
% =============================
axAV = nexttile;
hold on; grid on
title('Altitude vs Velocity')

plot(v_mag/1e3, alt/1e3,'Color',[0.85 0.85 0.85])

av_line = plot(NaN,NaN,'m','LineWidth',2);
av_point = plot(NaN,NaN,'mo','MarkerFaceColor','m');

xlim([0 1.05 * max(v_mag)/1e3])
ylim([0 1.05 * max(alt)/1e3])
xlabel('Velocity [km/s]')
ylabel('Altitude [km]')

% =============================
% CONTROL ANGLES
% =============================
axAng = nexttile;
hold on; grid on
title('Control Angles')

ang_s = plot(NaN,NaN,'b','LineWidth',1.5);
ang_a = plot(NaN,NaN,'r','LineWidth',1.5);

legend('\sigma (bank)','\alpha (attack)','Location','best')

xlim([time(1) time(end)])
ylim(margin([sigma alpha]))
xlabel('Time [s]')
ylabel('Angle [deg]')

% =============================
% PATH CONSTRAINTS
% =============================
axC = nexttile;
hold on; grid on
title('Path Constraints')

heat_line = plot(NaN,NaN,'r','LineWidth',1.5);
q_line = plot(NaN,NaN,'b','LineWidth',1.5);
n_line = plot(NaN,NaN,'k','LineWidth',1.5);
yline(100,'k--','LineWidth',1.5);

legend('heat flux','dynamic pressure','load factor','Location','best')

xlim([time(1) time(end)])
ylim([0 120])
xlabel('Time [s]')
ylabel('Fraction of the limit [%]')

% =============================
% ANIMATION
% =============================
if strlength(videoFile) > 0
    video = VideoWriter(videoFile, "MPEG-4");
    video.FrameRate = frame_rate;
    open(video);
end

for k = 1:n_frames

    % --- 3D trajectory ---
    set(traj3d,'XData',lon(1:k),'YData',lat(1:k),'ZData',alt(1:k)/1e3)
    set(vehicle_plot,'XData',lon(k),'YData',lat(k),'ZData',alt(k)/1e3)

    % --- Ground track ---
    set(gt_line,'XData',lon(1:k),'YData',lat(1:k))
    set(gt_point,'XData',lon(k),'YData',lat(k))

    % --- Alt vs downrange ---
    set(alt_line,'XData',downrange(1:k)/1e3,'YData',alt(1:k)/1e3)
    set(alt_point,'XData',downrange(k)/1e3,'YData',alt(k)/1e3)

    % --- Alt vs velocity ---
    set(av_line,'XData',v_mag(1:k)/1e3,'YData',alt(1:k)/1e3)
    set(av_point,'XData',v_mag(k)/1e3,'YData',alt(k)/1e3)

    % --- Control angles ---
    set(ang_s,'XData',time(1:k),'YData',sigma(1:k))
    set(ang_a,'XData',time(1:k),'YData',alpha(1:k))

    % --- Path constraints ---
    set(heat_line,'XData',time(1:k),'YData',heat_rate(1:k))
    set(q_line,'XData',time(1:k),'YData',dyn_press(1:k))
    set(n_line,'XData',time(1:k),'YData',load_factor(1:k))

    drawnow
    if strlength(videoFile) > 0
        writeVideo(video, getframe(fig));
    end
end

% hold the last frame for one second before the video loops
if strlength(videoFile) > 0
    lastFrame = getframe(fig);
    for k = 1:video.FrameRate
        writeVideo(video, lastFrame);
    end
    close(video);
end

end
