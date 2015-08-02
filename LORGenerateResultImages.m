function LORGenerateResultImages(SPdata,SPparam)

HOMEWEB = fullfile(SPparam.HOMETESTDATA,'Website');
if ~exist(HOMEWEB,'dir'), mkdir(HOMEWEB); end;

HOMESEMANTICLABEL = SPparam.HOMELABELSETS{1}; % HOMELABELSETS{1} = HOMELABELSETS{labelType}; only SemanticLabels
[~,semanticlabelsFolderName] = fileparts(HOMESEMANTICLABEL);

labelColors = GetColors(SPparam.HOMEDATA,SPparam.SPCODE,SPparam.HOMELABELSETS,SPdata.Labels(SPparam.UseLabelSet));
semanticLabelColor = labelColors{1}; % labelColors{1} = labelColors{labelType}; only SemanticLabels

foldList = dir(fullfile(SPparam.HOMETESTDATA,'LearningObjRel',semanticlabelsFolderName,'*'));
for i = length(foldList):-1:1
    if strcmp(foldList(i).name,'.') || strcmp(foldList(i).name,'..')
        foldList(i) = [];
    end;
end;
WebTestList = {foldList.name};

% some parameters
maxDim = 1000;
regenerateResultImages = false;

pfig = ProgressBar('Generating Result Images');
range = 1:length(SPdata.testFileList);
for i = range
    im = imread(fullfile(SPparam.HOMEIMAGES,SPdata.testFileList{i}));
    [folder,onlyName,~] = fileparts(SPdata.testFileList{i});
    
    % only SemanticLabels, no need to recompute setBase
    % [~,setBase] = fileparts(HOMELABEL);
    
    groundTruthFile = fullfile(HOMESEMANTICLABEL,folder,[onlyName '.mat']);
    if ~exist(groundTruthFile,'file'),
        groundTruth = [];
    else
        load(groundTruthFile); % S metaData names
        groundTruth = S;
    end;
    
    gtImOut = fullfile(HOMEWEB,'GroundTruth',semanticlabelsFolderName,folder,[onlyName '.png']);
    if ~exist(fileparts(gtImOut),'dir'), mkdir(fileparts(gtImOut)); end;
    
    if ~exist(gtImOut,'file') || regenerateResultImages
        STemp = S + 1;
        STemp(STemp < 1) = 1;
        [~] = DrawImLabels(im,STemp,[0 0 0; semanticLabelColor],{'unlabeled' names{:}},gtImOut,128,0,1,maxDim);
    end;
    
    gtImOutNoLegend = fullfile(HOMEWEB,'GroundTruth',semanticlabelsFolderName,folder,[onlyName 'NoLegend.png']);
    if ~exist(fileparts(gtImOutNoLegend),'dir'), mkdir(fileparts(gtImOutNoLegend)); end;
    
    if ~exist(gtImOutNoLegend,'file') || regenerateResultImages
        STemp = S + 1;
        STemp(STemp < 1) = 1;
        [~] = DrawImLabels(im,STemp,[0 0 0; semanticLabelColor],{'unlabeled' names{:}},gtImOutNoLegend,0,0,1,maxDim);
    end;
    
    for j = 1:length(WebTestList)
        resultFile = fullfile(SPparam.HOMETESTDATA,'LearningObjRel',semanticlabelsFolderName,WebTestList{j},folder,[onlyName '.mat']);
        
        if ~exist(resultFile,'file')
            continue;
        end;
        
        load(resultFile); % L Lsp labelList
        
        resultCache = [resultFile '.cache'];
        if exist(resultCache,'file')
            load(resultCache,'-mat'); % metaData perLabelStat(#labelsx2) perPixelStat([# pix correct, # pix total]);
        end;
        
        if max(unique(L)) == length(labelList) + 1
            labelList = [labelList(:)' {'unlabeled'}];
        end
        
        labeledImOutCorrect = fullfile(HOMEWEB,semanticlabelsFolderName,WebTestList{j},folder,[onlyName 'Correct.png']);
        if ~exist(fileparts(labeledImOutCorrect),'dir'), mkdir(fileparts(labeledImOutCorrect)); end;
        
        labeledImOutLArea = fullfile(HOMEWEB,semanticlabelsFolderName,WebTestList{j},folder,[onlyName 'LArea.png']);
        if ~exist(fileparts(labeledImOutLArea),'dir'), mkdir(fileparts(labeledImOutLArea)); end;
        
        labeledImOutNoLegend = fullfile(HOMEWEB,semanticlabelsFolderName,WebTestList{j},folder,[onlyName 'NoLegend.png']);
        if ~exist(fileparts(labeledImOutNoLegend),'dir'), mkdir(fileparts(labeledImOutNoLegend)); end;
        
        labeledImOut = fullfile(HOMEWEB,semanticlabelsFolderName,WebTestList{j},folder,[onlyName '.png']);
        if ~exist(fileparts(labeledImOut),'dir'), mkdir(fileparts(labeledImOut)); end;
        
        if ~exist(labeledImOutCorrect,'file') || regenerateResultImages
            if isempty(groundTruth)
                [~] = DrawImLabels(im,L,semanticLabelColor,labelList,labeledImOutCorrect,128,0,1,maxDim);
            else
                temp = L;
                temp(groundTruth ~= L) = -1;
                temp(groundTruth < 1) = 0;
                [~] = DrawImLabels(im,temp+2,[.5 0 0; 0 0 0; semanticLabelColor],{'wrong' 'unlabeled' labelList{:}},labeledImOutCorrect,128,0,1,maxDim);
            end;
        end;
        
        if ~exist(labeledImOutLArea,'file') || regenerateResultImages
            if isempty(groundTruth)
                [~] = DrawImLabels(im,L,semanticLabelColor,labelList,labeledImOutLArea,128,0,1,maxDim);
            else
                temp = L;
                temp(groundTruth < 1) = 0;
                [~] = DrawImLabels(im,temp+1,[0 0 0; semanticLabelColor],{'unlabeled' labelList{:}},labeledImOutLArea,128,0,1,maxDim);
            end;
        end;
        
        if ~exist(labeledImOutNoLegend,'file') || regenerateResultImages
            [~] = DrawImLabels(im,L,semanticLabelColor,labelList,labeledImOutNoLegend,0,0,1,maxDim);
        end;
        
        if ~exist(labeledImOut,'file') || regenerateResultImages
            [~] = DrawImLabels(im,L,semanticLabelColor,labelList,labeledImOut,128,0,1,maxDim);
        end;
    end;
    ProgressBar(pfig,find(range==i),length(range));
end;
close(pfig);

return;