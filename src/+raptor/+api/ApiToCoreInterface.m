classdef (Abstract) ApiToCoreInterface < handle
    %APITOCOREINTERFACE  Base interface between api and core solver
    %
    % base class defining the required methods needed for a valid api
    % representation of the optimal control problem to correctly interface
    % with the core side of the solver.
    
    methods (Abstract)
        % method that outputs the raptor.core.OptimalControlProblem object
        % correctly populated with its properties
        [ocp, trajectories, postprocessing] = build(obj)
    end
end