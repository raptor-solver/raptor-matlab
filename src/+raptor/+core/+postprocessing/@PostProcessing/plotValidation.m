function plotValidation(obj, solution, trajectories, transcription)
% method that generates the plots for the errors between validated and
% discretized solution
import raptor.core.enumerations.*

% store the lower and upper bound vectors
ZL = transcription.getGlobalVariable(trajectories.lowerBound);
ZU = transcription.getGlobalVariable(trajectories.upperBound);

% loop over all groups of plotted phases (the metadata of the first phase
% of each group are used for the whole group)
problemName = string(obj.variableMetadata(1).auxdata.ocpName);
phaseNames = obj.getPhaseNames();
for gg = 1 : length(obj.plottedPhases)
    phaseIdxs = obj.plottedPhases{gg};
    pp = phaseIdxs(1);
    phaseName = join(phaseNames(phaseIdxs), "+");

    % store the time axis label
    timeName = obj.variableMetadata(pp).time(1);
    timeUnit = obj.variableMetadata(pp).time(2);
    timeLabel = obj.variableMetadata(pp).time(3);
    xLabel = strcat(timeName, " [", timeUnit, "]");

    % store the time data
    tDisc = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).discretized.time);
    tProp = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).propagated.time);

    % store the discretized and propagated states, and their errors
    xDisc = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).discretized.states);
    xProp = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).propagated.states);
    xErr = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).propagated.errors.states);

    %% plot the states
    fig = figure('Name', strcat(problemName, ":", phaseName, ":validation:states"), ...
        'NumberTitle','off', 'WindowStyle','docked', 'Color','w');
    tl = tiledlayout(fig, 'flow', 'TileSpacing','compact', 'Padding','compact');
    sgtitle(tl, strcat("States validation during the ", phaseName, " phase"));

    % store the lower and upper bounds on the states
    lb = obj.concatenatePhases(phaseIdxs, @(qq) reshape(ZL(transcription.var_idx(qq).discretized.states), ...
        [], length(solution.(phaseNames(qq)).discretized.time))); lb(isinf(lb)) = NaN;
    ub = obj.concatenatePhases(phaseIdxs, @(qq) reshape(ZU(transcription.var_idx(qq).discretized.states), ...
        [], length(solution.(phaseNames(qq)).discretized.time))); ub(isinf(ub)) = NaN;

    % loop over all states
    for ss = 1 : size(xDisc, 1)

        % assemble the label and title for the current tile
        stateName = obj.variableMetadata(pp).states(ss, 1);
        stateUnit = obj.variableMetadata(pp).states(ss, 2);
        stateLabel = obj.variableMetadata(pp).states(ss, 3);
        yLabel = strcat(stateLabel, "(", timeLabel, ") [", stateUnit, "]");
        currentTitle = stateName;
        ax = nexttile(tl);
        hold(ax, 'on');

        % plot the states and freeze the y limits
        plot(ax, tDisc, xDisc(ss, :), ...
            "-b", "LineWidth",1.8);
        plot(ax, tProp, xProp(ss, :), ....
            "--r", "LineWidth",1.2);
        axis manual;

        % plot the upper and lower bounds
        plot(tDisc, lb(ss, :), '--k', "LineWidth",1.2);
        plot(tDisc, ub(ss, :), '--k', "LineWidth",1.2);

        % apply titles and labels
        ax.TickLabelInterpreter = 'latex';
        title(ax, currentTitle);
        xlabel(ax, xLabel, 'Interpreter', 'latex');
        ylabel(ax, yLabel, 'Interpreter', 'latex');
        grid(ax, "on");
        box(ax, "on");
        legend(["discretized" "propagated"], "Location","best");
        ax.GridAlpha = 0.25;
        ax.MinorGridAlpha = 0.15;
        ax.XMinorGrid = 'on';
        ax.YMinorGrid = 'on';
        ax.XMinorTick = "on";
        ax.YMinorTick = "on";
        xlim(ax, [tDisc(1) tDisc(end)]);
        hold(ax, "off");
    end

    %% plot the errors
    fig = figure('Name', strcat(problemName, ":", phaseName, ":validation:errors"), ...
        'NumberTitle','off', 'WindowStyle','docked', 'Color','w');
    tl = tiledlayout(fig, 'flow', 'TileSpacing','compact', 'Padding','compact');
    sgtitle(tl, strcat("States validation during the ", phaseName, " phase"));

    % loop over all states
    for ss = 1 : size(xDisc, 1)

        % assemble the label and title for the current tile
        stateName = obj.variableMetadata(pp).states(ss, 1);
        stateUnit = obj.variableMetadata(pp).states(ss, 2);
        stateLabel = obj.variableMetadata(pp).states(ss, 3);
        yLabel = strcat("err ", stateLabel, "(", timeLabel, ") [", stateUnit, "]");
        currentTitle = stateName;
        ax = nexttile(tl);
        hold(ax, 'on');

        % plot the state errors
        plot(ax, tDisc, xErr(ss, :), ...
            "-b", "LineWidth",1.8);

        % apply titles and labels
        ax.TickLabelInterpreter = 'latex';
        title(ax, currentTitle);
        xlabel(ax, xLabel, 'Interpreter', 'latex');
        ylabel(ax, yLabel, 'Interpreter', 'latex');
        grid(ax, "on");
        box(ax, "on");
        ax.GridAlpha = 0.25;
        ax.MinorGridAlpha = 0.15;
        ax.XMinorGrid = 'on';
        ax.YMinorGrid = 'on';
        ax.XMinorTick = "on";
        ax.YMinorTick = "on";
        xlim(ax, [tDisc(1) tDisc(end)]);
        hold(ax, "off");
    end

end

end