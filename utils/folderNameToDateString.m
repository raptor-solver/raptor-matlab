function dateString = folderNameToDateString(folderName)
% function that converts folder name(s) to valid date string(s)
% NOTE: assumes that folderName was generated using dateStringToFolderName
dateString = strrep(folderName, "_", " "); 
dateString = strrep(dateString, ".", ":");
end

