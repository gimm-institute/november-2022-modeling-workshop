
close all
clear

load mat/createModel.mat m
ss = access(m, "steady-level");


%% Visualize credit risk function

figure();
z = reshape(linspace(-0.10, 0.10, 100), [], 1);
f1 = glogc1(-z, ss.ss_q_1, ss.c2_q_1, ss.c3_q_1, ss.c4_q_1, ss.c5_q_1);
plot(100*z, 400*f1);
grid on

xline(0, "lineWidth", 2);
title("Credit risk function");
xlabel("Macro conditions index");
ylabel("Portfolio default rate, %");


%%  Capital adequacy stress

car = linspace(ss.car_min-2/100, ss.car_min+ss.car_exs+5/100, 100);
car = reshape(car, [], 1);

rx = glogc1( ...
    -(car - ss.car_min) ...
    , ss.c1_rx, ss.c2_rx, ss.c3_rx, ss.c4_rx, ss.c5_rx ...
);

figure();
plot(100*car, 400*rx);
grid on

xline(100*m.car, "lineWidth", 2);
title("Regulatory capital adequacy stress function");
xlabel("Actual CAR");
ylabel("Effect on lending conditions (spread equivalent), PP PA");

