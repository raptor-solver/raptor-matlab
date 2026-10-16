classdef Manual_settings < dynamicprops
    %MANUAL_SETTINGS Settings of the manual scaling method
    %   One property is defined for each problem phase (named after the
    %   phase). Each property is a structure with one field for each
    %   quantity that can be scaled: time, states, controls,
    %   localParameters, globalParameters, cost, and the phase constraints.
    %   Each field takes the characteristic magnitude of each component of
    %   the corresponding quantity. Fields left empty are not scaled.
    %   NOTE: for the moment, the cost can only be scaled for the
    %   full-problem, not phase-wise
    %
    %   Example:
    %       problem.config.scaling.method = "Manual";
    %       problem.config.scaling.settings.ascent.states = [1e5; 1e3; 1e4];
    %       problem.config.scaling.settings.ascent.time = 100;

    properties (Hidden)
        % names of the phases, in the order of the problem phases
        phaseNames = string.empty
    end

    methods
        function obj = Manual_settings(phaseNames, constraintNames)
            % constructor that presets one property per phase, with one
            % (empty) field per quantity that can be scaled in the phase
            arguments
                phaseNames      string = string.empty
                constraintNames cell = {}
            end
            obj.phaseNames = phaseNames;
            for pp = 1 : length(phaseNames)
                phaseScales = struct("time", [], "states", [], "controls", [], ...
                    "localParameters", [], "globalParameters", [], "cost", []);
                for name = constraintNames{pp}
                    phaseScales.(name) = [];
                end
                addprop(obj, char(phaseNames(pp)));
                obj.(phaseNames(pp)) = phaseScales;
            end
        end
    end
end
