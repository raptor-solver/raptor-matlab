function results = inspectNlpConditioning(Z, funcs, options)
%INSPECTNLPCONDITIONING Inspect the local conditioning of a transcribed NLP.
%
%   RESULTS = INSPECTNLPCONDITIONING(Z, FUNCS) evaluates the standard
%   RAPTOR NLP callbacks at the current point Z and computes diagnostics
%   for the constraint Jacobian. FUNCS uses the same callback names and
%   signatures assembled by the RAPTOR solver interface:
%
%       objective   = funcs.objective(Z)
%       gradient    = funcs.gradient(Z)
%       constraints = funcs.constraints(Z)
%       jacobian    = funcs.jacobian(Z)
%
%   This permits the utility to be called directly after FUNCS is assembled
%   in a solver, including from a breakpoint or iteration callback.
%
%   Name-value options:
%
%       ConstraintIndices   Rows of the constraint Jacobian to inspect.
%                           The default is all rows. Selecting equality and
%                           active inequality rows gives the appropriate
%                           linearization for an active-set KKT analysis.
%       Multipliers         Full or selected constraint multipliers. The
%                           default is zero.
%       HessianMode         "none" (default), "finite-difference", or
%                           "identity". The latter is an explicitly labeled
%                           first-order KKT surrogate.
%       ConditionMethod     "cond" (default) or "condest". The default uses
%                           MATLAB's exact cond(A, 2). For a rectangular
%                           Jacobian, "condest" uses the square root of the
%                           condition estimate of the smaller Gram matrix.
%       FiniteDifferenceStep
%                           Relative central-difference step used to recover
%                           the Lagrangian Hessian. Default: eps^(1/3).
%       SymmetrizeHessian   Replace H by (H + H') / 2. Default: true.
%       ReturnMatrices      Include J, H, and KKT in RESULTS. Default: false.
%
%   With a requested Hessian mode, the equality-constrained KKT matrix is
%
%       K = [H, J'; J, 0].
%
%   This is not necessarily the matrix internally factorized by an NLP
%   solver. Interior-point and SQP implementations may add slack, barrier,
%   regularization, scaling, and quasi-Newton terms that are not exposed by
%   RAPTOR's first-order callbacks.
%
%   Examples:
%
%       % Directly inspect the scaled callbacks assembled in a solver.
%       info = inspectNlpConditioning(Z, funcs);
%
%       % Faster sparse estimate for a large transcription.
%       info = inspectNlpConditioning(Z, funcs, ...
%           ConditionMethod = "condest");
%
%       % Local KKT matrix using a finite-difference Lagrangian Hessian.
%       info = inspectNlpConditioning(Z, funcs, ...
%           HessianMode = "finite-difference", ...
%           Multipliers = lambda, ...
%           ConstraintIndices = activeRows);
%
%   For a meaningful scaled/unscaled or Lagrange/Birkhoff comparison, use
%   the same ConditionMethod and equivalent constraint-row selections in
%   every case. Z and Multipliers must use the same coordinates as FUNCS.
%
%   If no output is requested, a compact summary is printed. The function
%   does not modify Z, FUNCS, or solver state.

arguments
    Z (:, 1) double
    funcs (1, 1) struct
    options.ConstraintIndices (:, 1) double {mustBeInteger, mustBePositive} = zeros(0, 1)
    options.Multipliers (:, 1) double = zeros(0, 1)
    options.HessianMode (1, 1) string {mustBeMember(options.HessianMode, ...
        ["none", "finite-difference", "identity"])} = "none"
    options.ConditionMethod (1, 1) string {mustBeMember(options.ConditionMethod, ...
        ["cond", "condest"])} = "cond"
    options.FiniteDifferenceStep (1, 1) double {mustBePositive} = eps^(1 / 3)
    options.SymmetrizeHessian (1, 1) logical = true
    options.ReturnMatrices (1, 1) logical = false
end

validateCallbacks(funcs);

% Evaluate the same callbacks exposed to the NLP solver. A scaled callback
% bundle therefore diagnoses the scaled NLP, while an unscaled bundle
% diagnoses the physical transcription.
objective = funcs.objective(Z);
gradient = funcs.gradient(Z);
constraints = funcs.constraints(Z);
fullJacobian = funcs.jacobian(Z);

if ~isscalar(objective)
    error("RAPTOR:inspectNlpConditioning:InvalidObjective", ...
        "The objective callback must return a scalar.");
end
if numel(gradient) ~= numel(Z)
    error("RAPTOR:inspectNlpConditioning:InvalidGradient", ...
        "The gradient callback must return %d elements.", numel(Z));
end
if ~ismatrix(fullJacobian) || size(fullJacobian, 2) ~= numel(Z)
    error("RAPTOR:inspectNlpConditioning:InvalidJacobian", ...
        "The Jacobian callback must return an m-by-%d matrix.", numel(Z));
end
if numel(constraints) ~= size(fullJacobian, 1)
    error("RAPTOR:inspectNlpConditioning:InvalidConstraints", ...
        "The constraints and Jacobian callbacks must return the same number of rows.");
end

nConstraints = size(fullJacobian, 1);
constraintIndices = selectConstraintIndices(options.ConstraintIndices, nConstraints);
jacobian = fullJacobian(constraintIndices, :);
selectedConstraints = constraints(constraintIndices);
[multipliers, fullMultipliers] = selectMultipliers(options.Multipliers, ...
    constraintIndices, nConstraints);

% Store point-level quantities useful when comparing the same physical
% iterate across multiple transcription or scaling configurations.
results.objective = objective;
results.gradientNorm2 = norm(gradient, 2);
results.constraintNorm2 = norm(selectedConstraints, 2);
results.constraintNormInf = norm(selectedConstraints, Inf);
results.stationarityNorm2 = norm(gradient(:) + jacobian' * multipliers, 2);
results.pointSize = numel(Z);
results.constraintIndices = constraintIndices;
results.jacobian = matrixCondition(jacobian, options.ConditionMethod);

% A KKT matrix is optional because first-order solver callbacks do not
% define the Hessian block or the solver-specific barrier terms.
results.kkt = emptyKktResults(options.HessianMode);
if options.HessianMode ~= "none"
    hessian = assembleHessian(Z, funcs, options.HessianMode, ...
        multipliers, constraintIndices, options.FiniteDifferenceStep);
    if ~ismatrix(hessian) || ~isequal(size(hessian), [numel(Z), numel(Z)])
        error("RAPTOR:inspectNlpConditioning:InvalidHessian", ...
            "The Hessian must be a %d-by-%d matrix.", numel(Z), numel(Z));
    end
    if options.SymmetrizeHessian
        hessian = 0.5 .* (hessian + hessian');
    end

    sparseJacobian = sparse(jacobian);
    kkt = [sparse(hessian), sparseJacobian'; ...
        sparseJacobian, sparse(size(sparseJacobian, 1), size(sparseJacobian, 1))];
    results.kkt = matrixCondition(kkt, options.ConditionMethod);
    results.kkt.computed = true;
    results.kkt.hessianMode = options.HessianMode;

    if options.ReturnMatrices
        results.hessianMatrix = hessian;
        results.kktMatrix = kkt;
    end
end

if options.ReturnMatrices
    results.jacobianMatrix = jacobian;
    results.fullMultipliers = fullMultipliers;
end

if nargout == 0
    printSummary(results);
end

end

function validateCallbacks(funcs)
% Validate the callback bundle used by the RAPTOR solver interface.
requiredCallbacks = ["objective", "gradient", "constraints", "jacobian"];
for name = requiredCallbacks
    if ~isfield(funcs, name) || ~isa(funcs.(name), "function_handle")
        error("RAPTOR:inspectNlpConditioning:MissingCallback", ...
            "funcs.%s must be a function handle accepting the current NLP point.", ...
            name);
    end
end
end

function indices = selectConstraintIndices(requestedIndices, nConstraints)
% Validate or generate the selected constraint-row indices.
if isempty(requestedIndices)
    indices = (1 : nConstraints)';
    return
end

indices = requestedIndices;
if any(indices > nConstraints)
    error("RAPTOR:inspectNlpConditioning:InvalidConstraintIndices", ...
        "ConstraintIndices contains an index greater than the %d available constraints.", ...
        nConstraints);
end
if numel(unique(indices)) ~= numel(indices)
    error("RAPTOR:inspectNlpConditioning:DuplicateConstraintIndices", ...
        "ConstraintIndices must not contain duplicate rows.");
end
end

function [selected, full] = selectMultipliers(multipliers, indices, nConstraints)
% Normalize full and row-selected multiplier inputs.
if isempty(multipliers)
    full = zeros(nConstraints, 1);
    selected = full(indices);
elseif numel(multipliers) == nConstraints
    full = multipliers;
    selected = full(indices);
elseif numel(multipliers) == numel(indices)
    selected = multipliers;
    full = zeros(nConstraints, 1);
    full(indices) = selected;
else
    error("RAPTOR:inspectNlpConditioning:InvalidMultipliers", ...
        ["Multipliers must contain either one value per constraint " ...
        "(%d) or one value per selected row (%d)."], ...
        nConstraints, numel(indices));
end
end

function hessian = assembleHessian(Z, funcs, mode, multipliers, ...
        constraintIndices, finiteDifferenceStep)
% Assemble a Lagrangian Hessian or an explicitly requested surrogate.
switch mode
    case "identity"
        hessian = speye(numel(Z));

    case "finite-difference"
        hessian = zeros(numel(Z));
        for column = 1 : numel(Z)
            step = finiteDifferenceStep * max(1, abs(Z(column)));
            pointPlus = Z;
            pointMinus = Z;
            pointPlus(column) = pointPlus(column) + step;
            pointMinus(column) = pointMinus(column) - step;

            gradientPlus = lagrangianGradient(pointPlus, funcs, ...
                multipliers, constraintIndices);
            gradientMinus = lagrangianGradient(pointMinus, funcs, ...
                multipliers, constraintIndices);
            hessian(:, column) = (gradientPlus - gradientMinus) ./ (2 * step);
        end
end
end

function gradient = lagrangianGradient(Z, funcs, multipliers, constraintIndices)
% Evaluate the Lagrangian gradient from RAPTOR's first-order callbacks.
objectiveGradient = funcs.gradient(Z);
if numel(objectiveGradient) ~= numel(Z)
    error("RAPTOR:inspectNlpConditioning:InvalidGradient", ...
        "The gradient callback must return %d elements.", numel(Z));
end

constraintJacobian = funcs.jacobian(Z);
if ~ismatrix(constraintJacobian) || size(constraintJacobian, 2) ~= numel(Z)
    error("RAPTOR:inspectNlpConditioning:InvalidJacobian", ...
        "The Jacobian callback must return an m-by-%d matrix.", numel(Z));
end
if any(constraintIndices > size(constraintJacobian, 1))
    error("RAPTOR:inspectNlpConditioning:ChangingConstraintSize", ...
        "The Jacobian callback changed its number of constraint rows.");
end

gradient = objectiveGradient(:) + ...
    constraintJacobian(constraintIndices, :)' * multipliers;
end

function stats = matrixCondition(matrix, method)
% Compute a condition number using MATLAB's standard matrix utilities.
stats.size = size(matrix);
stats.nnz = nnz(matrix);
stats.structuralRank = sprank(matrix);
stats.conditionNumber = NaN;
stats.reciprocalConditionNumber = NaN;
stats.method = "not evaluated";

rowNorms = vecnorm(matrix, 2, 2);
columnNorms = vecnorm(matrix, 2, 1);
stats.zeroRows = find(rowNorms == 0);
stats.zeroColumns = find(columnNorms == 0)';
stats.rowNormMinimum = minimumNonzero(rowNorms);
stats.rowNormMaximum = maximumOrZero(rowNorms);
stats.rowNormSpread = safeRatio(stats.rowNormMaximum, stats.rowNormMinimum);
stats.columnNormMinimum = minimumNonzero(columnNorms);
stats.columnNormMaximum = maximumOrZero(columnNorms);
stats.columnNormSpread = safeRatio(stats.columnNormMaximum, stats.columnNormMinimum);

if any(size(matrix) == 0) || stats.nnz == 0
    stats.conditionNumber = Inf;
    stats.reciprocalConditionNumber = 0;
    stats.method = "empty or zero matrix";
    return
end

if method == "cond"
    % cond(A, 2) supports rectangular matrices and is the spectral
    % condition number normally reported for pseudospectral operators.
    stats.conditionNumber = cond(full(matrix), 2);
    stats.reciprocalConditionNumber = safeReciprocal(stats.conditionNumber);
    stats.method = "cond(A, 2)";
elseif size(matrix, 1) == size(matrix, 2)
    % condest directly supports large sparse square matrices such as KKT
    % systems and estimates their one-norm condition number.
    stats.conditionNumber = condest(sparse(matrix));
    stats.reciprocalConditionNumber = safeReciprocal(stats.conditionNumber);
    stats.method = "condest(A)";
else
    % condest requires a square matrix. The smaller Gram matrix avoids the
    % structurally singular choice when the Jacobian is rectangular. The
    % square root maps the squared Gram conditioning back to the Jacobian.
    if size(matrix, 1) <= size(matrix, 2)
        gramMatrix = sparse(matrix * matrix');
        stats.method = "sqrt(condest(A*A'))";
    else
        gramMatrix = sparse(matrix' * matrix);
        stats.method = "sqrt(condest(A'*A))";
    end
    stats.conditionNumber = sqrt(condest(gramMatrix));
    stats.reciprocalConditionNumber = safeReciprocal(stats.conditionNumber);
end
end

function value = minimumNonzero(values)
% Return the smallest nonzero norm, or zero when none exists.
nonzeroValues = values(values > 0);
if isempty(nonzeroValues)
    value = 0;
else
    value = min(nonzeroValues, [], "all");
end
end

function value = maximumOrZero(values)
% Return the largest norm, or zero for an empty matrix dimension.
if isempty(values)
    value = 0;
else
    value = max(values, [], "all");
end
end

function ratio = safeRatio(numerator, denominator)
% Form a diagnostic ratio with a useful zero-denominator convention.
if denominator == 0
    ratio = Inf;
else
    ratio = numerator ./ denominator;
end
end

function reciprocal = safeReciprocal(value)
% Return a stable reciprocal-condition representation.
if isinf(value)
    reciprocal = 0;
else
    reciprocal = 1 ./ value;
end
end

function results = emptyKktResults(hessianMode)
% Initialize a consistent result structure when no KKT matrix is requested.
results.computed = false;
results.hessianMode = hessianMode;
results.size = [0 0];
results.nnz = 0;
results.structuralRank = 0;
results.conditionNumber = NaN;
results.reciprocalConditionNumber = NaN;
results.method = "not requested";
results.zeroRows = zeros(0, 1);
results.zeroColumns = zeros(0, 1);
results.rowNormMinimum = NaN;
results.rowNormMaximum = NaN;
results.rowNormSpread = NaN;
results.columnNormMinimum = NaN;
results.columnNormMaximum = NaN;
results.columnNormSpread = NaN;
end

function printSummary(results)
% Print a compact summary for interactive use.
fprintf("Constraint Jacobian: %d-by-%d\n", ...
    results.jacobian.size(1), results.jacobian.size(2));
fprintf("  condition number : %.6e  [%s]\n", ...
    results.jacobian.conditionNumber, results.jacobian.method);
fprintf("  row norm spread  : %.6e\n", results.jacobian.rowNormSpread);
fprintf("  column norm spread: %.6e\n", results.jacobian.columnNormSpread);
fprintf("  zero rows/columns: %d / %d\n", ...
    numel(results.jacobian.zeroRows), numel(results.jacobian.zeroColumns));

if results.kkt.computed
    fprintf("KKT matrix: %d-by-%d\n", ...
        results.kkt.size(1), results.kkt.size(2));
    fprintf("  condition number : %.6e  [%s, %s Hessian]\n", ...
        results.kkt.conditionNumber, results.kkt.method, ...
        results.kkt.hessianMode);
end
end
