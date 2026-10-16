classdef BoundsProjection < raptor.core.scaling.CompositeLinearScaling
    %BOUNDSPROJECTION Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = BoundsProjection(cfg, previousScaling)
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
            % method that builds the linear scaling matrices for the bounds
            % projection scaling

            % store the scaled decision vector and bounds
            Z0 = obj.previousScalingObj.scaleDecisionVector( ...
                transcription.getGlobalVariable(trajectories.initialGuess));
            ZL = obj.previousScalingObj.scaleConstraint( ...
                transcription.getGlobalVariable(trajectories.lowerBound));
            ZU = obj.previousScalingObj.scaleConstraint( ...
                transcription.getGlobalVariable(trajectories.upperBound));

            % compute the variable scaling as defined in the Betts book
            kz = 1 ./ abs(ZU - ZL);
            kz(kz == 0) = 1;
            kz(~isfinite(kz)) = 1;
            obj.A = sparse(diag(kz));
            obj.A_inv = inv(obj.A);

            % compute the variable shift as defined in the Betts book
            bz = - obj.A * ZL;
            bz(~isfinite(bz)) = 0;
            obj.b = bz;
            bz_inv = ZL;
            bz_inv(~isfinite(bz_inv)) = 0;
            obj.b_inv = bz_inv;

            % correctly define identify scaling for the costs and
            % constraints
            obj.B = speye(transcription.con_idx(end).totalConstraints);
            obj.B_inv = speye(transcription.con_idx(end).totalConstraints);
            obj.D = 1; obj.D_inv = 1;
        end
    end
end

