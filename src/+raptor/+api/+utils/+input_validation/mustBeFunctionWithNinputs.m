function mustBeFunctionWithNinputs(f, n)
% input validation function that triggers an error when f is not a function
% handle, or when the function f does not take n input arguments

% check for function handle
if ~isa(f, "function_handle")
    raptor.core.utils.Logger.err("inputValidation", "The variable must " + ...
        "be a function handle.\n");
end

% check for n input arguments
nIns = nargin(f);
if n ~= nIns
    raptor.core.utils.Logger.err("inputValidation", "The function " + ...
        "should take %d input arguments, but takes %d.\n", n, nIns);
end
end

