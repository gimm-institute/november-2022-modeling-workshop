
close all
clear

load mat/createModel.mat m
ss = access(m, "steady-level");

d = databank.fromSheet("input-data/macro.csv");
b = databank.fromSheet("input-data/banking.csv");
f = databank.fromSheet("input-data/stab.csv");
fsi = databank.fromSheet("input-data/fsi.csv");

startHist = qq(2015,1);
endHist = qq(2022,1);

scale = 1e-3;

h = struct();
h.y = d.mgni * scale;
h.ny = d.nmgni * scale;
h.py = d.nmgni / d.mgni;
h.cpi = d.cpi / 100;
h.rp = d.rs/400;
h.rrp = (1 + h.rp) / roc(h.cpi) - 1;
h.ea_cpi = d.ea_cpi / 100;
h.re = d.ea_cpi / d.cpi;

h.bk = b.bk * scale;
h.le = b.le * scale;
h.tae = b.ta * scale;
h.sec = b.sec * scale;

h.d = h.tae - h.bk;
h.le_to_l = (f.l-f.as) / f.l;
h.a_to_l = f.as / f.l;
h.l = h.le / h.le_to_l;
h.a = h.l - h.le;
h.ln_to_l = f.ln / f.l;
h.ln = h.ln_to_l * h.l;
h.lp = h.l - h.ln;

h.tag = h.tae + h.a;
h.rwa_to_tag = fsi.FS_ODX_ARW_EUR / fsi.FS_ODX_AFLG_EUR;
h.rwa = h.rwa_to_tag * h.tag;
h.riskw = h.rwa / h.tae;
h.car = fsi.FSKRC_PT / 100;
h.reg = h.car * h.rwa;
h.reg_to_bk = h.reg / h.bk;

h.l_to_4ny = h.l / (4 * h.ny);
h.le_to_4ny = h.le / (4 * h.ny);
h.l_to_4ny_1 = h.l_to_4ny;
h.le_to_4ny_1 = h.le_to_4ny;

h.sec_to_4ny = h.sec / (4 * h.ny);
h.book_sec = h.sec;

h.oae = h.tae - h.le - h.sec;
h.oae_to_4ny = h.oae / (4*h.ny);

h.rl = b.rl / 400;
h.rd = b.rd / 400;
h.new_rl = b.new_rl / 400;
h.new_rd = b.new_rd / 400;

h.rbk = clip(fsi.FSERE_PT, qq(2015,1), Inf) / 400;

h.car_ccy = Series(startHist:endHist, 0);
h.car_cons = Series(startHist:endHist, 0);
h.car_min = Series(startHist:endHist, 20/100);

h.rl_1 = h.rl;
h.new_rl_1 = h.new_rl;
h.a_1 = h.a;
h.lp_1 = h.lp;
h.ln_1 = h.ln;

filterRange = [-Inf, qq(2022,4)];

[h.y_tnd, h.y_gap] = hpf(h.y, filterRange, log=true, lambda=500);
h.cpi_tnd = hpf(h.cpi, filterRange, log=true, lambda=500);
h.ea_cpi_tnd = hpf(h.ea_cpi, filterRange, log=true, lambda=500);
h.py_tnd = hpf(h.py, filterRange, log=true, lambda=500);
[h.re_tnd, h.re_gap] = hpf(h.re, filterRange, log=true, lambda=500);
[h.rrp_tnd, h.rrp_gap] = hpf(h.rrp, filterRange, lambda=500);

[h.l_to_4ny_tnd, h.l_to_4ny_gap] = hpf(h.l_to_4ny, filterRange, lambda=500, level=Series(endHist,100/100), change=Series(endHist,0));
h.l_to_4ny_tnd_1 = h.l_to_4ny_tnd;

h = databank.apply( ...
    h, @roc ...
    , sourceNames=["y", "y_tnd", "py", "py_tnd", "cpi", "cpi_tnd", "re", "re_tnd", "rrp"] ...
    , targetNames=@(n) "roc_"+n ...
);

h.rsec = h.rp + ss.ss_rsec_apm;
h.roae = h.rp + ss.ss_roae_apm;
h.ivy_1 = Series(startHist:endHist, ss.ivy_1);
h.lnc_1 = (ss.lnc_1/ss.ln_1) * h.ln_1;
h.lnw_1 = (ss.lnw_1/ss.ln_1) * h.ln_1;


databank.toSheet(h, "input-data/model-data.csv");


ss = databank.forModel(m, qq(2010,1):qq(2022,4));
buildReport("reports/data-report", h, ss, qq(2010,1):qq(2022,4), {});

