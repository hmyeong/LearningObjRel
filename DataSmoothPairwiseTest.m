function [] = DataSmoothPairwiseTest(SPdata,SPparam,LORparam)

pfig = ProgressBar('Parsing Images (Data Smooth Pairwise (Potts) Test)');
range = 1:length(SPdata.testFileList);
for i = range
    fprintf('Test image number : %d ',i);
    [folder,onlyName] = fileparts(SPdata.testFileList{i});
    baseFileName = fullfile(folder,onlyName);
    fprintf('filename : %s\n',baseFileName);
    
    %% Get data term
    [dataCost,imSP,adjPairs] = GetSuperParsingDataCost(baseFileName,i,SPdata,SPparam);
    
    %% Get nonsmooth pairwise term
    testSuffix = '';
    testName = ['DPwPotts' '_beta_' num2str(LORparam.beta)...
        '_nIter_' num2str(LORparam.numQPBOIter) '_' testSuffix];
    
    for j = 1:LORparam.numMultiStart
        [Lsp,EnergyVal] = mexPottsOptQPBO(int32(adjPairs),dataCost{1},...
            [LORparam.beta LORparam.numQPBOIter 0]); % note: dataCost{1} = dataCost{labelType*Kndx}
        L = ProjectLabelToImage(imSP,Lsp);
        
        [EnergyValStored] = GenOutFileComparingEnergy(baseFileName,L,Lsp,EnergyVal,LORparam.HOMETESTDATA,...
            LORparam.outFileSuffix,testName,SPdata.Labels{1,1}); % note: Labels{1,1} = Labels{labelType,Kndx}
        
        fprintf('Iter %d\t: Previous: %f\tAchieved.. %f\n',j,EnergyVal,EnergyValStored);
    end;
    
    ProgressBar(pfig,find(i==range),length(range));
end;
close(pfig);

return;