function build_differentialConstraints(phase, corePhase, postProcessing, discretizedTimeIdxs, collocatedTimeIdxs, trajectories)
% asemble the variable sizes object
import raptor.core.problem.descriptors.*
import raptor.core.enumerations.*
varSizes = VariableSizes(corePhase.collocation.n_disc, corePhase.nStates, ...
    corePhase.nControls, corePhase.nLocalParameters, corePhase.nGlobalParameters);

% loop over all dynamics terms
for term = phase.dynamics.terms

    % instantiate the core function descriptor
    currentFunction = Function(term.functionHandle, phase.nStates, ...
        FunctionType.nonlinear, EvaluationDomain.path, ...
        OperatorType.none, varSizes, collocatedTimeIdxs);
    raptor.api.v1.elements.build_jacobians(currentFunction, term, corePhase, trajectories, phase);

    % append it to the core phase dynamics
    corePhase.dynamics = [corePhase.dynamics currentFunction];
end

% instantiate the descriptor for the state derivative
stateDer = Function(@(inputData) - inputData.states, corePhase.nStates, ...
    FunctionType.linear, EvaluationDomain.path, OperatorType.differentiation, ...
    varSizes, discretizedTimeIdxs);
stateDer.jacobianPattern.states = eye(corePhase.nStates);
stateDer.jacobianValue.states = - eye(corePhase.nStates);
stateDer = corePhase.collocation.applyDifferentiationWrapper(stateDer, corePhase, trajectories, postProcessing);

% assemble the dynamics constraint descriptor
dynamicsFunctions = num2cell(corePhase.dynamics);
dynamicsFunctions{end + 1} = stateDer;
corePhase.constraints = [corePhase.constraints Constraint("ResidualsDynamics", ...
    dynamicsFunctions, corePhase.nStates, OutputNodes.collocated, ...
    - ones(corePhase.nStates, 1) * corePhase.collocation.dyn_tol, ...
    ones(corePhase.nStates, 1) * corePhase.collocation.dyn_tol, corePhase.collocation)];

% assign the metadata regarding the dynamics residuals
postProcessing.variableMetadata(phase.idx).auxdata.constraints.ResidualsDynamics = ["ResidualsDynamics", "-", "res"];

% loop over all differential constraints
constraintNames = string(properties(phase.constraints.differential));
if ~isempty(constraintNames)
    for name = constraintNames'

        % get the current constraint
        constraint = phase.constraints.differential.(name);
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
                    OperatorType.differentiation, varSizes, discretizedTimeIdxs);
                raptor.api.v1.elements.build_jacobians(coreFunction, term, corePhase, trajectories, phase);

                % apply the differentiation operator and append the
                % function descriptor to the full list
                coreFunction = corePhase.collocation.applyDifferentiationWrapper(coreFunction, corePhase, trajectories, postProcessing);
                coreFunction.functionType = FunctionType.nonlinear;
                functionDescriptors{end + 1} = coreFunction;
            end

            % instantiate the differential constraint in physical time
            coreConstraint = Constraint(name, functionDescriptors, outputSize, ...
                OutputNodes.collocated, constraint.lowerBound, ...
                constraint.upperBound, corePhase.collocation);
            coreConstraint.divideByTimeDilation = true;
            corePhase.constraints = [corePhase.constraints coreConstraint];

            % store the differential constraint metadata in the auxdata
            % structure
            postProcessing.variableMetadata(phase.idx).auxdata.constraints.(name) = ...
                [name phase.constraints.differential.(name).unit ...
                phase.constraints.differential.(name).label];
        end

    end
end

