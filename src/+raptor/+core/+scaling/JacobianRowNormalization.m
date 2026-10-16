classdef JacobianRowNormalization < raptor.core.scaling.CompositeLinearScaling
    %JACOBIANROWNORMALIZATION Summary of this class goes here
    %   Detailed explanation goes here

    methods
        function obj = JacobianRowNormalization(cfg, previousScaling)
            % superclass constructor
            if nargin == 0
                super_args = {};
            elseif nargin == 1
                super_args = {cfg};
            elseif nargin == 2
                super_args = {cfg, previousScaling};
            end
            obj@raptor.core.scaling.CompositeLinearScaling(super_args{:});
        end

        function build(obj, transcription, trajectories)
            % method that builds the linear scaling matrices for the
            % jacobian row normalization approach

            % compute the regular jacobian matrix
            Z0 = transcription.getGlobalVariable(trajectories.initialGuess);
            J0 = obj.previousScalingObj.scaleJacobian( ...
                transcription.getJacobian(Z0));

            % compute the row-norms of the jacobian and assign the
            % constraints scaling matrices
            nJ0 = vecnorm(J0, 2, 2);
            nJ0(nJ0 == 0) = 1;
            obj.B = sparse(diag(1 ./ nJ0));
            obj.B_inv = inv(obj.B);

            % compute the regular gradient vector
            G0 = obj.previousScalingObj.scaleGradient(...
                transcription.getGradient(Z0));

            % compute the cost scaling factor and assign the cost scaling
            % matrices
            kj = 1 / norm(G0);
            kj(kj == 0 || ~isfinite(kj)) = 1;
            obj.D = kj;
            obj.D_inv = inv(obj.D);

            % compute and assign the identify scaling for the decision
            % variables
            obj.A = speye(length(Z0));
            obj.A_inv = speye(length(Z0));
            obj.b = zeros(length(Z0), 1);
            obj.b_inv = obj.b;
        end
    end
end

