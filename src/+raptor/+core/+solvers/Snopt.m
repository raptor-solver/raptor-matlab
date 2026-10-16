classdef Snopt < raptor.core.abstract.Solver
    % core class implementing the interface to the snopt solver

    properties (SetAccess = protected, GetAccess = public)
        % TODO: check whether to add properties here or not
    end

    methods
        function obj = Snopt(cfg)
            % superclass constructor
            if nargin == 0
                super_args = {};
            else
                super_args = {cfg};
            end
            obj@raptor.core.abstract.Solver(super_args{:});
        end

        function [solution, Z, lambda, zl, zu] = solve(obj, ocp, trajectories, transcription, scaling, raw)
            % wrapper method that sets up and calls the snopt solver

            % start defining the options for the snopt solver
            clear SNOPT_AUX
            global igrid SNOPT_AUX
            clear snoptcmex
            SNOPT_AUX.transcription = transcription;
            SNOPT_AUX.scaling = scaling;

            % set the snopt termination criteria
            snseti('Verify Level', -1);
            snseti('Iteration Limit', obj.settings.iterations_limit);
            snseti('Major Iterations Limit', obj.iter_limit);
            snseti('Minor Iterations Limit', obj.settings.minor_iterations_limit);
            % snsetr('Time limit', obj.settings.termination_wall_time);

            % set the snopt convergence criteria
            snsetr('Optimality Tolerance', obj.tol);
            if obj.settings.feasibility_tolerance == 1e-16
                snsetr('Feasibility Tolerance', 2 * obj.tol);
            else
                snsetr('Feasibility Tolerance', obj.settings.feasibility_tolerance);
            end

            % set the snopt output behavior
            snscreen on;
            snseti('Major print level', 1);
            snseti('Minor print level', 1);

            % set the raptor-specific snopt adjustments
            snset('Hessian Limited Memory');
            snseti('Derivative Option', 1);

            % set the variable bounds and initial guess
            ig = trajectories.initialGuess;
            lb = trajectories.lowerBound;
            ub = trajectories.upperBound;
            Z0 = scaling.scaleDecisionVector(transcription.getGlobalVariable(ig));
            ZL = scaling.scaleDecisionVector(transcription.getGlobalVariable(lb));
            ZU = scaling.scaleDecisionVector(transcription.getGlobalVariable(ub));

            % set the constraint bounds
            CL = scaling.scaleConstraint(transcription.getConstraintBounds("lowerBound"));
            CU = scaling.scaleConstraint(transcription.getConstraintBounds("upperBound"));

            % compute the indexes for sparsity reconstruction
            objPattern = ones(1, length(Z0));
            fullPattern = [objPattern; full(transcription.getPattern)];
            [SNOPT_AUX.iGfun, SNOPT_AUX.jGvar] = find(fullPattern);

            % initialize variables and constraints multipliers
            if ~isempty(raw)
                % state and constraint multipliers
                Zmul = raw.zl - raw.zu;
                Fmul = - [0; raw.lambda];

                % state and constraints internal state
                tolBound = 1e-8; tolMult = 1e-6;
                Zstate = 2 * ones(size(Z0));
                Zstate(abs(Z0 - ZL) < tolBound & Zmul > tolMult) = 0;
                Zstate(abs(Z0 - ZU) < tolBound & Zmul < - tolMult) = 1;
                Fstate = 2 * ones(size(CL, 1) + 1, 1);
                [F, ~] = snopt_usrfun(Z0);
                Fstate(abs(F - [-Inf; CL]) < tolBound & Fmul > tolMult) = 0;
                Fstate(abs(F - [Inf; CU]) < tolBound & Fmul < - tolMult) = 1;
            else
                % state and constraints multipliers
                Zmul = zeros(size(Z0));
                Fmul = zeros(size(CL, 1) + 1, 1);

                % state and constraints internal state
                Zstate = zeros(size(Z0));
                Fstate = zeros(size(CL, 1) + 1, 1);
            end

            % call to external snopt solver
            tic;
            [Z, ~, Zmul, Fmul, info, ~, ~, ~, ~, ~, ~, ~, ~] = ...
                snsolve( Z0, ZL, ZU, Zmul, Zstate, [-Inf; CL], [Inf; CU], ...
                Fmul, Fstate, 0, 1, [], [], [], SNOPT_AUX.iGfun, ...
                SNOPT_AUX.jGvar, 'snopt_usrfun');
            solveTime = toc;
            clear SNOPT_AUX

            % reassemble solution vector
            Z = scaling.descaleDecisionVector(Z);
            zlu = scaling.descaleBoxMultipliers(Zmul);
            zl = max(zlu, 0);
            zu = max(- zlu, 0);
            lambda = - scaling.descaleMultipliers(Fmul(2 : end));

            % build the initial solution structure
            solution.solveTime = solveTime;
            solution.nIterations = Inf;
            solution.exitStatus = (info == 1);
            solution.objective = transcription.getObjective(Z);
            solution.raw.zl = max(Zmul, 0);
            solution.raw.zu = max(- Zmul, 0);
            solution.raw.lambda = - Fmul(2 : end);
        end
    end
end

