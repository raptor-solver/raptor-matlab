classdef Constraint < handle
    %CONSTRAINT Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % identification
        name

        % constraint definition
        fcnDescriptors
        outputDim
        outputNodes

        % bounds on the constraint values
        lowerBound
        upperBound

        % collocation object for trajectory and evaluation adjustments
        collocation

        % normalize differentiated terms from pseudo-time to physical time
        divideByTimeDilation = false

        % internal utility variables
        nRows
        functionsTypesToExclude
        fcnsToEvaluate
        variableSizes
        initializedJac
        phaseIdxs
    end

    methods
        function obj = Constraint(name, fcnDescriptors, outputDim, outputNodes, lowerBound, upperBound, collocation, phaseIdxs)
            % constructor
            import raptor.core.enumerations.*
            obj.name = name;
            obj.fcnDescriptors = fcnDescriptors;
            obj.outputDim = outputDim;
            obj.outputNodes = outputNodes;
            obj.lowerBound = lowerBound;
            obj.upperBound = upperBound;
            obj.collocation = collocation;
            obj.fcnsToEvaluate = fcnDescriptors;

            % number of constraint rows
            obj.nRows = ((obj.outputNodes == OutputNodes.collocated) * obj.collocation.n_coll + ...
                (obj.outputNodes == OutputNodes.collocatedWithoutInitial) * (obj.collocation.n_coll - obj.collocation.n_seg) + ...
                (obj.outputNodes == OutputNodes.discretized) * obj.collocation.n_disc + ...
                (obj.outputNodes == OutputNodes.single) * 1) * obj.outputDim;

            % phase indexes for linkage conditions
            if nargin == 8
                obj.phaseIdxs = phaseIdxs;
            end
        end

        function initialize(obj, inputData)
            % utility function to be called only once at the start of the
            % optimization to pre-compute the empty value of the
            % pattern/jacobian and the problem variable sizes

            % store the variable sizes
            varSizes = raptor.core.problem.descriptors.VariableSizes;
            varSizes.states = size(inputData.states, 1);
            varSizes.controls = size(inputData.controls, 1);
            varSizes.localParameters = size(inputData.localParameters, 1);
            varSizes.globalParameters = size(inputData.globalParameters, 1);
            varSizes.time = size(inputData.states, 2);
            obj.variableSizes = varSizes;

            % initialize the jacobian pattern/value structure
            jInit.states = zeros(obj.nRows, varSizes.states * varSizes.time);
            jInit.controls = zeros(obj.nRows, size(inputData.controls, 1) * size(inputData.controls, 2) * (~isempty(inputData.controls)));
            jInit.initialStates = zeros(obj.nRows, size(inputData.initialStates, 1));
            jInit.finalStates = zeros(obj.nRows, size(inputData.finalStates, 1));
            jInit.initialControls = zeros(obj.nRows, size(inputData.initialControls, 1) * (~isempty(inputData.initialControls)));
            jInit.finalControls = zeros(obj.nRows, size(inputData.finalControls, 1) * (~isempty(inputData.finalControls)));
            jInit.localParameters = zeros(obj.nRows, size(inputData.localParameters, 1) * (~isempty(inputData.localParameters)));
            jInit.globalParameters = zeros(obj.nRows, size(inputData.globalParameters, 1) * (~isempty(inputData.globalParameters)));
            jInit.upstreamParameters = zeros(obj.nRows, size(inputData.upstreamParameters, 1)  * (~isempty(inputData.globalParameters)));
            jInit.initialTime = zeros(obj.nRows, 1);
            jInit.finalTime = zeros(obj.nRows, 1);
            obj.initializedJac = jInit;
        end

        function set.functionsTypesToExclude(obj, functionTypesToExclude)
            % overridden setter method to update the utility array of which
            % functions should be evaluated
            obj.functionsTypesToExclude = functionTypesToExclude;
            functionsMask = ismember(cellfun(@(fcn) fcn.functionType, obj.fcnDescriptors), obj.functionsTypesToExclude);
            obj.fcnsToEvaluate = obj.fcnDescriptors(functionsMask == 0);
        end

        function cVal = evaluateConstraint(obj, inputData)
            % method that evaluates the constraint functions on the
            % specified inputData object

            % precompute the time dilation factor if needed
            import raptor.core.enumerations.*
            if any(cellfun(@(func) func.operatorType == OperatorType.differentiation, obj.fcnDescriptors))
                dTdTau = obj.collocation.timeDilation.evaluateFunction(inputData);
            else
                dTdTau = 1;
            end

            % loop over all function descriptors (without evaluating those
            % to exclude)
            cVal = zeros(obj.nRows, 1);
            for func = obj.fcnsToEvaluate

                % evaluate the constraint function
                if func{1}.operatorType == OperatorType.differentiation
                    fVal = func{1}.evaluateFunction(inputData);
                    if obj.divideByTimeDilation
                        fVal = fVal ./ dTdTau;
                    end
                    cVal = cVal + reshape(fVal, obj.nRows, 1);
                else
                    fVal = func{1}.evaluateFunction(inputData);
                    if ~obj.divideByTimeDilation
                        fVal = fVal .* dTdTau;
                    end
                    cVal = cVal + reshape(fVal, obj.nRows, 1);
                end
            end
        end

        function jPatt = evaluatePattern(obj, ~)
            % method that evaluates the constraint function pattern from
            % the constituing function objects

            % precompute the patterns for the time dilation corrections
            import raptor.core.enumerations.*
            if any(cellfun(@(func) func.operatorType == OperatorType.differentiation, obj.fcnDescriptors))
                dTdTau = obj.collocation.timeDilation.dTdTauPattern;
            else
                dTdTau.initialTime = [];
                dTdTau.finalTime = [];
                dTdTau.localParameters = [];
            end

            % initialize the jacobian pattern structure
            jPatt = obj.initializedJac;

            % loop over all functions
            for func = obj.fcnDescriptors

                % compute the indexes for the evaluation nodes of dynamic
                % quantities
                stateNodes = reshape((0 + (1 : obj.variableSizes.states) + (obj.variableSizes.states * (func{1}.timeIdxs - 1)'))', 1, []);
                controlNodes = reshape((0 + (1 : obj.variableSizes.controls) + (obj.variableSizes.controls * (func{1}.timeIdxs - 1)'))', 1, []);

                %% NOTE: this is a temporary fix and should be removed
                % correct the state nodes for the exceptional case of the
                % Birkhoff b product wrapper
                if isprop(func{1}, 'outputNodesBypass')
                    stateNodes = reshape((0 + (1 : obj.variableSizes.states) + (obj.variableSizes.states * (func{1}.outputNodesBypass - 1)'))', 1, []);
                    controlNodes = reshape((0 + (1 : obj.variableSizes.controls) + (obj.variableSizes.controls * (func{1}.outputNodesBypass - 1)'))', 1, []);
                end

                % compute the functions jacobian pattern
                fPatt = func{1}.evaluatePattern(obj.collocation.timeDilation);

                % loop over all variables to sum the jacobian contributions
                if isfield(fPatt,'states')
                    jPatt.states(:, stateNodes) = jPatt.states(:, stateNodes) + fPatt.states;
                end
                if isfield(fPatt,'controls')
                    jPatt.controls(:, controlNodes) = jPatt.controls(:, controlNodes) + fPatt.controls;
                end
                if isfield(fPatt,'localParameters')
                    jPatt.localParameters = jPatt.localParameters + fPatt.localParameters;
                end
                if isfield(fPatt,'upstreamParameters')
                    jPatt.upstreamParameters = jPatt.upstreamParameters + fPatt.upstreamParameters;
                end
                if isfield(fPatt,'globalParameters')
                    jPatt.globalParameters = jPatt.globalParameters + fPatt.globalParameters;
                end
                if isfield(fPatt,'initialStates')
                    jPatt.initialStates = jPatt.initialStates + fPatt.initialStates;
                end
                if isfield(fPatt,'finalStates')
                    jPatt.finalStates = jPatt.finalStates + fPatt.finalStates;
                end
                if isfield(fPatt,'initialControls')
                    jPatt.initialControls = jPatt.initialControls + fPatt.initialControls;
                end
                if isfield(fPatt,'finalControls')
                    jPatt.finalControls = jPatt.finalControls + fPatt.finalControls;
                end
                if isfield(fPatt,'initialTime')
                    jPatt.initialTime = jPatt.initialTime + fPatt.initialTime;
                end
                if isfield(fPatt,'finalTime')
                    jPatt.finalTime = jPatt.finalTime + fPatt.finalTime;
                end

                % apply the corrections for differential functions if
                % present (row contributions get added to each row of the
                % jacobian uniformly)
                if obj.divideByTimeDilation
                    applyTimeDilationCorrection = func{1}.operatorType == OperatorType.differentiation;
                else
                    applyTimeDilationCorrection = func{1}.operatorType ~= OperatorType.differentiation;
                end
                if ~isempty(dTdTau.initialTime) && applyTimeDilationCorrection
                    jPatt.initialTime = jPatt.initialTime + dTdTau.initialTime;
                end
                if ~isempty(dTdTau.finalTime) && applyTimeDilationCorrection
                    jPatt.finalTime = jPatt.finalTime + dTdTau.finalTime;
                end
                if ~isempty(dTdTau.localParameters) && applyTimeDilationCorrection
                    jPatt.localParameters = jPatt.localParameters + dTdTau.localParameters;
                end
            end
        end

        function jVal = evaluateJacobian(obj, inputData)
            % method that evaluates the constraint function jacobian on the
            % specified inputData object

            % precompute the time dilation corrections if needed
            import raptor.core.enumerations.*
            if any(cellfun(@(func) func.operatorType == OperatorType.differentiation, obj.fcnDescriptors))
                dTdTau = obj.collocation.timeDilation.evaluateJacobian(inputData);
                dTdTau_val = obj.collocation.timeDilation.evaluateFunction(inputData);
            else
                dTdTau.initialTime = [];
                dTdTau.finalTime = [];
                dTdTau.localParameters = [];
                dTdTau_val = [];
            end

            % initialize the jacobian value structure
            jVal = obj.initializedJac;

            % loop over all function descriptors
            for func = obj.fcnsToEvaluate

                % compute the indexes for the evaluation nodes of dynamic
                % quantities
                stateNodes = reshape((0 + (1 : obj.variableSizes.states) + (obj.variableSizes.states * (func{1}.timeIdxs - 1)'))', 1, []);
                controlNodes = reshape((0 + (1 : obj.variableSizes.controls) + (obj.variableSizes.controls * (func{1}.timeIdxs - 1)'))', 1, []);

                %% NOTE: this is a temporary fix and should be removed
                % correct the state nodes for the exceptional case of the
                % Birkhoff b product wrapper
                if isprop(func{1}, 'outputNodesBypass')
                    stateNodes = reshape((0 + (1 : obj.variableSizes.states) + (obj.variableSizes.states * (func{1}.outputNodesBypass - 1)'))', 1, []);
                    controlNodes = reshape((0 + (1 : obj.variableSizes.controls) + (obj.variableSizes.controls * (func{1}.outputNodesBypass - 1)'))', 1, []);
                end

                % plain evaluation for terms that do not require a time
                % dilation correction
                if obj.divideByTimeDilation
                    applyTimeDilationCorrection = func{1}.operatorType == OperatorType.differentiation;
                else
                    applyTimeDilationCorrection = func{1}.operatorType ~= OperatorType.differentiation;
                end
                if ~applyTimeDilationCorrection || isempty(dTdTau_val)

                    % loop over all variables to sum the jacobian
                    % contributions
                    fJac = func{1}.evaluateJacobian(inputData, obj.collocation.timeDilation);
                    if isfield(fJac, 'states')
                        jVal.states(:, stateNodes) = jVal.states(:, stateNodes) + fJac.states;
                    end
                    if isfield(fJac, 'controls')
                        jVal.controls(:, controlNodes) = jVal.controls(:, controlNodes) + fJac.controls;
                    end
                    if isfield(fJac, 'localParameters')
                        jVal.localParameters = jVal.localParameters + fJac.localParameters;
                    end
                    if isfield(fJac, 'upstreamParameters')
                        jVal.upstreamParameters = jVal.upstreamParameters + fJac.upstreamParameters;
                    end
                    if isfield(fJac, 'globalParameters')
                        jVal.globalParameters = jVal.globalParameters + fJac.globalParameters;
                    end
                    if isfield(fJac, 'initialStates')
                        jVal.initialStates = jVal.initialStates + fJac.initialStates;
                    end
                    if isfield(fJac, 'finalStates')
                        jVal.finalStates = jVal.finalStates + fJac.finalStates;
                    end
                    if isfield(fJac, 'initialControls')
                        jVal.initialControls = jVal.initialControls + fJac.initialControls;
                    end
                    if isfield(fJac, 'finalControls')
                        jVal.finalControls = jVal.finalControls + fJac.finalControls;
                    end
                    if isfield(fJac, 'initialTime')
                        jVal.initialTime = jVal.initialTime + fJac.initialTime;
                    end
                    if isfield(fJac, 'finalTime')
                        jVal.finalTime = jVal.finalTime + fJac.finalTime;
                    end

                else % compute the time dilation corrections

                    % compute the function value for the first correction
                    % term
                    fVal = func{1}.evaluateFunction(inputData);
                    fJac = func{1}.evaluateJacobian(inputData, obj.collocation.timeDilation);

                    if obj.divideByTimeDilation
                        timeDilationScaling = kron(diag(1 ./ dTdTau_val), eye(obj.outputDim));
                        timeDilationCorrection = - fVal ./ dTdTau_val .^ 2;
                    else
                        timeDilationScaling = kron(diag(dTdTau_val), eye(obj.outputDim));
                        timeDilationCorrection = fVal;
                    end

                    % loop over all variables
                    if isfield(fJac, 'states')
                        jVal.states(:, stateNodes) = jVal.states(:, stateNodes) + ...
                            timeDilationScaling * fJac.states;
                    end
                    if isfield(fJac, 'controls')
                        jVal.controls(:, controlNodes) = jVal.controls(:, controlNodes) + ...
                            timeDilationScaling * fJac.controls;
                    end
                    if isfield(fJac, 'localParameters')
                        jVal.localParameters = jVal.localParameters + ...
                            timeDilationScaling * fJac.localParameters;
                    end
                    if ~isempty(dTdTau.localParameters)
                        jVal.localParameters = jVal.localParameters + ...
                            obj.expandDilationCorrection(timeDilationCorrection, ...
                            dTdTau.localParameters);
                    end
                    if isfield(fJac, 'initialTime')
                        jVal.initialTime = jVal.initialTime + ...
                            timeDilationScaling * fJac.initialTime;
                    end
                    jVal.initialTime = jVal.initialTime + reshape(timeDilationCorrection .* dTdTau.initialTime', [], 1);
                    if isfield(fJac, 'finalTime')
                        jVal.finalTime = jVal.finalTime + ...
                            timeDilationScaling * fJac.finalTime;
                    end
                    jVal.finalTime = jVal.finalTime + reshape(timeDilationCorrection .* dTdTau.finalTime', [], 1);
                    if isfield(fJac, 'globalParameters')
                        jVal.globalParameters = jVal.globalParameters + ...
                            timeDilationScaling * fJac.globalParameters;
                    end
                    if isfield(fJac, 'initialStates')
                        jVal.initialStates = jVal.initialStates + ...
                            timeDilationScaling * fJac.initialStates;
                    end
                    if isfield(fJac, 'finalStates')
                        jVal.finalStates = jVal.finalStates + ...
                            timeDilationScaling * fJac.finalStates;
                    end
                    if isfield(fJac, 'initialControls')
                        jVal.initialControls = jVal.initialControls + ...
                            timeDilationScaling * fJac.initialControls;
                    end
                    if isfield(fJac, 'finalControls')
                        jVal.finalControls = jVal.finalControls + ...
                            timeDilationScaling * fJac.finalControls;
                    end

                end
            end
        end

    end

    methods(Static, Access = private)
        function correction = expandDilationCorrection(functionValue, dilationJacobian)
            % Product-rule contribution for a node-wise scalar dilation
            % depending on one or more phase-local parameters.
            [outputDimension, nNodes] = size(functionValue);
            nParameters = size(dilationJacobian, 2);
            correction = reshape( ...
                reshape(functionValue, outputDimension, nNodes, 1) .* ...
                reshape(dilationJacobian, 1, nNodes, nParameters), ...
                outputDimension * nNodes, nParameters);
        end
    end
end
