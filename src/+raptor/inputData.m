classdef inputData
    % inputData  class defining the inputs for user-provided functions
    %
    %   inputData provides the unified input object for all RAPTOR
    %   functions
    %
    %
    % -------------------------------------------------------------------------
    % PROPERTIES:
    %
    %   time
    %
    %   states
    %
    %   controls
    %
    %   localParameters
    %
    %   globalParameters
    %
    %   auxdata
    %
    %   initialStates
    %
    %   finalStates
    %
    %   initialTime
    %
    %   finalTime
    %
    %   initialControls
    %
    %   finalControls
    %
    % METHODS:
    %
    %   None
    %
    % -------------------------------------------------------------------------
    % USAGE:
    %   dynamics = @(inputData) [inputData.states(2); inputData.controls]
    %
    % -------------------------------------------------------------------------
    % NOTES:
    %   - The class is intened as the generalized input for all user
    %   provided functions.
    %
    % -------------------------------------------------------------------------
    % SEE ALSO:
    %

    properties(Access = public)
        % local quantities
        time
        states
        controls
        localParameters

        % dual variables
        lowerBoundMultipliers
        upperBoundMultipliers
        constraintsMultipliers

        % global quantities
        globalParameters
        auxdata

        % extremal quantities
        initialTime
        initialStates
        initialControls
        finalTime
        finalStates
        finalControls
        upstreamParameters
    end

    methods

        function obj = inputData(globalParameters, auxdata)
            % class constructor
            if nargin == 2
                obj.globalParameters = globalParameters;
                obj.auxdata = auxdata;
            end
        end

    end
end