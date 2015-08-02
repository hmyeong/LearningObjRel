function [L] = MinDataCost(dataCost)

[~, L] = min(dataCost,[],2);

return;