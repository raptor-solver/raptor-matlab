function unknownNames = worhpWriteParams(xmlFile, params)
% worhpWriteParams Apply a set of parameters to a WORHP parameter file.
%
%   unknownNames = worhpWriteParams(xmlFile, params) writes every parameter
%   of params into the WORHP xml parameter file, formatting each value
%   according to the type declared by the xml node (INT, DOUBLE or BOOL),
%   and returns the names that do not correspond to any parameter of the
%   file. The whole file is parsed and rewritten once, instead of once per
%   parameter.
%
%   Inputs:
%       xmlFile - string, full path to the WORHP xml parameter file, which
%                 is modified in place
%       params  - parameters to apply, given as a struct, a dictionary, a
%                 containers.Map or an Nx2 cell/string array of name/value
%                 pairs. Dictionaries and name/value arrays also accept the
%                 dotted WORHP parameter names (e.g. "qp.ipComTol")
%
%   Outputs:
%       unknownNames - Nx1 string array with the names that were not found
%                      in the parameter file
%
%   Example:
%       raptor.core.utils.worhpWriteParams("worhp.xml", struct("MaxIter", 500))

arguments
    xmlFile (1, 1) string {mustBeFile}
    params
end

% bring every accepted container down to a common name/value representation
[names, valueList] = localNormaliseParams(params);
unknownNames = string.empty(0, 1);
if isempty(names)
    return
end

% a single parse/write cycle is used for the whole set: rewriting the file
% once per parameter is both slow and a chance to leave it half written
doc = xmlread(xmlFile);
nodes = doc.getElementsByTagName("*");
isAssigned = false(size(names));

for k = 0 : nodes.getLength - 1
    node = nodes.item(k);
    if ~node.hasAttribute("name")
        continue
    end
    idx = find(names == string(node.getAttribute("name")), 1);
    if isempty(idx)
        continue
    end
    node.setTextContent(localFormatValue(valueList{idx}, string(node.getTagName())));
    isAssigned(idx) = true;
end

unknownNames = names(~isAssigned);
unknownNames = unknownNames(:);

% only touch the file when at least one parameter was actually assigned
if any(isAssigned)
    xmlwrite(xmlFile, doc);
end
end

function [names, valueList] = localNormaliseParams(params)
% helper converting the supported parameter containers into a string array
% of names and a cell array of values
if isstruct(params)
    names = string(fieldnames(params));
    valueList = struct2cell(params);
elseif isa(params, "dictionary")
    names = string(keys(params));
    rawValues = values(params);
    if iscell(rawValues)
        valueList = rawValues;
    else
        valueList = num2cell(rawValues);
    end
elseif isa(params, "containers.Map")
    names = string(keys(params));
    valueList = values(params);
elseif iscell(params) || isstring(params)
    if size(params, 2) ~= 2
        raptor.core.utils.Logger.err("solver:Worhp", "WORHP parameters given as " + ...
            "an array must have exactly two columns (name and value).");
    end
    names = string(params(:, 1));
    if iscell(params)
        valueList = params(:, 2);
    else
        valueList = num2cell(double(params(:, 2)));
    end
else
    raptor.core.utils.Logger.err("solver:Worhp", "WORHP parameters must be given " + ...
        "as a struct, a dictionary, a containers.Map or an Nx2 name/value array.");
end
names = names(:);
valueList = valueList(:);
end

function text = localFormatValue(value, nodeType)
% helper formatting a matlab value using the type declared by the xml node,
% which is what makes a plain numeric value usable for every parameter
if isstring(value) || ischar(value)
    text = char(string(value));
    return
end
switch upper(nodeType)
    case "BOOL"
        if logical(value)
            text = 'True';
        else
            text = 'False';
        end
    case "INT"
        text = sprintf('%d', round(double(value)));
    otherwise
        text = sprintf('%.16e', double(value));
end
end
