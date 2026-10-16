function build_metadata(phase, ocp, postProcessing)
% instantiate the metadata object
variableMetadata = raptor.inputData([ocp.metadata.name.globalParameters ...
    ocp.metadata.unit.globalParameters ocp.metadata.label.globalParameters], ...
    struct('ocpName', ocp.name, 'phaseName', phase.name, 'startIntegrator', ...
    phase.metadata.startIntegrator, 'coordinateChange', ...
    phase.metadata.coordinateChange));

% populate the problem variables
variableMetadata.time = [phase.metadata.name.time phase.metadata.unit.time ...
    phase.metadata.label.time];
variableMetadata.states = [phase.metadata.name.states phase.metadata.unit.states ...
    phase.metadata.label.states];
variableMetadata.controls = [phase.metadata.name.controls phase.metadata.unit.controls ...
    phase.metadata.label.controls];
variableMetadata.localParameters = [phase.metadata.name.localParameters ...
    phase.metadata.unit.localParameters phase.metadata.label.localParameters];

% store also the path constraints
constraintNames = string(properties(phase.constraints.path));
if ~isempty(constraintNames)
    for name = constraintNames(:)'

        % store the constraint metadata in the auxdata structure
        variableMetadata.auxdata.constraints.(name) = [name phase.constraints.path.(name).unit ...
            phase.constraints.path.(name).label];
    end
end

% assign to the post processing object
postProcessing.variableMetadata(phase.idx) = variableMetadata;
end

