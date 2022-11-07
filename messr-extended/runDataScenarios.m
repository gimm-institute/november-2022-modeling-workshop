
close all
clear

load mat/createModel.mat m

startHist = qq(2015,1);
endHist = qq(2022,2);

baseline = databank.fromSheet("baseline.csv");
history = databank.fromSheet("history.csv");

d = databank.merge("replace", history, baseline);

range = startHist:endHist+6;

reportSimulation( ...
    "html/baselineInput", d ...
    , range, "History", startHist:endHist ...
);

startFcast = endHist + 1;
endFcast = endHist + 16;
endTune = endHist + 6;

%% Hands-free simulation

s0 = simulate( ...
    m, d, startFcast:endFcast ...
    , "prependInput", true ...
    , "method", "stacked" ...
);



%% Reproduce baseline using Plan (exogenize/endogenize)

p1 = Plan.forModel(m, startFcast:endFcast);
p1 = swap( ...
    p1, startFcast:endTune ...
    , ["yw_gap", "tune_yw_gap"], ["roc_cpiw", "tune_roc_cpiw"], ["rw", "tune_rw"], ["rrw_tnd", "tune_rrw_tnd"] ...
    , ["y_gap", "tune_y_gap"], ["roc_y_tnd", "tune_roc_y_tnd"], ["roc_cpi", "tune_roc_cpi"], ["e", "tune_e"], ["r", "tune_r"], ["rr_tnd", "tune_rr_tnd"], ["roc_re_tnd", "tune_roc_re_tnd"] ...
);

s1 = simulate( ...
    m, d, startFcast:endFcast ...
    , "prependInput", true ...
    , "method", "stacked" ...
    , "plan", p1 ...
);


%% Reproduce baseline using tunes

d2 = history;

tuneNames = access(m, "transition-shocks");
tuneNames = tuneNames(startsWith(tuneNames, "tune_"));
for n = tuneNames
    d2.(n) = s1.(n);
end

s2 = simulate( ...
    m, d2, startFcast:endFcast ...
    , "prependInput", true ...
    , "method", "stacked" ...
);



%% Stress scenario #1: Policy rate hike


d3 = d2;

p3 = Plan.forModel(m, startFcast:endFcast+20);
p3 = swap(p3, startFcast:startFcast+3, ["r", "shock_r"]);

d3.r(startFcast:startFcast+3) = 12.5/400;

s3 = simulate( ...
    m, d3, startFcast:endFcast+20 ...
    , "prependInput", true ...
    , "method", "stacked" ...
    , "plan", p3 ...
);


%% Stress scenario #2: Policy rate hike and permanent increase in PDR


d4 = d3;
p4 = p3;

m4 = m;
m4.ss_q_hh = 2/100;
m4 = steady(m4);
checkSteady(m4);
m4 = solve(m4);

s4 = simulate( ...
    m4, d4, startFcast:endFcast+20 ...
    , "prependInput", true ...
    , "method", "stacked" ...
    , "plan", p4 ...
);


%% Stress scenario #3 Morocco: Inflation & exchange rate


d5 = d2;

m5 = m;
m5.c1_roc_cpi_exp = 1;
m5.c1_r = 3;
m5.c1_z_hh = 0.85;
% m5.c1_bk = 3;
checkSteady(m5);
m5 = solve(m5);

p5 = Plan.forModel(m, startFcast:endFcast);
p5 = swap(p5, startFcast:startFcast+3, ["roc_cpi", "shock_roc_cpi"]);
p5 = swap(p5, startFcast:startFcast+3, ["rw", "shock_rw"]);
p5 = swap(p5, startFcast:startFcast+3, ["roc_cpiw", "shock_roc_cpiw"]);

d5.roc_cpi(startFcast:startFcast+3) = 1.20^(1/4);
d5.roc_cpiw(startFcast:startFcast+3) = 1.15^(1/4);
d5.rw(startFcast:endFcast+3) = 5/400;

s5 = simulate( ...
    m5, d5, startFcast:endFcast ...
    , "prependInput", true ...
    , "method", "stacked" ...
    , "plan", p5 ...
);

%% Bank profit components

s5 = postprocess(m5, s5, startFcast-1:endFcast);

figure();
bar(startFcast-1:endFcast,[s5.prof_int_loans, s5.prof_int_ona, s5.prof_int_liab, s5.prof_prov, s5.prof_val_ass, s5.prof_val_liab, s5.prof_other], "stacked");
legend("Int loans", "Int other assets", "Int liabs", "Provisioning", "Valuation assets", "Valuation liabs", "Other");
title("Bank profit components");


%% Report

reportDb = databank.merge("horzcat", s0, s1, s2, s3, s4, s5);

reportSimulation( ...
    "html/dataScenarios", reportDb ...
    , startFcast-8:endFcast, ["Hands-free", "Baseline", "Reproduced", "Policy rate hike", "Policy rate hike & PDR", "Morocco"], startFcast:endFcast ...
);

