function run_baselines
% Reproduce the four independently documented baseline scenarios.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'Models'));
folder=fullfile(root,'Results','raw','after');
if ~isfolder(folder),mkdir(folder);end
models={'droop_source','hbridge_rl','plasma_load','cs_rectifier_average'};
for k=1:numel(models)
    in=Simulink.SimulationInput(models{k});
    if strcmp(models{k},'cs_rectifier_average')
        values=classroom_cs_parameters;
        names=fieldnames(values);
        for j=1:numel(names),in=in.setVariable(names{j},values.(names{j}));end
        in=in.setModelParameter('StopTime','460','SolverType','Variable-step', ...
            'Solver','ode15s','MaxStep','0.01','RelTol','1e-6');
    end
    timer=tic;
    out=sim(in);
    wallSeconds=toc(timer);
    save(fullfile(folder,[models{k} '.mat']),'out','wallSeconds','-v7.3');
    fprintf('%s complete (%.1f wall seconds).\n',models{k},wallSeconds);
end
end
