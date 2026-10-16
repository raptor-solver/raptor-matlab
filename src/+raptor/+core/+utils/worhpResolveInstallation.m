function info = worhpResolveInstallation(licenseFile, parametersFile)
% worhpResolveInstallation Locate the WORHP mex, license and parameter files.
%
%   info = worhpResolveInstallation() locates every file raptor needs in
%   order to run WORHP and reports the problems preventing it from running.
%   The function never throws, so it can be used both as a pre-flight check
%   inside the solver and as a user facing diagnostic.
%
%   info = worhpResolveInstallation(licenseFile, parametersFile) uses the
%   given files instead of the automatically resolved ones. Empty strings
%   fall back to the automatic resolution.
%
%   Inputs:
%       licenseFile    - (optional) string, full path to the WORHP license
%       parametersFile - (optional) string, full path to the parameter xml
%
%   Outputs:
%       info - structure with fields:
%              isAvailable    - whether WORHP can be run as configured
%              mexFile        - resolved path of the worhp mex gateway
%              mexDirectory   - folder containing the mex gateway
%              sharedLibrary  - resolved path of the WORHP shared library
%              licenseFile    - resolved path of the license file
%              parametersFile - resolved path of the parameter template
%              problems       - string array of blocking problems
%              warnings       - string array of non blocking remarks
%
%   Example:
%       info = raptor.core.utils.worhpResolveInstallation();

arguments
    licenseFile (1, 1) string = ""
    parametersFile (1, 1) string = ""
end

info = struct( ...
    "isAvailable", false, ...
    "mexFile", "", ...
    "mexDirectory", "", ...
    "sharedLibrary", "", ...
    "licenseFile", "", ...
    "parametersFile", "", ...
    "problems", string.empty(0, 1), ...
    "warnings", string.empty(0, 1));

% the mex gateway is the entry point of the whole interface: without it
% nothing else matters, and a shadowing m-file is a common path problem
mexFile = string(which("worhp"));
switch exist("worhp", "file")
    case 3
        info.mexFile = mexFile;
        info.mexDirectory = string(fileparts(mexFile));
    case 0
        info.problems(end + 1, 1) = "The WORHP mex gateway was not found on the " + ...
            "matlab path. Run RAPTOR_init from the toolbox root folder, and make " + ...
            "sure that third_party/worhp contains a worhp." + string(mexext) + " file.";
    otherwise
        info.problems(end + 1, 1) = "The name 'worhp' resolves to '" + mexFile + ...
            "', which is not a mex gateway. Remove it from the matlab path so " + ...
            "that the WORHP mex file can be found.";
end

% the mex gateway links against the WORHP shared library, which must sit
% next to it to be resolved by the operating system loader
if info.mexDirectory ~= ""
    if ispc()
        libraryName = "worhp.dll";
    elseif ismac()
        libraryName = "libworhp.dylib";
    else
        libraryName = "libworhp.so";
    end
    candidate = fullfile(info.mexDirectory, libraryName);
    if isfile(candidate)
        info.sharedLibrary = string(candidate);
    else
        info.warnings(end + 1, 1) = "The WORHP shared library '" + libraryName + ...
            "' was not found next to the mex gateway. It is expected to be " + ...
            "resolved through the system library search path.";
    end
end

% the license and the parameter template are looked for next to the mex
% gateway first, and in the repository third_party folder as a fallback,
% so that the defaults keep working regardless of the current folder
fallbackDirectory = localToolboxWorhpDirectory();
searchDirectories = unique([info.mexDirectory, fallbackDirectory], "stable");
searchDirectories = searchDirectories(searchDirectories ~= "");

info.licenseFile = localResolveFile(licenseFile, "worhp.lic", searchDirectories);
if info.licenseFile == ""
    if licenseFile ~= ""
        info.problems(end + 1, 1) = "The WORHP license file '" + licenseFile + ...
            "' does not exist.";
    else
        info.problems(end + 1, 1) = "No WORHP license file was found. Copy your " + ...
            "worhp.lic into '" + localFirst(searchDirectories, "third_party/worhp") + ...
            "', or set problem.config.solver.settings.license_file to its full path.";
    end
end

info.parametersFile = localResolveFile(parametersFile, "worhp_raptor.xml", searchDirectories);
if info.parametersFile == ""
    if parametersFile ~= ""
        info.problems(end + 1, 1) = "The WORHP parameter file '" + parametersFile + ...
            "' does not exist.";
    else
        info.problems(end + 1, 1) = "The default WORHP parameter file " + ...
            "'worhp_raptor.xml' was not found. Restore it in '" + ...
            localFirst(searchDirectories, "third_party/worhp") + "', or set " + ...
            "problem.config.solver.settings.parameters_file to its full path.";
    end
end

info.isAvailable = isempty(info.problems);
end

function directory = localToolboxWorhpDirectory()
% helper returning third_party/worhp as derived from the location of this
% file, which keeps the defaults independent of the current folder
thisFile = string(mfilename("fullpath"));
packageRoot = fileparts(fileparts(fileparts(fileparts(thisFile))));
directory = string(fullfile(fileparts(packageRoot), "third_party", "worhp"));
if ~isfolder(directory)
    directory = "";
end
end

function resolved = localResolveFile(requested, defaultName, searchDirectories)
% helper resolving an explicitly requested file or, failing that, the
% default file name inside the search directories
resolved = "";
if requested ~= ""
    if isfile(requested)
        candidate = dir(requested);
        resolved = string(fullfile(candidate(1).folder, candidate(1).name));
    end
    return
end
for k = 1 : numel(searchDirectories)
    candidate = fullfile(searchDirectories(k), defaultName);
    if isfile(candidate)
        resolved = string(candidate);
        return
    end
end
end

function value = localFirst(list, fallback)
% helper returning the first element of a string array, or a fallback
if isempty(list)
    value = string(fallback);
else
    value = list(1);
end
end
