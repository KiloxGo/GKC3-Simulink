function start_project
% Open the working models and initialize their documented dependencies.
projectFolder = fileparts(mfilename('fullpath'));
addpath(fullfile(projectFolder,'Scripts'),fullfile(projectFolder,'Models'), ...
    fullfile(projectFolder,'Variants'),fullfile(projectFolder,'Components'));
Simulink.fileGenControl('set','CacheFolder',fullfile(projectFolder,'work'), ...
    'CodeGenFolder',fullfile(projectFolder,'codegen'),'createDir',true);
if ~isfile(fullfile(projectFolder,'Components','gkc_lib.slx'))
    build_components;
end
models = {'droop_source','hbridge_rl','plasma_load','cs_rectifier_average'};
for k = 1:numel(models)
    open_system(fullfile(projectFolder,'Models',[models{k} '.slx']));
end
open_system(fullfile(projectFolder,'Variants','hbridge_rl_verified.slx'));
open_system(fullfile(projectFolder,'Models','tokamak_integrated.slx'));
parameters = classroom_cs_parameters;
workspace = get_param('cs_rectifier_average','ModelWorkspace');
names = fieldnames(parameters);
for k = 1:numel(names)
    assignin(workspace,names{k},parameters.(names{k}));
end
disp('Integrated model, verified H bridge, and classroom baselines opened.');
disp('Run run_integrated(''startup'') or run_integrated(''full'') for joint simulation.');
end
