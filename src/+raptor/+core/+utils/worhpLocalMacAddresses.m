function macs = worhpLocalMacAddresses()
% worhpLocalMacAddresses List the MAC addresses of the local machine.
%
%   macs = worhpLocalMacAddresses() returns the hardware addresses of all
%   the network interfaces of the machine running the code, normalised to
%   the lowercase colon-separated form used by the WORHP license files.
%
%   Inputs:
%       None
%
%   Outputs:
%       macs - Nx1 string array of MAC addresses (empty if none could be
%              retrieved)
%
%   Example:
%       macs = raptor.core.utils.worhpLocalMacAddresses();

% WORHP locks its license to the hardware addresses of the host, so the
% addresses are needed to tell a genuinely missing license apart from a
% license that simply does not cover this machine
macs = string.empty(0, 1);

% the jvm route is the only platform independent one, so it is attempted
% first and the shell fallbacks are only used when matlab runs -nojvm
try
    if usejava("jvm")
        interfaces = java.net.NetworkInterface.getNetworkInterfaces();
        while interfaces.hasMoreElements()
            hardwareAddress = interfaces.nextElement().getHardwareAddress();
            if ~isempty(hardwareAddress)
                bytes = typecast(int8(hardwareAddress), "uint8");
                macs(end + 1, 1) = join(string(lower(dec2hex(bytes, 2)))', ":"); %#ok<AGROW>
            end
        end
    end
catch
    macs = string.empty(0, 1);
end

% fall back to the platform specific command line tools
if isempty(macs)
    if ispc()
        [status, output] = system("getmac /fo csv /nh");
        separator = "-";
    else
        [status, output] = system("ifconfig -a 2>/dev/null || ip link show");
        separator = ":";
    end
    if status == 0
        pattern = "[0-9A-Fa-f]{2}(" + separator + "[0-9A-Fa-f]{2}){5}";
        macs = string(regexp(string(output), pattern, "match"))';
        macs = lower(replace(macs, separator, ":"));
    end
end

% drop duplicates and the placeholder addresses reported by virtual
% adapters
if ~isempty(macs)
    macs = unique(macs);
    macs = macs(macs ~= "00:00:00:00:00:00");
end
macs = macs(:);
end
