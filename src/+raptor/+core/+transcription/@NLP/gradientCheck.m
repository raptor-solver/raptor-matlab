function g = gradientCheck(obj, Z)
% function to compute the gradient of the cost function

g = raptor.core.transcription.differentiation.centralDiff(@obj.getObjective, Z, 1e-5);

end