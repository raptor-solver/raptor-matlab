function build_costs(phase, corePhase, collocatedTimeIdxs, trajectories)
% asemble the variable sizes object
import raptor.core.problem.descriptors.*
import raptor.core.enumerations.*
varSizes = VariableSizes(corePhase.collocation.n_disc, corePhase.nStates, ...
    corePhase.nControls, corePhase.nLocalParameters, corePhase.nGlobalParameters);

% loop over all Lagrange cost terms
functionDescriptors = {};
for term = phase.costs.lagrange.terms

    % instantiate the corresponding function descriptor
    coreFunction = Function(term.functionHandle, 1, ...
        FunctionType.nonlinear, EvaluationDomain.path, ...
        OperatorType.integration, varSizes, collocatedTimeIdxs);
    raptor.api.v1.elements.build_jacobians(coreFunction, term, corePhase, trajectories, phase);
    coreFunction = corePhase.collocation.applyIntegrationWrapper(coreFunction, corePhase, trajectories);

    % append the function descriptor to the full list
    functionDescriptors{end + 1} = coreFunction;
end

% loop over all mayer cost terms
for term = phase.costs.mayer.terms

    % instantiate the corresponding function descriptor
    coreFunction = Function(term.functionHandle, 1, ...
        FunctionType.(term.functionType), EvaluationDomain.boundary, ...
        OperatorType.none, varSizes, 1);
    raptor.api.v1.elements.build_jacobians(coreFunction, term, corePhase, trajectories, phase);

    % append the function descriptor to the full list
    functionDescriptors{end + 1} = coreFunction;
end

% instantiate and populate the core phase descriptor
corePhase.cost = Cost(functionDescriptors, corePhase.collocation);
end

