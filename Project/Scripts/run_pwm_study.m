function run_pwm_study
% Compare inherited PWM settings without changing the classroom-04 baseline.
% This is a sensitivity study, not a newly imposed classroom requirement.
projectFolder=fileparts(fileparts(mfilename('fullpath')));
folder=fullfile(projectFolder,'Results','raw','variants');
if ~isfolder(folder),mkdir(folder);end
open_system(fullfile(projectFolder,'Variants','plasma_2khz_detail.slx'));
cases={'inherited_2khz','detail_startup','detail_full'};
summary=struct('case_name',{},'model',{},'stop_s',{},'wall_seconds',{}, ...
    'global_step_s',{},'carrier_Hz',{},'deadtime_constant_s',{},'raw_file',{});
for k=1:numel(cases)
    if k==1
        model='plasma_load';step=1e-5;deadtime=0;
        in=Simulink.SimulationInput(model);
        in=in.setBlockParameter(Simulink.ID.getFullName([model ':394']), ...
            'Gain','2000');
    else
        model='plasma_2khz_detail';step=1e-6;deadtime=2e-6;
        in=Simulink.SimulationInput(model);
    end
    if strcmp(cases{k},'detail_startup'),stopTime=2;else,stopTime=30;end
    % Disable only redundant physical/time logging; logdata retains 10 us.
    in=in.setModelParameter('StopTime',num2str(stopTime),'SimscapeLogType','none', ...
        'SaveTime','off');
    fprintf('START %s: %g s, step %g s\n',cases{k},stopTime,step);
    timer=tic;
    out=sim(in);
    wallSeconds=toc(timer);
    snapshot=model_snapshot(model);
    save(fullfile(folder,[cases{k} '.mat']),'out','snapshot','wallSeconds','-v7.3');
    summary(end+1)=struct('case_name',cases{k},'model',model,'stop_s',stopTime, ...
        'wall_seconds',wallSeconds,'global_step_s',step,'carrier_Hz',2000, ...
        'deadtime_constant_s',deadtime,'raw_file', ...
        ['raw/variants/' cases{k} '.mat']); %#ok<AGROW>
    fprintf('DONE %s: %.1f wall seconds\n',cases{k},wallSeconds);
end
fid=fopen(fullfile(projectFolder,'Results','pwm_study_runs.json'),'w');
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(summary,'PrettyPrint',true));
end
