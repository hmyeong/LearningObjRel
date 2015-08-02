function [weights] = MakeGeoWeight(sourceImSPDesc,targetSPDesc,sourceSize,targetSize,segmentDescriptors,wei)

weights = ones(sourceSize,targetSize);

for j = 1:(length(segmentDescriptors)/wei)
    temp = slmetric_pw(sourceImSPDesc',targetSPDesc','eucdist');
    weights = weights .* exp(-temp./std(temp(:)));
end;

return;