classdef (Abstract) Birkhoff_a < raptor.core.collocation.interpolants.Lagrange
    % partial implementation of a collocation method based on the 'a'
    % version of the Birkhoff integration matrix

    properties (SetAccess = protected, GetAccess = public)
        B  (:, :) {mustBeNumeric}
        b  (:, 1) {mustBeNumeric}
        nV (1, 1) {mustBeNumeric}
        currentV (1, 1) {mustBeNumeric}
    end

    methods

        function obj = Birkhoff_a(cfg)
            % superclass constructor
            if nargin == 0
                super_args = {};
            else
                super_args = {cfg};
            end
            obj@raptor.core.collocation.interpolants.Lagrange(super_args{:});

        end

    end

    methods (Access = protected)

        function build(obj)
            % function defining the differentiation matrix (after the
            % collocation nodes are defined)

            % compute the differentiation matrix for the Lagrange
            % interpolants
            build@raptor.core.collocation.interpolants.Lagrange(obj);

            % initialize the matrices
            N = obj.n_coll - 1;
            obj.b = ones(N + 1, 1);

            % compute the B = SQ factorization
            S = obj.compute_S_matrix();
            Q = obj.compute_Q_matrix();
            obj.B = S * Q;
        end

        function attachSegments(obj, segments)
            % function that attaches the operators of consecutive segments,
            % where the Birkhoff integration matrix is block diagonal since
            % each segment is integrated from its own initial node
            attachSegments@raptor.core.collocation.interpolants.Lagrange(obj, segments);
            segmentsB = cellfun(@(segment) segment.B, segments, 'UniformOutput', false);
            obj.B = blkdiag(segmentsB{:});
            obj.b = ones(obj.n_coll, 1);
        end

        % internal utilities
        Q = compute_Q_matrix(obj)
        S = compute_S_matrix(obj)

    end

    methods (Access = {?raptor.api.ApiToCoreInterface, ?raptor.core.abstract.Collocation})

        function nExtraControls = getNumberOfExtraControls(obj, phase)
            % function that outputs the number of extra controls required
            % by the collocation technique

            % by default the states are always differentiated
            nExtraControls = phase.nStates;

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

                        nExtraControls = nExtraControls + outputSize;
                    end
                end
            end

            obj.nV = nExtraControls;
        end

        function wrapperFunc = applyDifferentiationWrapper(obj, func, phase, trajectories, postProcessing)
            % function that creates the wrapper for a differentiated
            % function and optionally adjusts the phase descriptor and
            % guess object
            import raptor.core.problem.descriptors.*
            import raptor.core.enumerations.*

            % approximate the state derivative using the differentiation
            % matrix
            [discNodes, collNodes] = obj.getLocalTimeIdxs();
            outputSize = func.outputDim;
            V_guess = zeros(outputSize, length(discNodes));
            V_guess(:, collNodes) = func.fcnHandle(trajectories.initialGuess(phase.idx)) * obj.D';

            % store the indexes of the current virtual controls
            V_idxs = phase.nControls - obj.nV + obj.currentV + (1 : outputSize);
            obj.currentV = obj.currentV + outputSize;

            % inject the initial guess for the Birkhoff virtual controls
            trajectories.initialGuess(phase.idx).controls(V_idxs, :) = V_guess;

            % set also the metadata for Birkhoff's virtual controls
            for ss = 1 : outputSize
                vName(ss, 1) = strcat("BirkhoffV", string(V_idxs(ss) - phase.nControls + obj.nV));
                vLabel(ss, 1) = strcat("$V_", string(V_idxs(ss) - phase.nControls + obj.nV), "$");
            end
            postProcessing.variableMetadata(phase.idx).controls = ...
                [postProcessing.variableMetadata(phase.idx).controls; ...
                [vName repmat("-", outputSize, 1) vLabel]];

            % instantiate the birkhoff interpolation condition X - VB' -
            % xab the function should only be evaluated on the collocated
            % nodes
            func.operatorType = OperatorType.none;
            X = Function(func);
            [discIdxs, collIdxs] = phase.collocation.getLocalTimeIdxs();
            segmentStarts = obj.seg_idxs(:, 1)';
            interpolationRows = true(1, obj.n_coll);
            interpolationOutputNodes = OutputNodes.collocated;
            if collIdxs(1) == discIdxs(1)
                % B(1,:) is identically zero at the anchored initial
                % endpoint of each segment, hence this equation is 0 = 0
                % and must not be passed to the NLP solver.
                interpolationRows = ~ismember(collIdxs, segmentStarts);
                interpolationOutputNodes = OutputNodes.collocatedWithoutInitial;
            end
            interpolationIdxs = collIdxs(interpolationRows);
            interpolationB = obj.B(interpolationRows, :);
            X.timeIdxs = interpolationIdxs;

            % add the birkhoff integration matrix part of the constraint
            minusV = raptor.core.problem.descriptors.Function(@(inputData) - inputData.controls(V_idxs, :), ...
                outputSize, FunctionType.linear, EvaluationDomain.path, ...
                OperatorType.none, func.variableSizes, collIdxs);
            minusV.jacobianValue.controls = zeros(length(V_idxs), phase.nControls);
            minusV.jacobianValue.controls(:, V_idxs) = - eye(length(V_idxs));
            minusV.jacobianPattern.controls = zeros(length(V_idxs), phase.nControls);
            minusV.jacobianPattern.controls(:, V_idxs) = eye(length(V_idxs));
            VB = raptor.core.collocation.wrappers.BikrhoffIntegration(minusV, interpolationB);

            % add the bikhoff b product part of the constraint, where each
            % node uses the initial value of its own segment
            xab = raptor.core.collocation.wrappers.BirkhoffBproduct(func, ...
                segmentStarts(obj.seg_coll(interpolationRows)), interpolationIdxs, discIdxs);

            % compose the full birkhoff interpolation condition constraint
            idxString = strcat(string(V_idxs(1)), "to", string(V_idxs(end)));
            phase.constraints = [phase.constraints Constraint(strcat("BirkhoffAinterpolation", idxString), ...
                {X, VB, xab}, outputSize, interpolationOutputNodes, ...
                zeros(outputSize, 1), zeros(outputSize, 1), phase.collocation)];

            % also attach the metadata related to the interpolation
            % constraint
            postProcessing.variableMetadata(phase.idx).auxdata.constraints.(strcat("BirkhoffAinterpolation", idxString)) = ...
                [strcat("BirkhoffAinterpolation", idxString) "-" ...
                strcat("$\mathbf{X}-\mathbf{V}B^T - x_a\mathbf{b}$ (", idxString, ")")];

            % instantiate the Birkhoff calculus theorem boundary constraint
            % integrate the birkhoff virtual controls
            V = raptor.core.problem.descriptors.Function(@(inputData) inputData.controls(V_idxs, :), ...
                outputSize, FunctionType.linear, EvaluationDomain.path, ...
                OperatorType.none, func.variableSizes, collIdxs);
            V.jacobianValue.controls = zeros(length(V_idxs), phase.nControls);
            V.jacobianValue.controls(:, V_idxs) = eye(length(V_idxs));
            V.jacobianPattern.controls = zeros(length(V_idxs), phase.nControls);
            V.jacobianPattern.controls(:, V_idxs) = eye(length(V_idxs));
            % If the final endpoint is collocated, the last interpolation
            % row is the calculus-theorem equation because B(end,:) = w'.
            % Adding it again makes the equality Jacobian rank deficient.
            if collIdxs(end) ~= discIdxs(end)
                % one calculus theorem constraint is needed for each
                % segment, integrating only the virtual controls of the
                % segment itself
                for k = 1 : obj.n_seg
                    minusVk = Function(minusV);
                    minusVk.timeIdxs = collIdxs(obj.seg_coll == k);
                    Vw = raptor.core.collocation.wrappers.QuadratureBirkhoffIntegration(minusVk, obj.w(obj.seg_coll == k));

                    % instantiate the birkhoff wrappers to get the values of a path
                    % function at specfic boundaries
                    xa = raptor.core.collocation.wrappers.BirkhoffBoundaryMinus(func, obj.seg_idxs(k, 1));
                    xb = raptor.core.collocation.wrappers.BirkhoffBoundaryPlus(func, obj.seg_idxs(k, 2));

                    % instantiate the calculus theorem constraint
                    calculusName = strcat("BirkhoffAcalculus", idxString);
                    if obj.n_seg > 1
                        calculusName = strcat(calculusName, "segment", string(k));
                    end
                    phase.constraints = [phase.constraints Constraint(calculusName, ...
                        {Vw, xa, xb}, outputSize, OutputNodes.single, zeros(outputSize, 1), ...
                        zeros(outputSize, 1), phase.collocation)];

                    % also attach the metadata related to the calculus theorem
                    % constraint
                    postProcessing.variableMetadata(phase.idx).auxdata.constraints.(calculusName) = ...
                        [calculusName "-" ...
                        strcat("$\mathbf{V}w^T - x_a + x_b$ (", idxString, ")")];
                end
            end

            % instantiate the birkhoff controls wrapper
            wrapperFunc = Function(V);
            wrapperFunc.operatorType = OperatorType.differentiation;
        end

    end

end


