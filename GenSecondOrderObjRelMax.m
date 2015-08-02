function [secondOrderObjRel] = GenSecondOrderObjRelMax(propagatedLabel,reducedLabels,Labels,retSetSize,testSize)

unfoldedReducedPropagatedLabel = cell(size(propagatedLabel));

% unfold reducedLabels
for i = 1:retSetSize
    unfoldedReducedPropagatedLabel{i} = zeros(testSize,length(Labels));
    if ~isempty(reducedLabels{i})
        unfoldedReducedPropagatedLabel{i}(:,reducedLabels{i}) = propagatedLabel{i}(end-testSize+1:end,:);
    end;
end;

secondOrderObjRel = cell(length(Labels));

for i = 1:length(Labels)
    for j = 1:length(Labels)
        stackPairwiseRankOneObjRel = ...
            reshape(unfoldedReducedPropagatedLabel{1}(:,i) * unfoldedReducedPropagatedLabel{1}(:,j)',[testSize*testSize 1]);
        for k = 2:retSetSize
            if ~isempty(reducedLabels{k})
                stackPairwiseRankOneObjRel = [stackPairwiseRankOneObjRel ...
                    reshape(unfoldedReducedPropagatedLabel{k}(:,i) * unfoldedReducedPropagatedLabel{k}(:,j)',[testSize*testSize 1])];
            end;
        end;
        secondOrderObjRel{i,j} = max(stackPairwiseRankOneObjRel,[],2);
        secondOrderObjRel{i,j} = reshape(secondOrderObjRel{i,j},[testSize testSize]);
    end;
end;

return;