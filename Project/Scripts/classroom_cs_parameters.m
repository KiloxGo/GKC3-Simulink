function parameters = classroom_cs_parameters
% Self-contained initialization of the documented independent CS scenario.
%% CS 1.5 kV rectifier supply model parameters
% Shared parameter initialization for the detailed rectifier model and the
% later 0--460 s average-value model.

tKey = [0 5 8 12 45 70 335 420 460];
RKey = [0.35 0.80 0.60 0.024 0.024 0.12 0.12 0.25 0.35];
LKey = [1.10 1.08 1.03 0.98 0.95 1.02 1.00 1.08 1.12];

dt = 0.01;
tGrid = 0:dt:tKey(end);
RGrid = interp1(tKey, RKey, tGrid, "pchip");
LGrid = interp1(tKey, LKey, tGrid, "pchip");

RGrid = max(RGrid, 1e-4);
LGrid = max(LGrid, 1e-3);

R_ts = timeseries(RGrid, tGrid);
L_ts = timeseries(LGrid, tGrid);

Vdc_ref = 1500;       % V
V_primary = 10e3;     % V RMS, line-to-line
V_secondary = 1.2e3; % V RMS, line-to-line
S_transformer = 70e6; % VA
transformer_ratio = V_secondary / V_primary;
alpha0_deg = acosd(Vdc_ref / (1.35 * 1200));
control_sample_time = 5e-5; % s
Vdc_filter_tau = 0.01;      % s
Vdc_filter_a = exp(-control_sample_time / Vdc_filter_tau);
Kp_vdc_alpha = 0.005;       % deg/V
Ki_vdc_alpha = 0.20;        % deg/(V*s)
alpha_min_deg = 5;
alpha_max_deg = 80;
alpha_integral_min = alpha_min_deg - alpha0_deg;
alpha_integral_max = alpha_max_deg - alpha0_deg;
avg_Kp_deg_per_V = 0.02;    % Average converter proportional gain (deg/V)
avg_Ki_deg_per_Vs = 0.50;   % Average converter integral gain (deg/(V*s))
avg_converter_tau_s = 0.05; % Average converter first-order response time (s)
I_base = 45e3;        % A
B_base = 13;          % T
kB = B_base / I_base;

parameters = struct;
parameters.tKey = tKey;
parameters.RKey = RKey;
parameters.LKey = LKey;
parameters.dt = dt;
parameters.tGrid = tGrid;
parameters.RGrid = RGrid;
parameters.LGrid = LGrid;
parameters.R_ts = R_ts;
parameters.L_ts = L_ts;
parameters.Vdc_ref = Vdc_ref;
parameters.V_primary = V_primary;
parameters.V_secondary = V_secondary;
parameters.S_transformer = S_transformer;
parameters.transformer_ratio = transformer_ratio;
parameters.alpha0_deg = alpha0_deg;
parameters.control_sample_time = control_sample_time;
parameters.Vdc_filter_tau = Vdc_filter_tau;
parameters.Vdc_filter_a = Vdc_filter_a;
parameters.Kp_vdc_alpha = Kp_vdc_alpha;
parameters.Ki_vdc_alpha = Ki_vdc_alpha;
parameters.alpha_min_deg = alpha_min_deg;
parameters.alpha_max_deg = alpha_max_deg;
parameters.alpha_integral_min = alpha_integral_min;
parameters.alpha_integral_max = alpha_integral_max;
parameters.avg_Kp_deg_per_V = avg_Kp_deg_per_V;
parameters.avg_Ki_deg_per_Vs = avg_Ki_deg_per_Vs;
parameters.avg_converter_tau_s = avg_converter_tau_s;
parameters.I_base = I_base;
parameters.B_base = B_base;
parameters.kB = kB;
end
