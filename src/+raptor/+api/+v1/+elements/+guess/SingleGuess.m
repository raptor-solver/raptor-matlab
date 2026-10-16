classdef SingleGuess
    %SINGLEGUESS Summary of this class goes here
    %   Detailed explanation goes here

    properties
        time            (1, :)
        states          (:, :)
        controls        (:, :)
        localParameters (:, 1)
    end

    methods
        function obj = SingleGuess(nStates, nControls, nLocalParameters)
            % constructor
            obj.time = NaN;
            obj.states = nan(nStates, 1);
            obj.controls = nan(nControls, 1);
            obj.localParameters = nan(nLocalParameters, 1);
        end

    end
end

