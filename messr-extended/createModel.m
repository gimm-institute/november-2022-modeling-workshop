%% Create model object 


%% Clear workspace 

close all
clear
% #ok<*CLARRSTR>
 
if ~exist("mat", "dir")
    mkdir mat
end

if ~exist("printout", "dir")
    mkdir printout
end


%% Read source files and create model object 

% Create a model object based on a subset of modules

modelFiles = [...
  "model-source/world.model"
  "model-source/macro.model"
  "model-source/bankCapital.model"
  "model-source/creditCreation.model"
  "model-source/creditRisk.model"
  "model-source/interestRates.model"  
  "model-source/loanPerformance.model"  
  "model-source/prudentialProvisions.model"
  "model-source/financialProvisions.model"
];

m = Model.fromFile( ...
    modelFiles ...
    , 'growth',true...
    , 'assign',struct("segments", ["hh"]) ...
);



%% Calibrate parameters for world and macro modules

% Collect all baseline parameter values in the p struct; list the values
% afterwards; assign all the values to the model object

p = struct();
p = calibrate.world(p);
p = calibrate.macro(p);
p = calibrate.creditCreation(p);
p = calibrate.creditRisk(p);
p = calibrate.loanPerformance(p);
p = calibrate.prudentialProvisions(p);
p = calibrate.financialProvisions(p);
p = calibrate.interestRates(p);
p = calibrate.bankCapital(p);
p = calibrate.stress(p);

m = assign(m, p);

%% Calculate steady state

m = steady(m);
checkSteady(m);


%% Print steady state table for nonlinear model

table( ...
    m, ["SteadyLevel", "SteadyChange", "Form", "Description"] ...
    , "writeTable", "steadyState.xlsx" ...
)

m = solve(m);


%% Save model objects to MAT File

save mat/createModel.mat m

