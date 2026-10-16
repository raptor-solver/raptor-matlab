function checkDuplicateStringArrayElement(names)
% function that triggers an error when the user-provided names array
% contains duplicate elements

if numel(names) ~= numel(unique(names))
    % store the first duplicated element
    [~, ia] = unique(names, 'stable');
    idxFirstDup = find(~ismember(1:numel(names), ia), 1, 'first');
    firstDup = names(idxFirstDup);
    raptor.core.utils.Logger.err("problemDefinition:duplicateName", "User-provided " + ...
        "array of strings contains more than one '%s' element. Make sure " + ...
        "that array names are defined with unique values.\n", firstDup);
end
end