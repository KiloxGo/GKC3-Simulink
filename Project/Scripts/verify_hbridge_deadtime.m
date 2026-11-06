function verify_hbridge_deadtime(rerun)
% Verify the corrected 03 implementation over its entire 0.42 s scenario.
if nargin==0,rerun=true;end
projectFolder=fileparts(fileparts(mfilename('fullpath')));
raw=fullfile(projectFolder,'Results','raw','verified');
folder=fullfile(projectFolder,'Materials','VerifiedHBridge');
if ~isfolder(raw),mkdir(raw);end
if ~isfolder(folder),mkdir(folder);end
if rerun
    addpath(fullfile(projectFolder,'Variants'));
    in=Simulink.SimulationInput('hbridge_rl_verified');
    in=in.setModelParameter('StopTime','0.42','SimscapeLogType','none');
    out=sim(in);
    save(fullfile(raw,'hbridge_rl_verified.mat'),'out','in','-v7.3');
else
    loaded=load(fullfile(raw,'hbridge_rl_verified.mat'),'out');out=loaded.out;
end
t=out.logsout.get('g1').Values.Time;
g=zeros(numel(t),4);
for k=1:4,g(:,k)=out.logsout.get(sprintf('g%d',k)).Values.Data;end
metrics=struct('stop_s',t(end),'overlap_A_samples',nnz(g(:,1)>0 & g(:,2)>0), ...
    'overlap_B_samples',nnz(g(:,3)>0 & g(:,4)>0));
for leg=1:2
    off=~any(g(:,2*leg-1:2*leg)>0,2);
    starts=find(diff([false;off])==1);ends=find(diff([off;false])==-1);
    complete=starts>1 & ends<numel(t);
    starts=starts(complete);ends=ends(complete);
    % Explicitly exclude the commanded disable interval, not long gaps in general.
    enabled=~(t(starts)<.32 & t(ends+1)>.30) & t(starts)>=.002;
    starts=starts(enabled);ends=ends(enabled);
    gaps=round((t(ends+1)-t(starts))*1e6);
    metrics.(sprintf('leg_%d_deadtime_us',leg))=unique(gaps)';
    assert(~isempty(gaps) && all(gaps==2),'Enabled dead time is not exactly 2 us.');
    writetable(table(t(starts),gaps,'VariableNames',{'off_start_s','both_off_duration_us'}), ...
        fullfile(folder,sprintf('leg_%d_deadtime.csv',leg)));
end
assert(metrics.overlap_A_samples==0 && metrics.overlap_B_samples==0, ...
    'Both switches in a bridge leg are on.');
selected=t>=.10 & t<=.101;
writetable(array2table([t(selected) g(selected,:)],'VariableNames', ...
    {'time_s','g1','g2','g3','g4'}),fullfile(folder,'gates_native_1us.csv'));
fig=figure('Visible','off','Color','white','Position',[100 100 1000 650]);
tiledlayout(fig,2,1,'TileSpacing','compact');
nexttile;stairs(t(selected),g(selected,1:2));grid on;ylabel('Leg A');legend('g1','g2');
nexttile;stairs(t(selected),g(selected,3:4));grid on;ylabel('Leg B');legend('g3','g4');xlabel('Time (s)');
save_figure(fig,folder,'verified_deadtime');
fig=figure('Visible','off','Color','white','Position',[100 100 1000 650]);
tiledlayout(fig,2,1,'TileSpacing','compact');
nexttile;hold on;
for name={'Iref','Iload'}
    signal=out.logsout.get(name{1}).Values;index=1:100:numel(signal.Time);
    plot(signal.Time(index),signal.Data(index),'DisplayName',name{1});
end
grid on;legend('Location','best');ylabel('Current (A)');
nexttile;signal=out.logsout.get('Iload').Values;
selected=signal.Time>=.295 & signal.Time<=.34;
plot(signal.Time(selected),signal.Data(selected));grid on;
ylabel('Current (A)');xlabel('Time (s)');title('Disable and restart');
save_figure(fig,folder,'verified_tracking_restart');
fid=fopen(fullfile(folder,'metrics.json'),'w');assert(fid>=0);
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(metrics,'PrettyPrint',true));disp(metrics);
end

function save_figure(fig,folder,name)
exportgraphics(fig,fullfile(folder,[name '.png']),'Resolution',220);
exportgraphics(fig,fullfile(folder,[name '.pdf']),'ContentType','vector');
savefig(fig,fullfile(folder,[name '.fig']));close(fig);
end
