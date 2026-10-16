classdef QuadratureBirkhoffIntegration < raptor.core.problem.descriptors.Function
    %QUADRATUREINTEGRATION Summary of this class goes here
    %   Detailed explanation goes here

    properties (SetAccess = protected, GetAccess = public)
        % function definition
        baseFunction

        % required pseudospectral operators
        w
    end

    methods
        function obj = QuadratureBirkhoffIntegration(baseFunction, w)
            % constructor
            import raptor.core.enumerations.*

            % check for valid base function
            if baseFunction.evaluationDomain ~= EvaluationDomain.path
                raptor.core.utils.Logger.err_operatorRequiresPathFunction("quadrature integration", baseFunction);
            end

            % assign base function properties
            obj.evaluationDomain = EvaluationDomain.path;
            obj.functionType = baseFunction.functionType;
            obj.operatorType = OperatorType.integration;
            obj.outputDim = baseFunction.outputDim;
            obj.timeIdxs = baseFunction.timeIdxs;

            % assign wrapper specific quantities
            obj.baseFunction = baseFunction;
            obj.w = w;
        end

        function fVal = evaluateFunction(obj, inputData)
            % method that evaluates the base function and returns its
            % integral value
            fVal = obj.baseFunction.evaluateFunction(inputData) * obj.w;
        end

        function jPatt = evaluatePattern(obj, timeDilation)
            % method that evaluates the pattern of the base function and
            % expands it to account for the integration operator

            % evaluate the pattern of the base function
            if nargin < 2, timeDilation = []; end
            jPatt = obj.baseFunction.evaluatePattern(timeDilation);
            nColl = length(obj.timeIdxs);

            % apply the integration pattern to the collocated quantities
            if isfield(jPatt, 'states')
                jTmp = reshape(jPatt.states, obj.outputDim, nColl, []);
                jPatt.states = squeeze(sum(jTmp, 2));
                jPatt.states = reshape(jPatt.states, obj.outputDim, []);
            end
            if isfield(jPatt, 'controls')
                jTmp = reshape(jPatt.controls, obj.outputDim, nColl, []);
                jPatt.controls = squeeze(sum(jTmp, 2));
                jPatt.controls = reshape(jPatt.controls, obj.outputDim, []);
            end
            if isfield(jPatt, 'localParameters')
                jTmp = reshape(jPatt.localParameters, obj.outputDim, nColl, []);
                jPatt.localParameters = squeeze(sum(jTmp, 2));
            end
            if isfield(jPatt, 'globalParameters')
                jTmp = reshape(jPatt.globalParameters, obj.outputDim, nColl, []);
                jPatt.globalParameters = squeeze(sum(jTmp, 2));
            end
        end

        function jVal = evaluateJacobian(obj, inputData, timeDilation)
            % method that evaluates the base function jacobian and
            % integrates it

            % evaluate the value and jacobian of the base function
            jVal = obj.baseFunction.evaluateJacobian(inputData, timeDilation);
            fVal = obj.baseFunction.evaluateFunction(inputData);

            % compute the "corrected" weights
            wcorr = obj.w;

            % apply the quadrature weights to the collocated quantities
            if isfield(jVal, 'states')
                tmpJ = kron(diag(wcorr), eye(obj.baseFunction.outputDim)) * jVal.states;
                tmpJ = reshape(tmpJ, obj.baseFunction.outputDim, [], size(tmpJ, 2));
                jVal.states = reshape(sum(tmpJ, 2), obj.baseFunction.outputDim, []);
            end
            if isfield(jVal, 'controls')
                tmpJ = kron(diag(wcorr), eye(obj.baseFunction.outputDim)) * jVal.controls;
                tmpJ = reshape(tmpJ, obj.baseFunction.outputDim, [], size(tmpJ, 2));
                jVal.controls = reshape(sum(tmpJ, 2), obj.baseFunction.outputDim, []);
            end
            if isfield(jVal, 'localParameters')
                tmpJ = jVal.localParameters;
                tmpJ = reshape(tmpJ, obj.baseFunction.outputDim, [], size(tmpJ, 2));
                jVal.localParameters = reshape(sum(tmpJ, 2), obj.baseFunction.outputDim, []);
            end
            if isfield(jVal, 'globalParameters')
                tmpJ = jVal.globalParameters;
                tmpJ = reshape(tmpJ, obj.baseFunction.outputDim, [], size(tmpJ, 2));
                jVal.localParameters = reshape(sum(tmpJ, 2), obj.baseFunction.outputDim, []);
            end

        end
    end
end
