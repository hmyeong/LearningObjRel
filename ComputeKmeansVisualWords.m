%
% refactored from the SuperParsing code
% im_parser/ComputeSegmentDescriptors.m
% http://www.cs.unc.edu/~jtighe/Papers/ECCV10/index.html
%
function [] = ComputeKmeansVisualWords(imgFileList, HOMEIMAGES, HOMEDATA, centerFunsList)

HOMEVW = fullfile(HOMEDATA,'Descriptors','VWDictionaries');

visualWordsDics = [];
for k = 1:length(centerFunsList)
    outVWDicFileName = fullfile(HOMEVW,sprintf('%s.mat',centerFunsList{k}));
    if exist(outVWDicFileName,'file')
        load(outVWDicFileName);
    else
        dic = feval(centerFunsList{k}, imgFileList, HOMEIMAGES, 100);
        make_dir(outVWDicFileName); save(outVWDicFileName,'dic');
    end;
    
    visualWordsDics.(centerFunsList{k}) = dic;
end;

return;