
close all
clear

load mat/createModel.mat m

m = alter(m, 3);
m.c0_roc_re_tnd = 0;
m.ss_sigma_hh = [0, 0.30, 0.60];
m = steady(m);
m = solve(m);

d = databank.forModel(m, 1:40);
d.shock_e(1:4) = 0.10;
d.shock_roc_re_tnd(1) = 0.06;

s = simulate(m, d, 1:40, "prependInput", true, "method", "stacked");

reportSimulation( ...
    "html/simulateForexRisk", s ...
    , 0:40, ["0%", "30%", "60%"], [] ...
);

