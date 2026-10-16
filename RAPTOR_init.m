function RAPTOR_init(verbosity)
% RAPTOR_init Add the RAPTOR solver to path.
%
%   RAPTOR_init() adds to the MATLAB path the raptor package (and the
%   related subpackages), the required third party software, and utility
%   functions, and sets the default verbosity level (2).
%
%   RAPTOR_init(verbosity) also sets the amount of information printed by
%   RAPTOR for the rest of the MATLAB session. The level can be changed at
%   any later time through raptor.core.utils.Logger.setVerbosity.
%
%   Inputs:
%       verbosity - (optional) integer verbosity level:
%                   0 = errors only
%                   1 = errors and warnings
%                   2 = errors, warnings and information (default)
%                   3 = as 2, with timestamps
%
%   Outputs:
%       None
%
%   Example:
%       RAPTOR_init()
%       RAPTOR_init(1)

arguments
    verbosity (1, 1) {mustBeInteger, mustBeInRange(verbosity, 0, 3)} = 2
end

% the paths are built from the location of this file, so that RAPTOR can be
% initialized from any folder
rootDir = fileparts(mfilename('fullpath'));

% add raptor routines
addpath(genpath(fullfile(rootDir, 'src')));

% add third party software
addpath(genpath(fullfile(rootDir, 'third_party')));

% add utility functions
addpath(genpath(fullfile(rootDir, 'utils')));

% set the verbosity level of the session
raptor.core.utils.Logger.setVerbosity(verbosity);

% the startup messages are information, so they follow the same level
if verbosity >= 2
    % splash screen to notify of RAPTOR startup
    fprintf("RAPTOR paths added. \n");

    % specify the current branch, only when the RAPTOR folder is itself a
    % git repository (e.g., not for a downloaded archive, nor for a copy
    % placed inside another repository) and git is available
    if exist(fullfile(rootDir, '.git'), 'file')
        [status, branch] = system(sprintf('git -C "%s" rev-parse --abbrev-ref HEAD', rootDir));
        if status == 0
            fprintf("Current branch is: %s\n", strtrim(branch));
        end
    end
end
end
