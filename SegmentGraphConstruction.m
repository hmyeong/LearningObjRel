function SegmentGraphConstruction(SPdata,SPparam,LORparam)

if ~exist(fullfile(SPparam.HOMEDATA,'WeightMat'),'dir')
    mkdir(fullfile(SPparam.HOMEDATA,'WeightMat'));
end;

if ~exist(fullfile(SPparam.HOMEDATA,LORparam.testName),'dir')
    mkdir(fullfile(SPparam.HOMEDATA,LORparam.testName));
end;

timeFileStr = fopen(fullfile(SPparam.HOMEDATA,LORparam.testName,...
    ['graph_construction_time_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
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
    [testImSPDesc,~] = LoadSegmentDesc(SPdata.testFileList(i),[],SPparam.HOMEDATA,...
        LORparam.segmentDescriptors,SPparam.K,SPparam.segSuffix);
    
    nWnOutFileName = fullfile(SPparam.HOMEDATA,'WeightMat',...
        [baseFileName '_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
        '_w_Q_' num2str(LORparam.w_Q) '_w_U_' num2str(LORparam.w_U)...
        '_K_' num2str(SPparam.K) '_nWn_app.mat']);
    
    if exist(nWnOutFileName,'file') && ~LORparam.reconstructGraph
        %         load(nWnOutFileName);
    else
        retSetIndex = PruneIndex(SPdata.trainIndex{1},retInds,LORparam.retSetSize,LORparam.minSPinRetSet); %% check
        
        [retSetSPDesc,~] = LoadSegmentDesc(SPdata.trainFileList,retSetIndex,SPparam.HOMEDATA,...
            LORparam.segmentDescriptors,SPparam.K,SPparam.segSuffix);
        
        testSize = size(testImSPDesc.(LORparam.segmentDescriptors{1}),1);
        trainSize = size(retSetSPDesc.(LORparam.segmentDescriptors{1}),1);
        
        weightsTestToTest = MakeDescWeight(testImSPDesc,testImSPDesc,testSize,testSize,LORparam.segmentDescriptors);
        weightsTestToTrain = MakeDescWeight(testImSPDesc,retSetSPDesc,testSize,trainSize,LORparam.segmentDescriptors);
        weightsTrain = MakeDescWeight(retSetSPDesc,retSetSPDesc,trainSize,trainSize,LORparam.segmentDescriptors);
        
        W = [weightsTrain LORparam.w_Q*weightsTestToTrain';
            LORparam.w_Q*weightsTestToTrain LORparam.w_U*weightsTestToTest];
        
        W = W - diag(diag(W)); % make diagonal 0
        
        % select kNN
        [~,I] = sort(W,'descend');
        selectedI = I(1:LORparam.kNN,:);
        x = meshgrid(1:size(W,1),1:LORparam.kNN);
        mask = sparse(selectedI(:), x(:), ones(size(W,1)*LORparam.kNN,1), size(W,1), size(W,1));
        W(~mask) = 0;
        
        d = sum(W); D = diag(d); iD = sparse(diag(1./d));
        iD2 = sparse(diag(1./sqrt(d)));
        
        nW = sparse(iD * W); % column-normalize
        Wn = sparse(W * iD); % row-normalize
        nWn = sparse(iD2 * W * iD2);
        
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