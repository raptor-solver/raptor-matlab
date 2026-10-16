classdef Ipopt < raptor.core.abstract.Solver
    % Concrete solver class implementation for the solution through the
    % Ipopt solver

    properties (SetAccess = protected, GetAccess = public)
        % TODO: check whether to add properties here or not
    end

    methods
        function obj = Ipopt(cfg)
            % superclass constructor
            if nargin == 0
                super_args = {};
            else
                super_args = {cfg};
            end
            obj@raptor.core.abstract.Solver(super_args{:});
        end

        function [solution, Z, lambda, zl, zu] = solve(obj, ocp, trajectories, transcription, scaling, raw)
            % wrapper method that sets up and calls the ipopt solver

            % set the ipopt termination criteria
            options.ipopt.max_iter = obj.iter_limit;
            options.ipopt.max_wall_time = obj.settings.termination_wall_time;

            % set the ipopt convergence criteria
            options.ipopt.tol = obj.tol;
            options.ipopt.dual_inf_tol = obj.settings.convergence_dual_infeasibility_tol;
            options.ipopt.constr_viol_tol = obj.settings.convergence_constraint_violation_tol;
            options.ipopt.compl_inf_tol = obj.settings.convergence_complementarity_tol;

            % set the ipopt acceptance criteria
            options.ipopt.acceptable_tol = obj.settings.acceptance_rel_tol;
            options.ipopt.acceptable_iter = obj.settings.acceptance_consecutive_iters_limit;
            options.ipopt.acceptable_dual_inf_tol = obj.settings.acceptance_dual_infeasibility_tol;
            options.ipopt.acceptable_constr_viol_tol = obj.settings.acceptance_constraint_violation_tol;
            options.ipopt.acceptable_compl_inf_tol = obj.settings.acceptance_complementarity_tol;
            options.ipopt.acceptable_obj_change_tol = obj.settings.acceptance_objective_change_tol;

            % set the ipopt failure criteria
            options.ipopt.diverging_iterates_tol = obj.settings.failure_diverging_iterates_threshold;

            % set the ipopt output behavior
            options.ipopt.print_level = obj.settings.output_print_level;
            options.ipopt.print_user_options = char(obj.settings.output_print_options);

            % set the parameter adjustment rules
            options.ipopt.mu_strategy = char(obj.settings.parameters_mu_strategy);

            % set the raptor-specific ipopt adjustments
            options.ipopt.hessian_approximation = 'limited-memory';

            % set the problem definition functions
            funcs.gradient = @(Z) scaling.scaleGradient(transcription.getGradient(scaling.descaleDecisionVector(Z)));
            funcs.objective = @(Z) scaling.scaleObjective(transcription.getObjective(scaling.descaleDecisionVector(Z)));
            funcs.jacobian = @(Z) scaling.scaleJacobian(transcription.getJacobian(scaling.descaleDecisionVector(Z)));
            funcs.constraints = @(Z) scaling.scaleConstraint(transcription.getConstraint(scaling.descaleDecisionVector(Z)));
            funcs.jacobianstructure = @transcription.getPattern;

            % set the variable bounds and initial guess
            ig = trajectories.initialGuess;
            lb = trajectories.lowerBound;
            ub = trajectories.upperBound;
            Z0 = scaling.scaleDecisionVector(transcription.getGlobalVariable(ig));
            options.lb = scaling.scaleDecisionVector(transcription.getGlobalVariable(lb));
            options.ub = scaling.scaleDecisionVector(transcription.getGlobalVariable(ub));

            % set the constraint bounds
            options.cl = scaling.scaleConstraint(transcription.getConstraintBounds("lowerBound"));
            options.cu = scaling.scaleConstraint(transcription.getConstraintBounds("upperBound"));

            % warm start ipopt if previous raw results are provided as
            % input
            if ~isempty(raw)
                options.zl = raw.zl;
                options.zu = raw.zu;
                options.lambda = raw.lambda;
            end

            % % debug jacobians
            % fullJac = full(transcription.getJacobian(scaling.descaleDecisionVector(Z0)));
            % scaledJac = full(scaling.scaleJacobian(transcription.getJacobian(scaling.descaleDecisionVector(Z0))));
            % con = full(transcription.getConstraint(scaling.descaleDecisionVector(Z0)));
            % scaledCon = full(scaling.scaleConstraint(transcription.getConstraint(scaling.descaleDecisionVector(Z0))));
            % raptor.core.utils.diagnoseJacobian(fullJac, scaledJac);

            % call to external ipopt solver
            [Z, INFO] = ipopt_auxdata(Z0, funcs, options);
            Z = scaling.descaleDecisionVector(Z);
            zl = scaling.descaleBoxMultipliers(INFO.zl);
            zu = scaling.descaleBoxMultipliers(INFO.zu);
            lambda = scaling.descaleMultipliers(INFO.lambda);

            % build the initial solution structure
            solution.solveTime = INFO.cpu;
            solution.nIterations = INFO.iter;
            solution.exitStatus = (INFO.status == 0 || INFO.status == 1);
            solution.objective = transcription.getObjective(Z);
            solution.raw.zl = INFO.zl;
            solution.raw.zu = INFO.zu;
            solution.raw.lambda = INFO.lambda;
        end

    end
end

