
function reportSimulation(fileName, db, range, legend, highlightRange)

    content = containers.Map();

    content("External") = {
        "Foreign demand gap, %", 100*(db.yw_gap-1)
        "Foreign short-term rate, % PA", 400*db.rw
        "Foreign CPI Q/Q PA", 100*(db.roc_cpiw^4-1) 
        "Foreign real short-term rate trend, % PA", 400*db.rrw_tnd
    };

    content("Macroeconomy") = {
        "GDP, Q/Q PA", 100*(db.roc_y^4-1)
        "GDP gap, %", 100*(db.y_gap-1)
        "Potential GDP, % PA", 100*(db.roc_y_tnd^4-1)
        "Short-term rate, % PA", 400*db.r
        "CPI Q/Q PA", 100*(db.roc_cpi^4-1)
        "GDP deflator Q/Q PA", 100*(db.roc_py^4-1) 
        "Nominal exchange rate", db.e
        "Real exchange rate gap", 100*(db.re_gap-1)
    };

    content("Bank credit") = {
        "Credit to GDP ratio", 100*db.l_to_4ny_hh
        "Sustainable credit to GDP ratio", 100*db.l_to_4ny_tnd_hh
        "Nominal credit Q/Q PA", apct(db.l)
        "Real credit Q/Q PA", apct(db.l/db.py)
        "New nominal credit Q/Q PA", apct(db.new_l)
        "New real credit Q/Q PA", apct(db.new_l/db.py)
    };

    R = rephrase.Report("MESSr simulation report");

    P = rephrase.Pager("");

    if isempty(highlightRange)
        H = [];
    else
        H = rephrase.Highlight(highlightRange(1), highlightRange(end));
    end

    for topic = ["External", "Macroeconomy", "Bank credit"]

        G = rephrase.Grid(topic, [], 2, "pass", {"dateFormat", "YYYY-Q", "round", 4, "highlight", H});

        for i = 1 : size(content(topic), 1)
            x = content(topic);
            title = x{i, 1};
            series = x{i, 2};
            G = G + rephrase.SeriesChart.fromSeries({title, range}, {legend, series});
        end

        P = P + G;
    end

    R = R + P;

    show(R);

    build(R, fileName, [], "source", "web", "saveJSON", true);

end%

