function setPlottedPhases(obj, phases, combinedPhases)
% method that converts the phase names specified in the plotting config
% into the groups of phase indices that are plotted in the same figures

% store the problem and phase names
problemName = string(obj.variableMetadata(1).auxdata.ocpName);
phaseNames = obj.getPhaseNames();

% by default, all phases are plotted individually
if isequal(phases, "all")
    phases = phaseNames;
end

% each individually plotted phase is a group of its own
obj.plottedPhases = {};
for phaseName = reshape(phases, 1, [])
    obj.plottedPhases{end + 1} = findPhase(problemName, phaseNames, phaseName);
end

% each set of combined phases is a single group
for cc = 1 : length(combinedPhases)
    phaseIdxs = [];
    for phaseName = reshape(string(combinedPhases{cc}), 1, [])
        phaseIdxs(end + 1) = findPhase(problemName, phaseNames, phaseName); %#ok<AGROW>
    end

    % check that the variable sizes of the combined phases match
    for pp = phaseIdxs(2 : end)
        if size(obj.variableMetadata(pp).states, 1) ~= size(obj.variableMetadata(phaseIdxs(1)).states, 1)
            raptor.core.utils.Logger.err_interPhaseMismatch(phaseNames(phaseIdxs(1)), ...
                phaseNames(pp), "states");
        elseif size(obj.variableMetadata(pp).controls, 1) ~= size(obj.variableMetadata(phaseIdxs(1)).controls, 1)
            raptor.core.utils.Logger.err_interPhaseMismatch(phaseNames(phaseIdxs(1)), ...
                phaseNames(pp), "controls");
        end
    end
    obj.plottedPhases{end + 1} = phaseIdxs;
end

end

function idx = findPhase(problemName, phaseNames, phaseName)
% function that returns the index of the specified phase
idx = find(phaseNames == phaseName, 1);
if isempty(idx)
    raptor.core.utils.Logger.errNoVariableMatch(problemName, phaseName, ...
        "get", "phase");
end
end
