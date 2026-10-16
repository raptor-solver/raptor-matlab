classdef (Abstract) Transcription < handle
    % Abstract transcription class defining the base interface methods for
    % the problem transcription

    properties(SetAccess = public, GetAccess = public)
        % transcription indexing
        var_idx
        con_idx
        undefined_controls

        % pre-computed global quantities for faster internal
        % pre-allocations
        jacobian
        gradient
        pattern

        % jacobian utilities
        numericalDifferentiation

        % problem description
        ocp
    end

    methods
        function obj = Transcription(cfg)
            % class constructor
            if nargin ~= 0
                obj.numericalDifferentiation = raptor.core.transcription.differentiation.(cfg.numericalJacobian)(cfg.finiteStep);
            end
        end

        % defined in external files
        inputData = assembleInputData(obj, Z, phase_idxs)
        Z = getGlobalVariable(obj, trajectories)

        function build(obj, ocp, ~)
            % base implementation of the build function, setting the
            % variable and function indexing properties
            import raptor.core.enumerations.OperatorType

            % set the problem description
            obj.ocp = ocp;

            % set the variable indexing
            obj.buildVariableIndexing();

            % set the constraints indexing
            obj.buildConstraintIndexing();

            % assign the chosen numerical differentiation method to all
            % function descriptors
            for phase = obj.ocp.phases
                for con = phase.constraints
                    for fcn = con.fcnDescriptors
                        if ~isprop(fcn{1}, 'baseFunction')
                            fcn{1}.numericalDifferentiation = obj.numericalDifferentiation;
                        else
                            fcn{1}.baseFunction.numericalDifferentiation = obj.numericalDifferentiation;
                        end
                    end
                end
                for fcn = phase.cost.fcnDescriptors
                    if ~isprop(fcn{1}, 'baseFunction')
                        fcn{1}.numericalDifferentiation = obj.numericalDifferentiation;
                    else
                        fcn{1}.baseFunction.numericalDifferentiation = obj.numericalDifferentiation;
                    end
                end
            end
            for linkage = obj.ocp.linkageConditions
                for fcn = linkage.fcnDescriptors
                    fcn{1}.numericalDifferentiation = obj.numericalDifferentiation;
                end
            end

        end

    end

    methods (Abstract, Access = public)

        % methods to build the function indexing
        buildConstraintIndexing(obj)
        bound = getConstraintBounds(obj, ocp, whichBound)

        % initialization methods
        pattern = buildJacobianPattern(obj)
        buildLinearTerms(obj)

        % functional interface for the solver object (TODO: check if these
        % hold for all solvers or only for NLPs)
        getObjective(obj, Z)
        getGradient(obj, Z)
        getConstraint(obj, Z)
        getJacobian(obj, Z)
        getPattern(obj)
    end

    methods (Access = protected)
        % internal utility methods
        buildVariableIndexing(obj)
    end
end