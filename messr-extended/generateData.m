
close all
clear

load mat/createModel.mat m

shocks = access(m, "transition-shocks");
macro = byAttributes(m, [":macro", ":world"]);

m = assign(m, "std_"+setdiff(shocks, macro), 0);
m = assign(m, "std_"+shocks(startsWith(shocks, "tune")), 0);

m = rescaleStd(m, 0);

m.std_shock_rrw_tnd = 0.001;

m.std_shock_yw_gap = 0.01;
m.std_shock_roc_cpiw = 0.02;
m.std_shock_rw = 0.001;

m.std_shock_roc_y_tnd = 0.001;
m.std_shock_y_tnd = 0.001;
m.std_shock_roc_re_tnd = 0.001;
m.std_shock_rr_tnd = 0.001;

m.std_shock_fwy_bubble = 0;
m.std_shock_y_gap = 0.01;
m.std_shock_roc_py = 0.01;
m.std_shock_roc_cpi = 0.005;
m.std_shock_r = 0.005;
m.std_shock_e = 0.01;
m.std_shock_prem_gap = 0.001;


%{
m.std_shock_ivy_tnd_hh = 0.001;
m.std_shock_l_to_4ny_tnd_hh = 0.001;
m.std_shock_rl_hh = 0;
m.std_shock_rl_apm = 0.01;
m.std_shock_new_rl_hh = 0;
m.std_shock_new_rl_full_hh = 0;
m.std_shock_new_rl_full1_hh = 0;
m.std_shock_new_rl_full2_hh = 0;
m.std_shock_rl_apm_hh = 0;

m.std_shock_rbk = 0;
m.std_shock_riskw = 0;
m.std_shock_onfx = 0.001;
m.std_shock_car_min = 0;
m.std_shock_ona = 0.001;
m.std_shock_bg_to_bk = 0;
m.std_shock_new_l = 0.01;
m.std_shock_ivy_hh = 0.01;
m.std_shock_new_l_hh = 0.01;
m.std_shock_q = 0;
m.std_shock_q_hh = 0.01;
m.std_shock_rona = 0.01;
m.std_shock_rona_spread = 0.01;
m.std_shock_rd_lcy = 0;
m.std_shock_new_rd_lcy = 0;
m.std_shock_rd_fcy = 0;
m.std_shock_new_rd_fcy = 0;
m.std_shock_sigma_hh = 0;
m.std_shock_woff_hh = 0.01;
m.std_shock_ap_fe_hh = 0;
%}

d = steadydb(m, qq(2010,1):qq(2022,1), shockFunc=@randn);

h = simulate( ...
    m, d, qq(2011,1):qq(2022,1) ...
    , prependInput=true ...
    , method="stacked" ...
    , anticipate=false ...
    , successOnly=true ...
);

