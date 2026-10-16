classdef Phase < raptor.api.ApiToCoreInterface
    %PHASE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % filekeeping
        name
        idx
        ocp

        % configuration
        collocation

        % variable description
        boundaryConditions
        initialGuess
        box
        metadata

        % problem description
        costs
        dynamics
        constraints

        % variable sizes
        nStates
        nControls
        nLocalParameters
        nGlobalParameters
    end

    methods
        function obj = Phase(name, idx, nStates, nControls, nLocalParameters, nGlobalParameters, ocp)
            % constructor
            import raptor.api.v1.elements.boundaries.Boundary
            import raptor.api.v1.elements.boundaries.SingleBoundary
            import raptor.api.v1.elements.guess.Guess
            import raptor.api.v1.elements.limits.Limits
            import raptor.api.v1.elements.metadata.Metadata
            import raptor.api.v1.elements.functions.*
            import raptor.core.enumerations.*
            import raptor.api.config.CollocationConfig

            % filekeeping
            obj.name = name;
            obj.idx = idx;
            obj.ocp = ocp;

            % variable sizes
            obj.nStates = nStates;
            obj.nControls = nControls;
            obj.nLocalParameters = nLocalParameters;
            obj.nGlobalParameters = nGlobalParameters;

            % variable metadata
            obj.metadata = Metadata(nStates, nControls, nLocalParameters);

            % boundary conditions
            obj.boundaryConditions = Boundary(nStates, nControls);

            % initial guess
            obj.initialGuess = Guess(nStates, nControls, nLocalParameters, obj);

            % variable limits
            obj.box = Limits(nStates, nControls, nLocalParameters);

            % costs
            obj.costs.lagrange = Cost(EvaluationDomain.path, obj);
            obj.costs.mayer = Cost(EvaluationDomain.boundary, obj);

            % constraints
            obj.constraints.path = PathConstraints(obj);
            obj.constraints.boundary = BoundaryConstraints(obj);
            obj.constraints.differential = DifferentialConstraints(obj);

            % dynamics
            obj.dynamics = Dynamics(EvaluationDomain.path, obj);

            % collocation
            obj.collocation = CollocationConfig();
        end

        % methods defined in external files
        corePhase = build(obj, trajectories, ocp, postProcessing)
        validate(obj)

        % utility methods for the build process
        build_metadata(phase, ocp, postProcessing)
        [discretizedTimeIdxs, collocatedTimeIdxs] = build_collocation(phase, corePhase)
        build_initialGuess(phase, ocp, corePhase, trajectories)
        build_boxConstraints(phase, ocp, corePhase, trajectories, discretizedTimeIdxs)
        build_boundaryConditions(phase, corePhase)
        build_differentialConstraints(phase, corePhase, postProcessing, discretizedTimeIdxs, collocatedTimeIdxs, trajectories)
        build_pathConstraints(phase, corePhase, discretizedTimeIdxs, trajectories)
        build_boundaryConstraints(phase, corePhase, trajectories)
        build_costs(phase, corePhase, collocatedTimeIdxs, trajectories)
        build_jacobians(phase, coreFunc, apiFunc, corePhase, trajectories)
    end
end

