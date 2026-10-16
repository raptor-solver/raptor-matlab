classdef CompositeLinearScaling < raptor.core.abstract.Scaling
    %BETTSPROJECTION Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % linear scaling matrics
        A % z_scaled = A z + b
        B % c_scaled = B c
        D % j_scaled = D j
        b

        % inverse matrices
        A_inv % z = A_inv z_scaled + b_inv
        B_inv % c = B_inv c_scaled
        D_inv % j = D_inv j_scaled
        b_inv

        % previous scaling object
        previousScalingObj
    end

    methods
        function obj = CompositeLinearScaling(cfg, previousScaling)
            % superclass constructor
            if nargin ~= 0
                super_args = {cfg};
            else
                super_args = {};
            end
            obj@raptor.core.abstract.Scaling(super_args{:});

            % assign previous scaling object
            if nargin <= 1
                previousScaling = raptor.core.scaling.NoScaling();
            end
            obj.previousScalingObj = previousScaling;
        end

        function build(obj, transcription, trajectories)
            % method that sequentially builds the linear scaling objects to
            % be composed and combines their matrices

            % instantiate the deafult no scaling object
            previousScaling = raptor.core.scaling.NoScaling();

            % store the class names of all composable scaling methods
            methods = string(fieldnames(obj.cfg));

            % loop over all methods
            for m = methods(:)'

                % instantiate the current method object with related config
                currentScaling = raptor.core.scaling.(m)(obj.cfg.(m), previousScaling);

                % build the current linear scaling method
                currentScaling.build(transcription, trajectories);

                % update (or assign) the linear scaling matrices
                if isempty(obj.A) && isempty(obj.B) && isempty(obj.D)
                    obj.A = currentScaling.A;
                    obj.B = currentScaling.B;
                    obj.D = currentScaling.D;
                    obj.b = currentScaling.b;
                    obj.A_inv = currentScaling.A_inv;
                    obj.B_inv = currentScaling.B_inv;
                    obj.D_inv = currentScaling.D_inv;
                    obj.b_inv = currentScaling.b_inv;
                    previousScaling = obj;
                else
                    obj.A = currentScaling.A * obj.A;
                    obj.B = currentScaling.B * obj.B;
                    obj.D = currentScaling.D * obj.D;
                    obj.b = currentScaling.A * obj.b + currentScaling.b;
                    obj.A_inv = inv(obj.A);
                    obj.B_inv = inv(obj.B);
                    obj.D_inv = inv(obj.D);
                    obj.b_inv = - obj.A_inv * obj.b;
                end
            end
        end

        function Z = descaleDecisionVector(obj, Z_scaled)
            % function that descales the decision vector according to the
            % computed matrices
            Z = obj.A_inv * Z_scaled + obj.b_inv;
        end

        function Z_scaled = scaleDecisionVector(obj, Z)
            % function that scales the decision vector according to the
            % computed matrices
            Z_scaled = obj.A * Z + obj.b;
        end

        function j_scaled = scaleObjective(obj, j)
            % function that scales the cost function according to the
            % computed scaling factor
            j_scaled = obj.D * j;
        end

        function g_scaled = scaleGradient(obj, g)
            % function that scales the cost gradient according to the
            % computed scaling factor
            g_scaled = obj.D * g * obj.A_inv;
        end

        function c_scaled = scaleConstraint(obj, c)
            % function that scales the constraint according to the computed
            % scaling matrix
            c_scaled = obj.B * c;
        end

        function jac_scaled = scaleJacobian(obj, jac)
            % function that scales the jacobian according to the computed
            % scaling matrix
            jac_scaled = obj.B * jac * obj.A_inv;
        end

        function lambda = descaleMultipliers(obj, lambda_scaled)
            % function that descales the constraints multipliers according
            % to the computed matrices
            lambda = obj.B * lambda_scaled * obj.D_inv;
        end

        function z = descaleBoxMultipliers(obj, z_scaled)
            % function that descales the box constraints multipliers
            % according to the computed matrices
            z = obj.A * z_scaled * obj.D_inv;
        end

        function j = descaleObjective(obj, j_scaled)
            % method that rescales the objective value according to the
            % computed matrices
            j = obj.D_inv * j_scaled;
        end

    end
end

