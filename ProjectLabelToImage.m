function [Lim] = ProjectLabelToImage(imSP,Lsp)

Lim = zeros(size(imSP));
for i = 1:max(imSP(:))
    Lim(imSP == i) = Lsp(i);
end;

return;