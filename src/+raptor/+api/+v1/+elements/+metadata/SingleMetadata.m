classdef SingleMetadata
    % object storing the specific metadata property (name, unit, or label)
    % for the specified variable

    properties
        time            (1, 1) string
        states          (:, 1) string
        controls        (:, 1) string
        localParameters (:, 1) string
    end

end