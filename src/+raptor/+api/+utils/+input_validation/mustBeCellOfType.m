function mustBeCellOfType(cellOfClasses, desiredType)
% function that triggers an error when the input is not a cell array of the
% desired type

% check if it is a cell
if ~iscell(cellOfClasses)
    raptor.core.utils.Logger.err("inputValidation", "Property must be a cell array.\n");
end

% check if the elements are of the correct type
for k = 1 : numel(cellOfClasses)
    if ~isa(cellOfClasses{k}, desiredType)
        raptor.core.utils.Logger.err("inputValidation", "All cell array " + ...
            "elements must be of type %s", desiredType);
    end
end

end

