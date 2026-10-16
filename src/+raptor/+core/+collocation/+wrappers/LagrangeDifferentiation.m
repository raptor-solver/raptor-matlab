classdef LagrangeDifferentiation < raptor.core.problem.descriptors.Function
    %LAGRANGEDIFFERENTIATION Summary of this class goes here
    %   Detailed explanation goes here

    properties (SetAccess = protected, GetAccess = public)
        % function definition
        baseFunction

        % required pseudospectral operators
        D
    end

    methods
        function obj = LagrangeDifferentiation(baseFunction, D)
            % constructor
            import raptor.core.enumerations.*

            % check for valid base function
            if baseFunction.evaluationDomain ~= EvaluationDomain.path
                raptor.core.utils.Logger.err_operatorRequiresPathFunction("Lagrange differentiation", baseFunction);
            end

            % assign base function properties
            obj.evaluationDomain = EvaluationDomain.path;
            obj.functionType = baseFunction.functionType;
            obj.operatorType = OperatorType.differentiation;
            obj.outputDim = baseFunction.outputDim;
            obj.timeIdxs = baseFunction.timeIdxs;
            obj.variableSizes = baseFunction.variableSizes;

            % assign wrapper specific quantities
            obj.baseFunction = baseFunction;
            obj.D = D;
        end

        function fVal = evaluateFunction(obj, inputData)
            % method that evaluates the base function and returns its
            % derivative value
            fVal = obj.baseFunction.evaluateFunction(inputData) * obj.D';
        end

        function jPatt = evaluatePattern(obj, timeDilation)
            % method that evaluates the pattern of the base function and
            % expands it to account for the differentiation operator
            if nargin < 2, timeDilation = []; end
            jPatt = obj.baseFunction.evaluatePattern(timeDilation);

            % apply the differentiation matrix in the form of a logical
            % mask
            logicalD = logical(obj.D);
            if isfield(jPatt, 'states')
                jPatt.states = kron(logicalD, eye(obj.baseFunction.outputDim)) * jPatt.states;
            end
            if isfield(jPatt, 'controls')
                jPatt.controls = kron(logicalD, eye(obj.baseFunction.outputDim)) * jPatt.controls;
            end
            if isfield(jPatt, 'localParameters')
                jPatt.localParameters = kron(logicalD, eye(obj.baseFunction.outputDim)) * jPatt.localParameters;
            end
            if isfield(jPatt, 'globalParameters')
                jPatt.globalParameters = kron(logicalD, eye(obj.baseFunction.outputDim)) * jPatt.globalParameters;
            end
        end

        function jVal = evaluateJacobian(obj, inputData, timeDilation)
            % method that evaluates the jacobian of the base function and
            % computes its derivative

            % evaluate the jacobian of the base function
            jVal = obj.baseFunction.evaluateJacobian(inputData, timeDilation);

            % apply the differentiation matrix to the discretized
            % quantities
            if isfield(jVal, 'states')
                jVal.states = kron(obj.D, eye(obj.baseFunction.outputDim)) * jVal.states;
            end
            if isfield(jVal, 'controls')
                jVal.controls = kron(obj.D, eye(obj.baseFunction.outputDim)) * jVal.controls;
            end
            if isfield(jVal, 'localParameters')
                jVal.localParameters = kron(obj.D, eye(obj.baseFunction.outputDim)) * jVal.localParameters;
            end
            if isfield(jVal, 'globalParameters')
                jVal.globalParameters = kron(obj.D, eye(obj.baseFunction.outputDim)) * jVal.globalParameters;
            end

            %% TODO: check whether there should also be expansions to other variables

        end
    end
end
