classdef ComplexStepDifferences < raptor.core.abstract.NumericalDifferentiation
    %CENTRALDIFFERENCES Summary of this class goes here
    %   Detailed explanation goes here

    methods
        function obj = ComplexStepDifferences(step_h)
            % superclass constructor
            if nargin == 0
                super_args = {};
            else
                super_args = {step_h};
            end
            obj@raptor.core.abstract.NumericalDifferentiation(super_args{:});
        end

        function jacobianMatrix = perform(obj, fcnHandle, inputData, whichVar, pattern, timeDilation, localTimeIdxs)
            % method to perform the numerical differentiation of the
            % provided function on the specified inputData object

            % compute which pattern columns have nonzero entries
            dependencyMask = any(pattern, 1);
            nJacobianVariables = nnz(dependencyMask);
            nVars = size(pattern, 2);

            % distinguish between continuous variables (states, controls)
            % and static variables
            if whichVar == "states" || whichVar == "controls"

                % augment the inputdata object according to the number of
                % perturbed variables
                nTimes = size(inputData.states, 2);
                inputData.states = repelem(inputData.states, 1, nJacobianVariables);
                inputData.controls = repelem(inputData.controls, 1, nJacobianVariables);
                inputData.time = repelem(inputData.time, 1, nJacobianVariables);

                % define the perturbation to be applied
                idx = find(dependencyMask);
                perturbationMatrix = sparse(idx, 1 : nJacobianVariables, 1, nVars, nJacobianVariables);
                perturbationMatrix = repmat(perturbationMatrix, 1, nTimes);

                % apply the perturbation
                if whichVar == "states"
                    inputData.states = inputData.states + 1i * obj.step_h .* perturbationMatrix;
                else
                    inputData.controls = inputData.controls + 1i * obj.step_h .* perturbationMatrix;
                end

                % compute the function value
                fVal = fcnHandle(inputData);

                % compute the complex differences
                jVal = zeros(size(pattern, 1), size(pattern, 2) * nTimes);
                jVal(:, repmat(dependencyMask, 1, nTimes) == 1) = ...
                    imag(fVal) ./ obj.step_h;

                % assemble the full jacobian matrix
                jacobianMatrix = blkdiagJacobians(jVal, nTimes);

            elseif whichVar == "initialTime" || whichVar == "finalTime"

                % positive perturbation
                inputData.(whichVar) = inputData.(whichVar) + 1i * obj.step_h;

                % rebuilt the updated time vector
                inputData.time = timeDilation.mapDiscretizedTime(inputData);
                inputData.time = inputData.time(localTimeIdxs);
                fc = reshape(fcnHandle(inputData), [], 1);

                % assign the jacobian column
                jacobianMatrix(:, 1) = imag(fc) ./ obj.step_h;

            else

                % for all other variables, no vectorized computation is
                % available/needed
                nJacobianVariables = size(pattern, 2);
                unperturbedTime = inputData.time;

                % loop over all variables
                for vv = 1 : nJacobianVariables

                    % complex perturbation
                    inputData.(whichVar)(vv) = inputData.(whichVar)(vv) + 1i * obj.step_h;
                    if whichVar == "localParameters" && ...
                            obj.timeMapDependsOnParameter(timeDilation, vv, nJacobianVariables)
                        inputData.time = timeDilation.mapDiscretizedTime(inputData);
                        inputData.time = inputData.time(localTimeIdxs);
                    end
                    fc = reshape(fcnHandle(inputData), [], 1);

                    % assign the jacobian column and reset the variable
                    jacobianMatrix(:, vv) = imag(fc) ./ obj.step_h;
                    inputData.(whichVar)(vv) = inputData.(whichVar)(vv) - 1i * obj.step_h;
                    inputData.time = unperturbedTime;
                end
            end

        end
    end

    methods(Static, Access = private)
        function depends = timeMapDependsOnParameter(timeDilation, parameterIndex, nParameters)
            pattern = timeDilation.timeMapPattern.localParameters;
            if isempty(pattern)
                depends = false;
            elseif isscalar(pattern)
                depends = logical(pattern);
            elseif numel(pattern) ~= nParameters
                error('raptor:TimeDilation:InvalidPattern', ...
                    ['TimeMapJacobianPattern.localParameters must contain ' ...
                    'one entry per phase-local parameter.']);
            else
                depends = logical(pattern(parameterIndex));
            end
        end
    end
end

