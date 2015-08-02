function [unfoldedReducedPropagatedLabel] = UnfoldReducedPropagatedLabel(propagatedLabel,reducedLabels,Labels,retSetSize,testSize)

unfoldedReducedPropagatedLabel = cell(size(propagatedLabel));

% unfold reducedLabels
for i = 1:retSetSize
    unfoldedReducedPropagatedLabel{i} = zeros(testSize,length(Labels));
    if ~isempty(reducedLabels{i})
        unfoldedReducedPropagatedLabel{i}(:,reducedLabels{i}) = propagatedLabel{i}(end-testSize+1:end,:);
    end;
end;

return;