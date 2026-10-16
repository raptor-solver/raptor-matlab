classdef Solver < handle
    % Abstract solver class defining the base interface methods for the NLP
    % solver
    
    properties(SetAccess = protected, GetAccess = public)
        % solver settings
        settings
        tol
        iter_limit
    end
    
    methods
        function obj = Solver(cfg)
            % constructor
            obj.settings = cfg.settings;
            obj.tol = cfg.tol;
            obj.iter_limit = cfg.iter_limit;
        end
        
    end

    methods (Abstract)

        solution = solve(obj, ocp, trajectories, transcription, scaling, raw)
        % TODO: adjust when adjusting the solver object

    end
end

