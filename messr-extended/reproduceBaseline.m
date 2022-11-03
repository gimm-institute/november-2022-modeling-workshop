
close all
clear

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

