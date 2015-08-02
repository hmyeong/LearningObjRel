function [L] = MaxDataCost(dataCost)

[~, L] = max(dataCost,[],2);

return;