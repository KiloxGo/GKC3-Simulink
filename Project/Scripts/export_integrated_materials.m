function export_integrated_materials(scenario)
% Generate report assets from one saved joint run, without a report narrative.
if nargin==0,scenario='full';end
scenario=validatestring(scenario,{'startup','full'});
projectFolder=fileparts(fileparts(mfilename('fullpath')));
loaded=load(fullfile(projectFolder,'Results','raw','integrated',[scenario '.mat']),'out');
out=loaded.out;t=out.joint.Time;y=out.joint.Data;
folder=fullfile(projectFolder,'Materials','Integrated',scenario);
if ~isfolder(folder),mkdir(folder);end
names={'time_s','Iref_A','Enable','Demag','mH','Vrpl_V','Vab_V', ...
    'Ics_A','Vloop_V','Rp_ohm','Lp_H','Ip_A','Vdc_V','Idc_A', ...
    'Pac_W','Pdc_W','Pbridge_W','Eac_J','Edc_J','Ebridge_J'};
index=unique([1:100:numel(t) numel(t)]);
writetable(array2table([t(index) y(index,:)],'VariableNames',names), ...
    fullfile(folder,'overview_1ms.csv'));
for window=[1.8 11.8 12.3]
    selected=t>=window & t<=window+.02;
    if any(selected)
        writetable(array2table([t(selected) y(selected,:)],'VariableNames',names), ...
            fullfile(folder,sprintf('window_%g_s_native.csv',window)));
    end
end
fig=figure('Visible','off','Color','white','Position',[100 100 1000 720]);
tiledlayout(fig,3,1,'TileSpacing','compact');
nexttile;plot(t(index),y(index,[1 11])/1000);ylabel('I_p (kA)');legend('Reference','Measured');grid on;
nexttile;plot(t(index),y(index,7));ylabel('I_{CS} (A)');grid on;
nexttile;plot(t(index),y(index,12));ylabel('V_{DC} (V)');xlabel('Time (s)');grid on;
set(findall(fig,'Type','axes'),'XLim',[0 t(end)]);
save_figure(fig,folder,'joint_currents_dc');
% Average power from 1 us model-side energy integrals avoids switching aliasing.
edges=unique([1:100:numel(t) numel(t)]);
tp=(t(edges(1:end-1))+t(edges(2:end)))/2;
power=diff(y(edges,17:19),1,1)./diff(t(edges));
writetable(array2table([tp power],'VariableNames', ...
    {'time_s','Pac_mean_W','Pdc_mean_W','Pbridge_mean_W'}),fullfile(folder,'power_1ms_means.csv'));
fig=figure('Visible','off','Color','white','Position',[100 100 1000 720]);
tiledlayout(fig,2,1,'TileSpacing','compact');
nexttile;plot(tp,power/1e6);ylabel('Power (MW)');legend('AC secondary','DC converter','H bridge');grid on;
nexttile;plot(t(index),y(index,17:19)/1e6);ylabel('Net energy (MJ)');xlabel('Time (s)');legend('AC secondary','DC converter','H bridge');grid on;
set(findall(fig,'Type','axes'),'XLim',[0 t(end)]);
save_figure(fig,folder,'joint_power_energy');
ripple=t>=1.8 & t<=1.82;
if any(ripple)
    fig=figure('Visible','off','Color','white','Position',[100 100 1000 650]);
    tiledlayout(fig,2,1,'TileSpacing','compact');
    nexttile;plot(t(ripple),y(ripple,[1 11]));ylabel('I_p (A)');legend('Reference','Measured');grid on;
    nexttile;plot(t(ripple),y(ripple,12));ylabel('V_{DC} (V)');xlabel('Time (s)');grid on;
    save_figure(fig,folder,'current_dc_ripple');
end
if t(end)>=18
    selected=t>=11.5 & t<=18;indexZoom=find(selected);indexZoom=indexZoom(1:100:end);
    startDemag=find(t>=12.3,1);
    fig=figure('Visible','off','Color','white','Position',[100 100 1000 850]);
    tiledlayout(fig,3,1,'TileSpacing','compact');
    nexttile;plot(t(indexZoom),y(indexZoom,[1 7 11])/1000);ylabel('Current (kA)');legend('Reference','I_{CS}','I_p');grid on;xline(12.3,':','HandleVisibility','off');
    selectedPower=tp>=11.5 & tp<=18;
    nexttile;plot(tp(selectedPower),power(selectedPower,:)/1e6);ylabel('Power (MW)');legend('AC secondary','DC converter','H bridge');grid on;xline(12.3,':','HandleVisibility','off');
    selectedEnergy=t(indexZoom)>=12.3;indexEnergy=indexZoom(selectedEnergy);
    nexttile;plot(t(indexEnergy),(y(indexEnergy,17:19)-y(startDemag,17:19))/1e3);ylabel('Net energy since 12.3 s (kJ)');xlabel('Time (s)');legend('AC secondary','DC converter','H bridge');grid on;
    save_figure(fig,folder,'demagnetization_return');
end
tc=out.control.Time;c=out.control.Data;ic=unique([1:10:numel(tc) numel(tc)]);
writetable(array2table([tc(ic) c(ic,:)],'VariableNames', ...
    {'time_s','Vpu','Ppu','Qpu','Vfiltered_pu','Qfiltered_pu','Ecommand_pu','Epu','error_pu','integrator'}), ...
    fullfile(folder,'grid_control_1ms.csv'));
fig=figure('Visible','off','Color','white','Position',[100 100 1000 850]);
tiledlayout(fig,4,1,'TileSpacing','compact');
nexttile;plot(tc(ic),c(ic,[1 4 7]));ylabel('Voltage (pu)');legend('Measured','Filtered','Source');grid on;
nexttile;plot(tc(ic),c(ic,2:3));ylabel('Power (pu)');legend('P','Q');grid on;
nexttile;semilogy(t(index),y(index,9));ylabel('R_p (ohm)');grid on;
nexttile;plot(t(index),y(index,10)*1e6);ylabel('L_p (uH)');xlabel('Time (s)');grid on;
set(findall(fig,'Type','axes'),'XLim',[0 t(end)]);
save_figure(fig,folder,'grid_response_load_schedule');
tg=out.gates_carrier.Time;g=out.gates_carrier.Data;
gate=struct('window_s',[tg(1) tg(end)],'sample_s',median(diff(tg)), ...
    'overlap_A_samples',nnz(g(:,2)>0 & g(:,3)>0), ...
    'overlap_B_samples',nnz(g(:,4)>0 & g(:,5)>0));
for leg=1:2
    off=~any(g(:,2*leg:2*leg+1)>0,2);
    starts=find(diff([false;off])==1);ends=find(diff([off;false])==-1);
    complete=starts>1 & ends<numel(tg);
    gaps=round((tg(ends(complete)+1)-tg(starts(complete)))*1e6);
    gate.(sprintf('leg_%d_deadtime_us',leg))=unique(gaps)';
end
selected=tg>=tg(end)-.001;
writetable(array2table([tg(selected) g(selected,:)],'VariableNames', ...
    {'time_s','carrier','g1','g2','g3','g4'}),fullfile(folder,'gates_native_1us.csv'));
fig=figure('Visible','off','Color','white','Position',[100 100 1000 720]);
tiledlayout(fig,3,1,'TileSpacing','compact');
nexttile;plot(tg(selected),g(selected,1));ylabel('Carrier');grid on;
nexttile;stairs(tg(selected),g(selected,2:3));ylabel('Leg A');legend('g1','g2');grid on;
nexttile;stairs(tg(selected),g(selected,4:5));ylabel('Leg B');legend('g3','g4');xlabel('Time (s)');grid on;
save_figure(fig,folder,'gates_carrier');
fig=figure('Visible','off','Color','white','Position',[100 100 1000 650]);
tiledlayout(fig,2,1,'TileSpacing','compact');
for leg=1:2
    off=~any(g(:,2*leg:2*leg+1)>0,2);
    turnoff=find(diff(off)==1,1,'last')+1;
    relative=(tg-tg(turnoff))*1e6;selected=relative>=-4 & relative<=8;
    nexttile;stairs(relative(selected),g(selected,2*leg:2*leg+1));
    grid on;ylim([-.1 1.2]);ylabel(sprintf('Leg %c','A'+leg-1));
    legend(sprintf('g%d',2*leg-1),sprintf('g%d',2*leg),'AutoUpdate','off');
    xline(0,':','HandleVisibility','off');xline(2,':','2 us','HandleVisibility','off');xlabel('Time from turn-off (us)');
end
save_figure(fig,folder,'deadtime_zoom');
metrics=struct('scenario',scenario,'stop_s',t(end),'finite',all(isfinite(y),'all'), ...
    'Vdc_min_max_V',[min(y(:,12)) max(y(:,12))], ...
    'Ics_final_A',y(end,7),'Ip_final_A',y(end,11), ...
    'converter_power_residual_max_W',max(abs(y(:,14)-y(:,15))), ...
    'converter_energy_residual_J',y(end,17)-y(end,18), ...
    'dc_buffer_energy_change_J',.5*.02*(y(end,12)^2-y(1,12)^2), ...
    'net_energies_ac_dc_bridge_J',y(end,17:19),'gate_measurements',gate);
plateau=t>=6 & t<=11;
if any(plateau),metrics.Ip_mean_6_to_11_s_A=mean(y(plateau,11));end
ripple=t>=1.8 & t<=1.85;
if any(ripple),metrics.Ip_ripple_1p8_to_1p85_s_A=max(y(ripple,11))-min(y(ripple,11));end
demag=find(t>=12.3,1);
if ~isempty(demag),metrics.net_ac_energy_after_12p3_s_J=y(end,17)-y(demag,17);end
fid=fopen(fullfile(folder,'metrics.json'),'w');assert(fid>=0);
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(metrics,'PrettyPrint',true));
disp(metrics);
end

function save_figure(fig,folder,name)
exportgraphics(fig,fullfile(folder,[name '.png']),'Resolution',220);
exportgraphics(fig,fullfile(folder,[name '.pdf']),'ContentType','vector');
savefig(fig,fullfile(folder,[name '.fig']));close(fig);
end
