classdef OptimalControlProblem < raptor.api.ApiToCoreInterface
    %OPTIMALCONTROLPROBLEM Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % filekeeping
        name

        % problem description
        phases
        auxdata
        initialGuess
        box
        metadata
        linkage

        % configuration
        solver
        transcription
        scaling
        validation % REMEMBER: use the reset_integrator flag here

        % variable sizes
        nGlobalParameters
    end

    methods
        function obj = OptimalControlProblem(name, auxdata, nGlobalParameters)
            % constructor
            import raptor.api.v1.elements.guess.OcpGuess
            import raptor.api.v1.elements.limits.OcpLimits
            import raptor.api.v1.elements.metadata.OcpMetadata
            import raptor.api.v1.elements.functions.LinkageConstraints

            % variable sizes
            obj.nGlobalParameters = nGlobalParameters;

            % problem definition
            obj.name = name;
            obj.auxdata = auxdata;

            % guess
            obj.initialGuess = OcpGuess(nGlobalParameters);

            % limits
            obj.box = OcpLimits(nGlobalParameters);

            % metadata
            obj.metadata = OcpMetadata(nGlobalParameters);

            % linkage constraints
            obj.linkage = LinkageConstraints(obj);
        end

        function phaseObject = addPhase(obj, phaseName, nStates, nControls, nLocalParameters)
            % method that adds a phase to the current optimal control
            % problem
            import raptor.api.v1.Phase
            idx = length(obj.phases) + 1;
            phaseObject = Phase(phaseName, idx, nStates, nControls, nLocalParameters, obj.nGlobalParameters, obj);
            obj.phases = [obj.phases phaseObject];
        end

        % defined in external files
        [coreOcp, coreTrajectories, postProcessing] = build(obj)
        validate(obj)
    end
end

