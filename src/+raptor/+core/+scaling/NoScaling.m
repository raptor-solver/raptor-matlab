classdef NoScaling < raptor.core.abstract.Scaling
    % Dummy class that implements the scaling wrapper functions without
    % actually applying any scaling

    methods
        function obj = NoScaling(cfg)
            % superclass constructor
            if nargin ~= 0
                super_args = {cfg};
            else
                super_args = {};
            end
            obj@raptor.core.abstract.Scaling(super_args{:});
        end

        function build(obj, transcription, trajectories)
            % empty method since no pre-computations are needed in this
            % case
        end

        function Z = descaleDecisionVector(obj, Z_scaled)
            % dummy function to map the scaled decision vector to physical
            % units
            Z = Z_scaled;
        end

        function Z_scaled = scaleDecisionVector(obj, Z)
            % dummy function to map the physical decision vector to scaled
            % units
            Z_scaled = Z;
        end

        function c_scaled = scaleObjective(obj, c)
            % dummy function to scale the cost function value
            c_scaled = c;
        end

        function g_scaled = scaleGradient(obj, g)
            % dummy function to scale the cost gradient value
            g_scaled = g;
        end

        function f_scaled = scaleConstraint(obj, f)
            % dummy function to scale the constraint function value
            f_scaled = f;
        end

        function j_scaled = scaleJacobian(obj, j)
            % dummy function to scale the constraint jacobian value
            j_scaled = j;
        end

        function lambda = descaleMultipliers(obj, lambda_scaled)
            % dummy function to scale the constraint multipliers
            lambda = lambda_scaled;
        end

        function z = descaleBoxMultipliers(obj, z_scaled)
            % dummy function to scale the multipliers associated to the box
            % constraints
            z = z_scaled;
        end

        function c = descaleObjective(obj, c_scaled)
            % dummy function to rescale the cost value
            c = c_scaled;
        end

    end
end

