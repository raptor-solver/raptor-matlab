function plotPrimal(obj, solution, trajectories, transcription)
% method that generates the plots for the primal variables
import raptor.core.enumerations.*

% store the lower and upper bound vectors
ZL = transcription.getGlobalVariable(trajectories.lowerBound);
ZU = transcription.getGlobalVariable(trajectories.upperBound);
CU = transcription.getConstraintBounds("upperBound");
CL = transcription.getConstraintBounds("lowerBound");

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

    %% plot the states
    fig = figure('Name', strcat(problemName, ":", phaseName, ":primal:states"), ...
        'NumberTitle','off', 'WindowStyle','docked', 'Color','w');
    tl = tiledlayout(fig, 'flow', 'TileSpacing','compact', 'Padding','compact');
    sgtitle(tl, strcat("States during the ", phaseName, " phase"));

    % store the states and their lower and upper bounds
    xDisc = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).discretized.states);
    xColl = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).collocated.states);
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
        plot(ax, tColl, xColl(ss, :), ....
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

    %% plot the controls
    fig = figure('Name', strcat(problemName, ":", phaseName, ":primal:controls"), ...
        'NumberTitle','off', 'WindowStyle','docked', 'Color','w');
    tl = tiledlayout(fig, 'flow', 'TileSpacing','compact', 'Padding','compact');
    sgtitle(tl, strcat("Controls during the ", phaseName, " phase"));

    % store the controls and their lower and upper bounds
    uDisc = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).discretized.controls);
    uColl = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).collocated.controls);
    lb = obj.concatenatePhases(phaseIdxs, @(qq) reshape(ZL(transcription.var_idx(qq).discretized.controls), ...
        [], length(solution.(phaseNames(qq)).discretized.time))); lb(isinf(lb)) = NaN;
    ub = obj.concatenatePhases(phaseIdxs, @(qq) reshape(ZU(transcription.var_idx(qq).discretized.controls), ...
        [], length(solution.(phaseNames(qq)).discretized.time))); ub(isinf(ub)) = NaN;

    % loop over all states
    for cc = 1 : size(uDisc, 1)

        % assemble the label and title for the current tile
        controlName = obj.variableMetadata(pp).controls(cc, 1);
        controlUnit = obj.variableMetadata(pp).controls(cc, 2);
        controlLabel = obj.variableMetadata(pp).controls(cc, 3);
        yLabel = strcat(controlLabel, "(", timeLabel, ") [", controlUnit, "]");
        currentTitle = controlName;
        ax = nexttile(tl);
        hold(ax, 'on');

        % plot the controls and freeze the y limits
        plot(ax, tDisc, uDisc(cc, :), ...
            "-b", "LineWidth",1.8);
        plot(ax, tColl, uColl(cc, :), ....
            "--r", "LineWidth",1.2);
        axis manual;

        % plot the upper and lower bounds
        plot(tDisc, lb(cc, :), '--k', "LineWidth",1.2);
        plot(tDisc, ub(cc, :), '--k', "LineWidth",1.2);

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

    %% plot the constraints
    fig = figure('Name', strcat(problemName, ":", phaseName, ":primal:constraints"), ...
        'NumberTitle','off', 'WindowStyle','docked', 'Color','w');
    tl = tiledlayout(fig, 'flow', 'TileSpacing','compact', 'Padding','compact');
    sgtitle(tl, strcat("Constraints during the ", phaseName, " phase"));

    % loop over all path constraints (for combined phases, only the
    % constraints defined in all the phases are plotted)
    for constraint = transcription.ocp.phases(pp).constraints
        if (constraint.outputNodes == OutputNodes.collocated || ...
                constraint.outputNodes == OutputNodes.collocatedWithoutInitial || ...
                constraint.outputNodes == OutputNodes.discretized) && ...
                isSharedConstraint(constraint, transcription.ocp.phases(phaseIdxs))
            leg = [];

            % retrieve the constraint values, upper and lower bound
            cDisc = obj.concatenatePhases(phaseIdxs, @(qq) solution.(phaseNames(qq)).discretized.(constraint.name));
            cu = obj.concatenatePhases(phaseIdxs, @(qq) reshape(CU(transcription.con_idx(qq).(constraint.name)), constraint.outputDim, []));
            cl = obj.concatenatePhases(phaseIdxs, @(qq) reshape(CL(transcription.con_idx(qq).(constraint.name)), constraint.outputDim, []));
            cu(isinf(cu)) = NaN;
            cl(isinf(cl)) = NaN;
            tBoundaries = obj.concatenatePhases(phaseIdxs, @(qq) getBoundaryTimes(constraint, ...
                solution.(phaseNames(qq)), transcription.ocp.phases(qq).collocation));

            % assemble the label and title for the current tile
            constraintName = obj.variableMetadata(pp).auxdata.constraints.(constraint.name)(1);
            constraintUnit = obj.variableMetadata(pp).auxdata.constraints.(constraint.name)(2);
            constraintLabel = obj.variableMetadata(pp).auxdata.constraints.(constraint.name)(3);
            yLabel = strcat(constraintLabel, "(", timeLabel, ") [", constraintUnit, "]");
            currentTitle = constraintName;
            ax = nexttile(tl);
            hold(ax, 'on');

            % loop over each dimension of the constraint and plot the
            % corresponding line
            for cc = 1 : constraint.outputDim
                plot(tDisc, cDisc(cc, :), ...
                    "LineWidth",1.2);
                leg = [leg strcat(constraintLabel, " \{", string(cc), "\}")];
            end
            axis manual

            % plot the upper and lower bounds
            for cc = 1 : constraint.outputDim
                plot(tBoundaries, cl(cc, :), '--k', "LineWidth",1.2);
                plot(tBoundaries, cu(cc, :), '--k', "LineWidth",1.2);
            end

            % apply titles and labels
            ax.TickLabelInterpreter = 'latex';
            title(ax, currentTitle);
            xlabel(ax, xLabel, 'Interpreter', 'latex');
            ylabel(ax, yLabel, 'Interpreter', 'latex');
            grid(ax, "on");
            box(ax, "on");
            legend(leg, "Location","best", "Interpreter", "latex");
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

%% TODO: maybe add a figure/plot of the static parameters

end

function tBoundaries = getBoundaryTimes(constraint, phaseSolution, collocation)
% function that returns the time instants at which the bounds of the
% specified constraint are defined within a single phase
import raptor.core.enumerations.*

tColl = phaseSolution.collocated.time;
if constraint.outputNodes == OutputNodes.collocated
    tBoundaries = tColl;
elseif constraint.outputNodes == OutputNodes.collocatedWithoutInitial
    tBoundaries = tColl(~collocation.getSegmentInitialMask());
else
    tBoundaries = phaseSolution.discretized.time;
end
end

function shared = isSharedConstraint(constraint, phases)
% function that checks whether the specified constraint is defined, with
% the same size, in all the specified phases
shared = true;
for phase = phases
    match = phase.constraints(string({phase.constraints.name}) == string(constraint.name));
    shared = shared && ~isempty(match) && match(1).outputDim == constraint.outputDim;
end
end
