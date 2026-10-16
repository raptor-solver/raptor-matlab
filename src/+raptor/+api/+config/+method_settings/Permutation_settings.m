classdef Permutation_settings
    %PERMUTATION_SETTINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        technique string {mustBeMember(technique, ["RowColAmd", "DmPerm"])} = "DmPerm";
    end
end

