function snapshot = normalize_model_snapshot(snapshot)
% Remove visual-only changes made by the layout engine.
% Sum '|' characters are port spacers; preserve all '+'/'-' operators.
for k = 1:numel(snapshot.blocks)
    record = snapshot.blocks{k};
    if isfield(record.parameters,'IconShape')
        record.parameters = rmfield(record.parameters,'IconShape');
    end
    if strcmp(record.type,'Sum') && isfield(record.parameters,'Inputs')
        record.parameters.Inputs = strrep(record.parameters.Inputs,'|','');
    end
    snapshot.blocks{k} = record;
end
end
