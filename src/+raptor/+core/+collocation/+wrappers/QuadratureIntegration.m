classdef QuadratureIntegration < raptor.core.problem.descriptors.Function
    %QUADRATUREINTEGRATION Physical-time quadrature wrapper.

    properties (SetAccess = protected, GetAccess = public)
        baseFunction
        w
        timeDilation
    end

    methods
        function obj = QuadratureIntegration(baseFunction, w, timeDilation)
            import raptor.core.enumerations.*

            if baseFunction.evaluationDomain ~= EvaluationDomain.path
                error('raptor:QuadratureIntegration:InvalidDomain', ...
                    'An integrated function must be defined on the path domain.');
            end

            obj.evaluationDomain = EvaluationDomain.path;
            obj.functionType = FunctionType.nonlinear;
            obj.operatorType = OperatorType.integration;
            obj.outputDim = baseFunction.outputDim;
            obj.timeIdxs = baseFunction.timeIdxs;
            obj.baseFunction = baseFunction;
            obj.w = w;
            obj.timeDilation = timeDilation;
        end

        function fVal = evaluateFunction(obj, inputData)
            dilation = obj.timeDilation.evaluateFunction(inputData);
            fVal = (obj.baseFunction.evaluateFunction(inputData) .* dilation) * obj.w;
        end

        function jPatt = evaluatePattern(obj, timeDilation)
            if nargin < 2
                timeDilation = obj.timeDilation;
            end

            jPatt = obj.baseFunction.evaluatePattern(timeDilation);
            nColl = length(obj.timeIdxs);
            integrationPattern = logical(kron(true(1, nColl), eye(obj.outputDim)));

            fields = {'states', 'controls', 'localParameters', ...
                'upstreamParameters', 'globalParameters', 'initialTime', ...
                'finalTime', 'initialStates', 'finalStates', ...
                'initialControls', 'finalControls'};
            for ff = 1:numel(fields)
                field = fields{ff};
                if isfield(jPatt, field)
                    jPatt.(field) = logical(integrationPattern * logical(jPatt.(field)));
                end
            end

            % Product-rule dependencies introduced by dt/dtau.
            pattern = obj.timeDilation.dTdTauPattern;
            jPatt = obj.addPattern(jPatt, 'initialTime', ...
                repmat(any(pattern.initialTime), obj.outputDim, 1));
            jPatt = obj.addPattern(jPatt, 'finalTime', ...
                repmat(any(pattern.finalTime), obj.outputDim, 1));

            nParameters = obj.baseFunction.variableSizes.localParameters;
            localPattern = obj.expandPattern(pattern.localParameters, nParameters);
            if ~isempty(localPattern)
                jPatt = obj.addPattern(jPatt, 'localParameters', ...
                    repmat(localPattern, obj.outputDim, 1));
            end
        end

        function jVal = evaluateJacobian(obj, inputData, timeDilation)
            % Apply the quadrature weights to every point-wise derivative,
            % then add the product-rule derivative of dt/dtau.
            jVal = obj.baseFunction.evaluateJacobian(inputData, timeDilation);
            fVal = obj.baseFunction.evaluateFunction(inputData);

            dilation = obj.timeDilation.evaluateFunction(inputData);
            correctedWeights = dilation(:) .* obj.w(:);
            integrationMatrix = kron(correctedWeights', eye(obj.outputDim));

            fields = {'states', 'controls', 'localParameters', ...
                'upstreamParameters', 'globalParameters', 'initialTime', ...
                'finalTime', 'initialStates', 'finalStates', ...
                'initialControls', 'finalControls'};
            for ff = 1:numel(fields)
                field = fields{ff};
                if isfield(jVal, field)
                    jVal.(field) = integrationMatrix * jVal.(field);
                end
            end

            dilationJacobian = obj.timeDilation.evaluateJacobian(inputData);
            dilationWeights = obj.w(:);
            jVal = obj.addValue(jVal, 'initialTime', ...
                fVal * (dilationJacobian.initialTime .* dilationWeights));
            jVal = obj.addValue(jVal, 'finalTime', ...
                fVal * (dilationJacobian.finalTime .* dilationWeights));
            if ~isempty(dilationJacobian.localParameters)
                jVal = obj.addValue(jVal, 'localParameters', ...
                    fVal * (dilationJacobian.localParameters .* dilationWeights));
            end
        end
    end

    methods(Static, Access = private)
        function structure = addPattern(structure, field, value)
            if isempty(value)
                return
            end
            if isfield(structure, field)
                structure.(field) = logical(structure.(field)) | logical(value);
            else
                structure.(field) = logical(value);
            end
        end

        function structure = addValue(structure, field, value)
            if isempty(value)
                return
            end
            if isfield(structure, field)
                structure.(field) = structure.(field) + value;
            else
                structure.(field) = value;
            end
        end

        function pattern = expandPattern(pattern, nVariables)
            if nVariables == 0 || isempty(pattern)
                pattern = false(1, nVariables);
            elseif isscalar(pattern)
                pattern = repmat(logical(pattern), 1, nVariables);
            elseif numel(pattern) ~= nVariables
                error('raptor:TimeDilation:InvalidPattern', ...
                    ['JacobianPattern.localParameters must contain one ' ...
                    'entry per phase-local parameter.']);
            else
                pattern = logical(reshape(pattern, 1, []));
            end
        end
    end
end
