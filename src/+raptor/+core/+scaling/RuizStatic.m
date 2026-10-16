classdef RuizStatic < raptor.core.scaling.CompositeLinearScaling
    %RUIZSTATIC Summary of this class goes here
    %   Detailed explanation goes here

    properties (Access = protected)
        tol
        max_iter
        which_norm
    end

    methods
        function obj = RuizStatic(cfg, previousScaling)
            % superclass constructor
            if nargin == 0
                super_args = {};
            elseif nargin == 1
                super_args = {cfg};
            elseif nargin == 2
                super_args = {cfg, previousScaling};
            end
            obj@raptor.core.scaling.CompositeLinearScaling(super_args{:});

            % assign convergence criteria
            if nargin >= 1
                obj.tol = cfg.tol;
                obj.max_iter = cfg.max_iter;
                obj.which_norm = cfg.which_norm;
            end
        end

        function build(obj, transcription, trajectories)
            % method that builds the left and right scaling matrices such
            % that the max infinity row and column norm of the jacobian is
            % 1 (this version builds the jacobian first and later adjusts
            % the gradient)

            % get the initial (scaled) jacobian
            Z0 = transcription.getGlobalVariable(trajectories.initialGuess);
            A = obj.previousScalingObj.scaleJacobian( ...
                transcription.getJacobian(Z0));

            % iterate to scale the jacobian
            [D1, D2] = obj.ruiz_iterations(A);

            % assign the left and right scaling matrices
            obj.B = sparse(D1); obj.B_inv = inv(obj.B);
            obj.A_inv = sparse(D2); obj.A = inv(obj.A_inv);
            obj.b = zeros(length(Z0), 1);
            obj.b_inv = obj.b;

            % compute the gradient and adjust its columns according to the
            % precomputed right scaling
            A = obj.previousScalingObj.scaleGradient(...
                transcription.getGradient(Z0)) * obj.A_inv;
            [D1, D2] = obj.ruiz_iterations(A);

            % assign the cost scaling factor
            obj.D = D1; obj.D_inv = inv(obj.D);
            % NOTE: the column scaling is not re-applied to prioritize a
            % "better" jacobian matrix rather than gradient
        end

        function [D1, D2] = ruiz_iterations(obj, A)
            % function that condenses the iterative part of the ruiz
            % scaling method on a generic matrix A

            % initialize the iteration for the Ruiz scaling algorithm
            converged = false; m = size(A, 1); n = size(A, 2);
            D1 = eye(m); D2 = eye(n); k = 0;

            % start iterating
            while ~converged
                k = k + 1;
                % compute the row and column norm matrices
                DrInv = 1 ./ sqrt(vecnorm(A, obj.which_norm, 2));
                DrInv(~isfinite(DrInv)) = 1; % adjust non-dependent rows
                DrInv = diag(DrInv);
                DcInv = 1 ./ sqrt(vecnorm(A, obj.which_norm, 1));
                DcInv(~isfinite(DcInv)) = 1; % adjust non-dependent controls
                DcInv = diag(DcInv);

                % scale the jacobian matrix
                A = DrInv * A * DcInv;

                % update the sacling matrices
                D1 = D1 * DrInv;
                D2 = D2 * DcInv;

                % check convergence only on non-singular columns
                A_fullRank = A;
                A_fullRank(:, all(A_fullRank == 0, 1)) = [];
                if max(abs(1 - vecnorm(A, obj.which_norm, 2))) < obj.tol && ...
                        max(abs(1 - vecnorm(A_fullRank, obj.which_norm, 1))) < obj.tol
                    converged = true;
                elseif k >= obj.max_iter
                    converged = true;
                    raptor.core.utils.Logger.warn("scaling:RuizStatic", strcat("RuizStatic scaling couldn't achieve convergence within the\n" + ...
                        "specific number of iterations (", string(obj.max_iter), ...
                        "):\nthe solver will use the scaling obtained " + ...
                        "at the last iteration.\n"));
                end
            end
        end

        function build_jacGradTogether(obj, transcription, trajectories)
            % method that builds the left and right scaling matrices such
            % that the max infinity row and column norm of the jacobian is
            % 1

            % get the initial (scaled) jacobian
            Z0 = transcription.getGlobalVariable(trajectories.initialGuess);
            A = obj.previousScalingObj.scaleJacobian( ...
                transcription.getJacobian(Z0));

            % append it to the (scaled) gradient
            A = [obj.previousScalingObj.scaleGradient(...
                transcription.getGradient(Z0)); A];

            % iterate to scale the jacobian
            [D1, D2] = obj.ruiz_iterations(A);

            % assign the left and right scaling matrices
            obj.B = sparse(D1(2 : end, 2 : end)); obj.B_inv = inv(obj.B);
            obj.A_inv = sparse(D2); obj.A = inv(obj.A_inv);
            obj.b = zeros(length(Z0), 1);
            obj.b_inv = obj.b;
            obj.D = D1(1, 1); obj.D_inv = inv(obj.D);
        end

    end
end

