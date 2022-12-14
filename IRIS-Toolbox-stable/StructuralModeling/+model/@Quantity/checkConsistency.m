% checkConsistency  Check consistency of model.Equation properties
%
% -[IrisToolbox] for Macroeconomic Modeling
% -Copyright (c) 2007-2022 [IrisToolbox] Solutions Team

function flag = checkConsistency(this)

    numQuantities = numel(this.Name);

    flag = numel(this.Type)==numQuantities ...
        && isnumeric(this.Type) ...
        && numel(this.Label)==numQuantities ...
        && iscellstr(this.Label) ...
        && numel(this.Alias)==numQuantities ...
        && iscellstr(this.Alias) ...
        && numel(this.IxLog)==numQuantities ...
        && islogical(this.IxLog) ...
        && numel(this.IxLagrange)==numQuantities ...
        && islogical(this.IxLagrange) ...    
        && numel(this.IxObserved)==numQuantities ...
        && islogical(this.IxObserved) ...
        && size(this.Bounds,1)==4 ...
        && size(this.Bounds,2)==numQuantities ...
        && isnumeric(this.Bounds);

    if ~flag
        return
    end

    flag = numel(this.Name)==numel(unique(this.Name)) ...
        && ~any(startsWith(this.Name, "std_")) ...
        && ~any(startsWith(this.Name, "corr_"));

end%
