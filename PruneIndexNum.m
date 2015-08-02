%
% refactored from the SuperParsing code
% im_parser/Utilities/PruneIndex.m
% http://www.cs.unc.edu/~jtighe/Papers/ECCV10/index.html
%
function [index,mask] = PruneIndexNum(index,imageNNs,idxNum)

mask = zeros(size(index.image))==1;
mask(index.image==imageNNs(idxNum)) = 1;

names = fieldnames(index);
for i = 1:length(names)
    index.(names{i}) = index.(names{i})(mask);
end;

return;