classdef BirkhoffBproduct < raptor.core.problem.descriptors.Function
    %BIRKHOFFBPRODUCT Summary of this class goes here
    %   Detailed explanation goes here

    properties (SetAccess = protected, GetAccess = public)
        % function definition
        baseFunction

        % discretized nodes indexes
        outputNodesBypass

        % index of the evaluation node (among the ones of the base
        % function) used by each output node
        funcNodesMap
    end

    methods
        function obj = BirkhoffBproduct(baseFunction, funcNodes, collocationNodes, discretizationNodes)
            % constructor, where funcNodes specifies for each of the
            % collocation nodes the node the base function is evaluated at
            import raptor.core.enumerations.*

            % check for valid base function
            if baseFunction.evaluationDomain ~= EvaluationDomain.path
                raptor.core.utils.Logger.err_operatorRequiresPathFunction("Birkhoff B-matrix product", baseFunction);
            end

            % assign base function properties
            insideBaseFunction = raptor.core.problem.descriptors.Function(baseFunction);
            obj.evaluationDomain = EvaluationDomain.path;
            obj.functionType = insideBaseFunction.functionType;
            obj.operatorType = OperatorType.none;
            obj.outputDim = insideBaseFunction.outputDim;
            obj.timeIdxs = collocationNodes;
            [funcNodes, ~, funcNodesMap] = unique(funcNodes);
            insideBaseFunction.timeIdxs = reshape(funcNodes, 1, []);
            obj.variableSizes = insideBaseFunction.variableSizes;

            % assign wrapper specific quantities
            obj.baseFunction = insideBaseFunction;
            obj.outputNodesBypass = discretizationNodes;
            obj.funcNodesMap = reshape(funcNodesMap, 1, []);
        end

        function fVal = evaluateFunction(obj, inputData)
            % method that evaluates the base function and returns its
            % birkhoff integral
            fVal = obj.baseFunction.evaluateFunction(inputData);
            fVal = - fVal(:, obj.funcNodesMap);
        end

        function jPatt = evaluatePattern(obj, timeDilation)
            % method that evaluates the pattern of the base function and
            % expands it to account for the integration operator
            if nargin < 2, timeDilation = []; end
            jPatt = obj.baseFunction.evaluatePattern(timeDilation);
            rowIdxs = obj.getRowIdxs();

            % apply the repetition along dynamical quantities
            if isfield(jPatt, 'states')
                jPatt.states = obj.expandNodes(jPatt.states, obj.variableSizes.states);
            end
            if isfield(jPatt, 'controls')
                jPatt.controls = obj.expandNodes(jPatt.controls, obj.variableSizes.controls);
            end
            if isfield(jPatt, 'localParameters')
                jPatt.localParameters = jPatt.localParameters(rowIdxs, :);
            end
            if isfield(jPatt, 'globalParameters')
                jPatt.globalParameters = jPatt.globalParameters(rowIdxs, :);
            end
        end

        function jVal = evaluateJacobian(obj, inputData, timeDilation)
            % method that evaluates the jacobian of the base function and
            % expands it to account for the integration operator
            jVal = obj.baseFunction.evaluateJacobian(inputData, timeDilation);
            rowIdxs = obj.getRowIdxs();

            % apply the repetition along dynamical quantities
            if isfield(jVal, 'states')
                jVal.states = - obj.expandNodes(jVal.states, obj.variableSizes.states);
            end
            if isfield(jVal, 'controls')
                jVal.controls = - obj.expandNodes(jVal.controls, obj.variableSizes.controls);
            end
            if isfield(jVal, 'localParameters')
                jVal.localParameters = - jVal.localParameters(rowIdxs, :);
            end
            if isfield(jVal, 'globalParameters')
                jVal.globalParameters = - jVal.globalParameters(rowIdxs, :);
            end

            %% TODO: check whether there should also be expansions to other variables

        end

    end

    methods (Access = protected)

        function rowIdxs = getRowIdxs(obj)
            % helper returning, for each output row, the corresponding row
            % of the base function evaluated on its own nodes
            rowIdxs = reshape((obj.funcNodesMap - 1) * obj.outputDim + (1 : obj.outputDim)', [], 1);
        end

        function J = expandNodes(obj, baseJ, nVariables)
            % helper placing the block diagonal jacobian of the base
            % function onto the output rows and the columns of the
            % discretized nodes it is evaluated at
            colIdxs = reshape((obj.baseFunction.timeIdxs - 1) * nVariables + (1 : nVariables)', [], 1);
            J = zeros(obj.outputDim * length(obj.timeIdxs), nVariables * length(obj.outputNodesBypass));
            J(:, colIdxs) = baseJ(obj.getRowIdxs(), :);
        end

    end
end
