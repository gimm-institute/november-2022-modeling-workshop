

close all
clear


disp("    Loading & processing data from cso.ie");

t0 = webread("https://ws.cso.ie/public/api.restful/PxStat.Data.Cube_API.ReadDataset/NA001/CSV/1.0/en");
t = t0(startsWith(t0.Item, "10. "), :);
d.nmgni_y = Series(yy(t.Year), t.VALUE, "Nominal modified GNI");


t0 = webread("https://ws.cso.ie/public/api.restful/PxStat.Data.Cube_API.ReadDataset/NA002/CSV/1.0/en");
t = t0(startsWith(t0.Item, "Modified"), :);
d.mgni_y = Series(yy(t.Year), t.VALUE, "Real modified GNI");


t0 = webread("https://ws.cso.ie/public/api.restful/PxStat.Data.Cube_API.ReadDataset/NAQ03/CSV/1.0/en");
t = t0(contains(t0.Statistic, "GDP at Constant") & contains(t0.Statistic, "Seasonally"), :);
d.gdp = Series(dater.fromString(t.Quarter, "{YYYY}Q{Q}"), t.VALUE, "Real GDP");

t = t0(contains(t0.Statistic, "GDP at Current") & contains(t0.Statistic, "Seasonally"), :);
d.ngdp = Series(dater.fromString(t.Quarter, "{YYYY}Q{Q}"), t.VALUE, "Nominal GDP");


d.nmgni = genip( ...
    d.nmgni_y, Frequency.QUARTERLY, 1, "sum" ...
    , "range", getStart(d.nmgni_y)+1:getEnd(d.nmgni_y) ...
    , "indicatorModel", "ratio" ...
    , "indicatorLevel", d.ngdp ...
);

d.mgni = genip( ...
    d.mgni_y, Frequency.QUARTERLY, 1, "sum" ...
    , "range", getStart(d.mgni_y)+1:getEnd(d.mgni_y) ...
    , "indicatorModel", "ratio" ...
    , "indicatorLevel", d.gdp ...
);

d.nmgni = grow(d.nmgni,  "roc", roc(d.ngdp), getEnd(d.nmgni)+1:getEnd(d.ngdp));
d.mgni = grow(d.mgni,  "roc", roc(d.gdp), getEnd(d.mgni)+1:getEnd(d.gdp));


d.pgdp = d.ngdp / d.gdp;
d.pmgni = d.nmgni / d.mgni;
d.pmgni_y = d.nmgni_y / d.mgni_y;


t0 = webread("https://ws.cso.ie/public/api.restful/PxStat.Data.Cube_API.ReadDataset/CPM02/CSV/1.0/en");
t = t0(contains(t0.SelectedBaseReferencePeriod, "2016"), :);
d.cpi_mu = Series(dater.fromString(t.Month, "{YYYY} {MMM}"), t.VALUE, "Consumer price index, 2016=100");
d.cpi_m = x13.season(d.cpi_mu);
d.cpi = convert(d.cpi_m, Frequency.QUARTERLY);


disp("    Loading & processing data from ECB SDW");

sdw = databank.fromECB.data("FM", "M.U2.EUR.RT.MM.EURIBOR3MD_.HSTA");
sdw = databank.fromECB.data("ICP", "M.U2.N.000000.4.INX", addToDatabank=sdw);
sdw = databank.fromECB.data("EXR", "Q.USD.EUR.SP00.A", addToDatabank=sdw);

d.rs_m = sdw.M_U2_EUR_RT_MM_EURIBOR3MD__HSTA;
d.rs = convert(d.rs_m, Frequency.QUARTERLY);

d.ea_cpi_mu = sdw.M_U2_N_000000_4_INX;
d.ea_cpi_m = x13.season(d.ea_cpi_mu);
d.ea_cpi = convert(d.ea_cpi_m, Frequency.QUARTERLY);


disp("    Loading & processing data from Fred");

fred = databank.fromFred.data(["CPIAUCSL", "TB3MS"]);

d.us_cpi_m = fred.CPIAUCSL;
d.us_cpi = convert(d.us_cpi_m, Frequency.QUARTERLY);

d.us_rs_m = fred.TB3MS;
d.us_rs = convert(d.us_rs_m, Frequency.QUARTERLY);


databank.toSheet(d, "input-data/macro.csv", numDividers=2);

