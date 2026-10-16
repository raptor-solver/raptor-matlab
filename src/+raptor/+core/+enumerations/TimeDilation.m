classdef TimeDilation < handle
    %TIMEDILATION Mapping between pseudotime and physical time.
    %
    % A custom mapping is most conveniently created through custom(). The
    % two required functions receive the phase input-data structure and a
    % row vector of pseudotime nodes:
    %
    %   mapping  = @(inputData, tau) ...; % t(tau)
    %   dilation = @(inputData, tau) ...; % dt/dtau
    %
    % Derivatives of dt/dtau are evaluated with complex-step differences
    % unless an analytical DilationJacobian function is supplied.

    properties
        % time mapping features
        tau2tFcn               function_handle
        dTdTauFcn              function_handle
        dTdTauJacobianFcn
        timeMapPattern         struct

        % legacy, component-wise dilation Jacobian functions
        d_dt0Fcn               function_handle
        d_dtfFcn               function_handle
        d_dlpFcn               function_handle
        dTdTauPattern          struct

        % pseudotime nodes
        tau_coll
        tau_disc

        % hp segment of each pseudotime node
        seg_coll
        seg_disc
    end

    methods
        function obj = TimeDilation(tau2tFcn, dTdTauFcn, dTdTauPattern, d_dt0Fcn, d_dtfFcn, d_dlpFcn)
            % Constructor retained for compatibility with existing code.
            obj.tau2tFcn = tau2tFcn;
            obj.dTdTauFcn = dTdTauFcn;
            obj.dTdTauPattern = raptor.core.enumerations.TimeDilation.completePattern(dTdTauPattern);
            obj.timeMapPattern = obj.dTdTauPattern;
            obj.d_dt0Fcn = d_dt0Fcn;
            obj.d_dtfFcn = d_dtfFcn;
            obj.d_dlpFcn = d_dlpFcn;
            obj.dTdTauJacobianFcn = [];
        end

        function copiedObject = copy(obj)
            % Return an independent object so different phases do not
            % overwrite one another's pseudotime nodes.
            copiedObject = raptor.core.enumerations.TimeDilation( ...
                obj.tau2tFcn, obj.dTdTauFcn, obj.dTdTauPattern, ...
                obj.d_dt0Fcn, obj.d_dtfFcn, obj.d_dlpFcn);
            copiedObject.dTdTauJacobianFcn = obj.dTdTauJacobianFcn;
            copiedObject.timeMapPattern = obj.timeMapPattern;
        end

        function setPseudoTimeNodes(obj, tau_coll, tau_disc, seg_coll, seg_disc)
            % Set the pseudotime nodes defined by the collocation object,
            % together with the hp segment each node belongs to (a single
            % segment when not specified).
            if nargin < 4
                seg_coll = ones(size(tau_coll));
                seg_disc = ones(size(tau_disc));
            end
            obj.tau_coll = reshape(tau_coll, 1, []);
            obj.tau_disc = reshape(tau_disc, 1, []);
            obj.seg_coll = reshape(seg_coll, 1, []);
            obj.seg_disc = reshape(seg_disc, 1, []);
        end

        function t = mapDiscretizedTime(obj, inputData)
            % Map the discretized pseudotime nodes to physical time. Each
            % hp segment is mapped between its own time extremes.
            t = zeros(1, numel(obj.tau_disc));
            for k = 1 : max(obj.seg_disc)
                idxs = obj.seg_disc == k;
                t(idxs) = obj.asRow(obj.tau2tFcn(obj.segmentInputData(inputData, k), ...
                    obj.tau_disc(idxs)), nnz(idxs), 'time mapping');
            end
        end

        function dTdTau = evaluateFunction(obj, inputData)
            % Evaluate dt/dtau on the collocation nodes. Each hp segment is
            % evaluated between its own time extremes.
            dTdTau = zeros(1, numel(obj.tau_coll));
            for k = 1 : max(obj.seg_coll)
                idxs = obj.seg_coll == k;
                dTdTau(idxs) = obj.asRow(obj.dTdTauFcn(obj.segmentInputData(inputData, k), ...
                    obj.tau_coll(idxs)), nnz(idxs), 'time dilation');
            end
        end

        function dTdTauJacobian = evaluateJacobian(obj, inputData)
            % Evaluate the Jacobian of dt/dtau on collocation nodes. Each
            % field is returned as nCollocationNodes-by-nVariables. The
            % Jacobian of each hp segment is evaluated with respect to its
            % own time extremes, and then mapped to the phase extremes.
            nNodes = numel(obj.tau_coll);
            nSegments = max(obj.seg_coll);
            dTdTauJacobian.initialTime = zeros(nNodes, 1);
            dTdTauJacobian.finalTime = zeros(nNodes, 1);
            dTdTauJacobian.localParameters = zeros(nNodes, numel(inputData.localParameters));
            for k = 1 : nSegments
                idxs = obj.seg_coll == k;
                segmentData = obj.segmentInputData(inputData, k);
                if ~isempty(obj.dTdTauJacobianFcn)
                    jacobian = obj.dTdTauJacobianFcn(segmentData, obj.tau_coll(idxs));
                else
                    jacobian.initialTime = obj.d_dt0Fcn(segmentData, obj.tau_coll(idxs));
                    jacobian.finalTime = obj.d_dtfFcn(segmentData, obj.tau_coll(idxs));
                    jacobian.localParameters = obj.d_dlpFcn(segmentData, obj.tau_coll(idxs));
                end
                jacobian = obj.normalizeJacobian(jacobian, segmentData, nnz(idxs));

                % the segment extremes are a linear combination of the
                % phase extremes
                a = (k - 1) / nSegments;
                b = k / nSegments;
                dTdTauJacobian.initialTime(idxs) = (1 - a) * jacobian.initialTime + (1 - b) * jacobian.finalTime;
                dTdTauJacobian.finalTime(idxs) = a * jacobian.initialTime + b * jacobian.finalTime;
                dTdTauJacobian.localParameters(idxs, :) = jacobian.localParameters;
            end

            dTdTauJacobian.globalParameters = [];
            dTdTauJacobian.time = [];
            dTdTauJacobian.states = [];
            dTdTauJacobian.controls = [];
            dTdTauJacobian.initialStates = [];
            dTdTauJacobian.finalStates = [];
            dTdTauJacobian.initialControls = [];
            dTdTauJacobian.finalControls = [];
        end
    end

    methods(Static)
        function obj = affine()
            % Create the standard affine time mapping.
            tau2tFcn = @(inputData, tau) (tau + 1) .* 0.5 .* ...
                (inputData.finalTime - inputData.initialTime) + inputData.initialTime;
            dTdTauFcn = @(inputData, tau) tau .* 0 + 0.5 * ...
                (inputData.finalTime - inputData.initialTime);
            pattern = struct('initialTime', true, 'finalTime', true, ...
                'localParameters', []);
            d_dt0Fcn = @(inputData, tau) tau' .* 0 - 0.5;
            d_dtfFcn = @(inputData, tau) tau' .* 0 + 0.5;
            d_dlpFcn = @(inputData, tau) [];
            obj = raptor.core.enumerations.TimeDilation(tau2tFcn, dTdTauFcn, ...
                pattern, d_dt0Fcn, d_dtfFcn, d_dlpFcn);
        end

        function obj = custom(tau2tFcn, dTdTauFcn, options)
            %CUSTOM Create a user-defined time mapping.
            %
            %   timeDilation = TimeDilation.custom(mapping, dilation)
            %
            % Optional name-value inputs:
            %   DilationJacobian       Function returning a structure with
            %                          initialTime, finalTime, and
            %                          localParameters fields. Derivative
            %                          matrices use nodes-by-variables shape.
            %   JacobianPattern        Dependency pattern for dt/dtau.
            %   TimeMapJacobianPattern Dependency pattern for t(tau). This
            %                          defaults to JacobianPattern.
            arguments
                tau2tFcn (1, 1) function_handle
                dTdTauFcn (1, 1) function_handle
                options.DilationJacobian = []
                options.JacobianPattern struct = struct()
                options.TimeMapJacobianPattern struct = struct()
            end

            pattern = raptor.core.enumerations.TimeDilation.completePattern( ...
                options.JacobianPattern);
            if isempty(fieldnames(options.TimeMapJacobianPattern))
                mapPattern = pattern;
            else
                mapPattern = raptor.core.enumerations.TimeDilation.completePattern( ...
                    options.TimeMapJacobianPattern);
            end

            emptyDerivative = @(inputData, tau) [];
            obj = raptor.core.enumerations.TimeDilation(tau2tFcn, dTdTauFcn, ...
                pattern, emptyDerivative, emptyDerivative, emptyDerivative);
            obj.timeMapPattern = mapPattern;

            if isempty(options.DilationJacobian)
                obj.dTdTauJacobianFcn = @(inputData, tau) ...
                    raptor.core.enumerations.TimeDilation.complexStepJacobian( ...
                    dTdTauFcn, inputData, tau, pattern);
            else
                if ~isa(options.DilationJacobian, 'function_handle')
                    error('raptor:TimeDilation:InvalidJacobian', ...
                        'DilationJacobian must be a function handle.');
                end
                obj.dTdTauJacobianFcn = options.DilationJacobian;
            end
        end
    end

    methods(Static, Access = private)
        function pattern = completePattern(pattern)
            defaults = struct('initialTime', true, 'finalTime', true, ...
                'localParameters', []);
            fields = fieldnames(defaults);
            for ii = 1:numel(fields)
                field = fields{ii};
                if ~isfield(pattern, field)
                    pattern.(field) = defaults.(field);
                end
                pattern.(field) = logical(reshape(pattern.(field), 1, []));
            end
        end

        function jacobian = complexStepJacobian(dilationFcn, inputData, tau, pattern)
            step = 1e-20;
            nNodes = numel(tau);

            jacobian.initialTime = zeros(nNodes, 1);
            if any(pattern.initialTime)
                perturbed = inputData;
                perturbed.initialTime = perturbed.initialTime + 1i * step;
                value = dilationFcn(perturbed, tau);
                jacobian.initialTime = reshape(imag(value) ./ step, [], 1);
            end

            jacobian.finalTime = zeros(nNodes, 1);
            if any(pattern.finalTime)
                perturbed = inputData;
                perturbed.finalTime = perturbed.finalTime + 1i * step;
                value = dilationFcn(perturbed, tau);
                jacobian.finalTime = reshape(imag(value) ./ step, [], 1);
            end

            nParameters = numel(inputData.localParameters);
            dependencyMask = raptor.core.enumerations.TimeDilation.expandPattern( ...
                pattern.localParameters, nParameters);
            jacobian.localParameters = zeros(nNodes, nParameters);
            for pp = find(dependencyMask)
                perturbed = inputData;
                perturbed.localParameters(pp) = ...
                    perturbed.localParameters(pp) + 1i * step;
                value = dilationFcn(perturbed, tau);
                jacobian.localParameters(:, pp) = reshape(imag(value) ./ step, [], 1);
            end
        end

        function pattern = expandPattern(pattern, nVariables)
            if nVariables == 0 || isempty(pattern)
                pattern = false(1, nVariables);
            elseif isscalar(pattern)
                pattern = repmat(logical(pattern), 1, nVariables);
            elseif numel(pattern) ~= nVariables
                error('raptor:TimeDilation:InvalidPattern', ...
                    'The time-mapping pattern must contain one entry per variable.');
            else
                pattern = logical(reshape(pattern, 1, []));
            end
        end
    end

    methods(Access = private)
        function inputData = segmentInputData(obj, inputData, k)
            % Replace the phase time extremes with the ones of the k-th hp
            % segment, the segments splitting the phase in equal intervals.
            nSegments = max(obj.seg_disc);
            if nSegments == 1
                return
            end
            a = (k - 1) / nSegments;
            b = k / nSegments;
            initialTime = inputData.initialTime;
            finalTime = inputData.finalTime;
            inputData.initialTime = (1 - a) * initialTime + a * finalTime;
            inputData.finalTime = (1 - b) * initialTime + b * finalTime;
        end

        function jacobian = normalizeJacobian(~, jacobian, inputData, nNodes)
            nParameters = numel(inputData.localParameters);

            if ~isfield(jacobian, 'initialTime') || isempty(jacobian.initialTime)
                jacobian.initialTime = zeros(nNodes, 1);
            else
                jacobian.initialTime = reshape(jacobian.initialTime, nNodes, 1);
            end
            if ~isfield(jacobian, 'finalTime') || isempty(jacobian.finalTime)
                jacobian.finalTime = zeros(nNodes, 1);
            else
                jacobian.finalTime = reshape(jacobian.finalTime, nNodes, 1);
            end
            if ~isfield(jacobian, 'localParameters') || isempty(jacobian.localParameters)
                jacobian.localParameters = zeros(nNodes, nParameters);
            elseif isequal(size(jacobian.localParameters), [nParameters, nNodes]) && ...
                    nParameters ~= nNodes
                % Accept the orientation used by the original internal API.
                jacobian.localParameters = jacobian.localParameters';
            elseif ~isequal(size(jacobian.localParameters), [nNodes, nParameters])
                error('raptor:TimeDilation:InvalidJacobianSize', ...
                    ['The localParameters dilation Jacobian must have size ' ...
                    'nCollocationNodes-by-nLocalParameters.']);
            end
        end

        function value = asRow(~, value, expectedLength, description)
            if numel(value) ~= expectedLength
                error('raptor:TimeDilation:InvalidOutputSize', ...
                    'The %s must return one value per pseudotime node.', description);
            end
            value = reshape(value, 1, []);
        end
    end
end
