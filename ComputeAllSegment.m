%
% refactored from the SuperParsing code
% im_parser/ComputeSegmentDescriptors.m
% http://www.cs.unc.edu/~jtighe/Papers/ECCV10/index.html
%
function [] = ComputeAllSegment(imgFileList, HOMEIMAGES, HOMEDATA, K)

HOMESEGDESCDATA = fullfile(HOMEDATA,'Descriptors',sprintf('FH_segDesc_K%d',K));

pfig = ProgressBar('Pre-computing All Segment');
range = 1:length(imgFileList);

for i = range
    if isempty(imgFileList{i})
        continue;
    end;
    
    [folder,onlyName] = fileparts(imgFileList{i});
    baseFileName = fullfile(folder,onlyName);
    
    adjFileName = fullfile(HOMESEGDESCDATA,'sp_adjacency',sprintf('%s.mat',baseFileName));
    
    if ~exist(adjFileName,'file')
        filename = fullfile(HOMEIMAGES,imgFileList{i});
        im = imread(filename);
        [~, ~, ch] = size(im);
        
        %force it to have 3 channels
        if ch == 1
            im = repmat(im,[1 1 3]);
        end;
        
        % Get super-pixels for image
        outSPFileName = fullfile(HOMESEGDESCDATA,'super_pixels',sprintf('%s.mat',baseFileName));
        if exist(outSPFileName,'file')
            load(outSPFileName);
        else
            superPixels = GenerateSuperPixels(im,K);
            make_dir(outSPFileName); save(outSPFileName,'superPixels');
        end;
        
        % Find the adjacency graph between superpixels
        if ~exist(adjFileName,'file')
            adjPairs = FindSPAdjacnecy(superPixels);
            make_dir(adjFileName);save(adjFileName,'adjPairs');
        end;
        
        ProgressBar(pfig,find(i==range),length(range));
    end;
    
    if mod(i,100) == 0
        ProgressBar(pfig,find(i==range),length(range));
    end;
end;

close(pfig);

return;