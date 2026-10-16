function guessVector = evaluatePropertyGuess(problemElement, t, propertyName, guessType)
% function that evaluates the guess/bound objects for a specific property
% and build the corresponding guess/bound vector

% input validation
arguments
    problemElement  {mustBeA(problemElement, "raptor.api.abstract.ProblemElement")}
    t               {mustBeNumeric}
    propertyName    {mustBeMember(propertyName, ["states", "controls", "parameters"])}
    guessType       {mustBeMember(guessType, ["initialGuess", "lowerBound", "upperBound"])}
end

% initialize the guess vector
if ~isempty(problemElement.(propertyName))
    np = sum([problemElement.(propertyName).dim]);
else
    np = 0;
end
nt = length(t);
switch guessType
    case "initialGuess"
        guessVector = zeros(np, nt);
    case "lowerBound"
        guessVector = - inf(np, nt);
    case "upperBound"
        guessVector = inf(np, nt);
end

% loop over all descriptors of the desired property
shift = 0;
for pp = 1 : length(problemElement.(propertyName))
    prop = problemElement.(propertyName)(pp);

    % get the guess/bound objects for the current property
    guessObj = problemElement.getGuessObject(guessType, prop.name);

    % loop over all identified guess/bound objects
    for gg = 1 : length(guessObj)
        currentGuess = guessObj{gg};

        % sample the guess/bound object
        subGuessVector = currentGuess.sample(t);

        % get the correct time indexes
        switch currentGuess.nodes
            case "initial"
                idx = {shift + (1 : prop.dim), 1};
            case "final"
                idx = {shift + (1 : prop.dim), nt};
            case "continuous"
                idx = {shift + (1 : prop.dim), 1 : nt};
        end

        % assign the sub guess vector depending on the guess type
        switch guessType
            case "initialGuess"
                guessVector(idx{:}) = subGuessVector;
            case "lowerBound"
                guessVector(idx{:}) = max(guessVector(idx{:}), subGuessVector);
            case "upperBound"
                guessVector(idx{:}) = min(guessVector(idx{:}), subGuessVector);
        end
    end

    % update the shift for the following property descriptorù
    shift = shift + prop.dim;
end

end

