function snake_case2camelCaseFunctions(rootDir)
% function that converts all fuctions in directory rootDir from snake_case
% to camelCase

if nargin == 0
    rootDir = pwd;
end

files = dir(fullfile(rootDir, '**', '*.m'));

for k = 1:numel(files)
    filePath = fullfile(files(k).folder, files(k).name);

    % Read file
    txt = fileread(filePath);

    % Skip class definitions
    if contains(txt, 'classdef')
        continue
    end

    % Extract function name from first function line
    expr = '^\s*function\s+(?:\[[^\]]*\]\s*=|\w+\s*=)?\s*(\w+)';
    tokens = regexp(txt, expr, 'tokens', 'once', 'lineanchors');

    if isempty(tokens)
        continue
    end

    oldName = tokens{1};

    % Only process snake_case names
    if ~contains(oldName, '_')
        continue
    end

    newName = snakeToCamel(oldName);

    % Rename file
    oldFile = filePath;
    newFile = fullfile(files(k).folder, [newName '.m']);

    if ~strcmp(oldFile, newFile)
        movefile(oldFile, newFile);
    end

    % Update function definition
    txt = regexprep(txt, ...
        ['(?<=function\s+.*)' oldName], ...
        newName, ...
        'once');

    % Write updated file
    fid = fopen(newFile, 'w');
    fwrite(fid, txt);
    fclose(fid);

    fprintf('Renamed: %s → %s\n', oldName, newName);
end
end

function out = snakeToCamel(str)
parts = split(str, '_');
parts = string(parts);
out = parts(1) + join(upperFirst(parts(2:end)), "");
out = char(out);
end

function s = upperFirst(s)
s = arrayfun(@(x) ...
    extractBefore(x,1) + upper(extractBetween(x,1,1)) + extractAfter(x,1), ...
    s, 'UniformOutput', false);
s = string(s);
end
