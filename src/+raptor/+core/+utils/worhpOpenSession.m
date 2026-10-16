function session = worhpOpenSession(settings, params)
% worhpOpenSession Prepare an isolated working folder for a WORHP solve.
%
%   session = worhpOpenSession(settings, params) validates the WORHP
%   installation, creates a private temporary folder containing the license
%   file and a parameter file with the requested parameters applied, and
%   makes that folder the current one.
%
%   The WORHP library looks for its license in the current folder and has
%   no interface to point it elsewhere from within matlab (the
%   WORHP_LICENSE_FILE environment variable is read through the C runtime
%   and is therefore not affected by setenv). Running the solver from a
%   private folder is what allows raptor to leave the folder of the user
%   completely untouched.
%
%   Inputs:
%       settings - raptor.api.config.method_settings.Worhp_settings object
%       params   - Nx2 cell array of WORHP name/value pairs to apply
%
%   Outputs:
%       session - structure describing the open session, to be passed to
%                 raptor.core.utils.worhpCloseSession
%
%   Example:
%       session = raptor.core.utils.worhpOpenSession(settings, params);
%       guard = onCleanup(@() raptor.core.utils.worhpCloseSession(session));
%
%   See also raptor.core.utils.worhpCloseSession

arguments
    settings
    params cell
end

% resolve every file the interface needs and stop early, with an
% actionable message, when something is missing
installation = raptor.core.utils.worhpResolveInstallation( ...
    settings.license_file, settings.parameters_file);
if ~installation.isAvailable
    raptor.core.utils.Logger.err_worhpUnavailable(installation.problems);
end
for k = 1 : numel(installation.warnings)
    raptor.core.utils.Logger.warn("solver:Worhp", "%s", installation.warnings(k));
end

% a license that is expired, or not issued for this machine, produces a
% cryptic error inside the WORHP library: diagnose it here instead
license = raptor.core.utils.worhpInspectLicense(installation.licenseFile);
if ~isempty(license.problems)
    raptor.core.utils.Logger.err_worhpUnavailable(license.problems);
end
for k = 1 : numel(license.warnings)
    raptor.core.utils.Logger.warn("solver:Worhp", "%s", license.warnings(k));
end
if ~isnan(license.daysToExpiry) && license.daysToExpiry <= settings.licenseExpiryWarningDays
    raptor.core.utils.Logger.warn("solver:Worhp", "The WORHP license expires in " + ...
        "%d days (on %s).", license.daysToExpiry, string(license.expiry, "dd.MM.yyyy"));
end

% create the private folder that WORHP is going to be run from
if settings.sandbox_root == ""
    sandboxRoot = string(tempdir);
else
    sandboxRoot = settings.sandbox_root;
end
sessionName = "raptor_worhp_" + string(feature("getpid")) + "_" + ...
    string(datetime("now", "Format", "yyyyMMdd_HHmmss_SSS"));
directory = string(fullfile(sandboxRoot, sessionName));
try
    if isfolder(directory)
        rmdir(directory, "s");
    end
    mkdir(directory);
catch ME
    raptor.core.utils.Logger.err("solver:Worhp", "The temporary folder '%s' used " + ...
        "to run WORHP could not be created (%s). Set " + ...
        "problem.config.solver.settings.sandbox_root to a writable folder.", ...
        directory, string(ME.message));
end

% the WORHP parameter reader truncates the file name it is given to a
% fixed internal length, which a temporary folder easily exceeds: the mex
% gateway is therefore handed the bare file name, resolved against the
% session folder it is run from, while raptor keeps the full path for its
% own file operations
session = struct( ...
    "directory", directory, ...
    "paramFileName", "worhp_raptor.xml", ...
    "paramFile", string(fullfile(directory, "worhp_raptor.xml")), ...
    "previousDirectory", string(pwd), ...
    "installation", installation, ...
    "license", license, ...
    "keepSandbox", logical(settings.keep_sandbox));

% populate the folder: WORHP resolves 'worhp.lic' relative to the current
% folder, while the parameter file is passed to it by absolute path
try
    copyfile(installation.licenseFile, fullfile(directory, "worhp.lic"));
    copyfile(installation.parametersFile, session.paramFile);
    fileattrib(session.paramFile, "+w");
catch ME
    raptor.core.utils.worhpCloseSession(session);
    raptor.core.utils.Logger.err("solver:Worhp", "The WORHP license and parameter " + ...
        "files could not be copied into the temporary folder '%s' (%s).", ...
        directory, string(ME.message));
end

% write the requested parameters, warning about the ones that WORHP does
% not know: a silently ignored parameter is much harder to debug
try
    unknownNames = raptor.core.utils.worhpWriteParams(session.paramFile, params);
catch ME
    raptor.core.utils.worhpCloseSession(session);
    raptor.core.utils.Logger.err("solver:Worhp", "The WORHP parameter file '%s' " + ...
        "could not be written (%s). Check that the parameter template is a valid " + ...
        "WORHP xml file.", installation.parametersFile, string(ME.message));
end
if ~isempty(unknownNames)
    raptor.core.utils.Logger.warn("solver:Worhp", "The following parameters are not " + ...
        "defined in the WORHP parameter file and were ignored:\n  %s", ...
        join(unknownNames, ", "));
end

% finally move into the private folder, the caller is responsible for
% closing the session through an onCleanup guard
try
    cd(directory);
catch ME
    raptor.core.utils.worhpCloseSession(session);
    raptor.core.utils.Logger.err("solver:Worhp", "The temporary folder '%s' used " + ...
        "to run WORHP could not be entered (%s).", directory, string(ME.message));
end

if session.keepSandbox
    raptor.core.utils.Logger.info("WORHP is running in '%s', which is kept on disk " + ...
        "because keep_sandbox is enabled.", directory);
end
end
