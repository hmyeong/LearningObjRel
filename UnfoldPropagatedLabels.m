function [unfoldedPropagatedLabels] = UnfoldPropagatedLabels(propagatedLabels,reducedLabels,Labels,retSetSize,testSize)

unfoldedPropagatedLabels = cell(size(propagatedLabels));

% unfold reducedLabels
for i = 1:retSetSize
    unfoldedPropagatedLabels{i} = zeros(testSize,length(Labels));
    if ~isempty(reducedLabels{i})
        unfoldedPropagatedLabels{i}(:,reducedLabels{i}) = propagatedLabels{i}(end-testSize+1:end,:);
    end;
end;

return;