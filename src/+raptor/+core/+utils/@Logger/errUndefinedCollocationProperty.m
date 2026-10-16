function errUndefinedCollocationProperty(attemptedProperty, requiredProperty)
% function to trigger an error when a property of a collocation object is
% being defined without having previously defined pre-required properties

% input validation
arguments
    attemptedProperty {mustBeTextScalar} = "collocation object";
    requiredProperty  {mustBeTextScalar} = "a (unspecified) required property";
end

% trigger error
raptor.core.utils.Logger.err("internal:collocation", "An attempt " + ...
    "has been made at defining a %s without defining %s.\n", ...
    attemptedProperty, requiredProperty);
end

