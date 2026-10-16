classdef (Abstract) Collocation < handle
    % Abstract class implementing the base and interface methods for
    % collocation classes

    properties (SetAccess = protected, GetAccess = public)
        % user-defined
        n_nodes
        dyn_tol

        % pseudospectral operators
        tau_disc        (1, :) {mustBeNumeric} = - 2;
        tau_coll        (1, :) {mustBeNumeric} = - 2;
        D               (:, :) {mustBeNumeric} = - 2;
        w               (:, 1) {mustBeNumeric} = - 2;
        timeDilation    raptor.core.enumerations.TimeDilation

        % metadata
        n_disc          (1, 1) {mustBeNumeric} = - 2;
        n_coll          (1, 1) {mustBeNumeric} = - 2;
        coll_mask       (1, :)
        interp_method

        % hp segments metadata
        n_seg           (1, 1) {mustBeNumeric} = 1;
        seg_idxs        (:, 2) {mustBeNumeric}
        seg_disc        (1, :) {mustBeNumeric}
        seg_coll        (1, :) {mustBeNumeric}
    end

    methods
        function obj = Collocation(cfg)
            % set configuration parameters
            if nargin ~= 0
                obj.n_nodes = cfg.nNodes;
                obj.dyn_tol = cfg.dynamicsTolerance;
                obj.interp_method = cfg.interpolationMethod;
                if isa(cfg.timeDilation, 'raptor.core.enumerations.TimeDilation')
                    obj.timeDilation = cfg.timeDilation.copy();
                else
                    obj.timeDilation = raptor.core.enumerations.TimeDilation.(cfg.timeDilation);
                end

                % build pseudospectral operators
                if isscalar(obj.n_nodes)
                    obj.build();
                    obj.seg_idxs = [1 obj.n_disc];
                    obj.seg_disc = ones(1, obj.n_disc);
                    obj.seg_coll = ones(1, obj.n_coll);
                else
                    obj.buildSegments(cfg);
                end

                % update the time dilation object
                obj.timeDilation.setPseudoTimeNodes(obj.tau_coll, obj.tau_disc, ...
                    obj.seg_coll, obj.seg_disc);
            end
        end

        function [discretizedTimeIdxs, collocatedTimeIdxs] = getLocalTimeIdxs(obj)
            % function that retrieves localized indexes for the time nodes
            % that are discretized and collocated
            discretizedTimeIdxs = 1 : obj.n_disc;
            collocatedTimeIdxs = discretizedTimeIdxs(obj.coll_mask == 1);
        end

        function initialMask = getSegmentInitialMask(obj)
            % function that flags the collocated nodes that are the
            % initial node of an hp segment
            [~, collocatedTimeIdxs] = obj.getLocalTimeIdxs();
            initialMask = ismember(collocatedTimeIdxs, obj.seg_idxs(:, 1));
        end

        function t_disc = getDiscretizedTime(obj, inputData)
            % function to retrieve the physical times vector from a
            % trajectory object
            t_disc = obj.timeDilation.mapDiscretizedTime(inputData);
        end

        function sampleQuantity = interpolateQuantity(obj, timeData, quantityData, sampleTimes)
            % generic method that interpolates/extrapolates a quantity from
            % the specified times to the provided sample times

            % default use of interp1
            sampleQuantity = reshape(interp1(timeData, quantityData', sampleTimes, obj.interp_method, "extrap")', size(quantityData, 1), []);
        end

        function interpolatedTrajectory = interpolateTrajectory(obj, trajectoryData, sampleTimes)
            % function to interpolate a generic trajectory object onto the
            % specified sample times
            
            % assign the static quantities
            interpolatedTrajectory = trajectoryData;

            % interpolate the dynamic quantities
            interpolatedTrajectory.states = obj.interpolateQuantity(trajectoryData.time, trajectoryData.states, sampleTimes);
            interpolatedTrajectory.controls = obj.interpolateQuantity(trajectoryData.time, trajectoryData.controls, sampleTimes);
            interpolatedTrajectory.time = sampleTimes;
        end
    end

    methods (Abstract, Access = {?raptor.api.ApiToCoreInterface, ...
            ?raptor.core.abstract.Collocation})
        % functions to instantiate the pseudospectral function wrappers
        wrapperFunc = applyDifferentiationWrapper(obj, func, phase, trajectories)
        wrapperFunc = applyIntegrationWrapper(obj, func, phase, trajectories)
        nExtraControls = getNumberOfExtraControls(obj, phase)
    end

    methods (Abstract, Access = protected)
        % function to build the pseudo-spectral operators (in pseudo-time)
        build(obj)
    end

    methods (Access = protected)
        function buildSegments(obj, cfg)
            % function that builds the pseudospectral operators of an hp
            % grid, with one segment for each element of the number of
            % nodes

            % the segments can only be attached when one of their two
            % endpoints is not collocated
            if isa(obj, "raptor.core.collocation.nodes.GaussLobatto")
                raptor.core.utils.Logger.err("collocation:invalidHpGrid", "%s", ...
                    "hp collocation (an array of number of nodes) is only " + ...
                    "available for Gauss-Radau and flipped-Gauss-Radau nodes.");
            end

            % build each segment as a regular collocation object
            segments = cell(1, numel(obj.n_nodes));
            for k = 1 : numel(obj.n_nodes)
                segmentCfg = struct("nNodes", obj.n_nodes(k), ...
                    "dynamicsTolerance", cfg.dynamicsTolerance, ...
                    "interpolationMethod", cfg.interpolationMethod, ...
                    "timeDilation", obj.timeDilation);
                segments{k} = feval(class(obj), segmentCfg);
            end

            % attach the operators of consecutive segments
            obj.attachSegments(segments);
        end

        function attachSegments(obj, segments)
            % function that attaches the pseudospectral operators of
            % consecutive segments. Each segment keeps its own
            % pseudotime, and the node shared by two consecutive segments
            % is assigned to the segment it is collocated in
            obj.n_seg = numel(segments);
            obj.seg_idxs = zeros(obj.n_seg, 2);
            discTau = segments{1}.tau_disc;
            discSegments = ones(1, segments{1}.n_disc);
            collMask = segments{1}.coll_mask;
            weights = segments{1}.w;
            obj.seg_idxs(1, :) = [1 segments{1}.n_disc];
            for k = 2 : obj.n_seg
                segment = segments{k};
                if segment.coll_mask(1)
                    discTau(end) = segment.tau_disc(1);
                    discSegments(end) = k;
                    collMask(end) = true;
                end
                discTau = [discTau segment.tau_disc(2 : end)];
                discSegments = [discSegments k * ones(1, segment.n_disc - 1)];
                collMask = [collMask segment.coll_mask(2 : end)];
                weights = [weights; segment.w];
                obj.seg_idxs(k, :) = obj.seg_idxs(k - 1, 2) + [0 segment.n_disc - 1];
            end

            % set the nodes and the metadata of the full grid
            obj.tau_disc = discTau;
            obj.tau_coll = discTau(collMask == 1);
            obj.coll_mask = collMask;
            obj.n_disc = length(obj.tau_disc);
            obj.n_coll = length(obj.tau_coll);
            obj.seg_disc = discSegments;
            obj.seg_coll = discSegments(collMask == 1);
            obj.w = weights;

            % place the differentiation matrix of each segment on its
            % collocated rows and discretized columns
            collIdxs = cumsum(collMask);
            obj.D = zeros(obj.n_coll, obj.n_disc);
            for k = 1 : obj.n_seg
                discIdxs = obj.seg_idxs(k, 1) : obj.seg_idxs(k, 2);
                obj.D(collIdxs(discIdxs(segments{k}.coll_mask == 1)), discIdxs) = segments{k}.D;
            end
        end
    end

end
