%% Generate random data for history

close all
clear

load mat/createModel.mat m

shocks = access(m, "transition-shocks");
macro = byAttributes(m, [":macro", ":world"]);


%% Calibrate stds of selected shocks

m = rescaleStd(m, 0);

m.std_shock_rrw_tnd = 0.00;

m.std_shock_yw_gap = 0.01;
m.std_shock_roc_cpiw = 0.01;
m.std_shock_rw = 0.001;

m.std_shock_roc_y_tnd = 0.001;
m.std_shock_y_tnd = 0.001;
m.std_shock_roc_re_tnd = 0.001;
m.std_shock_rr_tnd = 0.001;

m.std_shock_fwy_bubble = 0;
m.std_shock_y_gap = 0.01;
m.std_shock_roc_py = 0.01;
m.std_shock_roc_cpi = 0.005;
m.std_shock_r = 0.001;
m.std_shock_e = 0.01;
m.std_shock_prem_gap = 0.001;


m = rescaleStd(m, 0.5);


%% Generate historical data

startHist = qq(2015,1);
endHist = qq(2022,2);

rng(0);

d = databank.forModel(m, startHist:endHist, "shockFunc", @randn);

h = simulate( ...
    m, d, startHist:endHist ...
    , "prependInput", true ...
    , "method", "stacked" ...
    , "anticipate", false ...
    , "successOnly", true ...
);

databank.toSheet(h, "history.csv");


%% Create HTML report

d.e(:) = NaN;

reportSimulation( ...
    "html/history", databank.merge("horzcat", h, d), startHist:endHist, ["History", "Steady"], [] ...
);


list = [
    "yw_gap"
    "rw"
    "rrw_tnd"
    "roc_cpiw"    
    "y_gap"
    "roc_y_tnd"
    "roc_cpi"
    "e"
    "r"
    "rr_tnd"
    "roc_re_tnd"
];

baseline = databank.copy(h, "sourceNames", list);
% databank.toSheet(baseline, "baseline.csv");





