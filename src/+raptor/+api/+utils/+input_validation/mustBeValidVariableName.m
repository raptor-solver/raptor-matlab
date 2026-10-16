function mustBeValidVariableName(variables)
% validation function that triggers an error if var is not a valid variable
% name, or if it is one of the raptor-reserved variable names

% loop over all variable names
for vv = 1 :length(variables)
    var = variables(vv);

    % valid matlab variables
    if ~isvarname(var)
        raptor.core.utils.Logger.err("inputValidation", "Attempted to define" + ...
            " a variable named %s, but it is not a valid variable name " + ...
            "(check with MATLAB's isvarname() function).\n", var);
    end

    % raptor reserved names
    res = ["F_"; "G_"; "PSI_"; "CON_"; "X_"; "U_"; "PL_"; "PG_"; "T_"; "auxdata"];
    if ismember(var, res)
        raptor.core.utils.Logger.err("inputValidation", "Attempted to define " + ...
            "a variable named %s, but the name is reserved for raptor " + ...
            "internal variables.\n raptor internal variables are: \n%s\n", var, sprintf("%s\n", res));
    end

    % raptor reserved prefixes
    pref = ["RESIDUALS_"; "VIRTUAL_"; "INTERNAL_"; "LINKAGE_"];
    if startsWith(var, pref)
        raptor.core.utils.Logger.err("inputValidation", "Attempted to define " + ...
            "a variable starting with %s, but the prefix is reserved for raptor " + ...
            "internal variables.\n raptor reserved prefixes are: \n%s\n", var, sprintf("%s\n", pref));
    end
end
end

