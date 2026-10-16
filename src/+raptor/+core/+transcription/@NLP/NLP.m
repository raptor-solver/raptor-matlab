classdef NLP < raptor.core.abstract.Transcription
    % Concrete implementation of the transcription class for problems to
    % NLP form

    properties (SetAccess = protected, GetAccess = public)
        % TODO: check whether there are properties to add here
    end

    methods
        function obj = NLP(cfg)
            % superclass constructor
            if nargin == 0
                super_args = {};
            else
                super_args = {cfg};
            end
            obj@raptor.core.abstract.Transcription(super_args{:});
        end

        function build(obj, ocp, trajectories)
            % function that builds the NLP transcription object

            % superclass method
            build@raptor.core.abstract.Transcription(obj, ocp, trajectories);

            %% NOTE: this is a temporary fix and should be removed once the building process is cleaned up
            % update the auxdata values
            obj.ocp.auxdata = trajectories.initialGuess.auxdata;

            % initialize all constraints
            Z0 = obj.getGlobalVariable(trajectories.initialGuess);
            for phase = obj.ocp.phases
                inputData = obj.assembleInputData(Z0, [phase.idx phase.idx]);
                for con = phase.constraints
                    con.initialize(inputData);
                end
                phase.cost.initialize(inputData);
            end
            for linkage = obj.ocp.linkageConditions
                inputData = obj.assembleInputData(Z0, linkage.phaseIdxs);
                linkage.initialize(inputData);
            end

            % initialize the jacobian pattern
            obj.pattern = zeros(obj.con_idx(1).totalConstraints, obj.var_idx(1).totalVariables);
            obj.pattern = obj.getPattern(obj.getGlobalVariable(trajectories.initialGuess));

            % check for any undefined controls to be extrapolated later on
            obj.checkUndefinedControls();

            % assemble the linear NLP portions
            obj.jacobian = zeros(obj.con_idx(1).totalConstraints, obj.var_idx(1).totalVariables);
            obj.gradient = zeros(1, obj.var_idx(1).totalVariables);
            obj.buildLinearTerms(trajectories);

            % % compute a "dummy" jacobian 
            % dummyJac = full(obj.getJacobian(obj.getGlobalVariable(trajectories.initialGuess)));
            % checkJac = full(obj.jacobianCheck(obj.getGlobalVariable(trajectories.initialGuess)));
            % dif = dummyJac - checkJac; 
            % if any(dif > 1e-3)
            %     error("TODO: implement error message for jacobian mismatch");
            % end

            % % compute a dummy gradient dummyGrad =
            % obj.getGradient(obj.getGlobalVariable(trajectories.initialGuess));
            % gradCheck =
            % obj.gradientCheck(obj.getGlobalVariable(trajectories.initialGuess));
            % dif = dummyGrad - gradCheck;

            % compute the pattern from the dummy jacobian obj.pattern =
            % obj.getPattern(obj.getGlobalVariable(trajectories.initialGuess));
            % checkPatt = sparse(dummyJac ~= 0); dif =
            % full(logical(obj.pattern) - logical(checkPatt));
        end

        % defined in external files
        buildConstraintIndexing(obj, ocp)
        bound = getConstraintBounds(obj, ocp, whichBound)
        checkUndefinedControls(obj)

        % initialization methods
        pattern = buildJacobianPattern(obj)
        buildLinearTerms(obj, trajectories)

        % solver interfacing functions
        c = getObjective(obj, Z)
        f = getConstraint(obj, Z)
        g = getGradient(obj, Z)
        Jac = getJacobian(obj, Z)
        patt = getPattern(obj, Z)

    end
end

