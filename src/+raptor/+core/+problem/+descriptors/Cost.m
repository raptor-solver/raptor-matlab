classdef Cost < raptor.core.problem.descriptors.Constraint
    %COST Summary of this class goes here
    %   Detailed explanation goes here

    methods
        function obj = Cost(fcnDescriptors, collocation)
            % superclass constructor
            import raptor.core.enumerations.*
            if nargin == 0
                super_args = {};
            else
                super_args = {"cost", fcnDescriptors, 1, OutputNodes.single, 0, 0, collocation};
            end
            obj@raptor.core.problem.descriptors.Constraint(super_args{:});
        end

        %% NOTE: the cost descriptor implements the "regular" constraint methods
        % this means that the method calls from outside functions may look
        % weird, but they should be consistent
        %% TODO: once the core functionalities are more stable,
        % the cost computations can be made easier by removing inhertiance
        % from the constraints and just implementing their own methods
        %% NOTE: no pattern evaluation method is implemented,
        % if a future solver requires it, it may make sense to implement it

        function cVal = evaluateCost(obj, inputData)
            % method to evaluate the cost function on the current inputdata
            % object

            cVal = 0;
            for func = obj.fcnsToEvaluate

                % evaluate the function
                cVal = cVal + func{1}.evaluateFunction(inputData);
            end
        end

        function jVal = evaluateJacobian(obj, inputData)
            % method to evaluate the jacobian of the current cost function
            % on the specified inputdata object

            % initialize the jacobian value structure
            jVal = obj.initializedJac;

            % loop over all function descriptors
            for func = obj.fcnsToEvaluate

                % compute the indexes for the evaluation nodes of dynamic
                % quantities
                stateNodes = reshape((0 + (1 : obj.variableSizes.states) + (obj.variableSizes.states * (func{1}.timeIdxs - 1)'))', 1, []);
                controlNodes = reshape((0 + (1 : obj.variableSizes.controls) + (obj.variableSizes.controls * (func{1}.timeIdxs - 1)'))', 1, []);

                % loop over all variables to sum the jacobian contributions
                % Note: to avoid duplicating the function logic, we instead
                % just condense here the repretition matrix that expands
                % the jacobian on multiple rows with the sum() function
                fJac = func{1}.evaluateJacobian(inputData, obj.collocation.timeDilation);
                if isfield(fJac, 'states')
                    % if size(fJac.states, 1) > 1
                    %     fJac.states = sum(fJac.states, 1); %% TODO: check if this makes sense
                    % end
                    jVal.states(1, stateNodes) = jVal.states(1, stateNodes) + fJac.states;
                end
                if isfield(fJac, 'controls')
                    % if size(fJac.controls, 1) > 1
                    %     fJac.controls = sum(fJac.controls, 1);
                    % end
                    jVal.controls(1, controlNodes) = jVal.controls(1, controlNodes) + fJac.controls;
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

            end

        end
    end
end