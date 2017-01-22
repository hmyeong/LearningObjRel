%
% refactored from the SuperParsing code
% im_parser/ComputeSegmentDescriptors.m
% http://www.cs.unc.edu/~jtighe/Papers/ECCV10/index.html
%
function [descFunsList] = ComputeAllSegmentDescriptors(imgFileList, HOMEIMAGES, HOMEDATA, K, recomputeSegDesc, descFunsList, centerFunsList, filterFunsList)

HOMEVWDIC = fullfile(HOMEDATA,'Descriptors','VWDictionaries');
HOMEVW = fullfile(HOMEDATA,'Descriptors','VisualWords');

% Load the visual words dictionaries
visualWordsDics = [];
for k = 1:length(centerFunsList)
    outVWDicFileName = fullfile(HOMEVWDIC,sprintf('%s.mat',centerFunsList{k}));
    if exist(outVWDicFileName,'file')
        load(outVWDicFileName);
    else
        fprintf(outVWDicFileName,' does not exist.. exiting\n');
        error('Error in ComputeAllSegmentDescriptors.m');
    end;
    visualWordsDics.(centerFunsList{k}) = dic;
end;

HOMESEGDESCDATA = fullfile(HOMEDATA,'Descriptors',sprintf('FH_segDesc_K%d',K));

poolstarted = 0;

pfig = ProgressBar('Pre-computing All Segment Descriptors');
range = 1:length(imgFileList);

for i = range
    if isempty(imgFileList{i})
        continue;
    end;
    
    [folder,onlyName] = fileparts(imgFileList{i});
    baseFileName = fullfile(folder,onlyName);
    
    descMask = zeros(size(descFunsList))==1;
    descInds = 1:length(descFunsList);
    for k = descInds
        descFun = descFunsList{k};
        outDescFileName = fullfile(HOMESEGDESCDATA,descFun,sprintf('%s.mat',baseFileName));
        if exist(outDescFileName,'file') && ~recomputeSegDesc
            continue;
        end;
        descMask(k) = 1;
    end;
    
    descInds = descInds(descMask);
    needTextons = false;
    for filtCount = 1:length(filterFunsList)
        outVWFileName = fullfile(HOMEVW,filterFunsList{filtCount},sprintf('%s.mat',baseFileName));
        if ~exist(outVWFileName,'file')
            needTextons = true;
            break;
        end;
    end;
    
    textons = [];
    
    % for each superpixel compute descriptor
    if ~isempty(descInds) || needTextons
        filename = fullfile(HOMEIMAGES,imgFileList{i});
        im = imread(filename);
        [~, ~, ch] = size(im);
        
        %force it to have 3 channels
        if ch == 1
            im = repmat(im,[1 1 3]);
        end;
        
        % Load super-pixels for image
        outSPFileName = fullfile(HOMESEGDESCDATA,'super_pixels',sprintf('%s.mat',baseFileName));
        if(exist(outSPFileName,'file'))
            SPstruct = load(outSPFileName,'superPixels');
            superPixels = SPstruct.superPixels;
            clear SPstruct;     % temporary structure for parfor
        else
            fprintf(outSPFileName,' does not exist.. exiting\n');
            error('Error in ComputeAllSegmentDescriptors');
        end;
        
        superPixInd = unique(superPixels);
        
        % Get visual words for each image
        if isempty(textons)
            for filtCount = 1:length(filterFunsList)
                outVWFileName = fullfile(HOMEVW,filterFunsList{filtCount},sprintf('%s.mat',baseFileName));
                if exist(outVWFileName,'file')
                    load(outVWFileName); textons.(filterFunsList{filtCount}) = texton;
                else
                    texton = feval(filterFunsList{filtCount},im,visualWordsDics); textons.(filterFunsList{filtCount}) = texton;
                    make_dir(outVWFileName); save(outVWFileName,'texton');
                end;
            end;
        end;
        
        if ~isempty(descInds)
            descs = cell(length(superPixInd),1);
            if exist('parpool','file')
                if isempty(gcp('nocreate'))
                    parpool;
                end;
            end;
            
            parfor j = 1:length(superPixInd)
                mask = superPixels==superPixInd(j);
                [~, borders, bb] = get_int_and_borders(mask);
                borders = borders(bb(1):bb(2),bb(3):bb(4),:);
                
                maskCrop = mask(bb(1):bb(2),bb(3):bb(4));
                imCrop = im(bb(1):bb(2),bb(3):bb(4),:);
                textonsCrop = textons;
                for filtCount = 1:length(filterFunsList)
                    textonsCrop.(filterFunsList{filtCount}) = textons.(filterFunsList{filtCount})(bb(1):bb(2),bb(3):bb(4));
                end;
                
                for k = descInds
                    descFun = descFunsList{k};
                    % Compute descriptor
                    spDesc = feval(descFun,imCrop,mask,maskCrop,bb,visualWordsDics,textonsCrop,borders,im);
                    descs{j}{k} = spDesc(:);
                end;
            end;
            
            descsD = [];
            for j = 1:length(superPixInd)
                for k = descInds;
                    desc = descs{j}{k};
                    if isfield(descsD,'descFuns{k}')
                        descsD.(descFunsList{k}) = zeros(numel(desc),length(superPixInd));
                    end;
                    descsD.(descFunsList{k})(:,j) = desc(:);
                end;
            end;
            
            for k = descInds
                descFun = descFunsList{k};
                outFileName = fullfile(HOMESEGDESCDATA,descFun,sprintf('%s.mat',baseFileName));
                desc = descsD.(descFunsList{k});
                make_dir(outFileName); save(outFileName,'desc');
            end;
        end;
        
        ProgressBar(pfig,find(i==range),length(range));
    end;
    
    if mod(i,100) == 0
        ProgressBar(pfig,find(i==range),length(range));
    end;
end;

close(pfig);

if exist('parpool','file')
    if ~isempty(gcp('nocreate')), delete(gcp('nocreate')); end;
end;

return;