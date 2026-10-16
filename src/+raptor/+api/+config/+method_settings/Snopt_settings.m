classdef Snopt_settings
    %SNOPT_SETTINGS Summary of this class goes here
    %   Detailed explanation goes here

    properties
        %% HARD TERMINATION CONDITIONS

        % limit of minor sqp iterations
        minor_iterations_limit double {mustBeInteger} = 100000;

        % limit of overall iterations
        iterations_limit double {mustBeInteger} = 100000;

        %% PRIMARY CONVERGENCE CRITERIA

        % absolute tolerance on the constraint violation
        feasibility_tolerance double {mustBePositive} = 1e-16;

        %% OUTPUT SETTINGS

        % print every k-th major iteration
        major_print_level double {mustBeInteger} = 1;

        % print every k-th minor iteration
        minor_print_level double {mustBeInteger} = 1;
    end
end

