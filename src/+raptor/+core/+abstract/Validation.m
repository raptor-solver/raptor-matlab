classdef (Abstract) Validation < handle
    %VALIDATION Summary of this class goes here
    %   Detailed explanation goes here

    properties (SetAccess = protected, GetAccess = public)
        relTol
        absTol
    end

    properties (SetAccess = public, GetAccess = public)
        resetIntegrator string
        coordinateChange
        phaseNames      string
    end

    methods
        function obj = Validation(cfg)
            % constructor
            obj.relTol = cfg.relTol;
            obj.absTol = cfg.absTol;
        end

        function solution = perform(obj, solution, ocp)
            % full function that performs the numerical validation of the
            % problem

            % loop over all phases
            phasesLeft = 1 : length(ocp.phases);
            while ~isempty(phasesLeft)

                % instantiate helper variables to break eventual loops in
                % phase initial-condition dependencies
                propagatedThisPass = false;
                removeIdx = [];

                % loop over all remaining phases to make sure at least one
                % can be propagated
                for kk = 1 : length(phasesLeft)
                    phase = ocp.phases(phasesLeft(kk));
                    phaseName = obj.phaseNames(phase.idx);
                    resetPhase = obj.resetIntegrator(phase.idx);
                    resetCoordinates = obj.coordinateChange{phase.idx};

                    % check whether the initial conditions are available
                    if strcmp(resetPhase,"none")
                        initialStates = solution.(phaseName).discretized.initialStates;
                    else

                        % if the required phase has not been propagated,
                        % try the next phase
                        if ~isfield(solution.(resetPhase),'propagated')
                            continue
                        end
                        initialStates = resetCoordinates(solution.(resetPhase).propagated);
                    end

                    % perform the actual propagation
                    solution.(phaseName).propagated = obj.propagate(initialStates, ...
                        solution.(phaseName).discretized, phase.dynamics, ...
                        phase.collocation.interp_method);

                    % compute the state error at the discretized nodes,
                    % where the discretized states are actually defined
                    err = solution.(phaseName).discretized.states - ...
                        solution.(phaseName).propagated.discretizedStates;
                    solution.(phaseName).propagated.errors.states = err;

                    % compute interesting error metrics
                    N = size(err, 2);
                    solution.(phaseName).propagated.errors.rms = sqrt(1/N * sum(vecnorm(err).^2));
                    solution.(phaseName).propagated.errors.max = max(vecnorm(err));
                    solution.(phaseName).propagated.errors.final = norm(err(:, end));
                    solution.(phaseName).propagated.errors.rmsRelative = sqrt(1/N * sum(vecnorm(err).^2)) /...
                        sqrt(1/N * sum(vecnorm(solution.(phaseName).propagated.discretizedStates).^2));
                    solution.(phaseName).propagated.errors.integral = trapz(solution.(phaseName).discretized.time, ...
                        vecnorm(err));

                    % register that this phase has been propagated
                    removeIdx = kk;
                    propagatedThisPass = true;
                end

                % remove propagated phases from the stack
                phasesLeft(removeIdx) = [];

                % trigger an error in the presence of circular dependencies
                % for propagations
                if ~propagatedThisPass
                    raptor.core.utils.Logger.err("postprocessing:validation", ...
                        "The numerical validation cannot be carried out\nsince " + ...
                        "all phases have initial conditions\ndepending on the " + ...
                        "propagation of other phases\n(i.e., circular dependencies)." + ...
                        " To correctly carry out the numerical propagation,\nat " + ...
                        "least one phase shall use prescribed initial conditions\n(specified " + ...
                        "through metadata.startIntegrator = 'none').\n");
                end
            end
        end

    end

    methods (Abstract)
        propagatedTrajectory = propagate(obj, initialStates, discretizedTrajectory, dynamicsFcn, interpolationMethod)
    end
end

