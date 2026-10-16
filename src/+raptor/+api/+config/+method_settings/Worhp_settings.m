classdef Worhp_settings
    % Worhp_settings  Settings for the WORHP nonlinear programming solver
    %
    %   Worhp_settings stores the raptor side configuration of the WORHP
    %   solver. The settings are translated into WORHP parameters and
    %   written into a private copy of the WORHP xml parameter file every
    %   time the problem is solved: neither the parameter template shipped
    %   with the toolbox nor the folder of the user are ever modified.
    %
    % -------------------------------------------------------------------------
    % PROPERTIES:
    %   license_file    - full path to the WORHP license file. When left
    %                     empty it is resolved automatically, first next to
    %                     the WORHP mex gateway and then in the third_party
    %                     folder of the toolbox.
    %   parameters_file - full path to the WORHP xml parameter template,
    %                     resolved in the same way as the license file.
    %   extraParameters - any additional WORHP parameter, given as a struct
    %                     or as a dictionary (a dictionary is required for
    %                     the dotted parameter names such as "qp.ipComTol").
    %                     These are applied last and therefore override the
    %                     parameters implied by the other settings.
    %
    % -------------------------------------------------------------------------
    % USAGE:
    %   problem.config.solver.method = "Worhp";
    %   problem.config.solver.settings.algorithm = "IP";
    %   problem.config.solver.settings.extraParameters.BFGSmaxblockSize = 5;
    %
    % -------------------------------------------------------------------------
    % NOTES:
    %   - WORHP looks for its license file in the current folder, and the
    %   WORHP_LICENSE_FILE environment variable cannot be set from within a
    %   running matlab session. The solver therefore runs inside a private
    %   temporary folder holding a copy of the license, and restores the
    %   original folder afterwards.
    %   - Use checkWorhpInstallation to diagnose a WORHP setup.
    %
    % -------------------------------------------------------------------------
    % SEE ALSO:
    %   raptor.api.config.SolverConfig, checkWorhpInstallation

    properties

        %% FILEKEEPING
        % full path to the worhp license file ("" resolves it automatically)
        license_file string = "";

        % full path to the parameters file ("" resolves it automatically)
        parameters_file string = "";

        % folder hosting the private run folders ("" uses the system
        % temporary folder)
        sandbox_root string = "";

        % whether to keep the private run folder after the solve, which is
        % useful to inspect the parameter file actually used by worhp
        keep_sandbox (1, 1) logical = false;

        %% ALGORITHM CHOICE
        algorithm string {mustBeMember(algorithm, ["SQP", "IP"])} = "SQP";

        %% HARD TERMINATION CONDITIONS

        % solve time limit in seconds
        Timeout double {mustBePositive} = 60*60*24*7;

        %% PRIMARY CONVERGENCE CRITERIA

        % tolerance on feasibility (the default sentinel value makes the
        % feasibility tolerance follow the solver tolerance)
        TolFeas double {mustBePositive} = 1e-16;

        %% ACCEPTABLE CONVERGENCE CRITERIA

        % optimality tolerance for acceptable iterations
        AcceptTolOpti double {mustBePositive} = 1e-3;

        % feasibility tolerance for acceptable iterations
        AcceptTolFeas double {mustBePositive} = 1e-3;

        % whether to keep the acceptable iterations as solution
        KeepAcceptableSol (1, 1) logical = true;

        %% DERIVATIVES SETTINGS

        % whether the Hessian is provided via raptor or not (raptor does
        % not compute second derivatives, so this must stay false)
        ProvideHessian (1, 1) logical = false;

        % which internal approximation of the Hessian is used
        InternalHessianApproximation string {mustBeMember(InternalHessianApproximation, ["FiniteDifference", "BFGS"])} = "BFGS";

        % which finite difference approach to use for the Hessian
        WhichFiniteDiff string {mustBeMember(WhichFiniteDiff, ["Central", "Forward"])} = "Central";

        % how much to perturb to compute finite differences
        FiniteDiffEps double = 1e-5;

        %% PROBLEM DATA SETTINGS

        % value above which a bound is considered infinite by worhp, used
        % to clip the infinite bounds of the transcribed problem
        InftyUnbounded double {mustBePositive} = 1e20;

        %% OUTPUT SETTINGS

        % level of detail in the printing
        NLPprint double {mustBeInteger} = 1;

        % how many days before the license expiry a warning is issued
        licenseExpiryWarningDays double {mustBeNonnegative} = 30;

        %% ADDITIONAL WORHP PARAMETERS

        % any further worhp parameter, applied after all the others
        extraParameters = struct();
    end

    methods

        function obj = Worhp_settings()
            % class constructor, which resolves the default license and
            % parameter files so that the user can see, and override, the
            % files that are going to be used. A missing installation is
            % not an error here: it is reported when the problem is solved
            installation = raptor.core.utils.worhpResolveInstallation();
            obj.license_file = installation.licenseFile;
            obj.parameters_file = installation.parametersFile;
        end

        function params = collectParameters(obj, tol, iter_limit)
            % collectParameters Translate the settings into WORHP parameters.
            %
            %   params = collectParameters(obj, tol, iter_limit) returns the
            %   WORHP parameters implied by the settings and by the solver
            %   tolerance and iteration limit, as an Nx2 cell array of
            %   name/value pairs.
            %
            %   Inputs:
            %       tol        - solver optimality tolerance
            %       iter_limit - maximum number of major iterations
            %
            %   Outputs:
            %       params - Nx2 cell array of WORHP name/value pairs
            %
            %   Example:
            %       params = settings.collectParameters(1e-8, 3000);

            % raptor never supplies second derivatives, so asking worhp to
            % use a user Hessian would fail inside the mex gateway
            if obj.ProvideHessian
                raptor.core.utils.Logger.err("solver:Worhp", "ProvideHessian is " + ...
                    "enabled, but raptor does not compute second derivatives. " + ...
                    "Leave it false and select the Hessian approximation through " + ...
                    "InternalHessianApproximation.");
            end

            % feasibility follows the solver tolerance unless the user
            % moved it away from its sentinel default
            if obj.TolFeas == 1e-16
                tolFeas = tol;
            else
                tolFeas = obj.TolFeas;
            end

            % the internal hessian approximation selects between finite
            % differences and the quasi-newton update
            isFiniteDifferenceHessian = obj.InternalHessianApproximation == "FiniteDifference";
            isCentralDifference = obj.WhichFiniteDiff == "Central";

            params = { ...
                "MaxIter",           iter_limit; ...
                "Timeout",           obj.Timeout; ...
                "TolOpti",           tol; ...
                "TolFeas",           tolFeas; ...
                "AcceptTolOpti",     obj.AcceptTolOpti; ...
                "AcceptTolFeas",     obj.AcceptTolFeas; ...
                "KeepAcceptableSol", obj.KeepAcceptableSol; ...
                "Algorithm",         1 + (obj.algorithm == "IP"); ...
                "UserHM",            false; ...
                "FidifHM",           isFiniteDifferenceHessian; ...
                "BFGSmethod",        1; ...
                "FirstDifCentral",   isCentralDifference; ...
                "SecondDifCentral",  isCentralDifference; ...
                "FidifEps",          obj.FiniteDiffEps; ...
                "InftyUnbounded",    obj.InftyUnbounded; ...
                "NLPprint",          obj.NLPprint};

            % finally apply the user defined parameters, which are allowed
            % to override everything above
            params = localAppendExtraParameters(params, obj.extraParameters);
        end

    end

end

function params = localAppendExtraParameters(params, extraParameters)
% helper appending the user defined parameters to the name/value list,
% dropping the entries they override so that each name appears only once
if isempty(extraParameters)
    return
end

% collect the extra parameters from any of the accepted containers
if isstruct(extraParameters)
    extraNames = string(fieldnames(extraParameters));
    extraValues = struct2cell(extraParameters);
elseif isa(extraParameters, "dictionary")
    extraNames = string(keys(extraParameters));
    extraValues = values(extraParameters);
elseif isa(extraParameters, "containers.Map")
    extraNames = string(keys(extraParameters));
    extraValues = values(extraParameters);
else
    raptor.core.utils.Logger.err("solver:Worhp", "extraParameters must be a " + ...
        "struct, a dictionary or a containers.Map.");
end
if ~iscell(extraValues)
    extraValues = num2cell(extraValues);
end
if isempty(extraNames)
    return
end

% the user defined values win over the ones implied by the settings
isOverridden = ismember(string(params(:, 1)), extraNames(:));
params = [params(~isOverridden, :); [cellstr(extraNames(:)), extraValues(:)]];
params(:, 1) = cellstr(string(params(:, 1)));
end
