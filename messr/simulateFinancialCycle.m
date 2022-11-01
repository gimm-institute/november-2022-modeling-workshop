
close all
clear

load mat/createModel.mat m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We first induce increase in credit by creating expectations
% of fast future growth rate (shocks to potential growth rate)
d = steadydb(m,1:40);

d.shock_roc_y_tnd(8) = 3/100;    % expected positive shock
% d.shock_xcf_to_bk(1:7) = -0.01;

s = simulate( ...
    m, d, 1:40 ...
    , "prependInput", true ...
    , "method", "stacked" ...
    , "solver", "quickNewton" ...
    , "blocks", false ...
);

% then we revise the potential growth rate back unexpectedly, which revises
% expectations and shows to agents they were mistaken and took on too much
% credit => they deleverage
d2 = d;
d2.shock_roc_y_tnd(8) = 3/100 -3/100*1i; % unexpected negative shock
s2 = simulate( ...
    m, d2, 1:40 ...
    , "prependInput", true ...
    , "method", "stacked" ...
    , "solver", "quickNewton" ...
    , "blocks", false ...
);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

smc1 = databank.minusControl(m, s, d);
smc2 = databank.minusControl(m, s2, d2);

ch = databank.Chartpack();
ch.Range = 0:20;
ch.TitleSettings = {"interpreter", "none"}; 
ch.ShowFormulas = true;
ch.PlotSettings = {"lineWidth", 2, "marker", ".", "markerSize", 6};
ch.Highlight = 0:8;

ch < "Output gap: 100*(y_gap - 1)";
ch < "Forward output: 100*(fws_y - 1)";
ch < "Potential growth, PA: 400*(roc_y_tnd-1)";
ch < "Real bank loans: 100*(l / py - 1)";
ch < "Real new bank loans: 100*(new_l / py - 1)";
ch < "Credit risk (portfolio default rates): 100*q";
ch < "Lending conditions: 400*new_rl_full_gap";
ch < "Stock lending rates, PA: 400*rl";
ch < "Capital adequacy ratio: 100*car";
ch < "NPL ratio: 100*ln_to_l";
ch < "Return on assets: 400*rtae";
ch < "Return on equity: 400*rbk";
ch < "Loan-to-GDP: 100*l_to_4ny";
% ch < "Loan-to-GDP trend: 100*l_to_4ny_tnd";

draw(ch, smc1 & smc2);