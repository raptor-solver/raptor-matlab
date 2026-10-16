function report = checkWorhpInstallation(settings)
% checkWorhpInstallation Diagnose the WORHP setup used by RAPTOR.
%
%   checkWorhpInstallation() checks everything RAPTOR needs in order to
%   solve a problem with WORHP, prints a readable report, and ends with a
%   smoke test that solves a two variable problem through the real WORHP
%   library. Every failure is reported together with the action that fixes
%   it.
%
%   report = checkWorhpInstallation(settings) runs the same checks on a
%   given raptor.api.config.method_settings.Worhp_settings object, which is
%   the way to verify a license or a parameter file that is not the default
%   one.
%
%   Inputs:
%       settings - (optional) Worhp_settings object to check
%
%   Outputs:
%       report - structure with fields:
%                isUsable       - whether WORHP can solve a problem
%                installation   - output of worhpResolveInstallation
%                license        - output of worhpInspectLicense
%                smokeTest      - structure describing the trial solve
%                problems       - string array of blocking problems
%
%   Example:
%       checkWorhpInstallation();
%
%   See also raptor.api.config.method_settings.Worhp_settings

arguments
    settings = raptor.api.config.method_settings.Worhp_settings();
end

fprintf('\n');
fprintf('==============================\n');
fprintf('WORHP INSTALLATION CHECK\n');
fprintf('==============================\n');

report = struct( ...
    "isUsable", false, ...
    "installation", [], ...
    "license", [], ...
    "smokeTest", struct("hasRun", false, "hasPassed", false, "message", ""), ...
    "problems", string.empty(0, 1));

%% files
report.installation = raptor.core.utils.worhpResolveInstallation( ...
    settings.license_file, settings.parameters_file);
localPrintSection("Files");
localPrintEntry("mex gateway", report.installation.mexFile);
localPrintEntry("shared library", report.installation.sharedLibrary);
localPrintEntry("license file", report.installation.licenseFile);
localPrintEntry("parameter file", report.installation.parametersFile);
report.problems = [report.problems; report.installation.problems(:)];
localPrintMessages(report.installation.problems, report.installation.warnings);

if ~report.installation.isAvailable
    localPrintOutcome(report);
    return
end

%% license
report.license = raptor.core.utils.worhpInspectLicense(report.installation.licenseFile);
localPrintSection("License");
localPrintEntry("format version", report.license.version);
localPrintEntry("licensee", report.license.licensee);
localPrintEntry("covers this machine", localYesNo(report.license.hostMatches));
if isnat(report.license.expiry)
    localPrintEntry("expiry", "unknown");
else
    localPrintEntry("expiry", string(report.license.expiry, "dd.MM.yyyy") + ...
        " (" + string(report.license.daysToExpiry) + " days left)");
end
report.problems = [report.problems; report.license.problems(:)];
localPrintMessages(report.license.problems, report.license.warnings);

if ~isempty(report.license.problems)
    localPrintOutcome(report);
    return
end

%% smoke test
localPrintSection("Smoke test");
[report.smokeTest, smokeProblems] = localSmokeTest(settings);
report.problems = [report.problems; smokeProblems(:)];
fprintf('  %s\n', report.smokeTest.message);

report.isUsable = isempty(report.problems);
localPrintOutcome(report);
end

function [smokeTest, problems] = localSmokeTest(settings)
% helper solving a trivial problem through the full raptor session
% machinery, which is the only way to prove that the setup really works
smokeTest = struct("hasRun", true, "hasPassed", false, "message", "");
problems = string.empty(0, 1);

% a quiet session, so that the report is not buried in the worhp output
settings.NLPprint = 0;
settings.keep_sandbox = false;
params = settings.collectParameters(1e-8, 100);
originalDirectory = pwd;

try
    session = raptor.core.utils.worhpOpenSession(settings, params);
    sessionGuard = onCleanup(@() raptor.core.utils.worhpCloseSession(session));

    % minimise (x1 - 1)^2 + (x2 - 2)^2 subject to x1 + x2 = 3
    wData.XL = [-10, -10];
    wData.XU = [10, 10];
    wData.xInit = [0, 0];
    wData.GL = 3;
    wData.GU = 3;
    wData.lambdaInit = [0, 0];
    wData.muInit = 0;
    wData.DFrow = int32([1, 2]);
    wData.DGrow = int32([1, 1]);
    wData.DGcol = int32([1, 2]);
    wData.HMrow = int32([1, 2, 2]);
    wData.HMcol = int32([1, 1, 2]);
    wData.param = char(session.paramFileName);

    funcs.f = @(x) (x(1) - 1)^2 + (x(2) - 2)^2;
    funcs.df = @(x) [2 * (x(1) - 1); 2 * (x(2) - 2)];
    funcs.g = @(x) x(1) + x(2);
    funcs.dg = @(x) [1; 1];
    funcs.jacobianstructure = [];

    [Z, status] = localRunQuietly(wData, funcs);
    [isSuccess, message] = raptor.core.utils.worhpStatusMessage(status.termination_status);
    hasConverged = isSuccess && max(abs(Z(:)' - [1, 2])) < 1e-6;

    % close the session explicitly, so that the restoration of the working
    % folder can be verified before this function returns
    clear sessionGuard
catch ME
    smokeTest.message = "FAILED: " + string(ME.message);
    problems(end + 1, 1) = "The WORHP smoke test failed with: " + string(ME.message);
    cd(originalDirectory);
    return
end

% leaving the user in another folder would be a bug of the interface
% itself, so it is checked rather than silently repaired
if ~strcmp(pwd, originalDirectory)
    problems(end + 1, 1) = "The WORHP session did not restore the working folder.";
    cd(originalDirectory);
end

if hasConverged
    smokeTest.hasPassed = true;
    smokeTest.message = "PASSED: WORHP solved the test problem in " + ...
        string(status.major_iterations) + " iterations.";
else
    smokeTest.message = "FAILED: " + message;
    problems(end + 1, 1) = "The WORHP smoke test did not converge: " + message;
end
end

function [Z, status] = localRunQuietly(wData, funcs)
% helper running the mex gateway while capturing the output it prints
% unconditionally, so that the report stays readable
assert(isstruct(wData) && isstruct(funcs));
Z = [];
status = struct("termination_status", NaN, "major_iterations", NaN);
evalc('[Z, ~, ~, status] = worhp(wData, funcs);');
end

function localPrintSection(title)
fprintf('\n-- %s %s\n', title, repmat('-', 1, max(0, 40 - strlength(title))));
end

function localPrintEntry(label, value)
if strlength(value) == 0
    value = "<not found>";
end
fprintf('  %-22s : %s\n', label, value);
end

function localPrintMessages(problems, warnings)
for k = 1 : numel(warnings)
    fprintf('  [warning] %s\n', warnings(k));
end
for k = 1 : numel(problems)
    fprintf('  [problem] %s\n', problems(k));
end
end

function localPrintOutcome(report)
fprintf('\n==============================\n');
if report.isUsable
    fprintf('WORHP IS READY TO BE USED\n');
else
    fprintf('WORHP IS NOT USABLE (%d problem(s) found)\n', numel(report.problems));
end
fprintf('==============================\n\n');
end

function text = localYesNo(flag)
if flag
    text = "yes";
else
    text = "no";
end
end
