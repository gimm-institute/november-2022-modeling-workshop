
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

reportDb = databank.merge("horzcat", s0, s1, s2);

reportSimulation( ...
    "html/baseline", reportDb ...
    , startFcast-8:endFcast, ["Hands-free", "Baseline", "Reproduced"], startFcast:endFcast ...
);


%% Stress scenario #1




