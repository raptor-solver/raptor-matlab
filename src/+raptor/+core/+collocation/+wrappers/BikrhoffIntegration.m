classdef BikrhoffIntegration < raptor.core.problem.descriptors.Function
    %BIKRHOFFINTEGRATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected, GetAccess = public)
        % function definition
        baseFunction

        % required pseudospectral operators
        B
    end
    
    methods
        function obj = BikrhoffIntegration(baseFunction, B)
            % constructor
            import raptor.core.enumerations.*

            % check for valid base function
            if baseFunction.evaluationDomain ~= EvaluationDomain.path
                raptor.core.utils.Logger.err_operatorRequiresPathFunction("Birkhoff integration", baseFunction);
            end

            % assign base function properties
            insideBaseFunction = raptor.core.problem.descriptors.Function(baseFunction);
            obj.evaluationDomain = EvaluationDomain.path;
            obj.functionType = insideBaseFunction.functionType;
            obj.operatorType = OperatorType.none;
            obj.outputDim = insideBaseFunction.outputDim;
            obj.timeIdxs = insideBaseFunction.timeIdxs;
            obj.variableSizes = insideBaseFunction.variableSizes;

            % assign wrapper specific quantities
            obj.baseFunction = insideBaseFunction;
            obj.B = B;
        end
        
        function fVal = evaluateFunction(obj, inputData)
            % method that evaluates the base function and returns its
            % birkhoff integral
            fVal = obj.baseFunction.evaluateFunction(inputData) * obj.B';
        end

        function jPatt = evaluatePattern(obj, timeDilation)
            % method that evaluates the pattern of the base function and
            % expands it to account for the integration operator
            if nargin < 2, timeDilation = []; end
            jPatt = obj.baseFunction.evaluatePattern(timeDilation);

            % apply the integration matrix in the form of a logical
            % mask
            logicalB = logical(obj.B);
            if isfield(jPatt, 'states')
                jPatt.states = kron(logicalB, eye(obj.baseFunction.outputDim)) * jPatt.states;
            end
            if isfield(jPatt, 'controls')
                jPatt.controls = kron(logicalB, eye(obj.baseFunction.outputDim)) * jPatt.controls;
            end
            if isfield(jPatt, 'localParameters')
                jPatt.localParameters = kron(logicalB, eye(obj.baseFunction.outputDim)) * jPatt.localParameters;
            end
            if isfield(jPatt, 'globalParameters')
                jPatt.globalParameters = kron(logicalB, eye(obj.baseFunction.outputDim)) * jPatt.globalParameters;
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
                jVal.states = kron(obj.B, eye(obj.baseFunction.outputDim)) * jVal.states;
            end
            if isfield(jVal, 'controls')
                jVal.controls = kron(obj.B, eye(obj.baseFunction.outputDim)) * jVal.controls;
            end
            if isfield(jVal, 'localParameters')
                jVal.localParameters = kron(obj.B, eye(obj.baseFunction.outputDim)) * jVal.localParameters;
            end
            if isfield(jVal, 'globalParameters')
                jVal.globalParameters = kron(obj.B, eye(obj.baseFunction.outputDim)) * jVal.globalParameters;
            end

            %% TODO: check whether there should also be expansions to other variables

        end
    end
end

