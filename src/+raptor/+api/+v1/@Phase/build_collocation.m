function [discretizedTimeIdxs, collocatedTimeIdxs] = build_collocation(phase, corePhase)

% set the collocation object
corePhase.collocation = raptor.core.collocation.(phase.collocation.method_string)(phase.collocation);

% store the localized time nodes for collocated and discretized variables
[discretizedTimeIdxs, collocatedTimeIdxs] = corePhase.collocation.getLocalTimeIdxs();

% get the number of extra control variables required to apply
% differentiation
nExtraControls = corePhase.collocation.getNumberOfExtraControls(phase);

% set the number of variables
corePhase.nStates = phase.nStates;
corePhase.nControls = phase.nControls + nExtraControls;
corePhase.nLocalParameters = phase.nLocalParameters;
corePhase.nGlobalParameters = phase.nGlobalParameters;
end

