function [curveH, minH] = drawCapitalAdequacyRiskFunc(axesH, model, varargin)

    x = access(model(1), "steady-level");
    if isempty(varargin)
        car_min = x.car_min;
    else
        car_min = varargin{1}(1);
    end

    car = linspace(car_min-0.02, car_min+0.07, 500);
    car = reshape(car, [], 1);
    rx = glogc1(-(car - car_min), x.c1_rx, x.c2_rx, x.c3_rx, x.c4_rx, x.c5_rx);

    curveH = plot(axesH, 100*car, 400*rx, "color", [0, 0.4470, 0.7410]);
    minH = xline(axesH, 100*car_min, "-", "", "lineWidth", 3, "fontSize", 20);
    set(axesH, "xLim", [8, 16], "xLimMode", "manual", "yLim", 400*[0, max(rx)], "fontSize", 20);

    title(axesH, "Capital adequacy stress function");
    xlabel(axesH, "Standard CAR [%]");
    ylabel(axesH, "Credit conditions [% PA]");

end%

