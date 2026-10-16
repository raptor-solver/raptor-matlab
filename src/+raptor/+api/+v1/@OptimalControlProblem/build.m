function [coreOcp, trajectories, postProcessing] = build(obj)
% method that fully builds the core representation of the optimal control
% problem
import raptor.core.problem.descriptors.*
import raptor.core.enumerations.*

% build the core optimal control problem
coreOcp = raptor.core.problem.OptimalControlProblem();
coreOcp.auxdata = obj.auxdata;
coreOcp.nPhases = length(obj.phases);
coreOcp.nGlobalParameters = obj.nGlobalParameters;

% build the trajectories, postprocessing, and phases objects
trajectories = raptor.core.problem.Trajectories();
postProcessing = raptor.core.postprocessing.PostProcessing();
for pp = 1 :  coreOcp.nPhases
    coreOcp.phases(pp) = obj.phases(pp).build(trajectories, obj, postProcessing);
end

% loop over all linkage conditions
constraintNames = string(properties(obj.linkage));
if ~isempty(constraintNames)
    for name = constraintNames'

        % get the current constraint
        constraint = obj.linkage.(name);
        outputSize = size(constraint.lowerBound, 1);

        % set the varsizes objects associated with the linked phases
        phase1 = constraint.phase1; phase2 = constraint.phase2;
        varSizes(1) = VariableSizes(coreOcp.phases(phase1.idx).collocation.n_disc, phase1.nStates, ...
            phase1.nControls, phase1.nLocalParameters, phase1.nGlobalParameters);
        varSizes(2) = VariableSizes(coreOcp.phases(phase2.idx).collocation.n_disc, phase2.nStates, ...
            phase2.nControls, phase2.nLocalParameters, phase2.nGlobalParameters);

        % only transcribe the constraint if it is bounded
        if any(isfinite(constraint.lowerBound), "all") || ...
                any(isfinite(constraint.upperBound), "all")

            % loop over all constraint terms
            functionDescriptors = {};
            for term = constraint.terms

                % instantiate the corresponding function descriptor
                coreFunction = Function(term.functionHandle, outputSize, ...
                    FunctionType.(term.functionType), EvaluationDomain.boundary, ...
                    OperatorType.none, varSizes, 1);
                raptor.api.v1.elements.build_jacobians(coreFunction, term, coreOcp.phases(phase1.idx), trajectories, phase1, phase2);

                % append the function descriptor to the full list
                functionDescriptors{end + 1} = coreFunction;
            end

            % instantiate the constraint descriptor and append it
            coreConstraint = Constraint(name, functionDescriptors, outputSize, ...
                OutputNodes.single, constraint.lowerBound, ...
                constraint.upperBound, coreOcp.phases(phase1.idx).collocation, ...
                [phase1.idx phase2.idx]);
            coreOcp.linkageConditions = [coreOcp.linkageConditions coreConstraint];
        end
    end
end

end

