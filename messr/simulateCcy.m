
close all
clear

load mat/createModel.mat m
h = databank.fromSheet("input-data/model-data.csv");

startSim = qq(2022,1);
endSim = qq(2030,4);

m0 = m;

s0 = simulate( ...
    m0, h, startSim:endSim ...
    , prependInput=true ...
    , method="stacked" ...
    , solver="quickNewton" ...
);

m1 = m;
m1.ss_car_ccy = 3/100;
m1.c0_car_ccy = 0.5;
m1 = steady(m1);
checkSteady(m1);
m1 = solve(m1);

s1 = simulate( ...
    m1, h, startSim:endSim ...
    , prependInput=true ...
    , method="stacked" ...
    , solver="quickNewton" ...
);


%% Plot basic results

ch = Chartpack();
ch.Range = qq(2015,1):endSim;
ch.Autocaption = true;
ch.Highlight = startSim:endSim;
ch.PlotSettings = { ...
    {"color"}, {[0,0.44,0.74];[0.85,0.33,0.10];[0,0.44,0.74];[0.85,0.33,0.10]} ...
    , {"lineStyle"}, {"-";"-";"-.";"-."} ...
};

ch + ["CAR and regulatory minimum: 100*[car, car_min]","Policy rate: 400*rp", "400*new_rl_1"];
ch + ["Nonperforming loans to gross loans: 100*ln/l"];
ch + ["Output gap: 100*(y_gap-1)"];

chartDb = databank.merge("horzcat", s0, s1);
draw(ch, chartDb);
visual.hlegend("bottom", "No CCY buffer", "Building CCY buffer");

