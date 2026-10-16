classdef Function < handle
    % base descriptor for problem decision variables

    properties
        % pseudospectral operator applied to the function
        operatorType

        % function definition
        evaluationDomain
        functionType
        fcnHandle
        outputDim

        % jacobian information
        jacobianValue
        jacobianPattern

        % numerical differentiation routine
        numericalDifferentiation % assigned during transcription

        % problem metadata required to evaluate the function
        variableSizes
        timeIdxs
    end

    methods
        function obj = Function(fcnHandle, outputDim, functionType, evaluationDomain, operatorType, variableSizes, timeIdxs)
            % constructor
            if nargin > 1
                % regular object construction
                obj.fcnHandle = fcnHandle;
                obj.outputDim = outputDim;
                obj.functionType = functionType;
                obj.evaluationDomain = evaluationDomain;
                obj.operatorType = operatorType;
                obj.variableSizes = variableSizes;
                obj.timeIdxs = timeIdxs;

                % instantiate the default values of the jacobian structures
                obj.jacobianPattern = obj.get_default_jacobian_structure([]);
                obj.jacobianValue = obj.get_default_jacobian_structure('numerical');
            elseif nargin == 1
                % assume that the only input is another function descriptor
                % to copy
                obj.fcnHandle = fcnHandle.fcnHandle;
                obj.outputDim = fcnHandle.outputDim;
                obj.functionType = fcnHandle.functionType;
                obj.evaluationDomain = fcnHandle.evaluationDomain;
                obj.operatorType = fcnHandle.operatorType;
                obj.variableSizes = fcnHandle.variableSizes;
                obj.timeIdxs = fcnHandle.timeIdxs;
                obj.jacobianPattern = fcnHandle.jacobianPattern;
                obj.jacobianValue = fcnHandle.jacobianValue;
            end

        end

        function fVal = evaluateFunction(obj, inputData)
            % method that computes the value of the function on the
            % specified inputData object

            % adjust the evaluation nodes according to those specified by
            % the function
            inputData.states = inputData.states(:, obj.timeIdxs);
            inputData.controls = inputData.controls(:, obj.timeIdxs);
            inputData.time = inputData.time(:, obj.timeIdxs);

            % perform the evaluation
            fVal = obj.fcnHandle(inputData);
        end

        function jPatt = evaluatePattern(obj, timeDilation)
            % method that builds the jacobian pattern for the specified
            % function

            if nargin < 2
                timeDilation = [];
            end
            obj.augmentTimeMappingDependencies(timeDilation);

            % set the repetition matrix to be used for the dynamic
            % variables
            nRepeatedEvaluations = length(obj.timeIdxs);
            repetitionMatrix = eye(nRepeatedEvaluations);

            % assign the pattern with respect to the states
            if ~isempty(obj.jacobianPattern.states)
                % check for a linear function with explicitly defined
                % jacobian
                if isnumeric(obj.jacobianValue.states) && ...
                        size(obj.jacobianValue.states, 2) ~= obj.variableSizes.states
                    jPatt.states = logical(obj.jacobianValue.states);
                else
                    jPatt.states = kron(repetitionMatrix, obj.jacobianPattern.states);
                end
            end

            % assign the pattern with respect to the controls
            if ~isempty(obj.jacobianPattern.controls)
                % check for a linear function with explicitly defined
                % jacobian
                if isnumeric(obj.jacobianValue.controls) && ...
                        size(obj.jacobianValue.controls, 2) ~= obj.variableSizes.controls
                    jPatt.controls = logical(obj.jacobianValue.controls);
                else
                    jPatt.controls = kron(repetitionMatrix, obj.jacobianPattern.controls);
                end
            end

            % assign the pattern with respect to the local parameters
            if ~isempty(obj.jacobianPattern.localParameters)
                % check for a linear function with explicitly defined
                % jacobian
                if isnumeric(obj.jacobianValue.localParameters) && ...
                        size(obj.jacobianValue.localParameters, 2) ~= obj.variableSizes.localParameters
                    jPatt.localParameters = logical(obj.jacobianValue.localParameters);
                else
                    jPatt.localParameters = repmat(obj.jacobianPattern.localParameters, nRepeatedEvaluations, 1);
                end
            end

            % assign the pattern with respect to the upstream parameters
            if ~isempty(obj.jacobianPattern.upstreamParameters)
                jPatt.upstreamParameters = repmat(obj.jacobianPattern.upstreamParameters, nRepeatedEvaluations, 1);
            end

            % assign the pattern with respect to the global parameters
            if ~isempty(obj.jacobianPattern.globalParameters)
                jPatt.globalParameters = repmat(obj.jacobianPattern.globalParameters, nRepeatedEvaluations, 1);
            end

            % assign the pattern with respect to the initial states
            if ~isempty(obj.jacobianPattern.initialStates)
                jPatt.initialStates = repmat(obj.jacobianPattern.initialStates, nRepeatedEvaluations, 1);
            end

            % assign the pattern with respect to the final states
            if ~isempty(obj.jacobianPattern.finalStates)
                jPatt.finalStates = repmat(obj.jacobianPattern.finalStates, nRepeatedEvaluations, 1);
            end

            % assign the pattern with respect to the initial controls
            if ~isempty(obj.jacobianPattern.initialControls)
                jPatt.initialControls = repmat(obj.jacobianPattern.initialControls, nRepeatedEvaluations, 1);
            end

            % assign the pattern with respect to the final controls
            if ~isempty(obj.jacobianPattern.finalControls)
                jPatt.finalControls = repmat(obj.jacobianPattern.finalControls, nRepeatedEvaluations, 1);
            end

            % assign the pattern with respect to the initial time
            if ~isempty(obj.jacobianPattern.initialTime)
                jPatt.initialTime = repmat(obj.jacobianPattern.initialTime, nRepeatedEvaluations, 1);
            end

            % assign the pattern with respect to the final time
            if ~isempty(obj.jacobianPattern.finalTime)
                jPatt.finalTime = repmat(obj.jacobianPattern.finalTime, nRepeatedEvaluations, 1);
            end
        end

        function jVal = evaluateJacobian(obj, inputData, timeDilation)
            % method that evaluates the function jacobian with respect to
            % the canonical variables

            % adjust the dynamic variables and retrieve their length
            inputData.states = inputData.states(:, obj.timeIdxs);
            inputData.controls = inputData.controls(:, obj.timeIdxs);
            inputData.time = inputData.time(:, obj.timeIdxs);
            nRepeatedEvaluations = length(obj.timeIdxs);
            repetitionMatrix = eye(nRepeatedEvaluations);

            % compute the jacobian with respect to the states
            if ~isempty(obj.jacobianPattern.states)
                % check whether the jacobian is numerical or constant
                if isnumeric(obj.jacobianValue.states)
                    % check whether the jacobian is provided for the full
                    % function or it is just for a single generic point
                    if size(obj.jacobianValue.states, 2) == obj.variableSizes.states
                        jVal.states = kron(repetitionMatrix, obj.jacobianValue.states);
                    else
                        jVal.states = obj.jacobianValue.states;
                    end
                else
                    % call the chosen numerical differentiation function
                    jVal.states = obj.numericalDifferentiation.perform(obj.fcnHandle, inputData, "states", obj.jacobianPattern.states, timeDilation, obj.timeIdxs);
                end
            end

            % compute the jacobian with respect to the controls
            if ~isempty(obj.jacobianPattern.controls)
                % check whether the jacobian is numerical or constant
                if isnumeric(obj.jacobianValue.controls)
                    % check whether the jacobian is provided for the full
                    % function or it is just for a single generic point
                    if size(obj.jacobianValue.controls, 2) == obj.variableSizes.controls
                        jVal.controls = kron(repetitionMatrix, obj.jacobianValue.controls);
                    else
                        jVal.controls = obj.jacobianValue.controls;
                    end
                else
                    % call the chosen nmuerical differentiation function
                    jVal.controls = obj.numericalDifferentiation.perform(obj.fcnHandle, inputData, "controls", obj.jacobianPattern.controls, timeDilation, obj.timeIdxs);
                end
            end

            % compute the jacobian with respect to the local parameters
            if ~isempty(obj.jacobianPattern.localParameters)
                % check whether the jacobian is numerical or constant
                if isnumeric(obj.jacobianValue.localParameters) && isempty(obj.jacobianPattern.time)
                    jVal.localParameters = repmat(obj.jacobianValue.localParameters, nRepeatedEvaluations, 1);
                else
                    % call the chosen numerical differentiation function
                    jVal.localParameters = obj.numericalDifferentiation.perform(obj.fcnHandle, inputData, "localParameters", obj.jacobianPattern.localParameters, timeDilation, obj.timeIdxs);
                end
            end

            % compute the jacobian with respect to the upstream parameters
            if ~isempty(obj.jacobianPattern.upstreamParameters)
                % check whether the jacobian is numerical or constant
                if isnumeric(obj.jacobianValue.upstreamParameters)
                    jVal.upstreamParameters = repmat(obj.jacobianValue.upstreamParameters, nRepeatedEvaluations, 1);
                else
                    % call the chosen numerical differentiation function
                    jVal.upstreamParameters = obj.numericalDifferentiation.perform(obj.fcnHandle, inputData, "upstreamParameters", obj.jacobianPattern.upstreamParameters, timeDilation, obj.timeIdxs);
                end
            end

            % compute the jacobian with respect to the global parameters
            if ~isempty(obj.jacobianPattern.globalParameters)
                % check whether the jacobian is numerical or constant
                if isnumeric(obj.jacobianValue.globalParameters)
                    jVal.globalParameters = repmat(obj.jacobianValue.globalParameters, nRepeatedEvaluations, 1);
                else
                    % call the chosen numerical differentiation function
                    jVal.globalParameters = obj.numericalDifferentiation.perform(obj.fcnHandle, inputData, "globalParameters", obj.jacobianPattern.globalParameters, timeDilation, obj.timeIdxs);
                end
            end

            % compute the jacobian with respect to the initial states
            if ~isempty(obj.jacobianPattern.initialStates)
                if isnumeric(obj.jacobianValue.initialStates)
                    jVal.initialStates = repmat(obj.jacobianValue.initialStates, nRepeatedEvaluations, 1);
                else
                    jVal.initialStates = obj.numericalDifferentiation.perform(obj.fcnHandle, inputData, "initialStates", obj.jacobianPattern.initialStates, timeDilation, obj.timeIdxs);
                end
            end

            % compute the jacobian with respect to the initial controls
            if ~isempty(obj.jacobianPattern.initialControls)
                if isnumeric(obj.jacobianValue.initialControls)
                    jVal.initialControls = repmat(obj.jacobianValue.initialControls, nRepeatedEvaluations, 1);
                else
                    jVal.initialControls = obj.numericalDifferentiation.perform(obj.fcnHandle, inputData, "initialControls", obj.jacobianPattern.initialControls, timeDilation, obj.timeIdxs);
                end
            end

            % compute the jacobian with respect to the final states
            if ~isempty(obj.jacobianPattern.finalStates)
                if isnumeric(obj.jacobianValue.finalStates)
                    jVal.finalStates = repmat(obj.jacobianValue.finalStates, nRepeatedEvaluations, 1);
                else
                    jVal.finalStates = obj.numericalDifferentiation.perform(obj.fcnHandle, inputData, "finalStates", obj.jacobianPattern.finalStates, timeDilation, obj.timeIdxs);
                end
            end

            % compute the jacobian with respect to the final controls
            if ~isempty(obj.jacobianPattern.finalControls)
                if isnumeric(obj.jacobianValue.finalControls)
                    jVal.finalControls = repmat(obj.jacobianValue.finalControls, nRepeatedEvaluations, 1);
                else
                    jVal.finalControls = obj.numericalDifferentiation.perform(obj.fcnHandle, inputData, "finalControls", obj.jacobianPattern.finalControls, timeDilation, obj.timeIdxs);
                end
            end

            % compute the jacobian with respect to the initial time
            if ~isempty(obj.jacobianPattern.initialTime)
                if isnumeric(obj.jacobianValue.initialTime) && isempty(obj.jacobianPattern.time)
                    jVal.initialTime = repmat(obj.jacobianValue.initialTime, nRepeatedEvaluations, 1);
                else
                    jVal.initialTime = obj.numericalDifferentiation.perform(obj.fcnHandle, inputData, "initialTime", obj.jacobianPattern.initialTime, timeDilation, obj.timeIdxs);
                end
            end

            % compute the jacobian with respect to the final time
            if ~isempty(obj.jacobianPattern.finalTime)
                if isnumeric(obj.jacobianValue.finalTime) && isempty(obj.jacobianPattern.time)
                    jVal.finalTime = repmat(obj.jacobianValue.finalTime, nRepeatedEvaluations, 1);
                else
                    jVal.finalTime = obj.numericalDifferentiation.perform(obj.fcnHandle, inputData, "finalTime", obj.jacobianPattern.finalTime, timeDilation, obj.timeIdxs);
                end
            end

        end

    end

    methods(Access = protected)

        function augmentTimeMappingDependencies(obj, timeDilation)
            % A function with explicit time dependence also depends on all
            % decision variables used by the physical-time mapping.
            if isempty(obj.jacobianPattern.time) || ...
                    ~any(obj.jacobianPattern.time, 'all')
                return
            end

            if isempty(timeDilation)
                mapPattern = struct('initialTime', true, ...
                    'finalTime', true, 'localParameters', []);
            else
                mapPattern = timeDilation.timeMapPattern;
            end
            timePattern = logical(obj.jacobianPattern.time);

            if any(mapPattern.initialTime)
                obj.jacobianPattern.initialTime = obj.unionPattern( ...
                    obj.jacobianPattern.initialTime, timePattern);
            end
            if any(mapPattern.finalTime)
                obj.jacobianPattern.finalTime = obj.unionPattern( ...
                    obj.jacobianPattern.finalTime, timePattern);
            end

            nParameters = obj.variableSizes.localParameters;
            localPattern = mapPattern.localParameters;
            if isscalar(localPattern) && nParameters > 1
                localPattern = repmat(localPattern, 1, nParameters);
            end
            if ~isempty(localPattern)
                if numel(localPattern) ~= nParameters
                    error('raptor:TimeDilation:InvalidPattern', ...
                        ['TimeMapJacobianPattern.localParameters must contain ' ...
                        'one entry per phase-local parameter.']);
                end
                mappedPattern = logical(timePattern) * logical(reshape(localPattern, 1, [])) > 0;
                obj.jacobianPattern.localParameters = obj.unionPattern( ...
                    obj.jacobianPattern.localParameters, mappedPattern);
            end
        end

        function pattern = unionPattern(~, existingPattern, addedPattern)
            if isempty(existingPattern)
                pattern = logical(addedPattern);
            else
                pattern = logical(existingPattern) | logical(addedPattern);
            end
        end

        function jacobianStructure = get_default_jacobian_structure(~, defaultValue)
            % method to create the default structure for the jacobian info
            % properties
            jacobianStructure.time = defaultValue;
            jacobianStructure.states = defaultValue;
            jacobianStructure.controls = defaultValue;
            jacobianStructure.localParameters = defaultValue;
            jacobianStructure.globalParameters = defaultValue;
            jacobianStructure.initialTime = defaultValue;
            jacobianStructure.finalTime = defaultValue;
            jacobianStructure.initialStates = defaultValue;
            jacobianStructure.finalStates = defaultValue;
            jacobianStructure.initialControls = defaultValue;
            jacobianStructure.finalControls = defaultValue;
            jacobianStructure.upstreamParameters = defaultValue;
        end

    end
end

