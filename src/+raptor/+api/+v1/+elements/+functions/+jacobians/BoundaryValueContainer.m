classdef BoundaryValueContainer < handle
    %BOUNDARYVALUECONTAINER Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % variables
        initialTime
        finalTime
        initialStates
        finalStates
        initialControls
        finalControls
        localParameters
        globalParameters
        upstreamParameters
    end

    properties(Hidden = true)
        % parent function reference
        parentFunction
    end

    methods
        function obj = BoundaryValueContainer(parentFunction)
            % constructor
            obj.parentFunction = parentFunction;
        end

        function set.initialStates(obj, initialStatesValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(initialStatesValue) && ~any(isnan(initialStatesValue), "all") && ...
                    all(size(initialStatesValue) == size(obj.parentFunction.jacobian.pattern.initialStates))
                obj.parentFunction.jacobian.pattern.initialStates = logical(initialStatesValue);
            end
            obj.initialStates = initialStatesValue;
        end


        function set.finalStates(obj, finalStatesValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(finalStatesValue) && ~any(isnan(finalStatesValue), "all") && ...
                    all(size(finalStatesValue) == size(obj.parentFunction.jacobian.pattern.finalStates))
                obj.parentFunction.jacobian.pattern.finalStates = logical(finalStatesValue);
            end
            obj.finalStates = finalStatesValue;
        end


        function set.initialTime(obj, initialTimeValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(initialTimeValue) && ~any(isnan(initialTimeValue), "all") && ...
                    all(size(initialTimeValue) == size(obj.parentFunction.jacobian.pattern.initialTime))
                obj.parentFunction.jacobian.pattern.initialTime = logical(initialTimeValue);
            end
            obj.initialTime = initialTimeValue;
        end


        function set.finalTime(obj, finalTimeValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(finalTimeValue) && ~any(isnan(finalTimeValue), "all") && ...
                    all(size(finalTimeValue) == size(obj.parentFunction.jacobian.pattern.finalTime))
                obj.parentFunction.jacobian.pattern.finalTime = logical(finalTimeValue);
            end
            obj.finalTime = finalTimeValue;
        end


        function set.initialControls(obj, initialControlsValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(initialControlsValue) && ~any(isnan(initialControlsValue), "all") && ...
                    all(size(initialControlsValue) == size(obj.parentFunction.jacobian.pattern.initialControls))
                obj.parentFunction.jacobian.pattern.initialControls = logical(initialControlsValue);
            end
            obj.initialControls = initialControlsValue;
        end


        function set.finalControls(obj, finalControlsValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(finalControlsValue) && ~any(isnan(finalControlsValue), "all") && ...
                    all(size(finalControlsValue) == size(obj.parentFunction.jacobian.pattern.finalControls))
                obj.parentFunction.jacobian.pattern.finalControls = logical(finalControlsValue);
            end
            obj.finalControls = finalControlsValue;
        end


        function set.localParameters(obj, localParametersValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(localParametersValue) && ~any(isnan(localParametersValue), "all") && ...
                    all(size(localParametersValue) == size(obj.parentFunction.jacobian.pattern.localParameters))
                obj.parentFunction.jacobian.pattern.localParameters = logical(localParametersValue);
            end
            obj.localParameters = localParametersValue;
        end


        function set.globalParameters(obj, globalParametersValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(globalParametersValue) && ~any(isnan(globalParametersValue), "all") && ...
                    all(size(globalParametersValue) == size(obj.parentFunction.jacobian.pattern.globalParameters))
                obj.parentFunction.jacobian.pattern.globalParameters = logical(globalParametersValue);
            end
            obj.globalParameters = globalParametersValue;
        end

        function set.upstreamParameters(obj, upstreamParametersValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(upstreamParametersValue) && ~any(isnan(upstreamParametersValue), "all") && ...
                    all(size(upstreamParametersValue) == size(obj.parentFunction.jacobian.pattern.upstreamParameters))
                obj.parentFunction.jacobian.pattern.upstreamParameters = logical(upstreamParametersValue);
            end
            obj.upstreamParameters = upstreamParametersValue;
        end
    end
end

