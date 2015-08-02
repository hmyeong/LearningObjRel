function [] = One2oneDataSmoothPairwiseNonsmoothHighorderSumTest(SPdata,SPparam,LORparam)

pfig = ProgressBar('Parsing Images (Data Smooth Pairwise Nonsmooth High-order Sum Test)');
range = 1:length(SPdata.testFileList);
for i = range
    [folder,onlyName] = fileparts(SPdata.testFileList{i});
    baseFileName = fullfile(folder,onlyName);
    
    %% Get data term
    [dataCost,imSP,adjPairs] = GetSuperParsingDataCost(baseFileName,i,SPdata,SPparam);
    
    %% Get nonsmooth pairwise term
    labelOutFileName = fullfile(SPparam.HOMEDATA,'PropagatedLabels',...
        [baseFileName '_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
        '_w_Q_' num2str(LORparam.w_Q) '_w_U_' num2str(LORparam.w_U)...
        '_K_' num2str(SPparam.K) '_lambda_' num2str(LORparam.lambda) '_one2one_propagatedLabel_app_geo.mat']);
    
    if ~exist(labelOutFileName,'file')
        fprintf('%s does not exist..! exiting..\n',labelOutFileName);
        error('Error in One2oneOptimizationWithQPBO.m');
    else
        load(labelOutFileName,'context2ndIdx','context3rdIdx','propagatedLabels','reducedLabels','testSize');
    end;
    
    if ~exist('reducedLabels','var')
        fprintf('reducedLabels does not exist..! exiting..\n');
        error('Error in One2oneOptimizationWithQPBO.m');
    end;
    
    %     numLabels = length(SPdata.Labels{1,1}); % note: Labels{1,1} = Labels{labelType,Kndx}
    unfoldPropagatedLabels = UnfoldPropagatedLabels(propagatedLabels,reducedLabels,SPdata.Labels{1,1},LORparam.retSetSize,testSize); % note: Labels{1,1} = Labels{labelType,Kndx}
    
    % Gen minMaxUnfoldPropagatedLabels & minSumUnfoldPropagatedLabels
    sumUnfoldPropagatedLabels = zeros(size(unfoldPropagatedLabels{1}));
    minUnfoldPropagatedLabels = 1e+100;
    for retSetIdx = 1:LORparam.retSetSize
        sumUnfoldPropagatedLabels = sumUnfoldPropagatedLabels + unfoldPropagatedLabels{retSetIdx};
        if ~isempty(propagatedLabels{retSetIdx})
            if minUnfoldPropagatedLabels > min(min(propagatedLabels{retSetIdx}(end-testSize+1:end,:)))
                minUnfoldPropagatedLabels = min(min(propagatedLabels{retSetIdx}(end-testSize+1:end,:)));
            end;
        end;
    end;
    tempUnfoldPropagatedLabels = sumUnfoldPropagatedLabels(end-testSize+1:end,:);
    tempUnfoldPropagatedLabels(tempUnfoldPropagatedLabels == 0) = inf;
    minSumUnfoldPropagatedLabels = min(min(tempUnfoldPropagatedLabels));
    
    testSuffix = 'Sampling';
    testName = ['DPwPottsHwSumPropagatedLabels' '_retSetSize_' num2str(LORparam.retSetSize)...
        '_kNN_' num2str(LORparam.kNN) '_l_' num2str(LORparam.lambda)...
        '_a_' num2str(LORparam.alpha) '_nIter_' num2str(LORparam.numQPBOIter)...
        '_nStart_' num2str(LORparam.numMultiStart) '_beta_' num2str(LORparam.beta)...
        '_Dinit_' num2str(LORparam.dataInitFlag) '_Qpre_' num2str(LORparam.QPBOpreFlag) '_' testSuffix];
    
    for j = 1:LORparam.numMultiStart
        [Lsp,EnergyVal] = mexLOROptSmoothPairwiseUndirectedHighOrderSum(unfoldPropagatedLabels,int32(adjPairs),dataCost{1},...
            [-log(minSumUnfoldPropagatedLabels^3) -log(minSumUnfoldPropagatedLabels^2) 0 ...
            LORparam.alpha LORparam.beta LORparam.numQPBOIter LORparam.dataInitFlag LORparam.QPBOpreFlag 1]); % note: dataCost{1} = dataCost{labelType*Kndx}
        L = ProjectLabelToImage(imSP,Lsp);
        
        [EnergyValStored] = GenOutFileComparingEnergy(baseFileName,L,Lsp,EnergyVal,LORparam.HOMETESTDATA,...
            LORparam.outFileSuffix,testName,SPdata.Labels{1,1}); % note: Labels{1,1} = Labels{labelType,Kndx}
        
        fprintf('Iter %d\t: Previous: %f\tAchieved.. %f\n',j,EnergyVal,EnergyValStored);
    end;
    
    ProgressBar(pfig,find(i==range),length(range));
end;
close(pfig);

return;