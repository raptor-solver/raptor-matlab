function computerName = getComputerName()
% function that retrieves the name of the machine running the code (using
% getenv("COMPUTERNAME") on windows and getenv("HOSTNAME") on mac and linux
if ispc()
    computerName = getenv("COMPUTERNAME");
else
    computerName = getenv("HOSTNAME");
end
end

