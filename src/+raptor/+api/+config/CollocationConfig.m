classdef CollocationConfig < handle
    % CollocationConfig  Config class for the collocation method of a
    % single phase
    %
    %   CollocationConfig stores the parameters required to define the
    %   collocation process of a single problem phase.
    %
    %
    % -------------------------------------------------------------------------
    % PROPERTIES:
    %
    %
    % -------------------------------------------------------------------------
    % USAGE:
    %   cfg = raptor.api.config.CollocationConfig("Lagrange", "Legendre",
    %   "Gauss-Radau"); nodes = cfg.nodes;
    %
    % -------------------------------------------------------------------------
    % NOTES:
    %   - The class is purely used as data storage for parameter values. In
    %   the case of method-specific information, the methodSpecific
    %   structure is left as a flexible way to define parameters that only
    %   concern specific collocation methods (and thus do not fall into the
    %   cathegorization provided by other properties of this class).
    %
    % -------------------------------------------------------------------------
    % SEE ALSO:
    %   raptor.api.config.ScalingConfig, raptor.api.config.SolverConfig,
    %   raptor.api.config.TranscriptionConfig, raptor.api.config.ValidationConfig

    properties (SetAccess = public, GetAccess = public)
        % method definition
        interpolant     {mustBeMember(interpolant, ["Birkhoff_a", "Lagrange", "Birkhoff_b"])} = "Lagrange";
        polynomials     {mustBeMember(polynomials, "Legendre")} = "Legendre";
        nodes           {mustBeMember(nodes, ["Gauss-Radau", "Gauss-Lobatto", "flipped-Gauss-Radau"])} = "Gauss-Lobatto";

        % collocation parameters (an array of number of nodes defines an hp
        % grid, with one equally spaced segment for each element)
        nNodes                  {mustBeInteger} = 10;
        timeDilation = "affine";
        dynamicsTolerance       {mustBeScalarOrEmpty} = 0;
        interpolationMethod     {mustBeMember(interpolationMethod, ["linear", "nearest", "next", "previous", "spline", "pchip", "cubic", "makima"])} = "linear";
    end

    properties (Hidden = true)
        method_string   {mustBeTextScalar} = "L_LGL";
    end

    methods
        function obj = CollocationConfig(interpolant, polynomials, nodes)
            % input validation to get default parameter values
            arguments
                interpolant {mustBeMember(interpolant, ["Birkhoff_a", "Lagrange", "Birkhoff_b"])} = "Lagrange";
                polynomials {mustBeMember(polynomials, "Legendre")} = "Legendre";
                nodes       {mustBeMember(nodes, ["Gauss-Radau", "Gauss-Lobatto", "flipped-Gauss-Radau"])} = "Gauss-Lobatto";
            end

            % assign the specified properties
            obj.interpolant = interpolant;
            obj.polynomials = polynomials;
            obj.nodes = nodes;

            % assemble and assign the method
            obj.method_string = obj.assemble_method_string();
        end

        function set.interpolant(obj, interpolant)
            % function that sets the interpolant of the chosen collocation
            % method
            arguments
                obj         raptor.api.config.CollocationConfig
                interpolant {mustBeMember(interpolant, ["Birkhoff_a", "Lagrange", "Birkhoff_b"])} = "Lagrange";
            end
            obj.interpolant = interpolant;

            % assemble and assign the method
            obj.method_string = obj.assemble_method_string();
        end

        function set.polynomials(obj, polynomials)
            % function that sets the polynomials for the chosen collocation
            % method
            arguments
                obj         raptor.api.config.CollocationConfig
                polynomials {mustBeMember(polynomials, "Legendre")} = "Legendre";
            end
            obj.polynomials = polynomials;

            % assemble and assign the method
            obj.method_string = obj.assemble_method_string();
        end

        function set.nodes(obj, nodes)
            % function that sets the polynomials for the chosen collocation
            % method
            arguments
                obj         raptor.api.config.CollocationConfig
                nodes       {mustBeMember(nodes, ["Gauss-Radau", "Gauss-Lobatto", "flipped-Gauss-Radau"])} = "Gauss-Lobatto";
            end
            obj.nodes = nodes;

            % assemble and assign the method
            obj.method_string = obj.assemble_method_string();
        end

        function setTimeDilation(obj, timeMap, timeRate, options)
            %SETTIMEDILATION Define a custom pseudotime-to-time mapping.
            %
            % Only the mapping t(tau) and its rate dt/dtau are required:
            %
            %   phase.collocation.setTimeDilation( ...
            %       @(data,tau) customTimeMap(data,tau), ...
            %       @(data,tau) customTimeRate(data,tau));
            %
            % By default, derivatives of dt/dtau are computed with
            % complex-step differences. For maximum performance, provide
            % an analytical DilationJacobian function. Custom dependencies
            % on phase-local parameters must be declared in the patterns.
            arguments
                obj raptor.api.config.CollocationConfig
                timeMap
                timeRate = []
                options.DilationJacobian = []
                options.JacobianPattern struct = struct()
                options.TimeMapJacobianPattern struct = struct()
            end

            if isa(timeMap, 'raptor.core.enumerations.TimeDilation')
                if ~isempty(timeRate)
                    error('raptor:CollocationConfig:InvalidTimeDilation', ...
                        'Do not provide timeRate when assigning a TimeDilation object.');
                end
                obj.timeDilation = timeMap.copy();
                return
            end

            if ~isa(timeMap, 'function_handle') || ~isa(timeRate, 'function_handle')
                error('raptor:CollocationConfig:InvalidTimeDilation', ...
                    'timeMap and timeRate must be function handles.');
            end
            obj.timeDilation = raptor.core.enumerations.TimeDilation.custom( ...
                timeMap, timeRate, ...
                DilationJacobian = options.DilationJacobian, ...
                JacobianPattern = options.JacobianPattern, ...
                TimeMapJacobianPattern = options.TimeMapJacobianPattern);
        end

        function set.timeDilation(obj, value)
            isAffine = (ischar(value) || (isstring(value) && isscalar(value))) && ...
                strcmp(string(value), "affine");
            isCustom = isa(value, 'raptor.core.enumerations.TimeDilation');
            if ~isAffine && ~isCustom
                error('raptor:CollocationConfig:InvalidTimeDilation', ...
                    'timeDilation must be "affine" or a TimeDilation object.');
            end
            obj.timeDilation = value;
        end

    end

    methods(Access = protected)
        % internal utilities
        function method = assemble_method_string(obj)
            % function that assembles the method string by using the
            % current values of its interpolant, polynomials, nodes
            % properties get the interpolant portion of the collocation
            % method
            switch obj.interpolant
                case "Birkhoff_a", int = "Ba";
                case "Lagrange", int = "L";
                case "Birkhoff_b", int = "Bb";
            end

            % get the polynomials portion of the collocation method
            switch obj.polynomials
                case "Legendre", pol = "L";
            end

            % get the nodes portion of the collocation method
            switch obj.nodes
                case "Gauss-Radau", nod = "GR";
                case "Gauss-Lobatto", nod = "GL";
                case "flipped-Gauss-Radau", nod = "fGR";
            end

            % assemble the full collocation methods name and construct
            % object
            method = strcat(int, "_", pol, nod);
        end

    end
end
