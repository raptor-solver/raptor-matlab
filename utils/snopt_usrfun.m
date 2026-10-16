function [F, G] = snopt_usrfun(Z)
global SNOPT_AUX;

% descale the decision vector
Z = SNOPT_AUX.scaling.descaleDecisionVector(Z);

% compute the nlp function
F = [SNOPT_AUX.scaling.scaleObjective(SNOPT_AUX.transcription.getObjective(Z)); ...
    SNOPT_AUX.scaling.scaleConstraint(SNOPT_AUX.transcription.getConstraint(Z))];

% compute the nlp gradients
J = [SNOPT_AUX.scaling.scaleGradient(SNOPT_AUX.transcription.getGradient(Z)); ...
    SNOPT_AUX.scaling.scaleJacobian(SNOPT_AUX.transcription.getJacobian(Z))];

% assemble column jacobian
J = full(J);
idx = sub2ind(size(J), SNOPT_AUX.iGfun, SNOPT_AUX.jGvar);
G = J(idx);
% G = zeros(size(SNOPT_AUX.jGvar, 1), 1);
% for ii = 1 : size(SNOPT_AUX.jGvar, 1)
%     G(ii) = J(SNOPT_AUX.iGfun(ii), SNOPT_AUX.jGvar(ii));
% end
end