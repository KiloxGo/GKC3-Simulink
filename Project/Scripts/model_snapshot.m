function snapshot = model_snapshot(modelName)
% Capture parameters and connectivity, excluding diagram coordinates.
blocks = find_system(modelName,'LookUnderMasks','all', ...
    'FollowLinks','off','Type','Block');
snapshot = struct('blocks',[],'configuration',struct);
records = cell(numel(blocks),1);
for k = 1:numel(blocks)
    block = blocks{k};
    record = struct('sid',Simulink.ID.getSID(block), ...
        'name',get_param(block,'Name'),'type',get_param(block,'BlockType'), ...
        'parameters',struct,'ports',[]);
    dialog = get_param(block,'DialogParameters');
    if ~isempty(dialog)
        names = sort(fieldnames(dialog));
        for j = 1:numel(names)
            record.parameters.(names{j}) = get_param(block,names{j});
        end
    end
    ports = get_param(block,'PortConnectivity');
    for j = 1:numel(ports)
        port = rmfield(ports(j),'Position');
        port.SrcBlock = block_ids(port.SrcBlock);
        destination = block_ids(port.DstBlock);
        if ~isempty(destination)
            [destination,order] = sort(destination);
            port.DstPort = port.DstPort(order);
        end
        port.DstBlock = destination;
        record.ports = [record.ports;port];
    end
    records{k} = record;
end
[~,order] = sort(cellfun(@(r)r.sid,records,'UniformOutput',false));
snapshot.blocks = records(order);
names = {'Solver','SolverType','FixedStep','MaxStep','RelTol', ...
    'AbsTol','StartTime','StopTime','InitFcn','PreLoadFcn','StartFcn'};
for k = 1:numel(names)
    snapshot.configuration.(names{k}) = get_param(modelName,names{k});
end
snapshot = normalize_model_snapshot(snapshot);
end

function ids = block_ids(handles)
ids = cell(size(handles));
for k = 1:numel(handles)
    if handles(k)>0
        ids{k} = Simulink.ID.getSID(handles(k));
    else
        ids{k} = num2str(handles(k));
    end
end
end
