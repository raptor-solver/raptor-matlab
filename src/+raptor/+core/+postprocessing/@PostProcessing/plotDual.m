function plotDual(obj, solution)
% method that generates the plots for the dual variables

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
    tColl = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).collocated.time);

    % store the costates and hamiltonian data
    lDisc = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).discretized.costates);
    lColl = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).collocated.costates);
    hDisc = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).discretized.hamiltonian);
    hColl = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).collocated.hamiltonian);

    %% plot the costates
    fig = figure('Name', strcat(problemName, ":", phaseName, ":dual:costates"), ...
        'NumberTitle','off', 'WindowStyle','docked', 'Color','w');
    tl = tiledlayout(fig, 'flow', 'TileSpacing','compact', 'Padding','compact');
    sgtitle(tl, strcat("Costates during the ", phaseName, " phase"));

    % loop over all states
    for ss = 1 : size(lDisc, 1)

        % assemble the label and title for the current tile
        stateName = obj.variableMetadata(pp).states(ss, 1);
        stateLabel = obj.variableMetadata(pp).states(ss, 3);
        yLabel = strcat("costate ", stateLabel, "(", timeLabel, ") [-]");
        currentTitle = stateName;
        ax = nexttile(tl);
        hold(ax, 'on');

        % plot the costates
        plot(ax, tDisc, lDisc(ss, :), ...
            "-b", "LineWidth",1.8);
        plot(ax, tColl, lColl(ss, :), ....
            "--r", "LineWidth",1.2);

        % apply titles and labels
        ax.TickLabelInterpreter = 'latex';
        title(ax, currentTitle);
        xlabel(ax, xLabel, 'Interpreter', 'latex');
        ylabel(ax, yLabel, 'Interpreter', 'latex');
        grid(ax, "on");
        box(ax, "on");
        legend(["discretized" "collocated"], "Location","best");
        ax.GridAlpha = 0.25;
        ax.MinorGridAlpha = 0.15;
        ax.XMinorGrid = 'on';
        ax.YMinorGrid = 'on';
        ax.XMinorTick = "on";
        ax.YMinorTick = "on";
        xlim(ax, [tDisc(1) tDisc(end)]);
        hold(ax, "off");
    end

    %% plot the hamiltonian
    fig = figure('Name', strcat(problemName, ":", phaseName, ":dual:hamiltonian"), ...
        'NumberTitle','off', 'WindowStyle','docked', 'Color','w');
    tl = tiledlayout(fig, 'flow', 'TileSpacing','compact', 'Padding','compact');
    sgtitle(tl, strcat("Hamiltonian during the ", phaseName, " phase"));

    % plot the hamiltonian data
    ax = nexttile(tl);
    hold(ax, 'on');
    plot(tDisc, hDisc, "-b", "LineWidth",1.8);
    plot(tColl, hColl, "--r", "LineWidth",1.2);

    % apply titles and labels
    ax.TickLabelInterpreter = 'latex';
    title(ax, "Hamiltonian");
    xlabel(ax, xLabel, 'Interpreter', 'latex');
    ylabel(ax, "hamiltonian [-]", 'Interpreter', 'latex');
    grid(ax, "on");
    box(ax, "on");
    legend(["discretized" "collocated"], "Location","best");
    ax.GridAlpha = 0.25;
    ax.MinorGridAlpha = 0.15;
    ax.XMinorGrid = 'on';
    ax.YMinorGrid = 'on';
    ax.XMinorTick = "on";
    ax.YMinorTick = "on";
    xlim(ax, [tDisc(1) tDisc(end)]);
    hold(ax, "off");

    %% TODO: maybe later add a figure for constraints covectors (box and path)
end

end