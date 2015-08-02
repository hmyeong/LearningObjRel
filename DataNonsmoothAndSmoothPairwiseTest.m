function [] = DataNonsmoothAndSmoothPairwiseTest(SPdata,SPparam,LORparam)

pfig = ProgressBar('Parsing Images (Data Nonsmooth and Smooth Pairwise Test)');
range = 1:length(SPdata.testFileList);
for i = range
    fprintf('Test image number : %d ',i);
    [folder,onlyName] = fileparts(SPdata.testFileList{i});
    baseFileName = fullfile(folder,onlyName);
    fprintf('filename : %s\n',baseFileName);
    
    %% Get data term
    [dataCost,imSP,adjPairs] = GetSuperParsingDataCost(baseFileName,i,SPdata,SPparam);
    
    %% Get nonsmooth pairwise term
    objRelOutFileName = fullfile(SPparam.HOMEDATA,'SecondOrderObjRel',...
        [baseFileName '_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
        '_w_Q_' num2str(LORparam.w_Q) '_w_U_' num2str(LORparam.w_U)...
        '_K_' num2str(SPparam.K) '_lambda_' num2str(LORparam.lambda) '_secondOrderObjRel_app.mat']);
    
    if ~exist(objRelOutFileName,'file')
        fprintf('%s does not exist..! exiting..\n',objRelOutFileName);
        error('Error in OptimizationWithQPBO.m');
    else
        load(objRelOutFileName,'secondOrderObjRel');
    end;
    
    numLabels = length(SPdata.Labels{1,1}); % note: Labels{1,1} = Labels{labelType,Kndx}
    numSites = max(imSP(:));
    
    [normSecondOrderObjRel, maxNormSecondOrderObjRel, minNormSecondOrderObjRel] =...
        LogNormObjRel(secondOrderObjRel,numLabels);
    
    normSecondOrderObjRelPlusSmoothness = AddSmoothnessToObjRel(normSecondOrderObjRel,adjPairs,numLabels,numSites,...
        LORparam.alpha,LORparam.beta,maxNormSecondOrderObjRel);
    
    testSuffix = '';
    testName = ['DPwSORPotts' '_retSetSize_' num2str(LORparam.retSetSize)...
        '_kNN_' num2str(LORparam.kNN) '_l_' num2str(LORparam.lambda)...
        '_a_' num2str(LORparam.alpha) '_nIter_' num2str(LORparam.numQPBOIter)...
        '_nStart_' num2str(LORparam.numMultiStart) '_beta_' num2str(LORparam.beta)...
        '_' testSuffix];
    
    for j = 1:LORparam.numMultiStart
        [Lsp,EnergyVal] = mexLOROptUndirectedQPBO(normSecondOrderObjRelPlusSmoothness,dataCost{1},...
            [maxNormSecondOrderObjRel minNormSecondOrderObjRel LORparam.alpha LORparam.numQPBOIter 0]); % note: dataCost{1} = dataCost{labelType*Kndx}
        L = ProjectLabelToImage(imSP,Lsp);
        
        [EnergyValStored] = GenOutFileComparingEnergy(baseFileName,L,Lsp,EnergyVal,LORparam.HOMETESTDATA,...
            LORparam.outFileSuffix,testName,SPdata.Labels{1,1}); % note: Labels{1,1} = Labels{labelType,Kndx}
        
        fprintf('Iter %d\t: Previous: %f\tAchieved.. %f\n',j,EnergyVal,EnergyValStored);
    end;
    
    ProgressBar(pfig,find(i==range),length(range));
end;
close(pfig);

return;