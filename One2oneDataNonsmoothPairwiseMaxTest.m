function [] = One2oneDataNonsmoothPairwiseMaxTest(SPdata,SPparam,LORparam)

pfig = ProgressBar('Parsing Images (Data Nonsmooth Pairwise Max Test)');
range = 1:length(SPdata.testFileList);
for i = range
    [folder,onlyName] = fileparts(SPdata.testFileList{i});
    baseFileName = fullfile(folder,onlyName);
    
    %% Get data term
    [dataCost,imSP,~] = GetSuperParsingDataCost(baseFileName,i,SPdata,SPparam);
    
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
    
    numLabels = length(SPdata.Labels{1,1}); % note: Labels{1,1} = Labels{labelType,Kndx}
    
    secondOrderObjRel = GenSecondOrderObjRelMax(propagatedLabels,reducedLabels,SPdata.Labels{1,1}...
        ,LORparam.retSetSize,testSize); % note: LORparam.retSetSize, Labels{1,1} = Labels{labelType,Kndx}
    [normSecondOrderObjRel, maxNormSecondOrderObjRel, minNormSecondOrderObjRel] =...
        LogNormObjRel(secondOrderObjRel,numLabels);
    
    testSuffix = '';
    testName = ['DPwMaxPropagatedLabels' '_retSetSize_' num2str(LORparam.retSetSize)...
        '_kNN_' num2str(LORparam.kNN) '_l_' num2str(LORparam.lambda)...
        '_a_' num2str(LORparam.alpha) '_nIter_' num2str(LORparam.numQPBOIter)...
        '_nStart_' num2str(LORparam.numMultiStart) '_' testSuffix];
    
    for j = 1:LORparam.numMultiStart
        [Lsp,EnergyVal] = mexLOROptUndirectedQPBO(normSecondOrderObjRel,dataCost{1},...
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