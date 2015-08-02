function [weights] = MakeDescWeight(sourceImSPDesc,targetSPDesc,sourceSize,targetSize,segmentDescriptors)

weights = ones(sourceSize,targetSize);

for j = 1:length(segmentDescriptors)
    temp = slmetric_pw(double(sourceImSPDesc.(segmentDescriptors{j})'),double(targetSPDesc.(segmentDescriptors{j})'),'eucdist');
    weights = weights .* exp(-temp./std(temp(:)));
end;

return;