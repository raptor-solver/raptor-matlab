function results = diagnoseJacobian(J, J_scaled)

fprintf('================ JACOBIAN DIAGNOSTICS ================\n');

[m,n] = size(J);
fprintf('Matrix size: %d x %d\n', m, n);

%% ============================================================
%% CONDITION NUMBER
%% ------------------------------------------------------------
% WHAT:
%   Ratio of largest to smallest singular value
%
% WHY:
%   Measures numerical sensitivity of linear solves Jx = b
%
% INTERPRETATION:
%   cond ~ 1           → perfectly conditioned cond ~ 1e3–1e6     →
%   moderate issues cond > 1e10        → serious instability
%
% SCALING EFFECT:
%   If scaling helps → problem was magnitude imbalance If not → structural
%   degeneracy (dependencies)
%% ============================================================

results.cond_full   = cond(J);
results.cond_scaled = cond(J_scaled);

fprintf('\nCondition number (full):   %.3e\n', results.cond_full);
fprintf('Condition number (scaled): %.3e\n', results.cond_scaled);

%% ============================================================
%% SVD WITH COLUMN/ROW ASSOCIATION
%% ------------------------------------------------------------
% KEY IDEA:
%   Each singular value corresponds to a direction:
%       J * v_i = sigma_i * u_i
%
%   v_i → combination of columns (variables)
%   u_i → combination of rows (equations)
%
%   We assign each singular value to:
%       - the column with largest weight in v_i
%       - the row with largest weight in u_i
%
% WHY:
%   Helps localize ill-conditioning to specific variables/equations
%
% LIMITATION:
%   This is an approximation (dominant contributor, not exact mapping)
%% ============================================================

[Uf,Sf,Vf] = svd(J,'econ');
[Us,Ss,Vs] = svd(J_scaled,'econ');

sf = diag(Sf);
ss = diag(Ss);

results.singular_values_full   = sf;
results.singular_values_scaled = ss;

% --- Dominant column/row indices (FULL) ---
[~, dom_col_full] = max(abs(Vf), [], 1);
[~, dom_row_full] = max(abs(Uf), [], 1);

% --- Dominant column/row indices (SCALED) ---
[~, dom_col_scaled] = max(abs(Vs), [], 1);
[~, dom_row_scaled] = max(abs(Us), [], 1);

results.dom_col_full   = dom_col_full;
results.dom_row_full   = dom_row_full;
results.dom_col_scaled = dom_col_scaled;
results.dom_row_scaled = dom_row_scaled;

% --- Sort by dominant column index ---
[sorted_cols_full, idx_sort_full] = sort(dom_col_full);
sf_sorted_by_col = sf(idx_sort_full);

[sorted_cols_scaled, idx_sort_scaled] = sort(dom_col_scaled);
ss_sorted_by_col = ss(idx_sort_scaled);

%% --- Plot: Singular values vs dominant column ---
figure('Name','SVD-ColMap','NumberTitle','off','WindowStyle','docked');

semilogy(sorted_cols_full, sf_sorted_by_col,'o','LineWidth',1.2); hold on;
semilogy(sorted_cols_scaled, ss_sorted_by_col,'x','LineWidth',1.2);

xlabel('Dominant column index');
ylabel('Singular value (log scale)');
title('Singular Values Mapped to Dominant Columns: Identifying Problematic Variables');
legend('Full','Scaled'); grid on;

%% --- Plot: Singular values vs dominant row ---
figure('Name','SVD-RowMap','NumberTitle','off','WindowStyle','docked');

[sorted_rows_full, idx_rf] = sort(dom_row_full);
sf_sorted_by_row = sf(idx_rf);

[sorted_rows_scaled, idx_rs] = sort(dom_row_scaled);
ss_sorted_by_row = ss(idx_rs);

semilogy(sorted_rows_full, sf_sorted_by_row,'o','LineWidth',1.2); hold on;
semilogy(sorted_rows_scaled, ss_sorted_by_row,'x','LineWidth',1.2);

xlabel('Dominant row index');
ylabel('Singular value (log scale)');
title('Singular Values Mapped to Dominant Rows: Identifying Problematic Equations');
legend('Full','Scaled'); grid on;

%% --- Keep worst directions ---
results.v_bad_full   = Vf(:,end);
results.u_bad_full   = Uf(:,end);
results.v_bad_scaled = Vs(:,end);
results.u_bad_scaled = Us(:,end);

%% ============================================================
%% ROW / COLUMN NORMS
%% ------------------------------------------------------------
% WHAT:
%   Magnitude of each row/column
%
% WHY:
%   Detect scaling imbalances
%
% INTERPRETATION:
%   - Wide spread → poor scaling - Very small norms → inactive
%   variables/equations - Uniform norms → good scaling
%
% SCALING EFFECT:
%   Should compress spread of norms
%% ============================================================

row_norms_full = vecnorm(J,2,2);
col_norms_full = vecnorm(J,2,1);

row_norms_scaled = vecnorm(J_scaled,2,2);
col_norms_scaled = vecnorm(J_scaled,2,1);

results.row_norms_full   = row_norms_full;
results.col_norms_full   = col_norms_full;
results.row_norms_scaled = row_norms_scaled;
results.col_norms_scaled = col_norms_scaled;

figure('Name','RowColNorms','NumberTitle','off','WindowStyle','docked');

subplot(2,2,1);
semilogy(row_norms_full,'LineWidth',1.2);
xlabel('Row index'); ylabel('Norm');
title('Row Norms (Full): Detecting Weak or Dominant Equations'); grid on;

subplot(2,2,2);
semilogy(col_norms_full,'LineWidth',1.2);
xlabel('Column index'); ylabel('Norm');
title('Column Norms (Full): Variable Scaling Imbalance'); grid on;

subplot(2,2,3);
semilogy(row_norms_scaled,'LineWidth',1.2);
xlabel('Row index'); ylabel('Norm');
title('Row Norms (Scaled): Should Become More Uniform'); grid on;

subplot(2,2,4);
semilogy(col_norms_scaled,'LineWidth',1.2);
xlabel('Column index'); ylabel('Norm');
title('Column Norms (Scaled): Check Scaling Effectiveness'); grid on;

%% ============================================================
%% COLUMN CORRELATION
%% ------------------------------------------------------------
% WHAT:
%   Correlation between columns
%
% WHY:
%   Detect linear dependence / redundancy
%
% INTERPRETATION:
%   |corr| ≈ 1 → columns nearly linearly dependent |corr| ≈ 0 → independent
%
% BAD SIGN:
%   Blocks of high correlation → redundant variables
%% ============================================================

C_full   = corrcoef(J);
C_scaled = corrcoef(J_scaled);

results.corr_full   = C_full;
results.corr_scaled = C_scaled;

figure('Name','ColCorr','NumberTitle','off','WindowStyle','docked');

subplot(1,2,1);
imagesc(abs(C_full)); colorbar;
xlabel('Column index'); ylabel('Column index');
title('Column Correlation (Full): Detecting Redundant Variables');

subplot(1,2,2);
imagesc(abs(C_scaled)); colorbar;
xlabel('Column index'); ylabel('Column index');
title('Column Correlation (Scaled): Structure Should Remain');

%% ============================================================
%% QR WITH COLUMN PIVOTING
%% ------------------------------------------------------------
% WHAT:
%   Reorders columns by importance
%
% WHY:
%   Reveals numerical rank
%
% INTERPRETATION:
%   Diagonal decay → rank deficiency Sharp drop → problematic columns
%% ============================================================

[~,Rf,Ef] = qr(J,0);
[~,Rs,Es] = qr(J_scaled,0);

diagRf = abs(diag(Rf));
diagRs = abs(diag(Rs));

results.qr_diag_full   = diagRf;
results.qr_diag_scaled = diagRs;

figure('Name','QrDiagonal','NumberTitle','off','WindowStyle','docked');
semilogy(diagRf,'o-','LineWidth',1.2); hold on;
semilogy(diagRs,'x-','LineWidth',1.2);
xlabel('Index');
ylabel('|R_{ii}| (log scale)');
title('QR Diagonal Decay: Revealing Numerical Rank and Dependencies');
legend('Full','Scaled'); grid on;

%% ============================================================
%% PSEUDOINVERSE SENSITIVITY
%% ------------------------------------------------------------
% WHAT:
%   Magnitude of entries in J^+
%
% WHY:
%   Measures sensitivity of solution to perturbations
%
% INTERPRETATION:
%   Large values → unstable directions
%% ============================================================

pinv_full   = pinv(J);
pinv_scaled = pinv(J_scaled);

results.pinv_max_full   = max(abs(pinv_full),[],2);
results.pinv_max_scaled = max(abs(pinv_scaled),[],2);

figure('Name','PseudoInv','NumberTitle','off','WindowStyle','docked');

subplot(2,1,1);
semilogy(results.pinv_max_full,'LineWidth',1.2);
xlabel('Row index'); ylabel('Max |value|');
title('Pseudoinverse Sensitivity (Full): Detecting Instability'); grid on;

subplot(2,1,2);
semilogy(results.pinv_max_scaled,'LineWidth',1.2);
xlabel('Row index'); ylabel('Max |value|');
title('Pseudoinverse Sensitivity (Scaled): Should Reduce Peaks'); grid on;

%% ============================================================
%% JACOBIAN HEATMAP (LOG SCALE, ZERO MASKED)
%% ------------------------------------------------------------
% WHAT:
%   Visual structure of matrix magnitude
%
% WHY:
%   Detect sparsity, scaling, structure
%
% INTERPRETATION:
%   - Uniform colors → good scaling - Strong contrast → imbalance -
%   Patterns → structure or coupling
%% ============================================================

J_log = log10(abs(J));
J_log(abs(J)==0) = NaN;

J_scaled_log = log10(abs(J_scaled));
J_scaled_log(abs(J_scaled)==0) = NaN;

figure('Name','JacLog10','NumberTitle','off','WindowStyle','docked');

subplot(1,2,1);
imagesc(J_log); colorbar;
xlabel('Column index'); ylabel('Row index');
title('Jacobian Magnitude (Full, log10): Structure and Scaling');

subplot(1,2,2);
imagesc(J_scaled_log); colorbar;
xlabel('Column index'); ylabel('Row index');
title('Jacobian Magnitude (Scaled, log10): Improved Uniformity');

%% ============================================================
%% IDENTIFY MOST PROBLEMATIC DIRECTIONS
%% ------------------------------------------------------------
% Uses smallest singular vectors
%
% OUTPUT:
%   Indices of most influential rows/columns in bad direction
%% ============================================================

[~, idx_vf] = sort(abs(results.v_bad_full),'descend');
[~, idx_uf] = sort(abs(results.u_bad_full),'descend');

results.problematic_columns_full = idx_vf(1:10);
results.problematic_rows_full    = idx_uf(1:10);

[~, idx_vs] = sort(abs(results.v_bad_scaled),'descend');
[~, idx_us] = sort(abs(results.u_bad_scaled),'descend');

results.problematic_columns_scaled = idx_vs(1:10);
results.problematic_rows_scaled    = idx_us(1:10);

fprintf('\nTop problematic columns (full):\n');
disp(results.problematic_columns_full);

fprintf('Top problematic rows (full):\n');
disp(results.problematic_rows_full);

fprintf('\nTop problematic columns (scaled):\n');
disp(results.problematic_columns_scaled);

fprintf('Top problematic rows (scaled):\n');
disp(results.problematic_rows_scaled);

fprintf('\n================ END DIAGNOSTICS ================\n');

end