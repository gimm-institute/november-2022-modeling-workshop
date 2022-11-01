function db = getInitcondFromData(m, n, simRange, macroFileName, CreditToGdpRatio)
  % getInitcondFromData: Prepares initial condition based on the data
  % 
  %   This function is intended to be used in all data-based simulation
  %   files to ensure consistency and correctness of the data inputs. 
  %   Using one function only also makes it easy to change data inputs
  %   across all simulation files.
  %
  %   Note that this file needs to evolve with the model. Model changes
  %   might require changes to this file.
  %
  %   This file also loads the macro assumptions from the specified file
  %   To update the data needed to run the simulation, the following files
  %   should be updated in folder "":
  %   1) DataPublic.xlsx
  %   2) DataStatistcsDepartment.xlsx
  %  
  %
  %   Inputs:
  %   m .................. model object
  %   simRange ........... simulation range
  %   macroFileName ...... name of XLSX with macro forecast
  %
  %
  % NOTE: At the moment, there is only one loan segment in the model, and all 
  % variables in this segment are denoted "_1", e.g. "l_1". We also have 
  % aggregate variables denoted e.g. "l", but at the moment "l = l_1"
  % because there is only one segment. If we create multiple segments in
  % future, the code below needs to be adjusted to load all necessary 
  % variables for each loan segment, as well as the aggregate values.
  
%   db = struct();
  db = emptydb(m);
%   db = steadydb(m,simRange);
    
  WorkingDir = '..';

  %% Scaling parameter
  % Apply scaling parameter to all data so that it is lower in absolute
  % value, to help numerical calculations
  
  rescale = 1;
  
  %% Macro data  
  
  x = ExcelSheet(['../data-v1/' macroFileName]);
  x.Orientation = 'Column';
  x.DataStart   = 2;
  x.Dates       = qq(2007, 1);

  db.cpi        = retrieveSeries(x, "B"); % log or nonlog?
  db.ip         = retrieveSeries(x, "C");
  db.rp         = db.ip / 400;
  db.y_su       = retrieveSeries(x, "E") / rescale;
  db.y_gap      = exp(retrieveSeries(x, "D")/100);
  db.d4y        = retrieveSeries(x, "F");
  
  db.y          = x13.season(db.y_su);

  % prolong GDP using YoY growth rates
  rng = getRange(db.d4y);
  for iPer = rng
    db.y(iPer) = db.y(iPer-4)*(1+db.d4y/100);
  end
  
  % calculate implied y_tnd
  db.y_tnd = db.y / db.y_gap;

  % calculate other necessary variables
  db.roc_y_tnd = roc(db.y_tnd);
  db.roc_cpi   = roc(db.cpi);
  db.l_cpi     = 100*log(db.cpi);
  db.dl_cpi    = 4*diff(db.l_cpi);
  db.fws_y     = db.y;
  db.l_y       = 100*log(db.y);
  db.l_y_gap   = 100*log(db.y_gap);
  db.l_y_tnd   = 100*log(db.y_tnd);
  db.dl_y_tnd  = 4*diff(db.l_y_tnd);
    
  
  % nominal GDP
  x = ExcelSheet([WorkingDir '/data-v1/DataPublic.xlsx'], 'Sheet=', 'GdpData');
  x.Orientation = 'Column';
  x.DataStart   = 8;
  x.Dates       = qq(2007, 1);

  db.ny_su    = retrieveSeries(x, "B", 'Comment=', 'Nominal GDP (mil MAD)') / rescale; 
  db.ny       = x13.season(db.ny_su);

  % GDP deflator
  db.py      = db.ny / db.y;
  db.roc_py  = roc(db.py);

  %% Run Kalman filter on the macro block only to get proper initial conditions
  dbin  = struct();
  dbin.obs_l_y_gap = db.l_y_gap;
  dbin.obs_l_y_tnd = db.l_y_tnd;
  dbin.obs_l_cpi   = db.l_cpi;
  dbin.obs_ip      = db.rp*400;

  [~, out] = filter(n, dbin, (simRange(1) - 20) : (simRange(1) - 1));
  
  db = dboverlay(out.mean, db);

  %% Load the data
  tic
  disp('Loading data from databases')
  

  % Assumptions/findings to be verified:
  %
  % * Total assets, bank credit reported in *gross* values (usually total assets are reported as net assets)
  % * Provisions reported as liabilities (usually: provisions are reported as contra-assets)
  % * Discrepancty between XLS and Supervision PDF in provisions (22,000 vs 55,000 in 2020) 
  % * Risk weighted assets are calculated based on net asset values (provisions fully subtracted)


  

  % Model notation
  %
  % * l is gross loans
  % * a is allowances (stock of provisions)
  % * lp is performing loans
  % * ln is nonperforming loans

  % loan performance module
  
  x = ExcelSheet([WorkingDir '/data-v1/DataPublic.xlsx'], 'Sheet=', 'CreditBancaire');
  x.Orientation = 'Row';
  x.DataStart   = 2;
  x.Dates       = mm(2001, 12);
  
  db.l_1          = convert(retrieveSeries(x, 4)/rescale,'q');
  db.ln_1         = convert(retrieveSeries(x, 15)/rescale,'q');
  db.lp_1         = db.l_1 - db.ln_1;   
  
  x = ExcelSheet([WorkingDir '/data-v1/DataStatistcsDepartment.xlsx'], 'Sheet=', 'Activite');
  x.Orientation = 'Row';
  x.DataStart   = 2;
  x.Dates       = qq(2006, 4);
  
  db.a_1          = retrieveSeries(x,13)/rescale;
  % if allowances are lagging, prolong by the same share on NPLs = keep
  % coverage ratio
  lst = get(db.a_1,'last');
  if lst < simRange(1)-1
    db.a_1(lst+1:simRange(1)) = db.ln_1 * db.a_1(lst) / db.ln_1(lst);
  end
  db.a9_1         = db.a_1;

  
  % aggregate variables - should be equal to sum of all segments
  db.l          = db.l_1;
  db.ln         = db.ln_1;
  db.lp         = db.l - db.ln;   
  db.a          = db.a_1;
  db.a9         = db.a;
  
  % other balance sheet items
  x = ExcelSheet([WorkingDir '/data-v1/DataPublic.xlsx'], 'Sheet=', 'PatrimoineDesbanques');
  x.Orientation = 'Row';
  x.DataStart   = 2;
  x.Dates       = mm(2001, 12);

  db.b          = convert(retrieveSeries(x, 13)/rescale,'q');
  db.oras       = convert(retrieveSeries(x, 18)/rescale,'q');
  
  db.tag        = convert(retrieveSeries(x, 4)/rescale,'q');
  db.tan        = db.tag - db.a;
  db.oas        = db.tag - db.l - db.b - db.oras;  
  
  % Bank capital module  
  x = ExcelSheet([WorkingDir '/data-v1/DataStatistcsDepartment.xlsx'], 'Sheet=', 'Solva');
  x.Orientation = 'Column';
  x.DataStart   = 2;
  x.Dates       = hh(2006, 2);
  
  dh.bk           = retrieveSeries(x,"B")/rescale;
  dh.rwa          = retrieveSeries(x,"E")/rescale; % risk-weighted assets

  db.bk           = convert(dh.bk, Frequency.QUARTERLY);
  db.rwa          = convert(dh.rwa, Frequency.QUARTERLY);
  % extend bank capital and risk weights if needed
  lst = get(db.bk,'last');
  if lst < (simRange(1)-1)
    warning('Extending bk and rwa by their last available value (%s).', dat2char(lst))
    db.bk(lst+1:simRange(1)-1)  = db.bk(lst);
    db.rwa(lst+1:simRange(1)-1) = db.rwa(lst);
  end

  % this is based on data that is income, not profits:
%   x = ExcelSheet('../data-v1/DSGD- Données requête mission BCC.xlsx', 'Sheet=', 'Renta');
%   x.Orientation = 'Row';
%   x.DataStart   = 2;
%   x.Dates       = yy(2010);
% 
%   dy.INC_TR     = retrieveSeries(x,3, 'Comment=', 'Income From Bond Trading (mil MAD)')/1e3;
%   dy.INC_PL     = retrieveSeries(x,4, 'Comment=', 'Income From Bonds Held to Maturity (mil MAD)')/1e3;
%   dy.INC_MA     = retrieveSeries(x,5, 'Comment=', 'Income From Market Operations (mil MAD)')/1e3;
%   dy.INC_II     = retrieveSeries(x,6, 'Comment=', 'Income From Interest (mil MAD)')/1e3;
%   dy.INC_LE     = retrieveSeries(x,7, 'Comment=', 'Income From Rent and Lease (mil MAD)')/1e3;
% 
%   db.prof = convert(dy.INC_TR+dy.INC_PL+dy.INC_MA+dy.INC_II+dy.INC_LE,'q')/4;
%   db.nim  = convert(dy.INC_MA,'q')/4;

  % this is based on actual profits
  x = ExcelSheet([WorkingDir '/data-v1/DataStatistcsDepartment.xlsx'], 'Sheet=', 'Rentabilite');
  x.Orientation = 'Row';
  x.DataStart   = 3;
  x.Dates       = hh(2006, 2); % hh = half-year
  
  dh.nim        = retrieveSeries(x,2)/rescale;  % net interest margin
  dh.prof       = retrieveSeries(x,11)/rescale; % net profit

  % diff(x, "tty") calculates differences throughout the year, keeping the
  % first period of the year (first quarter, first half-year, etc.)
  % unchanged

  dh.nim = diff(dh.nim, "tty");
  dh.prof = diff(dh.prof, "tty");
  
  % Interpolate from half-yearly to quarterly
  % Preserves sum of quarters==half-year
  db.prof = convert(dh.prof, Frequency.QUARTERLY, "method", "quadsum"); % interpolate
  db.nim = convert(dh.nim, Frequency.QUARTERLY, "method", "quadsum"); % interpolate

  % interest rate module
  x = ExcelSheet([WorkingDir '/data-v1/DataStatistcsDepartment.xlsx'], 'Sheet=', 'Taux debiteurs');
  x.Orientation = 'Row';
  x.DataStart   = 2;
  x.Dates       = qq(2010, 1);
  db.new_rl_1   = retrieveSeries(x,2)/400; % /400 to get non-annualized fraction


  x = ExcelSheet([WorkingDir '/data-v1/DataStatistcsDepartment.xlsx'], 'Sheet=', 'Autre');
  x.Orientation = 'Column';
  x.DataStart   = 74;
  x.Dates       = qq(2014, 1);
  db.tmp1       = retrieveSeries(x,2)/400; % /400 to get non-annualized fraction
  db.tmp2       = retrieveSeries(x,3)/400; % /400 to get non-annualized fraction
  db.rl_1       = [db.tmp2; db.tmp1];
  lst           = get(db.rl_1,'last');
  if lst < simRange(1)-1
    db.rl_1(lst:simRange(1)-1) = db.rl_1(lst);
  end

  x = ExcelSheet([WorkingDir '/data-v1/DataStatistcsDepartment.xlsx'], 'Sheet=', 'TRM BQ');
  x.Orientation = 'Row';
  x.DataStart   = 2;
  x.Dates       = yy(2010);

  dy.rd         = retrieveSeries(x,7)*100/400;
  db.rd         = convert(dy.rd,'q');
  lst           = get(db.rd,'last');
  if lst < simRange(1)-1
    db.rd(lst:simRange(1)-1) = db.rd(lst);
  end

  % credit creation module
  x = ExcelSheet([WorkingDir '/data-v1/DataStatistcsDepartment.xlsx'], 'Sheet=', 'Activite');
  x.Orientation = 'Row';
  x.DataStart   = 2;
  x.Dates       = qq(2006, 4);
  db.new_l_1    = retrieveSeries(x,28)/rescale;
  lst           = get(db.new_l_1,'last');
  if lst < simRange(1)-1
    db.new_l_1(lst:simRange(1)-1) = db.ny * db.new_l_1(lst) / db.ny(lst);
  end
  db.new_l      = db.new_l_1;
  
  % Real estate price index
  x = ExcelSheet([WorkingDir '/data-v1/DataPublic.xlsx'], 'Sheet=', 'REPI');
  x.Orientation = 'Column';
  x.DataStart   = 8;
  x.Dates       = qq(2003, 1);
  db.repi       = retrieveSeries(x,"B");
  db.roc_repi   = db.repi / db.repi{-1};
  db.repi_to_py = db.repi / db.py ;
  db.repi_gap   = (db.repi_to_py - db.repi_to_py{-8})/(db.repi_to_py{-8});

  % LCR
  x = ExcelSheet([WorkingDir '/data-v1/DataStatistcsDepartment.xlsx'], 'Sheet=', 'LCR');
  x.Orientation = 'Row';
  
  x.DataRange   = 3:7;
  x.Dates       = hh(2016, 2);
  dh.LCR        = retrieveSeries(x, 4);
  x.DataRange   = 8:11;
  x.Dates       = qq(2019, 1);
  dq.LCR        = retrieveSeries(x, 4);
  x.DataStart   = 12;
  x.DataRange   = [];
  x.Dates       = mm(2020, 1);
  dm.LCR        = retrieveSeries(x, 4);
  
  db.lcr        = [convert(dh.LCR,'q'); dq.LCR; convert(dm.LCR,'q')];
  
  % prolong LCR if needed
  lst = getEnd(db.lcr);
  if lst < simRange(1)-1
    db.lcr(lst+1: simRange(1)-1) = db.lcr(lst);
  end
  
  %% Filter unobservable variables - tune here is necessary                 

  % Loan to GDP ratio - filter separately for each loan segment
  db.l_to_4ny_1 = db.l_1 / (4*db.ny);

  [db.l_to_4ny_tnd_1, db.l_to_4ny_gap_1] = hpf( ...
      db.l_to_4ny_1, "level", CreditToGdpRatio ...
  );
  
  
  %% Variables with no counter-part in the database
  
  % split NPLs into the two buffers
  db.lnc_1 = db.ln_1 * real(m.lnc_1) / real(m.ln_1); % no data, we use model sstate share of NPLs
  db.lnw_1 = db.ln_1 * real(m.lnw_1) / real(m.ln_1); % no data, we use model sstate share of NPLs
  
  db.lnc   = db.lnc_1;
  db.lnw   = db.lnw_1;
  
  % Minimum CAR - use the sstate value
  db.car_bfr  = Series(simRange(1)-10:simRange(1), m.car_bfr);
  db.car_cons = Series(simRange(1)-10:simRange(1), m.car_cons);
  
  % risk weights - calculate from total assets and risk-weighted assets
  db.rw = db.rwa / db.tan;
  
  % Actual CAR - calculate from total assets, risk weights
  db.car = db.bk / (db.tan * db.rw);
  
  % Inverse leverage
  db.invlev = db.bk / db.tag;
  
  % Approximate calculation for roas
  db.roas = db.rp + m.ss_roas_apm;
  
  % Approximate calculation for roras
  db.roras = db.rp + m.ss_roras_apm;
  
  % App roximate calculation for roras
  db.rb = db.rp + m.ss_rb_apm;

  % Approximate calculation for ivy. Plug nominal GDP for the level of
  % transactions
  db.ivy_1 = db.new_l_1 / db.ny;

  % Remove high-frequency noise from ivy_1
  % Use x13 to extract the so-called trend-cycle component (removing
  % seasonals and irregulars)

%   db.ivy_1 = x13.season(db.ivy_1, "output", "tc");
  db.ivy_1 = hpf(db.ivy_1,get(db.ivy_1,'first'):simRange(1),'lambda',50);
  
  % idiosyncratic component of the real estate price index
  db.reid = Series(simRange(1)-1, real(m.reid));
%   db.reid = db.repi / db.py / db.y;
  
  
  %% Table with summary of initial conditions
  per = simRange(1)-1;

  desc       = {};
  dataValue  = [];
  modelValue = [];

  % loans to GDP + trend
  db.l_to_4ny = db.l_to_4ny_1;
  db.l_to_4ny_tnd = db.l_to_4ny_tnd_1;
  desc                     = [desc {'l_to_4ny', 'l_to_4ny_tnd'}];
  dataValue(end+1:end+2)   = [db.l_to_4ny(per) db.l_to_4ny_tnd(per)];
  modelValue(end+1:end+2)  = [real(m.l_to_4ny) real(m.l_to_4ny)];

  desc                     = [desc {'l_to_4ny_1', 'l_to_4ny_tnd_1'}];
  dataValue                = [dataValue ...
                              db.l_to_4ny_1(per) db.l_to_4ny_tnd_1(per)];
  modelValue               = [modelValue ...
                              real(m.l_to_4ny_1) real(m.l_to_4ny_tnd_1)];
                            
  % NPL shares
  db.ln_to_l_1 = db.ln_1 / db.l_1;
  db.ln_to_l   = db.ln   / db.l;
  desc                     = [desc {'ln_to_l', 'ln_to_l_1'}];
  dataValue(end+1:end+2)   = [db.ln_to_l(per) db.ln_to_l_1(per)];
  modelValue(end+1:end+2)  = [real(m.ln_to_l) real(m.ln_to_l_1)];
  
  % allowances to NPLs
  db.a_to_ln_1 = db.a_1 / db.ln_1;
  db.a_to_ln   = db.a   / db.ln;
  desc                     = [desc {'a_to_ln', 'a_to_ln_1'}];
  dataValue(end+1:end+2)   = [db.a_to_ln(per) db.a_to_ln(per)];
  modelValue(end+1:end+2)  = [real(m.a)/real(m.ln) real(m.a_1)/real(m.ln_1)];
  
  % new loans to total loans and to nominal GDP
  db.new_l_to_l_1 = db.new_l_1 / db.l_1;
  db.new_l_to_l   = db.new_l   / db.l;
  desc                     = [desc {'new_l_to_l', 'new_l_to_l_1'}];
  dataValue(end+1:end+2)   = [db.new_l_to_l(per) db.new_l_to_l_1(per)];
  modelValue(end+1:end+2)  = [real(m.new_l) / real(m.l) ...
                              real(m.new_l_1) / real(m.l_1)];
  db.new_l_to_4ny_1 = db.new_l_1 / (4*db.ny);
  db.new_l_to_4ny   = db.new_l   / (4*db.ny);
  desc                     = [desc {'new_l_to_4ny', 'new_to_4ny_1'}];
  dataValue(end+1:end+2)   = [db.new_l_to_4ny(per) db.new_l_to_4ny_1(per)];
  modelValue(end+1:end+2)  = [real(m.new_l_to_4ny) real(m.new_l_to_4ny_1)];
  
  % inverse loan velocity
  desc               = [desc {'ivy_1'}];
  dataValue(end+1)   = [db.ivy_1(per)];
  modelValue(end+1)  = [real(m.ivy_1)];
  
  % risk weights
  desc               = [desc {'rw'}];
  dataValue(end+1)   = [db.rw(per)];
  modelValue(end+1)  = [real(m.rw)];
  
  % CAR
  desc               = [desc {'car'}];
  dataValue(end+1)   = [db.car(per)];
  modelValue(end+1)  = [real(m.car)];
  
  % Inverse leverage
  desc               = [desc {'invlev'}];
  dataValue(end+1)   = [db.invlev(per)];
  modelValue(end+1)  = [real(m.invlev)];
  
  % bank capital to NGDP
  db.bk_to_4ny       = db.bk / (4*db.ny);
  desc               = [desc {'bk_to_4ny'}];
  dataValue(end+1)   = [db.bk_to_4ny(per)];
  modelValue(end+1)  = [real(m.bk) / (4*real(m.ny))];
  
  % bonds to NGDP
  db.b_to_4ny        = db.b / (4*db.ny);
  desc               = [desc {'b_to_4ny'}];
  dataValue(end+1)   = [db.b_to_4ny(per)];
  modelValue(end+1)  = [real(m.b) / (4*real(m.ny))];
  
  % risky assets to NGDP
  db.oras_to_4ny     = db.oras / (4*db.ny);
  desc               = [desc {'oras_to_4ny'}];
  dataValue(end+1)   = [db.oras_to_4ny(per)];
  modelValue(end+1)  = [real(m.oras) / (4*real(m.ny))];
  
  % other assets to NGDP
  db.oas_to_4ny      = db.oas / (4*db.ny);
  desc               = [desc {'oas_to_4ny'}];
  dataValue(end+1)   = [db.oas_to_4ny(per)];
  modelValue(end+1)  = [real(m.oas) / (4*real(m.ny))];
  
  % total assets to GDP
  db.tag_to_4ny      = db.tag  / (4*db.ny);
  desc               = [desc {'tag_to_4ny'}];
  dataValue(end+1)   = db.tag_to_4ny(per);
  modelValue(end+1)  = real(m.tag) / (4*real(m.ny));
                            
  % Interest rates - policy, lending stock, deposit stock, new lending
  desc                     = [desc {'rp','rl_1', 'new_rl_1','rd'}];
  dataValue(end+1:end+4)   = 400 * [db.rp(per) db.rl_1(per) db.new_rl_1(per) db.rd(per)];
  modelValue(end+1:end+4)  = 400 * real([m.rp m.rl_1 m.new_rl_1 m.rd]);
  
  % profit to GDP
  db.prof_to_4ny     = db.prof / (4*db.ny);
  desc               = [desc {'prof_to_4ny'}];
  dataValue(end+1)   = db.prof_to_4ny(per);
  modelValue(end+1)  = real(m.rbk)*real(m.bk) / (4*real(m.ny));
  
  % return on bank capital
  db.rbk             = db.prof / db.bk;
  desc               = [desc {'rbk'}];
  dataValue(end+1)   = 400*db.rbk(per);
  modelValue(end+1)  = 400*real(m.rbk);
  
  % Repi growth
  desc               = [desc {'roc_repi'}];
  dataValue(end+1)   = (db.roc_repi(per)-1)*100;
  modelValue(end+1)  = (real(m.roc_repi)-1)*100;
 

  t = table(desc', dataValue', modelValue', 'VariableNames',{'Desc','DataValue','SStateValue'});
  disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
  disp('The following table compares data (initial condition) and model steady-state:')
  disp(t);
  disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')


  %% check if the initial condition is complete
  [flag, listMissing] = checkInitials(m, db, simRange);
  toc
end

