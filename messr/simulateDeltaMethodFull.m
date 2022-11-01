%% Illustrate delta method - we first obtain shocks that replicate 
% QPM macro forecast, then use these shocks as a basis for further
% simulation


%% Clear workspace

close all
clear


%% Load model objects and databank

load mat/createModel.mat m n

endHist = qq(2022,1);
startSim = endHist + 1;
endSim = endHist + 6*4;
simRange = startSim:endSim;

CreditToGdpRatio = [75 80 85];

for ii = 1:numel(CreditToGdpRatio)
    
    dbin = getInitcondFromData(m, n, simRange,'../data-v1/QpmForecast.xlsx',Series(qq(2019,4), CreditToGdpRatio(ii)/100));


    %% Conditional simulation 
    % serves only to estimate "tune_xxx" shocks to be used later
    %
    % We will exogenize all macro variables; the results of this simulation
    % are not important, we are only interested in values of the "tune_xxx"
    % shocks

    endTune = getEnd(dbin.y);

    p0 = Plan.forModel(m, startSim:endSim);
    p0 = exogenize(p0, startSim:endTune, ["l_y_gap", ...
                                          "l_y_tnd", ...
                                          "l_cpi", ...
                                          "ip"]);
    p0 = endogenize(p0, startSim:endTune, ["tune_l_y_gap", ...
                                           "tune_dl_y_tnd", ...
                                           "tune_dl_cpi", ...
                                           "tune_ip"]);

    s0 = simulate( ...
        m, dbin, startSim:endSim ...
        , "prependInput", true ...
        , "method", "stacked" ...
        , "plan", p0 ...
        , "Solver"     , {"Iris-Newton", "SkipJacobUpdate", 0,'FunctionTolerance', 1e-8,'StepTolerance',Inf,...
                                 "FunctionNorm", Inf, "Display=","Iter"} ...
                  );

    % add estimated values of "tune_xxx" to database dbin
    list = fieldnames(s0);
    list = list(startsWith(list,'tune_'));
    dbin = dbin + s0*list;

    %% Simulate "hands-free" scenario - only conditioned on QPM macro forecast

    s(ii) = simulate( ...
        m, dbin, startSim:endSim ...
        , "prependInput", true ...
        , "method", "stacked" ...
        , "Solver"     , {"Iris-Newton", "SkipJacobUpdate", 0,'FunctionTolerance', 1e-8,'StepTolerance',Inf,...
                                 "FunctionNorm", Inf, "Display=",Inf} ...
                  );

    % report into HTML
    mkdir('reports');
    % reportSimulation(s1, startSim-4, endSim, 'reports/simulation1', 'This is a title')

    %% Simulate scenario with additional tunes on top of QPM macro forecast

%     % keep default rate q down by shocks in 2020Q2-Q4
%     P = Plan.forModel(m, startSim:endSim);
% 
%     % add "delayed defaults" after macroprudential measures finish
%     dbin.shock_q_1(qq(2022,2):qq(2022,4)) = [0.03 0.02 0.015]/2*i;
% 
%     [s2, info] = simulate( ...
%         m, dbin, startSim:endSim ...
%         , "prependInput", true ...
%         , "method", "stacked" ...
%     ...    , "Plan", P ...
%         , "Solver"     , {"Iris-Newton", "SkipJacobUpdate", 0,'FunctionTolerance', 1e-8,'StepTolerance',Inf,...
%                                  "FunctionNorm", Inf, "Display=",Inf} ...
%                   );
%     if ~info.Success
%       error('Simulation did not converge!')
%     end
end

    %% Plot results

    s2 = databank.merge("horzcat", s(1), s(2),s(3));

    ch = databank.Chartpack();
    ch.Range = simRange(1)-40:simRange(end);
    ch.TitleSettings = {"interpreter", "none"}; 
    ch.Highlight = simRange(1)-40 : simRange(1)-1;
    ch.ShowFormulas = true;
    ch.PlotSettings = {"lineWidth", 2, "marker", ".", "markerSize", 6};

    ch < "Output gap: 100*(y_gap - 1)";
    ch < "Real new bank loans: 100*(new_l / py - 1)";
    ch < "Lending conditions: 400*new_rl_full_gap";
    ch < "NPL ratio: 100*ln_to_l";
    ch < "Loan-to-GDP: 100*l_to_4ny";
    ch < "CAR: 100*car";
    ch < "Real estate price index: repi";
    % ch < "Real estate price index growth (% QoQ): 400*log(roc_repi)";
    ch < "Policy rate: rp*400";
    ch < "Repi gap (pp): repi_gap*100";
    ch < "LGD Lambda (%): lambda_1*100";
    ch < "Portfolio default rate (%): q*100";
    ch < "Return on bank capital, PA (%): rbk*400";
    draw(ch, s2);
    visual.hlegend("bottom", "75%","80%", "85%");
    

    ch2 = databank.Chartpack();
    ch2.Range = simRange(1)-12:simRange(end);
    ch2.TitleSettings = {"interpreter", "none"}; 
    ch2.Highlight = simRange(1)-12 : simRange(1)-1;
    ch2.ShowFormulas = true;
    ch2.PlotSettings = {"lineWidth", 2, "marker", ".", "markerSize", 6};

    ch2 < "Lending conditions: 400*new_rl_full_gap";
    ch2 < "Portfolio default rate (%): q*100";
    ch2 < "Composite macro indicator (pp): z_1*100";
   
    draw(ch2, s2);
    visual.hlegend("bottom", "75%","80%", "85%");

    figure;
    subplot(221);
      bar([log(s(1).y_gap) ...
        -m.c1_z_1 * ( s(1).l_1 / (4 * s(1).py * s(1).fws_y) - s(1).l_to_4ny_tnd_1) ...
        +m.c2_z_1 * s(1).repi_gap]*100, 'stacked');
      hold on 
      plot(s(1).z_1,'LineWidth',3);
      legend('Output gap','Credit gap','REPI gap');
      title('Z decomposed, 75%');
      grid;
    subplot(222);
      bar([log(s(2).y_gap) ...
        -m.c1_z_1 * ( s(2).l_1 / (4 * s(2).py * s(2).fws_y) - s(2).l_to_4ny_tnd_1) ...
        +m.c2_z_1 * s(2).repi_gap]*100, 'stacked');
      hold on 
      plot(s(2).z_1,'LineWidth',3);
      legend('Output gap','Credit gap','REPI gap');
      title('Z decomposed, 80%');     
      grid;
    subplot(223);
      bar([log(s(3).y_gap) ...
        -m.c1_z_1 * ( s(3).l_1 / (4 * s(3).py * s(3).fws_y) - s(3).l_to_4ny_tnd_1) ...
        +m.c2_z_1 * s(3).repi_gap]*100, 'stacked');
      hold on 
      plot(s(3).z_1,'LineWidth',3);
      legend('Output gap','Credit gap','REPI gap');
      title('Z decomposed, 85%');   
      grid;





