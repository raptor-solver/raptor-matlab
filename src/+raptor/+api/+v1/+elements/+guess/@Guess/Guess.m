classdef Guess < handle
    %GUESS Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % guess objects
        initial     raptor.api.v1.elements.guess.SingleGuess
        final       raptor.api.v1.elements.guess.SingleGuess
        continuous  raptor.api.v1.elements.guess.SingleGuess
    end

    properties (Hidden)
        % reference to the phase object
        phase
        % flag to indicate a guess that has already been filled
        isBuilt = false;
    end

    methods
        function obj = Guess(nStates, nControls, nLocalParameters, phase)
            % constructor
            import raptor.api.v1.elements.guess.*

            obj.initial = SingleGuess(nStates, nControls, nLocalParameters);
            obj.final = SingleGuess(nStates, nControls, nLocalParameters);
            obj.continuous = SingleGuess(nStates, nControls, nLocalParameters);
            obj.phase = phase;
        end

        % guess generation methods
        linear(obj)
        fromControl(obj)
    end

    methods (Hidden, Access = protected)
        % utility methods
        rebuildAttemptError(obj)
    end
end

