function export_pwm_study
% Export measured PWM comparisons; no new classroom pass/fail limits.
projectFolder=fileparts(fileparts(mfilename('fullpath')));
raw=fullfile(projectFolder,'Results','raw');
folder=fullfile(projectFolder,'Materials','PWMStudy');
if ~isfolder(folder),mkdir(folder);end
files={fullfile(raw,'after','plasma_load.mat'), ...
    fullfile(raw,'variants','inherited_2khz.mat'), ...
    fullfile(raw,'variants','detail_full.mat')};
labels={'Baseline: 4 kHz, 10 us','2 kHz, 10 us', ...
    '2 kHz, dead time, 1 us'};
rows=struct('case_name',{},'stop_s',{},'logging_step_s',{}, ...
    'Ip_mean_A',{},'Ip_ripple_pp_A',{},'Ics_final_A',{},'all_finite',{});
fullFigure=figure('Visible','off','Color','white');
fullAxes=axes(fullFigure);hold(fullAxes,'on');
rippleFigure=figure('Visible','off','Color','white');
rippleAxes=axes(rippleFigure);hold(rippleAxes,'on');
for k=1:numel(files)
    loaded=load(files{k},'out');out=loaded.out;
    t=out.logdata.Time;y=out.logdata.Data;
    plateau=t>=6 & t<=11;ripple=t>=1.8 & t<=1.85;
    rows(end+1)=struct('case_name',labels{k},'stop_s',t(end), ...
        'logging_step_s',median(diff(t)), ...
        'Ip_mean_A',mean(y(plateau,11)), ...
        'Ip_ripple_pp_A',max(y(ripple,11))-min(y(ripple,11)), ...
        'Ics_final_A',y(end,7),'all_finite',all(isfinite(y),'all')); %#ok<AGROW>
    stride=max(1,round(.001/median(diff(t))));index=1:stride:numel(t);
    plot(fullAxes,t(index),y(index,11)/1000,'DisplayName',labels{k});
    plot(rippleAxes,t(ripple),y(ripple,11),'DisplayName',labels{k});
    writetable(array2table([t(index) y(index,[1 7 11])], ...
        'VariableNames',{'time_s','Iref_A','Ics_A','Ip_A'}), ...
        fullfile(folder,sprintf('case_%d_overview.csv',k)));
    writetable(table(t(ripple),y(ripple,11),'VariableNames',{'time_s','Ip_A'}), ...
        fullfile(folder,sprintf('case_%d_ripple.csv',k)));
end
writetable(struct2table(rows),fullfile(folder,'comparison.csv'));
grid(fullAxes,'on');xlabel(fullAxes,'Time (s)');ylabel(fullAxes,'I_p (kA)');
legend(fullAxes,'Location','best');save_figure(fullFigure,folder,'current_full');
grid(rippleAxes,'on');xlabel(rippleAxes,'Time (s)');ylabel(rippleAxes,'I_p (A)');
legend(rippleAxes,'Location','best');save_figure(rippleFigure,folder,'current_ripple');
gateFiles={'detail_startup','detail_full'};gateSummary=struct;
for k=1:numel(gateFiles)
    loaded=load(fullfile(raw,'variants',[gateFiles{k} '.mat']),'out');
    out=loaded.out;t=out.gates_carrier.Time;y=out.gates_carrier.Data;
    summary=struct('window_s',[t(1) t(end)],'sample_s',median(diff(t)), ...
        'overlap_A_samples',nnz(y(:,2)>0 & y(:,3)>0), ...
        'overlap_B_samples',nnz(y(:,4)>0 & y(:,5)>0));
    for leg=1:2
        off=~any(y(:,2*leg:2*leg+1)>0,2);
        starts=find(diff([false;off])==1);
        ends=find(diff([off;false])==-1);
        complete=starts>1 & ends<numel(t);
        gaps=round((t(ends(complete)+1)-t(starts(complete)))*1e6);
        field=sprintf('leg_%d_deadtime_us',leg);
        summary.(field)=unique(gaps)';
        writetable(table(t(starts(complete)),gaps, ...
            'VariableNames',{'off_start_s','both_off_duration_us'}), ...
            fullfile(folder,sprintf('%s_leg_%d_gaps.csv',gateFiles{k},leg)));
    end
    gateSummary.(gateFiles{k})=summary;
    select=t>=t(end)-.001;
    writetable(array2table([t(select) y(select,:)], ...
        'VariableNames',{'time_s','carrier','g1','g2','g3','g4'}), ...
        fullfile(folder,[gateFiles{k} '_gates.csv']));
    fig=figure('Visible','off','Color','white');
    tiledlayout(fig,3,1,'TileSpacing','compact');
    nexttile;plot(t(select),y(select,1));grid on;ylabel('Carrier');
    nexttile;stairs(t(select),y(select,2:3));grid on;ylabel('Leg A');legend('g1','g2');
    nexttile;stairs(t(select),y(select,4:5));grid on;ylabel('Leg B');legend('g3','g4');
    xlabel('Time (s)');save_figure(fig,folder,[gateFiles{k} '_gates']);
end
fid=fopen(fullfile(folder,'gate_measurements.json'),'w');
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(gateSummary,'PrettyPrint',true));
disp(struct2table(rows));disp(gateSummary);
end

function save_figure(fig,folder,name)
exportgraphics(fig,fullfile(folder,[name '.png']),'Resolution',220);
exportgraphics(fig,fullfile(folder,[name '.pdf']),'ContentType','vector');
savefig(fig,fullfile(folder,[name '.fig']));close(fig);
end
