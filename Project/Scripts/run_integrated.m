function run_integrated(scenario)
% Reproduce one continuous electrical-network simulation and retain provenance.
% AC/DC assumptions are documented in docs/model-assumptions.md.
if nargin==0,scenario='full';end
scenario=validatestring(scenario,{'startup','full'});
projectFolder=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectFolder,'Models'),fullfile(projectFolder,'Components'));
folder=fullfile(projectFolder,'Results','raw','integrated');
if ~isfolder(folder),mkdir(folder);end
if strcmp(scenario,'startup'),stopTime=2;else,stopTime=30;end
in=Simulink.SimulationInput('tokamak_integrated');
in=in.setModelParameter('StopTime',num2str(stopTime),'SimulationMode','accelerator', ...
    'SimscapeLogType','none','SaveTime','off');
in=in.setBlockParameter(Simulink.ID.getFullName('tokamak_integrated:5'), ...
    'LinearAlgebra','Sparse');
in=in.setBlockParameter(Simulink.ID.getFullName('tokamak_integrated:5'), ...
    'DoFixedCost','on');
in=in.setBlockParameter(Simulink.ID.getFullName('tokamak_integrated:5'), ...
    'MaxNonlinIter','3');
fprintf('Integrated %s: %.1f simulation seconds.\n',scenario,stopTime);
runTimer=tic;
out=sim(in);
wallSeconds=toc(runTimer);
assert(out.joint.Time(end)>=stopTime-1e-9,'Simulation ended early.');
assert(all(isfinite(out.joint.Data),'all'),'Nonfinite joint data.');
snapshot=model_snapshot('tokamak_integrated');
componentSource=fileread(fullfile(projectFolder,'Components','+gkc','BidirectionalACDC.ssc'));
save(fullfile(folder,[scenario '.mat']),'out','in','snapshot','componentSource','wallSeconds','-v7.3');
metadata=struct('scenario',scenario,'stop_s',stopTime,'wall_seconds',wallSeconds, ...
    'matlab_version',version,'global_solver','ode3','global_step_s',1e-6, ...
    'local_solver','Backward Euler','local_step_s',1e-6, ...
    'linear_algebra','Sparse','nonlinear_iterations',3,'joint_logging_step_s',1e-5, ...
    'gate_logging_step_s',1e-6,'raw_file',['raw/integrated/' scenario '.mat']);
fid=fopen(fullfile(projectFolder,'Results',['integrated_' scenario '.json']),'w');
assert(fid>=0,'Cannot create run metadata.');
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(metadata,'PrettyPrint',true));
fprintf('Saved %s, wall time %.1f s.\n',scenario,wallSeconds);
end
