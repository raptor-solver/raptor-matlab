classdef RungeKutta45 < raptor.core.abstract.Validation
    %RUNGEKUTTA45 Summary of this class goes here
    %   Detailed explanation goes here

    methods
        function obj = RungeKutta45(cfg)
            % superclass constructor
            if nargin == 1
                super_args = {cfg};
            else
                super_args = {};
            end
            obj@raptor.core.abstract.Validation(super_args{:});
        end

        function propagatedTrajectory = propagate(obj, initialStates, discretizedTrajectory, dynamicsFcn, interpolationMethod)
            % method that performs the actual propagation of the dynamics
            % for the current phase

            % initialize the propagation from the initial states
            x0 = initialStates;

            % define the control interpolation function
            u = @(t) interp1(discretizedTrajectory.time, discretizedTrajectory.controls', t, interpolationMethod, "extrap")';

            function dx = dynamicsFcnWrapper(t, x)
                % assemble the inputData object
                inputData.time = t;
                inputData.states = x;
                inputData.controls = u(t);
                inputData.localParameters = discretizedTrajectory.localParameters;
                inputData.globalParameters = discretizedTrajectory.globalParameters;
                inputData.auxdata = discretizedTrajectory.auxdata;

                % evaluate the dynamics function
                dx = zeros(size(x));

                % loop over all phase function descriptors
                for dyn = dynamicsFcn
                    dx = dx + dyn.fcnHandle(inputData);
                end
            end

            % propagate the dynamics using rk45
            opts = odeset("Vectorized","on");
            opts.RelTol = obj.relTol;
            opts.AbsTol = obj.absTol;
            odeSolution = ode45(@dynamicsFcnWrapper, ...
                [discretizedTrajectory.initialTime discretizedTrajectory.finalTime], ...
                x0, opts);
            propagatedTimes = odeSolution.x;

            % reassemble the output trajectory
            propagatedTrajectory.time = propagatedTimes(:)';
            propagatedTrajectory.states = odeSolution.y;

            % evaluate the propagated states also at the discretized nodes,
            % through the continuous extension of the integrator
            propagatedTrajectory.discretizedStates = deval(odeSolution, discretizedTrajectory.time);
            propagatedTrajectory.controls = u(propagatedTimes(:)');
            propagatedTrajectory.initialTime = propagatedTrajectory.time(1);
            propagatedTrajectory.finalTime = propagatedTrajectory.time(end);
            propagatedTrajectory.initialStates = propagatedTrajectory.states(:, 1);
            propagatedTrajectory.finalStates = propagatedTrajectory.states(:, end);
            propagatedTrajectory.initialControls = propagatedTrajectory.controls(:, 1);
            propagatedTrajectory.finalControls = propagatedTrajectory.controls(:, end);

            % assign the untouched fields
            propagatedTrajectory.localParameters = discretizedTrajectory.localParameters;
            propagatedTrajectory.globalParameters = discretizedTrajectory.globalParameters;
            propagatedTrajectory.auxdata = discretizedTrajectory.auxdata;
        end
    end
end

