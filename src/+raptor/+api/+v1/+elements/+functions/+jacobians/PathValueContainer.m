classdef PathValueContainer < handle
    %PATHVALUECONTAINER Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % variables
        time
        states
        controls
        localParameters
        globalParameters
    end

    properties(Hidden = true)
        % parent function reference
        parentFunction
    end

    methods
        function obj = PathValueContainer(parentFunction)
            % constructor
            obj.parentFunction = parentFunction;
        end

        function set.states(obj, statesValue)
            % if the value is numeric, also updated the correspoding
            % pattern
            if isnumeric(statesValue) && ~any(isnan(statesValue), 'all') && ...
                    all(size(statesValue) == size(obj.parentFunction.jacobian.pattern.states))
                obj.parentFunction.jacobian.pattern.states = logical(statesValue);
            end
            obj.states = statesValue;
        end

        function set.time(obj, timeValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(timeValue) && ~any(isnan(timeValue), 'all') && ...
                    all(size(timeValue) == size(obj.parentFunction.jacobian.pattern.time))
                obj.parentFunction.jacobian.pattern.time = logical(timeValue);
            end
            obj.time = timeValue;
        end


        function set.controls(obj, controlsValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(controlsValue) && ~any(isnan(controlsValue), 'all') && ...
                    all(size(controlsValue) == size(obj.parentFunction.jacobian.pattern.controls))
                obj.parentFunction.jacobian.pattern.controls = logical(controlsValue);
            end
            obj.controls = controlsValue;
        end


        function set.localParameters(obj, localParametersValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(localParametersValue) && ~any(isnan(localParametersValue), 'all') && ...
                    all(size(localParametersValue) == size(obj.parentFunction.jacobian.pattern.localParameters))
                obj.parentFunction.jacobian.pattern.localParameters = logical(localParametersValue);
            end
            obj.localParameters = localParametersValue;
        end


        function set.globalParameters(obj, globalParametersValue)
            % if the value is numeric, also update the corresponding
            % pattern
            if isnumeric(globalParametersValue) && ~any(isnan(globalParametersValue), 'all') && ...
                    all(size(globalParametersValue) == size(obj.parentFunction.jacobian.pattern.globalParameters))
                obj.parentFunction.jacobian.pattern.globalParameters = logical(globalParametersValue);
            end
            obj.globalParameters = globalParametersValue;
        end

    end
end