classdef BirkhoffBoundaryPlus < raptor.core.problem.descriptors.Function
    %BIRKHOFFBOUNDARYPLUS Summary of this class goes here
    %   Detailed explanation goes here

    properties (SetAccess = protected, GetAccess = public)
        % function definition
        baseFunction
    end

    methods
        function obj = BirkhoffBoundaryPlus(baseFunction, boundaryNode)
            % constructor
            import raptor.core.enumerations.*

            % check for valid base function
            if baseFunction.evaluationDomain ~= EvaluationDomain.path
                raptor.core.utils.Logger.err_operatorRequiresPathFunction("Birkhoff final boundary", baseFunction);
            end

            % assign base function properties
            insideBaseFunction = raptor.core.problem.descriptors.Function(baseFunction);
            obj.evaluationDomain = EvaluationDomain.path;
            obj.functionType = insideBaseFunction.functionType;
            obj.operatorType = OperatorType.none;
            obj.outputDim = insideBaseFunction.outputDim;
            obj.timeIdxs = boundaryNode;
            insideBaseFunction.timeIdxs = boundaryNode;
            obj.variableSizes = insideBaseFunction.variableSizes;

            % assign wrapper specific quantities
            obj.baseFunction = insideBaseFunction;
        end

        function fVal = evaluateFunction(obj, inputData)
            % method that evaluates the base function and returns its
            % birkhoff integral
            fVal = obj.baseFunction.evaluateFunction(inputData);
        end

        function jPatt = evaluatePattern(obj, timeDilation)
            % method that evaluates the pattern of the base function and
            % expands it to account for the integration operator
            if nargin < 2, timeDilation = []; end
            jPatt = obj.baseFunction.evaluatePattern(timeDilation);
        end

        function jVal = evaluateJacobian(obj, inputData, timeDilation)
            % method that evaluates the pattern of the base function and
            % expands it to account for the integration operator
            jVal = obj.baseFunction.evaluateJacobian(inputData, timeDilation);
        end

        % function jPatt = evaluatePattern(obj)
        %     % method that evaluates the pattern of the base function and
        %     % expands it to account for the integration operator
        %     jPatt = obj.baseFunction.evaluatePattern();
        %
        %     % apply the pattern to the correct time node
        %     if isfield(jPatt, 'states')
        %         singlePatt = jPatt.states;
        %         whichTime = obj.baseFunction.timeIdxs;
        %         nStates = obj.variableSizes.states;
        %         jPatt.states = zeros(obj.outputDim * length(obj.timeIdxs), nStates * length(obj.timeIdxs));
        %         jPatt.states(:, (whichTime - 1) * nStates + (1 : nStates)) = repmat(singlePatt, length(obj.timeIdxs), 1);
        %     end
        %     if isfield(jPatt, 'controls')
        %         singlePatt = jPatt.controls;
        %         whichTime = obj.baseFunction.timeIdxs;
        %         nControls = obj.variableSizes.controls;
        %         jPatt.controls = zeros(obj.outputDim * length(obj.timeIdxs), nControls * length(obj.timeIdxs));
        %         jPatt.controls(:, (whichTime - 1) * nControls + (1 : nControls)) = repmat(singlePatt, length(obj.timeIdxs), 1);
        %     end
        %     if isfield(jPatt, 'localParameters')
        %         jPatt.localParameters = repmat(jPatt.localParameters, length(obj.timeIdxs), 1);
        %     end
        %     if isfield(jPatt, 'globalParameters')
        %         jPatt.globalParameters = repmat(jPatt.globalParameters, length(obj.timeIdxs), 1);
        %     end
        % end
    end
end

