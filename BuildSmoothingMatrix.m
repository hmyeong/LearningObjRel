%
% refactored from the SuperParsing code
% im_parser/ImageParser/BuildSmoothingMatrix.m
% http://www.cs.unc.edu/~jtighe/Papers/ECCV10/index.html
%
function [smoothingMatrix] = BuildSmoothingMatrix(labelPenality,labelSmoothing,interLabelSmoothing,labelPenalityFun,interLabelPenalityFun)
for i = 1:size(labelPenality,1)
    for j = 1:size(labelPenality,2)
        if(i==j)
            smoothing = labelSmoothing;
            penalityFun = labelPenalityFun;
        else
            smoothing = interLabelSmoothing;
            penalityFun = interLabelPenalityFun;
        end
        if(strcmp(penalityFun,'pots'))
            labelPenality{i,j} = labelPenality{i,j}>.05;
        elseif(strcmp(penalityFun,'metric'))
            mask = labelPenality{i,j}>0;
            labelPenality{i,j}(mask) = labelPenality{i,j}(mask)-min(labelPenality{i,j}(mask));
            labelPenality{i,j}(mask) = .5*labelPenality{i,j}(mask)/max(labelPenality{i,j}(mask));
            labelPenality{i,j}(mask) = .5+labelPenality{i,j}(mask);
        end
        labelPenality{i,j} = labelPenality{i,j}*smoothing;
    end
end
smoothingMatrix = cell2mat(labelPenality);
return