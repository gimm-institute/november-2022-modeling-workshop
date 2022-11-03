
%% Create and calibrate model object from model source files 

%% Clear workspace 

close all
clear

if ~exist("mat", "dir")
    mkdir mat
end


%% Read model 

% list of files (model modules) to be included
modelFiles = [ ...
    "model-source/creditCreation.model"
    "model-source/loanPerformance.model"
    "model-source/secPerformance.model"
    "model-source/creditRisk.model"
    "model-source/interestRate.model"
    "model-source/bankCapital.model"
    "model-source/macro.model"
 ];

% how many loan segments we create
numSegments = 1;

m = Model( ...
    modelFiles ...
    , "assign", struct('K', numSegments, 'onlyMacro', false) ...
    , "growth", true ...
);


p = struct();

%% Macro block

p = calibrate.macro(p);


%% Credit creation block 

p.ss_ivy_1 = 1; % S/S inverse velocity of credit 
% p.ss_ivy_2 = 1; % S/S inverse velocity of credit

p.c1_trn_1 = 0.65; % weight on today's output in trn
% p.c1_trn_2 = 0.5; % weight on today's output in trn

p.c0_ivy_1 = 0.85; % persistence
p.c1_ivy_1 = 0.20; % loan-to-GDP trend
p.c2_ivy_1 = 0.5; % lending conditions

% p.c0_ivy_2 = 0.85; % persistence
% p.c1_ivy_2 = 0.05; % loan-to-GDP trend
% p.c2_ivy_2 = 0.30; % lending conditions

p.c0_l_to_4ny_tnd_1 = 0.99; % loan-to-GDP trend persistence
% p.c0_l_to_4ny_tnd_2 = 0.99; % loan-to-GDP trend persistence


%% Loan performance block 

p.theta_lp_1 = 0.05; % inverse average perf. loan maturity
% p.theta_lp_2 = 1 / (2.5*4); % inverse average perf. loan maturity

p.theta_ln_1 = p.theta_lp_1; % inverse average nonperf. loan maturity
% p.theta_ln_2 = 1 / (2.5*4); % inverse average perf. loan maturity

p.lambda_1 = 0.55; % LGD
% p.lambda_2 = 0.5; % LGD 

p.omega_1 = 0.25; % write-offs as a share of NPLs
% p.omega_2 = 0.10; % write-offs as a share of NPLs

p.ss_a_to_ln_1 = 0.55; % Share of incurred loss-based allowances on NPLs
% p.c_a_to_ln_2 = 0.675; % Share of incurred loss-based allowances on NPLs

p.c0_a_1 = 0.5; % A/R in incurred-loss allowances

p.ss_oni_to_tae = 0/400; % general expense items: operations, taxes, ...


%% Credit risk block 

p = calibrate.creditRisk(p);


%% Lending and funding rates

p.ss_rl_apm_1 = 0.8/400;
% p.ss_rl_apm_2 = 4/400;
p.ss_rd_apm = 0/400;
p.ss_roae_apm = 1.0/400;

p.ss_rsec_apm = 0.3/400;

p.psi_rl1_1 = 0.15;
p.psi_rl2_1 = 1/(2);


p.psi_rd = 1/2;

p.c_rl_new_1 = 0.25; % degree of risk pass-through to the new lending rates
% p.c_rl_new_2 = 0.25; % degree of risk pass-through to the new lending rates

p.c1_rx =  2/400;
p.c2_rx =  0.007;
p.c3_rx =  0.50;
p.c4_rx = -2/400;
p.c5_rx =  0.5/400;


%% Bank capital

p.c1_xcf = 0.25;
p.floor_car_min = 0.20; % Regulatory minimum CAR floor
p.car_exs = 0.04; % S/S excess capital held by the banks

p.c0_car_ccy = 0.5;
p.ss_car_ccy = 0.00; % S/S counter-cyclical capital buffer

p.c0_car_cons = 0.5;
p.ss_car_cons = 0.00; % S/S conservation capital buffer

p.ss_oae_to_4ny = 0.25; % about 25% GDP share 
p.c0_oae_to_4ny = 0.98; 

p.c0_riskw = 0.85;
p.ss_riskw = 0.60;

p.theta_sec = 1/8; % inverse maturity of bond portfolio held by banks
p.theta_secdur = 1/4; % inverse duration of bond portfolio held by banks - should be higher than theta_b
p.c1_new_sec = 0.05; % elastisticity of new bond purchases to bonds-to-GDP gap

p.ss_reg_to_bk = 1.60;
p.c0_reg_to_bk = 0.85;

m = assign(m, p);


%% Calculate steady state

% Reverse engineering

m.l_to_4ny_1 = 100/100; % S/S loan-to-GDP ratio
m.ln_to_l_1 = 5/100; % S/S NPL ratio
m.sec_to_4ny = 25/100; % S/S ratio of bonds to nominal GDP
m.rl_spread_rp_1 = 3.5/400; % S/S stock lending spread
m.rbk = 5/400;


swaps = [
    "l_to_4ny_1", "ss_ivy_1"
    "ln_to_l_1", "ss_q_1"
    "sec_to_4ny", "ss_new_sec_to_4ny"
    "rl_spread_rp_1", "ss_rl_apm_1"
    "rbk", "ss_oni_to_tae"
];

m = steady( ...
    m ...
    , "exogenize", swaps(:, 1) ...
    , "endogenize", swaps(:, 2) ...
);

checkSteady(m);
table(m, ["SteadyLevel", "SteadyChange", "Form", "Description"])
ss = access(m, "steady-level");


%% Calculate first order solution matrices

m = solve(m);
disp(m);


%% Save model to mat file

save mat/createModel.mat m


