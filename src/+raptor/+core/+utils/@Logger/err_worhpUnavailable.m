function err_worhpUnavailable(problems)
% error reporting why the WORHP solver cannot be used, listing every
% problem found by the installation and license checks. The message is
% passed as an argument rather than as a format, because it carries file
% paths that sprintf would read as escape sequences
raptor.core.utils.Logger.err("solver:worhpUnavailable", "%s", ...
    "The WORHP solver cannot be used:" + newline + "  - " + ...
    join(problems(:), newline + "  - ") + newline + newline + ...
    "Run checkWorhpInstallation for a full diagnosis of the WORHP setup.");
end
