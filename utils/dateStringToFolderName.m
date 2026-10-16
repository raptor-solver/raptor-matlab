function folderName = dateStringToFolderName(dateString)
% function that converts date string(s) to valid folder name string(s)
folderName = strrep(dateString, " ", "_");
folderName = strrep(folderName, ":", ".");
end

