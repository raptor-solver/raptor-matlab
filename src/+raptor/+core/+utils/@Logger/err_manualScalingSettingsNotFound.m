function err_manualScalingSettingsNotFound(phaseIdx, settingsPropertyName, validPropertyNames)
% method that triggers the error for a manual scaling field that does not
% have corresponding indexes in the problem transcription
validPropertyNames = strjoin(validPropertyNames, newline);
raptor.core.utils.Logger.err("scaling:manual", strcat("Incorrect manual " + ...
    "scaling settings:\nphase ", string(phaseIdx), ...
    " has no variable/constraint\nnamed ", settingsPropertyName, ".\nThe " + ...
    "valid names are:\n%s\n"), validPropertyNames);
end

