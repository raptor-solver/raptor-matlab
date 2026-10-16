classdef Ruiz_settings
    %RUIZ_SETTINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tol         double = 1e-5
        max_iter    double = 100
        which_norm  (1, 1) double ...
            {raptor.api.config.method_settings.Ruiz_settings.isValidNorm(which_norm)} = Inf;
    end

    methods (Static)
        % validation methods
        function isValidNorm(x)
            % method that checks whether the property value is a valid norm
            if ~ismember(x, [1, 2, Inf])
                error("The norm provided for the Ruiz scaling shall be 1, 2, or Inf.");
            end
        end
    end
end

