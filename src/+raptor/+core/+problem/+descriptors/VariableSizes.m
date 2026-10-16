classdef VariableSizes
    %VARIABLESIZES Summary of this class goes here
    %   Detailed explanation goes here

    properties
        time
        states
        controls
        localParameters
        globalParameters
    end

    methods
        function obj = VariableSizes(nt, nx, nu, nlp, ngp)
            % constructor
            if nargin ~= 0
                obj.time = nt;
                obj.states = nx;
                obj.controls = nu;
                obj.localParameters = nlp;
                obj.globalParameters = ngp;
            end
        end

    end
end

