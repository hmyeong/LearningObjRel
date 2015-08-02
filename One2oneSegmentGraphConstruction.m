function One2oneSegmentGraphConstruction(SPdata,SPparam,LORparam)

if ~exist(fullfile(SPparam.HOMEDATA,'WeightMat'),'dir')
    mkdir(fullfile(SPparam.HOMEDATA,'WeightMat'));
end;

if ~exist(fullfile(SPparam.HOMEDATA,LORparam.testName),'dir')
    mkdir(fullfile(SPparam.HOMEDATA,LORparam.testName));
end;

timeFileStr = fopen(fullfile(SPparam.HOMEDATA,LORparam.testName,...
    ['graph_construction_time_one2one_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
    '_w_Q_' num2str(LORparam.w_Q) '_w_U_' num2str(LORparam.w_U)...
    '_K_' num2str(SPparam.K) '.txt']),'w');

pfig = ProgressBar('Segment Graph Construction');
range = 1:length(SPdata.testFileList);
for i = range
    fprintf('Test image number : %d ',i);
    [folder,onlyName] = fileparts(SPdata.testFileList{i});
    baseFileName = fullfile(folder,onlyName);
    fprintf('filename : %s\n',baseFileName);
    
    %Get Retrieval Set
    retInds = FindRetrievalSet(SPdata.trainGlobalDesc,SelectDesc(SPdata.testGlobalDesc,i,1),...
        SPparam.HOMEDATA,baseFileName,LORparam.globalDescriptors);
    
    clear imSP testImSPDesc;
    tic;
    [testImSPDesc,imSP] = LoadSegmentDesc(SPdata.testFileList(i),[],SPparam.HOMEDATA,...
        LORparam.segmentDescriptors,SPparam.K,SPparam.segSuffix);
    
    cent = regionprops(imSP,'Centroid');
    testCentroid = cat(1,cent.Centroid);
    
    nWnOutFileName = fullfile(SPparam.HOMEDATA,'WeightMat',...
        [baseFileName '_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
        '_w_Q_' num2str(LORparam.w_Q) '_w_U_' num2str(LORparam.w_U)...
        '_K_' num2str(SPparam.K) '_one2one_nWn_app_geo.mat']);
    
    if exist(nWnOutFileName,'file') && ~LORparam.reconstructGraph
        %         load(nWnOutFileName);
    else
        W = cell(LORparam.retSetSize,1);
        D = cell(LORparam.retSetSize,1);
        nW = cell(LORparam.retSetSize,1);
        Wn = cell(LORparam.retSetSize,1);
        nWn = cell(LORparam.retSetSize,1);
        trainSize = zeros(LORparam.retSetSize,1);
        
        for j = 1:LORparam.retSetSize
            retSetIndex = PruneIndexNum(SPdata.trainIndex{1},retInds,j); %% check
            if isempty(retSetIndex.image)
                W{j} = [];
                continue;
            end;
            
            [retSetSPDesc,retImSP] = LoadSegmentDesc(SPdata.trainFileList,retSetIndex,SPparam.HOMEDATA,...
                LORparam.segmentDescriptors,SPparam.K,SPparam.segSuffix);
            
            retCent = regionprops(retImSP,'Centroid');
            retCentroid = cat(1,retCent.Centroid);
            CentroidSet = [retCentroid(retSetIndex.sp,:); testCentroid]; % retSetIndex -> only labeled
            CentroidSet(:,1) = CentroidSet(:,1) ./ size(imSP,2);
            CentroidSet(:,2) = CentroidSet(:,2) ./ size(imSP,1);
            
            testSize = size(testImSPDesc.(LORparam.segmentDescriptors{1}),1);
            trainSize(j) = size(retSetSPDesc.(LORparam.segmentDescriptors{1}),1);
            
            weightsTestToTest = MakeDescWeight(testImSPDesc,testImSPDesc,testSize,testSize,LORparam.segmentDescriptors);
            weightsTestToTrain = MakeDescWeight(testImSPDesc,retSetSPDesc,testSize,trainSize(j),LORparam.segmentDescriptors);
            weightsTrain = MakeDescWeight(retSetSPDesc,retSetSPDesc,trainSize(j),trainSize(j),LORparam.segmentDescriptors);
            
            geoWeights = MakeGeoWeight(CentroidSet,CentroidSet,testSize + trainSize(j),testSize + trainSize(j),...
                LORparam.segmentDescriptors,length(LORparam.segmentDescriptors));
            
            W{j} = [weightsTrain LORparam.w_Q*weightsTestToTrain';
                LORparam.w_Q*weightsTestToTrain LORparam.w_U*weightsTestToTest];
            
            W{j} = W{j} .* geoWeights;
            
            W{j} = W{j} - diag(diag(W{j})); % make diagonal 0
            
            % select kNN
            %             [~,I] = sort(W{j},'descend');
            %             selectedI = I(1:paramsCL.kNN,:);
            %             x = meshgrid(1:size(W{j},1),1:paramsCL.kNN);
            %             mask = sparse(selectedI(:), x(:), ones(size(W{j},1)*paramsCL.kNN,1), size(W{j},1), size(W{j},1));
            %             W{j}(~mask) = 0;
            
            d = sum(W{j}); D{j} = diag(d); iD = sparse(diag(1./d));
            iD2 = sparse(diag(1./sqrt(d)));
            
            nW{j} = sparse(iD * W{j}); % column-normalize
            Wn{j} = sparse(W{j} * iD); % row-normalize
            nWn{j} = sparse(iD2 * W{j} * iD2);
            
            clear retCent retCentroid;
        end;
        
        graphConstructionTime = toc;
        fprintf(timeFileStr,'%d ',graphConstructionTime);
        fprintf(timeFileStr,'\n');
        
        make_dir(nWnOutFileName); save(nWnOutFileName,'W','D','nW','Wn','nWn','testSize','trainSize');
        
        clear W D nW Wn nWn;
    end;
    ProgressBar(pfig,find(i==range),length(range));
end;

close(pfig); fclose(timeFileStr);

return;