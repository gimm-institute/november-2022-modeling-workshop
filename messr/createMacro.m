
close all
clear

modelFiles = [ ...
    "model-source/macro.model"
    "model-source/macro-wrapper.model"
];

macro = Model.fromFile( ...
    modelFiles ...
    , growth=true ...
);

p = struct();
p = calibrate.macro(p);

macro = assign(macro, p);

macro = steady(macro);
checkSteady(macro);
macro = solve(macro);

access(macro, "initials")

h = databank.fromSheet("input-data/model-data.csv");
s = simulate( ...
    macro, h, qq(2022,2):qq(2025,4) ...
    , prependInput=true ...
    , method="stacked" ...
    , solver="quickNewton" ...
);

