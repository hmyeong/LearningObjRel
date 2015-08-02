function [normSecondOrderObjRel, maxVal, minVal] = LogNormObjRel(secondOrderObjRel,numLabels)

maxVal = 0;
minVal = 1000000;
Z = 0;

for i = 1:numLabels
    for j = 1:numLabels
        if ~isempty(secondOrderObjRel{i,j})
            Z = Z + sum(secondOrderObjRel{i,j}(:));
        end;
    end;
end;

normSecondOrderObjRel = cell(size(secondOrderObjRel));
for i = 1:numLabels
    for j = 1:numLabels
        if ~isempty(secondOrderObjRel{i,j})
            normSecondOrderObjRel{i,j} = secondOrderObjRel{i,j} ./ Z; % normalize
            %             normContext{i,j} = context{i,j}; % not normalize
            normSecondOrderObjRel{i,j} = -log(normSecondOrderObjRel{i,j});
            normSecondOrderObjRel{i,j}(isinf(normSecondOrderObjRel{i,j})) = NaN; % temporarily make it max
            
            if maxVal < max(normSecondOrderObjRel{i,j}(:))
                maxVal = max(normSecondOrderObjRel{i,j}(:));
            end
            
            if minVal > min(normSecondOrderObjRel{i,j}(:))
                minVal = min(normSecondOrderObjRel{i,j}(:));
            end;
        else
            normSecondOrderObjRel{i,j} = [];
        end;
    end;
end;

% NaN handling
for i = 1:numLabels
    for j = 1:numLabels
        if ~isempty(normSecondOrderObjRel{i,j})
            normSecondOrderObjRel{i,j}(isnan(normSecondOrderObjRel{i,j})) = maxVal;
        end;
    end;
end;

return;