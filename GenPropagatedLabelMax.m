function [propagatedLabelSum] = GenPropagatedLabelMax(unfoldedReducedPropagatedLabel,retSetSize,Labels,testSize)

stackedPropagatedLabelSum = zeros(testSize*length(Labels),retSetSize);

for i = 1:retSetSize
    stackedPropagatedLabelSum(:,i) = reshape(unfoldedReducedPropagatedLabel{i},[testSize*length(Labels) 1]);
end;

propagatedLabelSum = max(stackedPropagatedLabelSum,[],2);
propagatedLabelSum = reshape(propagatedLabelSum,testSize,length(Labels));

return;