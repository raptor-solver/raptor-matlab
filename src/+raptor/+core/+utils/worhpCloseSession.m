function worhpCloseSession(session)
% worhpCloseSession Restore the environment changed by worhpOpenSession.
%
%   worhpCloseSession(session) moves back to the folder that was current
%   before the session was opened and removes the private folder used to
%   run WORHP. The function never throws, so that it can safely be used as
%   an onCleanup task while an error is being propagated.
%
%   Inputs:
%       session - structure returned by worhpOpenSession
%
%   Outputs:
%       None
%
%   Example:
%       guard = onCleanup(@() raptor.core.utils.worhpCloseSession(session));
%
%   See also raptor.core.utils.worhpOpenSession

% restoring the working folder comes first: leaving the user inside a
% temporary folder would be far worse than leaving the folder behind
try
    if isfield(session, "previousDirectory") && isfolder(session.previousDirectory)
        if ~strcmp(pwd, session.previousDirectory)
            cd(session.previousDirectory);
        end
    end
catch ME
    warning("RAPTOR:solver:Worhp", "[RAPTOR WARN]>> The working folder could not " + ...
        "be restored after the WORHP solve (%s).", string(ME.message));
end

% remove the private folder unless it was explicitly kept for inspection
try
    keepSandbox = isfield(session, "keepSandbox") && session.keepSandbox;
    if ~keepSandbox && isfield(session, "directory") && isfolder(session.directory)
        rmdir(session.directory, "s");
    end
catch ME
    warning("RAPTOR:solver:Worhp", "[RAPTOR WARN]>> The temporary folder '%s' used " + ...
        "to run WORHP could not be removed (%s).", session.directory, string(ME.message));
end
end
