function folderNames = getFolderNames(rootDir)
% function that lists the names (as a string array) of all folders in
% directory rootDir

% validate inputs
if nargin == 0 || isempty(rootDir)
    rootDir = pwd;
end

% list all files/folders in current folder
d = dir(rootDir);

% keep only directories
d = d([d.isdir]);

% get names as cell array
folderNames = {d.name};

% remove '.' and '..'
folderNames = folderNames(~ismember(folderNames, {'.','..'}));
folderNames = string(folderNames);
end

