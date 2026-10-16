function Jac = jacobianCheck(obj, Z)

Jac = sparse(raptor.core.transcription.differentiation.centralDiff(@obj.getConstraint, Z, 1e-5));
end

