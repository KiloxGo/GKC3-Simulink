function export_writing_materials
% Build writing assets from actual saved runs, without rerunning simulation.
projectFolder = fileparts(fileparts(mfilename('fullpath')));
root = fullfile(projectFolder,'Materials');
figures = fullfile(root,'Figures');
tables = fullfile(root,'Tables');
if ~isfolder(figures), mkdir(figures); end
if ~isfolder(tables), mkdir(tables); end
raw = fullfile(projectFolder,'Results','raw','after');
metrics = struct;

%% Classroom 10 kV droop source.
loaded = load(fullfile(raw,'droop_source.mat'),'out');
out = loaded.out;
t = out.control.Time; y = out.control.Data;
writetable(array2table([t y],'VariableNames', ...
    {'time_s','vpu','ppu','qpu','vf','qf','Ecmd','Epu','err','integrator'}), ...
    fullfile(tables,'bus_control.csv'));
f = new_figure; tiledlayout(f,2,1,'TileSpacing','compact');
nexttile; plot(t,y(:,[1 6 7])); grid on;
ylabel('Voltage (pu)'); legend('V_{bus}','E_{cmd}','E','Location','best');
nexttile; plot(t,10*y(:,[2 3])); grid on;
xlabel('Time (s)'); ylabel('MW / Mvar'); legend('P','Q','Location','best');
write_figure(f,figures,'bus_voltage_power');
sel = out.vabc.Time>=1.94;
v = reshape(out.vabc.Data,3,[])';
f = new_figure; plot(out.vabc.Time(sel),v(sel,:)/1000); grid on;
xlabel('Time (s)');ylabel('Phase-to-ground voltage (kV)');
legend('a','b','c');write_figure(f,figures,'bus_three_phase');
steady = t>=1.8;
metrics.bus = struct('window_s',[1.8 2], ...
    'Vbus_pu',mean(y(steady,1)),'P_MW',mean(y(steady,2))*10, ...
    'Q_Mvar',mean(y(steady,3))*10,'E_pu',mean(y(steady,7)));

%% Classroom H bridge: full trace plus native switching/control windows.
loaded = load(fullfile(raw,'hbridge_rl.mat'),'out'); out = loaded.out;
names = {'Iref','Iload','Vab','mH','carrier','g1','g2','g3','g4', ...
    'Iload_fb','err','I_state','v_raw','v_sat'};
t = (0:1e-6:0.42)'; y = zeros(numel(t),numel(names));
for k=1:numel(names)
    values = out.logsout.get(names{k}).Values;
    y(:,k) = interp1(values.Time,double(values.Data),t,'previous','extrap');
end
sel = 1:100:numel(t);
writetable(array2table([t(sel) y(sel,:)],'VariableNames', ...
    [{'time_s'} names]),fullfile(tables,'hbridge_overview_100us.csv'));
f = new_figure; tiledlayout(f,3,1,'TileSpacing','compact');
nexttile; plot(t(sel),y(sel,1:2));grid on;ylabel('Current (A)');
legend('I_{ref}','I_{load}','Location','best');
nexttile; plot(t(sel),y(sel,1)-y(sel,2));grid on;ylabel('Error (A)');
nexttile; plot(t(sel),y(sel,4));grid on;ylabel('m_H');xlabel('Time (s)');
write_figure(f,figures,'hbridge_tracking');
sel = t>=0.05 & t<=0.051;
writetable(array2table([t(sel) y(sel,:)],'VariableNames', ...
    [{'time_s'} names]),fullfile(tables,'hbridge_switching_native.csv'));
f = new_figure; tiledlayout(f,3,1,'TileSpacing','compact');
nexttile; plot(t(sel),y(sel,5));grid on;ylabel('Carrier');
nexttile; stairs(t(sel),y(sel,6:7));grid on;ylabel('Leg A');legend('g_1','g_2');
nexttile; stairs(t(sel),y(sel,8:9));grid on;ylabel('Leg B');legend('g_3','g_4');
xlabel('Time (s)');write_figure(f,figures,'hbridge_pwm_gates');
sel = t>=0.295 & t<=0.335;
writetable(array2table([t(sel) y(sel,:)],'VariableNames', ...
    [{'time_s'} names]),fullfile(tables,'hbridge_enable_native.csv'));
f = new_figure;tiledlayout(f,2,1,'TileSpacing','compact');
plotIndex=find(sel);plotIndex=plotIndex(1:10:end);
nexttile;plot(t(plotIndex),y(plotIndex,1:2));grid on;ylabel('Current (A)');legend('I_{ref}','I_{load}');
nexttile;plot(t(plotIndex),y(plotIndex,4));grid on;ylabel('m_H');xlabel('Time (s)');
write_figure(f,figures,'hbridge_disable_restart');
sel = t>=0.019 & t<=0.09;
writetable(array2table([t(sel) y(sel,:)],'VariableNames', ...
    [{'time_s'} names]),fullfile(tables,'hbridge_pi_native.csv'));
f = new_figure;tiledlayout(f,2,1,'TileSpacing','compact');
plotIndex=find(sel);plotIndex=plotIndex(1:10:end);
nexttile;plot(t(plotIndex),y(plotIndex,13:14));grid on;ylabel('Voltage command (V)');legend('Before limit','After limit');
nexttile;plot(t(plotIndex),y(plotIndex,12));grid on;ylabel('Integral state (V)');xlabel('Time (s)');
write_figure(f,figures,'hbridge_pi_saturation');
edges = [0 .02 .12 .24 .30 .32 .36 .42]; rows = zeros(7,6);
for k=1:7
    segment = find(t>=edges(k) & t<edges(k+1));
    tail = segment(max(1,floor(.8*numel(segment))):end);
    rows(k,:) = [edges(k:k+1) mean(y(tail,1)) mean(y(tail,2)) ...
        max(y(tail,2))-min(y(tail,2)) mean(y(tail,1)-y(tail,2))];
end
writetable(array2table(rows,'VariableNames',{'start_s','end_s', ...
    'Iref_mean_A','Iload_mean_A','ripple_pp_A','tracking_error_A'}), ...
    fullfile(tables,'hbridge_segments.csv'));
metrics.hbridge = struct('shoot_through_A',max(y(:,6).*y(:,7)), ...
    'shoot_through_B',max(y(:,8).*y(:,9)), ...
    'statistics_note','Segment summaries use their final 20%; descriptive statistics, not acceptance thresholds.');

%% Classroom variable load. Instantaneous power is calculated before averaging.
loaded = load(fullfile(raw,'plasma_load.mat'),'out');out = loaded.out;
t = out.logdata.Time;y = out.logdata.Data;
names = {'Iref_A','Enable','Demag','mH','Vrpl_V','Vab_V','Ics_A', ...
    'Vloop_V','Rp_ohm','Lp_H','Ip_A'};
stride = max(1,round(.001/median(diff(t)))); sel = 1:stride:numel(t);
writetable(array2table([t(sel) y(sel,:)],'VariableNames', ...
    [{'time_s'} names]),fullfile(tables,'plasma_overview_1ms.csv'));
coilPower = y(:,6).*y(:,7); plasmaPower = y(:,5).*y(:,11);
count = floor(numel(t)/stride); used = 1:count*stride;
powerTime = mean(reshape(t(used),stride,count),1)';
coilMean = mean(reshape(coilPower(used),stride,count),1)';
plasmaMean = mean(reshape(plasmaPower(used),stride,count),1)';
writetable(table(powerTime,coilMean,plasmaMean,'VariableNames', ...
    {'time_s','coil_power_mean_W','plasma_power_mean_W'}), ...
    fullfile(tables,'plasma_power_1ms_means.csv'));
f = new_figure;tiledlayout(f,2,1,'TileSpacing','compact');
nexttile;plot(t(sel),y(sel,[1 11 7])/1000);grid on;ylabel('Current (kA)');
legend('I_{ref}','I_p','I_{cs}','Location','best');
nexttile;plot(powerTime,[plasmaMean coilMean]/1e6);grid on;ylabel('Power (MW)');
legend('Plasma','Coil side','Location','best');xlabel('Time (s)');
write_figure(f,figures,'plasma_full_pulse');
f = new_figure;tiledlayout(f,2,1,'TileSpacing','compact');
nexttile;semilogy(t(sel),y(sel,9));grid on;ylabel('R_p (ohm)');
nexttile;plot(t(sel),1e6*y(sel,10));grid on;ylabel('L_p (microhenry)');xlabel('Time (s)');
write_figure(f,figures,'plasma_load_schedule');
startup = t<=2; startupIndex=find(startup); startupIndex=startupIndex(1:10:end);
writetable(array2table([t(startupIndex) y(startupIndex,:)], ...
    'VariableNames',[{'time_s'} names]),fullfile(tables,'plasma_startup.csv'));
f = new_figure;plot(t(startupIndex),y(startupIndex,[1 11 7])/1000);grid on;
xlabel('Time (s)');ylabel('Current (kA)');legend('I_{ref}','I_p','I_{cs}');
write_figure(f,figures,'plasma_startup');
ripple = t>=1.80 & t<=1.85;
writetable(array2table([t(ripple) y(ripple,:)],'VariableNames', ...
    [{'time_s'} names]),fullfile(tables,'plasma_ripple_native.csv'));
f = new_figure;plot(t(ripple),y(ripple,11));grid on;
xlabel('Time (s)');ylabel('I_p (A)');write_figure(f,figures,'plasma_current_ripple');
f = new_figure;tiledlayout(f,2,1,'TileSpacing','compact');
late = sel(t(sel)>=11);nexttile;plot(t(late),y(late,[7 11])/1000);grid on;
ylabel('Current (kA)');legend('I_{cs}','I_p');
nexttile;latePower=powerTime>=11;plot(powerTime(latePower),coilMean(latePower)/1000);grid on;
xlabel('Time (s)');ylabel('Coil-side mean power (kW)');
write_figure(f,figures,'plasma_demagnetization');
% Guide: L1=L2=1 H, k=0.99999 and Rcs=20 microohm.
fluxCurrent = y(:,7)-0.99999*y(:,11);
fluxVoltage = fluxCurrent(1)+cumtrapz(t,y(:,6)-2e-5*y(:,7));
fluxResidual = fluxVoltage-fluxCurrent;
writetable(table(t(sel),fluxCurrent(sel),fluxVoltage(sel),fluxResidual(sel), ...
    'VariableNames',{'time_s','flux_from_current_Wb','flux_from_voltage_Wb','residual_Wb'}), ...
    fullfile(tables,'plasma_flux.csv'));
f = new_figure;tiledlayout(f,2,1,'TileSpacing','compact');
nexttile;plot(t(sel),[fluxCurrent(sel) fluxVoltage(sel)]);grid on;
ylabel('Flux linkage (Wb)');legend('Coupled currents','Measured voltage integral');
nexttile;plot(t(sel),fluxResidual(sel));grid on;ylabel('Residual (Wb)');xlabel('Time (s)');
write_figure(f,figures,'plasma_flux_crosscheck');
plateau = t>=6 & t<=11; demag=t>=12.3;
metrics.plasma = struct('plateau_window_s',[6 11], ...
    'Ip_mean_A',mean(y(plateau,11)),'Ics_mean_A',mean(y(plateau,7)), ...
    'plasma_power_mean_W',mean(plasmaPower(plateau)), ...
    'coil_power_mean_W',mean(coilPower(plateau)), ...
    'ripple_window_s',[1.80 1.85], ...
    'Ip_ripple_pp_A',max(y(ripple,11))-min(y(ripple,11)), ...
    'demag_window_s',[12.3 30], ...
    'demag_net_export_J',-trapz(t(demag),coilPower(demag)), ...
    'flux_residual_max_abs_Wb',max(abs(fluxResidual)), ...
    'note','All metrics describe the saved model; they do not establish classroom compliance.');

%% CS average model: teacher-provided 460 s reference case.
loaded = load(fullfile(raw,'cs_rectifier_average.mat'),'out');out = loaded.out;
t = out.Vdc_avg.Time;
fields = {'Vdc_avg','iCS_avg','Req_avg','Leq_avg','Pabs_avg', ...
    'PR_avg','pFlux_avg','BCS_avg','Emag_avg'};
y = zeros(numel(t),numel(fields));
for k=1:numel(fields)
    values = out.get(fields{k}); y(:,k)=interp1(values.Time,squeeze(values.Data),t);
end
writetable(array2table([t y],'VariableNames',{'time_s','Vdc_V','Ics_A', ...
    'Req_ohm','Leq_H','Pabs_W','PR_W','pFlux_W','BCS_T','Emag_J'}), ...
    fullfile(tables,'cs_full_pulse.csv'));
f = new_figure;tiledlayout(f,2,1,'TileSpacing','compact');
nexttile;plot(t,y(:,1)/1000);grid on;ylabel('V_{dc} (kV)');
nexttile;plot(t,y(:,2)/1000);grid on;ylabel('I_{cs} (kA)');xlabel('Time (s)');
write_figure(f,figures,'cs_voltage_current');
f = new_figure;tiledlayout(f,2,1,'TileSpacing','compact');
nexttile;plot(t,y(:,3));grid on;ylabel('R_{eq} (ohm)');
nexttile;plot(t,y(:,4));grid on;ylabel('L_{eq} (H)');xlabel('Time (s)');
write_figure(f,figures,'cs_load_schedule');
f = new_figure;tiledlayout(f,3,1,'TileSpacing','compact');
nexttile;plot(t,y(:,5:7)/1e6);grid on;ylabel('Power (MW)');legend('P_{abs}','P_R','p_{Flux}');
nexttile;plot(t,y(:,8));grid on;ylabel('B_{CS} (T)');
nexttile;plot(t,y(:,9)/1e9);grid on;ylabel('E_{mag} (GJ)');xlabel('Time (s)');
write_figure(f,figures,'cs_power_field_energy');
metrics.cs = struct('Vdc_mean_V',mean(y(:,1)), ...
    'Ics_peak_A',max(y(:,2)),'Pabs_peak_W',max(y(:,5)), ...
    'BCS_peak_T',max(y(:,8)),'Emag_peak_J',max(y(:,9)));
fid = fopen(fullfile(root,'measured_metrics.json'),'w');
cleanup = onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(metrics,'PrettyPrint',true));
disp('Writing assets exported: CSV, editable FIG, vector PDF and PNG.');
end

function fig = new_figure
fig = figure('Visible','off','Color','white','Units','centimeters', ...
    'Position',[2 2 19 12],'DefaultAxesFontSize',10, ...
    'DefaultLineLineWidth',1.2);
end

function write_figure(fig,folder,name)
exportgraphics(fig,fullfile(folder,[name '.png']),'Resolution',220);
exportgraphics(fig,fullfile(folder,[name '.pdf']),'ContentType','vector');
savefig(fig,fullfile(folder,[name '.fig']));
close(fig);
end
