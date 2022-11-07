%% Series of simulations to illustrate the key transmission mechanisms in the MESSr
% GIMM Fall 2022 workshop


%% Housekeeping
clear all
close all
clc

%% Load the model
load mat/createModel.mat

%% Prepare database of initial conditions - we start from steady-state, 
% economy and financial sector are in equlibrium

dbinit = steadydb(m, 1:40);


%% Prepare reporting 

ch = databank.Chartpack();
ch.Range = 0:20;
ch.Round = 8;
ch.TitleSettings = {"interpreter", "none"}; 
ch.ShowFormulas = true;
ch.PlotSettings = {"lineWidth", 2, "marker", ".", "markerSize", 6};


%% Introduce a simple negative demand shock that worsens credit performance

dbinit.shock_y_gap(1) = -0.02; % significant, 4pp shock into output gap


s1 = simulate( ...
    m, dbinit, 1:40 ...
    , "prependInput", true ...
    , "method", "stacked" ...
    , "anticipate", true ...
);


dbinit.shock_y_gap(1) = -0.04; % significant, 4pp shock into output gap


s2 = simulate( ...
    m, dbinit, 1:40 ...
    , "prependInput", true ...
    , "method", "stacked" ...
    , "anticipate", true ...
);

%% Draw results - start with output gap, default rates, NPLs, CAR

ch < "Output gap: 100*(y_gap - 1)";
ch < "Credit risk (portfolio default rates): 100*q";
ch < "Macro conditions index: 100*z_1";
ch < "NPL ratio: 100*ln/l";

draw(ch, s1 & s2 & dbinit);

% return

%% More details on bank balance sheet

ch < "Allowances (stock): a";
ch < "Allowances-to-NPLs: a/ln";


draw(ch, s1 & s2 & dbinit);

% return

%% Credit stock, credit creation

ch < "Credit-to-GDP: 100*l/(4*ny)";
ch < "New credit, gross (flow): new_l";


draw(ch, s1 & s2 & dbinit);

% return

%% Interest rates: stocks vs flows

ch < "New lending rate: 400*new_rl";
ch < "Stock lending rate: 400*rl";

draw(ch, s1 & s2 & dbinit);

% return

%% Interest rates: impact of higher credit risk

ch < "Base rate: 400*rl_base_1";
ch < "New lending rate w/ full risk: 400*new_rl_full";
ch < "Non-price conditions: 400*(new_rl_full-new_rl)";


draw(ch, s1 & s2 & dbinit);

% return

%% Profit and loss

ch < "Return on equity: 400*rbk";
ch < "Return on assets: 400*rtae";
ch < "CAR: 100*car";


draw(ch, s1 & s2 & dbinit);

% return

%% Capital risk surcharge

ch < "Capital risk surcharge: 400*rx";


draw(ch, s1 & s2 & dbinit);

% return
