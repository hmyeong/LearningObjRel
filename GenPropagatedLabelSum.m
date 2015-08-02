function [propagatedLabelSum] = GenPropagatedLabelSum(unfoldedReducedPropagatedLabel,Labels,testSize)

propagatedLabelSum = zeros(testSize,length(Labels));

for i = 1:length(testSize)
    propagatedLabelSum = propagatedLabelSum + unfoldedReducedPropagatedLabel{i};
end;

return;