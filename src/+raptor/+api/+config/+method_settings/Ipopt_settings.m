classdef Ipopt_settings
    %IPOPT_SETTINGS Summary of this class goes here
    %   Detailed explanation goes here

    properties
        %% HARD TERMINATION CONDITIONS

        % solve time limit in seconds
        termination_wall_time double {mustBePositive} = 1e20;

        %% PRIMARY CONVERGENCE CRITERIA

        % absolute tolerance on the dual infeasibility
        convergence_dual_infeasibility_tol double {mustBePositive} = 1;

        % absolute tolerance on the constraint violation
        convergence_constraint_violation_tol double {mustBePositive} = 0.0001;

        % absolute tolerance on the complementarity conditions
        convergence_complementarity_tol double {mustBePositive} = 0.0001;

        %% ITERATION PARAMETERS

        % interior point barrier parameter update strategy
        parameters_mu_strategy string {mustBeMember(parameters_mu_strategy, ...
            ["monotone", "adaptive"])} = "adaptive";

        %% ACCEPTABLE CONVERGENCE CRITERIA

        % relative tolerance for acceptable iterations
        acceptance_rel_tol double {mustBePositive} = 1e-6;

        % number of acceptable iterates before termination
        acceptance_consecutive_iters_limit double {mustBeInteger} = 15;

        % absolute tolerance for the dual infeasibility on acceptable
        % iterates
        acceptance_dual_infeasibility_tol double {mustBePositive} = 1e10;

        % absolute tolerance for the constraint violation on acceptable
        % iterates
        acceptance_constraint_violation_tol double {mustBePositive} = 0.01;

        % absolute tolerance for acceptable complementarity conditions
        acceptance_complementarity_tol double {mustBePositive} = 0.01;

        % absolute tolerance on the change in objective value between
        % consecutive iterates
        acceptance_objective_change_tol double {mustBePositive} = 1e20;

        %% FAILURE CRITERIA

        % maximum value allowed on any primal iterate
        failure_diverging_iterates_threshold double = 1e20;

        %% OUTPUT SETTINGS

        % level of detail in the printing
        output_print_level double = 5;

        % flag to print or not the user options at the start
        output_print_options string {mustBeMember(output_print_options, ["yes", "no"])} = "no";
    end
end

