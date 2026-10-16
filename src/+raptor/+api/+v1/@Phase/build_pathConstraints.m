function build_pathConstraints(phase, corePhase, discretizedTimeIdxs, trajectories)
% asemble the variable sizes object
import raptor.core.problem.descriptors.*
import raptor.core.enumerations.*
varSizes = VariableSizes(corePhase.collocation.n_disc, corePhase.nStates, ...
    corePhase.nControls, corePhase.nLocalParameters, corePhase.nGlobalParameters);

% loop over all path constraints
constraintNames = string(properties(phase.constraints.path));
if ~isempty(constraintNames)
    for name = constraintNames'

        % get the current constraint
        constraint = phase.constraints.path.(name);
        outputSize = size(constraint.lowerBound, 1);

        % only transcribe the constraint if it is bounded
        if any(isfinite(constraint.lowerBound), "all") || ...
                any(isfinite(constraint.upperBound), "all")

            % loop over all constraint terms
            functionDescriptors = {};
            for term = constraint.terms

                % instantiate the corresponding function descriptor
                coreFunction = Function(term.functionHandle, outputSize, ...
                    FunctionType.(term.functionType), EvaluationDomain.path, ...
                    OperatorType.none, varSizes, discretizedTimeIdxs);
                raptor.api.v1.elements.build_jacobians(coreFunction, term, corePhase, trajectories, phase);

                % append the function descriptor to the full list
                functionDescriptors{end + 1} = coreFunction;
            end

            % instantiate the constraint descriptor and append it
            coreConstraint = Constraint(name, functionDescriptors, outputSize, ...
                OutputNodes.discretized, constraint.lowerBound, ...
                constraint.upperBound, corePhase.collocation);
            corePhase.constraints = [corePhase.constraints coreConstraint];
        end
    end
end
end

