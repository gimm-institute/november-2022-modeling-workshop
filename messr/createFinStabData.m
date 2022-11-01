
close all
clear


if false
    d = databank.fromIMF.data("FSI", Frequency.QUARTERLY, "IE", "", includeArea=false);
    [summary, dims] = databank.fromIMF.dimensions("FSI");

    descript = dims{4};

    inx = ...
        ismember(descript.Code, textual.fields(d)) ...
        & contains(string(descript.Indicator), "deposit taker", ignoreCase=true) ...
    ;
    descript = descript(inx, :);

    numRows = height(descript);
    extract = repmat("", numRows, 1);
    for r = 1 : numRows
        temp = split(descript{r, 2}, ",");
        extract(r) = regexprep(descript{r, 2}, ".*?deposit takers\s*,\s*", "", "ignoreCase");
    end
    descript.Extract = extract;

    dd = databank.copy(d, sourceNames=descript.Code, targetDb=struct());

    writetable(descript, "input-data/fsi-descript.csv");
    databank.toSheet(dd, "input-data/fsi.csv");
end


dd = databank.fromSheet("input-data/fsi.csv");
f = struct();

scale = 1e-6;

f.ta = dd.FS_ODX_A_EUR * scale;
f.as = dd.FS_ODX_AFLS_EUR * scale;
% f.as_ln = dd.FS_ODX_AFLS_FSPN_EUR * scale;
f.ag = dd.FS_ODX_OGP_EUR * scale;
f.l = dd.FS_ODX_AFLG_EUR * scale;
f.ln = dd.FS_ODX_AFLNP_EUR * scale;
f.ct1 = dd.FS_ODX_CT1_EUR * scale;
f.ct2 = dd.FS_ODX_CT2_EUR * scale;
f.rwa = dd.FS_ODX_ARW_EUR * scale;

databank.toSheet(f, "input-data/stab.csv");

