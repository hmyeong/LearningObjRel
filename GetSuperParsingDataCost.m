%
% refactored from the SuperParsing code
% im_parser/ImageParser/ParseTestImages.m
% http://www.cs.unc.edu/~jtighe/Papers/ECCV10/index.html
%
function [dataCost,imSP,adjPairs] = GetSuperParsingDataCost(baseFileName,i,SPdata,SPparam)

% Get Retrieval Set
retInds = FindRetrievalSet(SPdata.trainGlobalDesc,SelectDesc(SPdata.testGlobalDesc,i,1),...
    SPparam.HOMEDATA,baseFileName,SPparam.globalDescriptors); %% note: SPparam.globalDescriptors

classifierStr = repmat('0',[1 length(SPparam.HOMELABELSETS)]);
Kstr = '';
clear imSP testImSPDesc;
for Kndx = 1:length(SPparam.K)
    [testImSPDesc, imSP{Kndx}] = LoadSegmentDesc(SPdata.testFileList(i),[],SPparam.HOMEDATA,...
        SPparam.segmentDescriptors,SPparam.K,SPparam.segSuffix); %% note: SPparam.segmentDescriptors
    
    for labelType = 1:length(SPparam.HOMELABELSETS)
        if isempty(SPdata.classifiers{Kndx,labelType})
            [~,labelSet] = fileparts(SPparam.HOMELABELSETS{labelType});
            if SPparam.retSetSize == length(SPdata.trainFileList)
                retSetIndex = SPdata.trainIndex{labelType,Kndx};
            else
                retSetIndex = PruneIndex(SPdata.trainIndex{labelType,Kndx},retInds,SPparam.retSetSize,SPparam.minSPinRetSet);
            end;
            suffix = sprintf('R%dK%d',SPparam.retSetSize,SPparam.K(Kndx));
            labelNums = 1:length(SPdata.trainCounts{labelType});
            probPerLabel{labelType,Kndx} = GetAllProbPerLabel(fullfile(SPparam.HOMETESTDATA,labelSet),baseFileName,suffix,retSetIndex,[],labelNums,SPdata.trainCounts{labelType,Kndx},'ratio',1); %#ok<AGROW>
            if isempty(probPerLabel{labelType,Kndx})
                rawNNs = DoRNNSearch(testImSPDesc,[],fullfile(SPparam.HOMETESTDATA,labelSet),baseFileName,suffix,SPdata,SPparam,Kndx);
                if isempty(rawNNs)
                    if SPparam.retSetSize == length(SPdata.trainFileList)
                        if isempty(fullSPDesc{labelType,Kndx})
                            fullSPDesc{labelType,Kndx} = LoadSegmentDesc(SPdata.trainFileList,retSetIndex,HOMEDATA,segmentDescriptors,K(Kndx));
                        end;
                        retSetSPDesc = fullSPDesc{labelType,Kndx};
                    else
                        retSetSPDesc = LoadSegmentDesc(SPdata.trainFileList,retSetIndex,SPparam.HOMEDATA,SPparam.segmentDescriptors,SPparam.K(Kndx),[]);
                    end;
                    rawNNs = DoRNNSearch(testImSPDesc,retSetSPDesc,fullfile(SPparam.HOMETESTDATA,labelSet),baseFileName,suffix,SPdata,SPparam,Kndx);
                end;
                probPerLabel{labelType,Kndx} = GetAllProbPerLabel(fullfile(SPparam.HOMETESTDATA,labelSet),baseFileName,suffix,retSetIndex,rawNNs,labelNums,SPdata.trainCounts{labelType,Kndx},'ratio',1); %#ok<AGROW>
            end;
        else
            features = GetFeaturesForClassifier(testImSPDesc);
            probPerLabel{labelType,Kndx} = test_boosted_dt_mc(SPdata.classifiers{Kndx,labelType}, features);
            classifierStr(labelType) = '1';
        end;
    end;
    Kstr = [Kstr num2str(SPparam.K(Kndx))];
end;

% Nomalize the datacosts for mrf. This is especiall important when using some classifier or when some labelsets are under represented
dataCost = cell(size(probPerLabel));
for j = 1:numel(probPerLabel)
    dataCost{j} = -(probPerLabel{j}-max(probPerLabel{j}(:))-1);
    dataCost{j} = 100*dataCost{j}/max(dataCost{j}(:));
end;

if length(SPparam.K) == 1
    imSP = imSP{Kndx};
    adjFile = fullfile(SPparam.HOMEDATA,'Descriptors',sprintf('FH_segDesc_K%d',SPparam.K(Kndx)),'sp_adjacency',[baseFileName '.mat']);
    load(adjFile);
else
    %implement multi segmentation code
    adjPairs = FindSPAdjacnecy(imSP);
end;

return;