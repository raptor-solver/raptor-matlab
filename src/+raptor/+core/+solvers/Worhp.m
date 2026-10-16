classdef Worhp < raptor.core.abstract.Solver
    % Concrete solver class implementation for the solution through the
    % Worhp solver
    %
    %   The WORHP library reads its license from the current folder, so the
    %   solve is run inside a private temporary folder created by
    %   raptor.core.utils.worhpOpenSession and removed, together with the
    %   original working folder, by raptor.core.utils.worhpCloseSession. The
    %   folder of the user is never written into.

    properties (SetAccess = protected, GetAccess = public)
        % TODO: check whether to add properties here or not
    end

    methods
        function obj = Worhp(cfg)
            % superclass constructor
            if nargin == 0
                super_args = {};
            else
                super_args = {cfg};
            end
            obj@raptor.core.abstract.Solver(super_args{:});
        end

        function [solution, Z, lambda, zl, zu] = solve(obj, ocp, trajectories, transcription, scaling, raw)
            % wrapper method that sets up and calls the worhp solver

            % translate the raptor settings into worhp parameters
            params = obj.settings.collectParameters(obj.tol, obj.iter_limit);

            % assemble the problem data and the callbacks before the
            % private folder is entered, so that any error raised while
            % evaluating the transcription is reported from the folder of
            % the user
            [wData, funcs] = obj.assembleProblem(trajectories, transcription, scaling, raw);

            % open the isolated worhp session and guarantee that the
            % original folder is restored whatever happens afterwards,
            % including an error or a ctrl+c interrupt
            session = raptor.core.utils.worhpOpenSession(obj.settings, params);
            sessionGuard = onCleanup(@() raptor.core.utils.worhpCloseSession(session));
            wData.param = char(session.paramFileName);

            % call to external worhp solver
            solveTimer = tic;
            try
                [Z, Zmul, Gmul, status] = worhp(wData, funcs);
            catch ME
                raptor.core.utils.Logger.err_worhpSolverFailure(ME, session);
            end
            solveTime = toc(solveTimer);

            % interpret the termination status, which worhp returns as a
            % code not smaller than 1000 on success and not larger than
            % -1000 on failure
            [exitStatus, statusCode, nIterations] = obj.interpretStatus(status);

            % a successful status with a non finite solution is a
            % contradiction, and must not be reported as a convergence
            if exitStatus && ~all(isfinite(Z))
                raptor.core.utils.Logger.warn("solver:Worhp", "WORHP reported a " + ...
                    "successful termination but returned a solution containing " + ...
                    "non finite entries, which is reported as a failure.");
                exitStatus = false;
            end

            % descale the primal and dual solution
            Z = scaling.descaleDecisionVector(Z);
            zlu = scaling.descaleBoxMultipliers(Zmul);
            zl = max(zlu, 0);
            zu = max(- zlu, 0);
            lambda = scaling.descaleMultipliers(Gmul);

            % build the initial solution structure, keeping the raw
            % multipliers in the scaled space used to warm start a re-solve
            solution.solveTime = solveTime;
            solution.nIterations = nIterations;
            solution.exitStatus = exitStatus;
            solution.exitCode = statusCode;
            solution.objective = transcription.getObjective(Z);
            solution.raw.zl = max(Zmul, 0);
            solution.raw.zu = max(- Zmul, 0);
            solution.raw.lambda = Gmul;
        end

    end

    methods (Access = private)

        function [wData, funcs] = assembleProblem(obj, trajectories, transcription, scaling, raw)
            % method assembling the worhp problem data structure and the
            % callback structure out of the transcribed problem

            % set the variable bounds and initial guess
            ig = trajectories.initialGuess;
            lb = trajectories.lowerBound;
            ub = trajectories.upperBound;
            Z0 = full(scaling.scaleDecisionVector(transcription.getGlobalVariable(ig)));
            XL = full(scaling.scaleDecisionVector(transcription.getGlobalVariable(lb)));
            XU = full(scaling.scaleDecisionVector(transcription.getGlobalVariable(ub)));

            % set the constraint bounds
            GL = full(scaling.scaleConstraint(transcription.getConstraintBounds("lowerBound")));
            GU = full(scaling.scaleConstraint(transcription.getConstraintBounds("upperBound")));

            % worhp treats as infinite any bound beyond InftyUnbounded, and
            % its input checks reject the genuinely infinite values, so the
            % bounds are clipped before being handed over
            infty = obj.settings.InftyUnbounded;
            XL = max(XL, - infty);
            XU = min(XU, infty);
            GL = max(GL, - infty);
            GU = min(GU, infty);

            % diagnose here the problem data that worhp would reject with a
            % message giving no indication of where the problem is
            obj.validateProblemData(Z0, XL, XU, GL, GU, infty);

            wData.XL = XL(:)';
            wData.XU = XU(:)';
            wData.xInit = Z0(:)';
            wData.GL = GL(:)';
            wData.GU = GU(:)';

            % warm start the solution when consistent raw multipliers are
            % available, and fall back to a cold start otherwise
            [wData.lambdaInit, wData.muInit] = obj.assembleWarmStart(raw, numel(Z0), numel(GL));

            % compute the indexes for sparsity reconstruction, keeping the
            % pattern sparse: densifying it costs n*m entries for nothing
            pattern = transcription.getPattern;
            [iGfun, jGvar] = find(pattern);
            wData.DFrow = int32(1 : numel(Z0));
            wData.DGrow = int32(iGfun(:)');
            wData.DGcol = int32(jGvar(:)');

            % worhp needs the structure of the hessian even when it builds
            % it itself, and expects the lower triangle row by row
            [wData.HMrow, wData.HMcol] = obj.assembleHessianStructure(numel(Z0));

            % the parameter file is assigned by the caller once the private
            % session folder exists, but the field must already be there:
            % the mex gateway checks that wData has exactly 13 fields
            wData.param = '';

            % set the problem definition functions. Every callback returns
            % a full array: the transcription and the scaling produce
            % sparse results, whose values the mex gateway would read as a
            % plain double buffer and silently misinterpret
            linearIdx = sub2ind(size(pattern), iGfun(:), jGvar(:));
            funcs.f = @(Z) full(scaling.scaleObjective(transcription.getObjective(scaling.descaleDecisionVector(Z))));
            funcs.df = @(Z) full(scaling.scaleGradient(transcription.getGradient(scaling.descaleDecisionVector(Z))));
            funcs.g = @(Z) full(scaling.scaleConstraint(transcription.getConstraint(scaling.descaleDecisionVector(Z))));
            funcs.dg = @jacobianValues;

            % the mex gateway checks that the callback structure has
            % exactly 5 fields, the structure of the jacobian being passed
            % through wData instead
            funcs.jacobianstructure = @transcription.getPattern;

            function G = jacobianValues(Z)
                % nested callback returning the jacobian values in the same
                % order as the sparsity pattern handed over to worhp
                J = scaling.scaleJacobian(transcription.getJacobian(scaling.descaleDecisionVector(Z)));
                G = full(J(linearIdx));
            end
        end

        function validateProblemData(~, Z0, XL, XU, GL, GU, infty)
            % method checking the problem data against the conditions that
            % the worhp input check rejects without saying where

            if any(~isfinite(Z0))
                raptor.core.utils.Logger.err("solver:Worhp", "The scaled initial " + ...
                    "guess contains %d non finite entries (first one at index %d).", ...
                    sum(~isfinite(Z0)), find(~isfinite(Z0), 1));
            end

            invalidBounds = find(isnan(XL) | isnan(XU));
            if ~isempty(invalidBounds)
                raptor.core.utils.Logger.err("solver:Worhp", "The scaled bounds of " + ...
                    "%d decision variables are NaN (first one at index %d).", ...
                    numel(invalidBounds), invalidBounds(1));
            end

            invalidBounds = find(isnan(GL) | isnan(GU));
            if ~isempty(invalidBounds)
                raptor.core.utils.Logger.err("solver:Worhp", "The scaled bounds of " + ...
                    "%d constraints are NaN (first one at row %d).", ...
                    numel(invalidBounds), invalidBounds(1));
            end

            crossedBounds = find(XL > XU);
            if ~isempty(crossedBounds)
                raptor.core.utils.Logger.err("solver:Worhp", "The lower bound is " + ...
                    "larger than the upper bound for %d decision variables " + ...
                    "(first one at index %d).", numel(crossedBounds), crossedBounds(1));
            end

            crossedBounds = find(GL > GU);
            if ~isempty(crossedBounds)
                raptor.core.utils.Logger.err("solver:Worhp", "The lower bound is " + ...
                    "larger than the upper bound for %d constraints " + ...
                    "(first one at index %d).", numel(crossedBounds), crossedBounds(1));
            end

            % a constraint with no finite bound constrains nothing, and is
            % rejected by the worhp input check
            freeConstraints = find(GL <= - infty & GU >= infty);
            if ~isempty(freeConstraints)
                raptor.core.utils.Logger.err("solver:Worhp", "%d constraints have " + ...
                    "no finite bound (first one at row %d). WORHP rejects such " + ...
                    "constraints: give them a bound or remove them from the problem.", ...
                    numel(freeConstraints), freeConstraints(1));
            end
        end

        function [lambdaInit, muInit] = assembleWarmStart(~, raw, nVariables, nConstraints)
            % method assembling the initial multipliers, falling back to a
            % cold start when the stored ones do not match the problem

            lambdaInit = zeros(1, nVariables);
            muInit = zeros(1, nConstraints);
            if isempty(raw)
                return
            end

            % a warm start coming from a different problem size would be
            % rejected by the mex gateway with no explanation
            hasFields = isstruct(raw) && all(isfield(raw, ["zl", "zu", "lambda"]));
            if ~hasFields || numel(raw.zl) ~= nVariables || numel(raw.zu) ~= nVariables ...
                    || numel(raw.lambda) ~= nConstraints
                raptor.core.utils.Logger.warn("solver:Worhp", "The multipliers of " + ...
                    "the previous solution do not match the current problem and " + ...
                    "were discarded: WORHP is started from zero multipliers.");
                return
            end

            boxMultipliers = full(raw.zl - raw.zu);
            lambdaInit = boxMultipliers(:)';
            muInit = full(raw.lambda(:))';
        end

        function [HMrow, HMcol] = assembleHessianStructure(~, nVariables)
            % method building the coordinate storage of the lower triangle
            % of the hessian, row by row, as expected by worhp

            nEntries = nVariables * (nVariables + 1) / 2;
            if nEntries > double(intmax("int32"))
                raptor.core.utils.Logger.err("solver:Worhp", "The problem has %d " + ...
                    "decision variables, for which the dense Hessian structure " + ...
                    "required by WORHP exceeds the size its interface can index. " + ...
                    "Reduce the number of nodes or use a different solver.", nVariables);
            end

            % the loop over the triangle is vectorised: the entries grow
            % with the square of the problem size, and building them one by
            % one dominates the setup time of any large problem
            rowLengths = (1 : nVariables)';
            rowOffsets = rowLengths .* (rowLengths - 1) / 2;
            HMrow = int32(repelem(rowLengths, rowLengths))';
            HMcol = int32((1 : nEntries)' - repelem(rowOffsets, rowLengths))';
        end

        function [exitStatus, statusCode, nIterations] = interpretStatus(~, status)
            % method extracting the termination information returned by the
            % worhp mex gateway, which is tolerant to a missing field

            statusCode = NaN;
            nIterations = NaN;
            if isstruct(status)
                if isfield(status, "termination_status")
                    statusCode = double(status.termination_status);
                end
                if isfield(status, "major_iterations")
                    nIterations = double(status.major_iterations);
                end
            end

            if isnan(statusCode)
                raptor.core.utils.Logger.warn("solver:Worhp", "WORHP did not return " + ...
                    "a termination status, and the solution is reported as failed.");
                exitStatus = false;
                return
            end

            [exitStatus, message] = raptor.core.utils.worhpStatusMessage(statusCode);
            if exitStatus
                raptor.core.utils.Logger.info("%s", message);
            else
                raptor.core.utils.Logger.warn("solver:Worhp", "%s", message);
            end
        end

    end
end
