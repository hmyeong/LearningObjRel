%
% refactored from the SuperParsing code
% im_parser/LoadData.m
% http://www.cs.unc.edu/~jtighe/Papers/ECCV10/index.html
%
function [SPdata] = SuperParsingPreprocessing(SPparam)
%% Extract all variables from SPparam
strNames = fieldnames(SPparam);
for i = 1:length(strNames), eval([strNames{i} '= SPparam.' strNames{i} ';']); end

%% Get image file list
imgFileList = dir_recurse(fullfile(HOMEIMAGES,'*.*'),0);

%% Compute segment descriptors and segment index
% cell of segIndex, Labels, and Counts are for multi label (refer Tighe and Lazebnik ICCV'11 for details)
% segIndex = index of segment

descFunsList = sort(segmentDescriptors);
centerFunsList = {'gist_centers','mr_resp_centers','sift_centers'};
filterFunsList = {'mr_filter','sift_textons'};

segIndex = cell(0); Labels = cell(0); Counts = cell(0);
for j = 1:length(K)
    ComputeKmeansVisualWords(imgFileList, HOMEIMAGES, HOMEDATA, centerFunsList);
    % ComputeDenseVisualWords();
    ComputeAllSegment(imgFileList, HOMEIMAGES, HOMEDATA, K(j));
    descFuns = ComputeAllSegmentDescriptors(imgFileList, HOMEIMAGES, HOMEDATA, K(j), 0, descFunsList, centerFunsList, filterFunsList);
    for i = 1:length(HOMELABELSETS)
        [segIndex{i,j},Labels{i},Counts{i,j}] = LoadSegmentLabelIndex(imgFileList, [], HOMELABELSETS{i}, fullfile(HOMEDATA,'Descriptors'), sprintf('FH_segDesc_K%d%s',K(j),segSuffix));
    end;
end;

%% generate test and train file index
testSetFile = fullfile(HOMEDATA,[testSetName '.txt']);

testFiles = importdata(testSetFile);
nTestFiles = length(testFiles);
testFileMask = false(size(imgFileList));
for i = 1:nTestFiles
    testFileMask(strcmp(testFiles{i},imgFileList)) = 1;
end;

testInd = find(testFileMask);
trainInd = find(~testFileMask);
testFileList = imgFileList(testFileMask);
trainFileList = imgFileList(~testFileMask);

%% Compute global desc.
testGlobalDesc = ComputeGlobalDescriptors(testFileList, HOMEIMAGES, HOMELABELSETS, HOMEDATA);
trainGlobalDesc = ComputeGlobalDescriptors(trainFileList, HOMEIMAGES, HOMELABELSETS, HOMEDATA);

%% Generate testIndex and trainIndex
testIndex = cell(0); trainIndex = cell(0);
testCounts = cell(0); trainCounts = cell(0);

for i = 1:length(HOMELABELSETS)
    for j = 1:length(K)
        testIndexMask = false(size(segIndex{i,j}.image));
        for k = 1:length(testInd)
            testIndexMask = testIndexMask | (segIndex{i,j}.image==testInd(k));
        end;
        
        testIndex{i,j}.label = segIndex{i,j}.label(testIndexMask);
        testIndex{i,j}.sp = segIndex{i,j}.sp(testIndexMask);
        indConverter = zeros(max(testInd),1); indConverter(testInd) = 1:length(testInd);
        testIndex{i,j}.image = indConverter(segIndex{i,j}.image(testIndexMask));
        [l,counts] = UniqueAndCounts(testIndex{i,j}.label);
        testCounts{i,j} = zeros(size(Counts{i,j}));
        testCounts{i,j}(l) = counts;
        
        trainIndex{i,j}.label = segIndex{i,j}.label(~testIndexMask);
        trainIndex{i,j}.sp = segIndex{i,j}.sp(~testIndexMask);
        indConverter = zeros(max(trainInd),1); indConverter(trainInd) = 1:length(trainInd);
        trainIndex{i,j}.image = indConverter(segIndex{i,j}.image(~testIndexMask));
        [l,counts] = UniqueAndCounts(trainIndex{i,j}.label);
        trainCounts{i,j} = zeros(size(Counts{i,j}));
        trainCounts{i,j}(l) = counts;
    end;
end;

%% Calculate object class co-occurrence
lptemp = cell(0);
for j = 1:1:length(K)
    lptemp{j} = ComputeLabelPenality(trainFileList, HOMEDATA, sprintf('FH_segDesc_K%d',K(j)), trainIndex(:,j), testName, Labels);
end;

labelPenality = cell(size(lptemp{1}));
for j = 1:numel(labelPenality)
    temp = zeros([size(lptemp{1}{j}) length(lptemp)]);
    for k = 1:length(lptemp)
        temp(:,:,k) = lptemp{k}{j};
    end;
    labelPenality{j} = mean(temp,3);
end;

%% Calculate Rs
Rs = cell(0);
for j = 1:1:length(K)
    Rs{j} = CalculateSearchRs(trainFileList, HOMEDATA, trainIndex{1,j}, descFuns,K(j), segSuffix);
end;

%% Train classifier
classifiers = cell(length(K),length(Labels));
for i = find(UseClassifier)
    labelMask = cell(1);
    labelMask{1} = ones(size(Labels{i}))==1;
    classifiers(:,i) = TrainClassifier(HOMEDATA, HOMELABELSETS(i), trainFileList, trainIndex(i), Labels(i), labelMask, claParams);
end;

%% Assign SPdata
SPdata.testFileList = testFileList;
SPdata.trainFileList = trainFileList;

SPdata.testIndex = testIndex;
SPdata.trainIndex = trainIndex;

SPdata.testCounts = testCounts;
SPdata.trainCounts = trainCounts;

SPdata.Labels = Labels;

SPdata.testGlobalDesc = testGlobalDesc;
SPdata.trainGlobalDesc = trainGlobalDesc;

SPdata.labelPenality = labelPenality;

SPdata.Rs = Rs;
SPdata.classifiers = classifiers;

return;