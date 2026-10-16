function errNotAColumn(phaseName, varName, size1, size2)
% function that triggers an error if the variable is not a column vector

raptor.core.utils.Logger.err("problemDefinition:notAColumn", "%s: variable" + ...
    " %s must be a column vector, but is of size %d x %d.\n", phaseName, varName, size1, size2);
end

