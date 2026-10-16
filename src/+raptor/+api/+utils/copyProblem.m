function new_opc = copyProblem(old_opc)
% copy_problem  copies an OptimalControlProblem object
%
%   copy_problem creates a copy of the old_opc object by breaking the hande
%   reference, effectively creating an identical problem that can be
%   modified separately
%
% -------------------------------------------------------------------------
% INPUTS:
%
%   old_opc    - raptor.problem.OptimalControlProblem. The problem to be
%   copied
%
% OUTPUTS:
%   new_opc     - raptor.problem.OptimalControlProblem. The new copy of
%   the problem
%
% -------------------------------------------------------------------------
% USAGE:
%   new_opc = copy_problem(old_opc)
%
% -------------------------------------------------------------------------
% NOTES:
%   The function works by saving the class handle in the current folder,
%   thus can ony be used in a folder where the user has read/write
%   privileges
%
% -------------------------------------------------------------------------
% SEE ALSO:
%

% save the old problem to file
save("raptor_problemToCopy.mat", "old_opc");

% delete the variable to break the handle reference to the original problem
clear old_opc

% reload the variable and copy it to output, creating an handle to a new
% classs
load("raptor_problemToCopy.mat");
new_opc = old_opc;

% delete the auxiliary file
delete("raptor_problemToCopy.mat");
end

