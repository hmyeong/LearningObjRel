function [objRelPlusSmoothness] = AddSmoothnessToObjRel(objRel,adjPairs,numLabels,numSites,alpha,beta,maxObjRel)

objRelPlusSmoothness = objRel;

adjMatrix = sparse(adjPairs(:,1),adjPairs(:,2),maxObjRel,numSites,numSites);

for i = 1:numLabels
    for j = 1:numLabels
        if ~isempty(objRelPlusSmoothness{i,j})
            if i ~= j
                objRelPlusSmoothness{i,j} = objRelPlusSmoothness{i,j} + beta/alpha * adjMatrix;
            end;
        end;
    end;
end;

return;