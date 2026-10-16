function info = worhpInspectLicense(licenseFile)
% worhpInspectLicense Parse and diagnose a WORHP license file.
%
%   info = worhpInspectLicense(licenseFile) reads the WORHP license file
%   and returns the information it contains together with the list of
%   problems that would prevent WORHP from running on this machine. The
%   function never throws: an unreadable or malformed license is reported
%   through the returned structure.
%
%   Inputs:
%       licenseFile - string, full path to the WORHP license file
%
%   Outputs:
%       info - structure with fields:
%              file           - the inspected file
%              isReadable     - whether the file could be read
%              version        - license format version
%              licensee       - string describing user and company
%              keys           - structure array with one entry per key
%                               (host, mac, type, module, version, until)
%              hostMatches    - whether a key matches a local MAC address
%              expiry         - datetime of the last usable day for the
%                               'worhp' module (NaT if unknown)
%              daysToExpiry   - days left before expiry (NaN if unknown)
%              problems       - string array of blocking problems
%              warnings       - string array of non blocking remarks
%
%   Example:
%       info = raptor.core.utils.worhpInspectLicense("worhp.lic");

arguments
    licenseFile (1, 1) string
end

% initialise the output so that every early return is still a valid
% diagnosis structure
info = struct( ...
    "file", licenseFile, ...
    "isReadable", false, ...
    "version", "", ...
    "licensee", "", ...
    "keys", struct("host", {}, "mac", {}, "type", {}, "module", {}, "version", {}, "until", {}), ...
    "hostMatches", false, ...
    "expiry", NaT, ...
    "daysToExpiry", NaN, ...
    "problems", string.empty(0, 1), ...
    "warnings", string.empty(0, 1));

% the file must exist and be readable before anything else can be said
if licenseFile == "" || ~isfile(licenseFile)
    info.problems(end + 1, 1) = "The WORHP license file '" + licenseFile + "' does not exist.";
    return
end
try
    raw = string(fileread(licenseFile));
catch ME
    info.problems(end + 1, 1) = "The WORHP license file '" + licenseFile + ...
        "' could not be read (" + string(ME.message) + ").";
    return
end
info.isReadable = true;

% strip comments and blank lines, the license format ignores both
lines = strtrim(splitlines(raw));
lines = lines(lines ~= "" & ~startsWith(lines, "#"));

% the header line identifies the file as a worhp license
header = regexp(lines, 'WORHP-LICENSE\s+VERSION="([^"]*)"', "tokens", "once");
header = header(~cellfun(@isempty, header));
if isempty(header)
    info.problems(end + 1, 1) = "The file '" + licenseFile + "' is not a WORHP " + ...
        "license file (the WORHP-LICENSE header is missing).";
    return
end
info.version = string(header{1}{1});

% collect the licensee information
for k = 1 : numel(lines)
    if ~startsWith(lines(k), "USER")
        continue
    end
    name = localMatch(lines(k), 'NAME="([^"]*)"');
    company = localMatch(lines(k), 'COMPANY="([^"]*)"');
    if strlength(company) > 0
        info.licensee = name + " (" + company + ")";
    else
        info.licensee = name;
    end
    break
end

% walk the file keeping track of the host each key belongs to
currentHost = "";
currentMac = "";
for k = 1 : numel(lines)
    host = regexp(lines(k), 'HOST\s+NAME="([^"]*)"\s+MAC="([^"]*)"', "tokens", "once");
    if ~isempty(host)
        currentHost = string(host{1});
        currentMac = lower(string(host{2}));
        continue
    end
    if ~startsWith(lines(k), "KEY")
        continue
    end
    entry = struct( ...
        "host", currentHost, ...
        "mac", currentMac, ...
        "type", localMatch(lines(k), 'TYPE=\"?(\w+)\"?'), ...
        "module", localMatch(lines(k), 'MODULE="([^"]*)"'), ...
        "version", localMatch(lines(k), 'VERSION="([^"]*)"'), ...
        "until", localDate(localMatch(lines(k), 'UNTIL="([^"]*)"')));
    info.keys(end + 1, 1) = entry;
end

if isempty(info.keys)
    info.problems(end + 1, 1) = "The WORHP license file '" + licenseFile + ...
        "' contains no license key.";
    return
end

% the solver itself is provided by the 'worhp' module, the other modules
% (zen, ...) are not used by raptor
isWorhpModule = [info.keys.module] == "worhp";
if ~any(isWorhpModule)
    info.problems(end + 1, 1) = "The WORHP license file '" + licenseFile + ...
        "' contains no key for the 'worhp' module.";
    return
end

% check whether any key covers one of the network interfaces of this
% machine: a mismatch is the single most common reason for the cryptic
% 'Could not obtain license' failure
localMacs = raptor.core.utils.worhpLocalMacAddresses();
licensedMacs = [info.keys(isWorhpModule).mac];
if isempty(localMacs)
    info.warnings(end + 1, 1) = "The MAC addresses of this machine could not be " + ...
        "retrieved, so the license could not be matched against it.";
    info.hostMatches = true;
else
    info.hostMatches = any(ismember(licensedMacs, localMacs));
    if ~info.hostMatches
        info.problems(end + 1, 1) = "The WORHP license does not cover this machine. " + ...
            "Licensed MAC addresses: " + join(unique(licensedMacs), ", ") + ...
            "; local MAC addresses: " + join(localMacs', ", ") + ".";
    end
end

% report the expiry of the keys that are actually usable on this machine
usable = isWorhpModule;
if info.hostMatches && ~isempty(localMacs)
    usable = usable & ismember([info.keys.mac]', localMacs)';
end
expiryDates = [info.keys(usable).until];
expiryDates = expiryDates(~isnat(expiryDates));
if isempty(expiryDates)
    info.warnings(end + 1, 1) = "The expiry date of the WORHP license could not be parsed.";
else
    info.expiry = max(expiryDates);
    info.daysToExpiry = floor(days(info.expiry - dateshift(datetime("now"), "start", "day")));
    if info.daysToExpiry < 0
        info.problems(end + 1, 1) = "The WORHP license expired on " + ...
            string(info.expiry, "dd.MM.yyyy") + ".";
    end
end
end

function value = localMatch(line, pattern)
% helper extracting the first capture group of a pattern, "" if absent
token = regexp(line, pattern, "tokens", "once");
if isempty(token)
    value = "";
else
    value = string(token{1});
end
end

function value = localDate(text)
% helper converting the dd.mm.yyyy dates of the license file to datetime
value = NaT;
if strlength(text) == 0
    return
end
try
    value = datetime(text, "InputFormat", "dd.MM.yyyy");
catch
    value = NaT;
end
end
