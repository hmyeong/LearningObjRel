function [] = One2onePropagatedLabelMaxTest(SPdata,SPparam,LORparam)

pfig = ProgressBar('Parsing Images (Nonsmooth Pairwise First Order Test)');
range = 1:length(SPdata.testFileList);
for i = range
    fprintf('Test image number : %d ',i);
    [folder,onlyName] = fileparts(SPdata.testFileList{i});
    baseFileName = fullfile(folder,onlyName);
    fprintf('filename : %s\n',baseFileName);
    
    %% Get data term
    [~,imSP,~] = GetSuperParsingDataCost(baseFileName,i,SPdata,SPparam);
    
    %% Assign label using propagated label
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
    
    unfoldedReducedPropagatedLabels = UnfoldReducedPropagatedLabel(propagatedLabels,reducedLabels,...
        SPdata.Labels{1,1},LORparam.retSetSize,testSize); % note: LORparam.retSetSize, Labels{1,1} = Labels{labelType,Kndx}
    
    propagatedLabelSum = GenPropagatedLabelMax(unfoldedReducedPropagatedLabels,LORparam.retSetSize,SPdata.Labels{1,1},testSize); % note: Labels{1,1} = Labels{labelType,Kndx}
    
    Lsp = MaxDataCost(propagatedLabelSum);
    L = ProjectLabelToImage(imSP,Lsp);
    
    testName = ['DwMaxPropagatedLabels' '_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)];
    GenOutFile(baseFileName,L,Lsp,LORparam.HOMETESTDATA,LORparam.outFileSuffix,testName,SPdata.Labels{1,1}); % note: Labels{1,1} = Labels{labelType,Kndx}
    
    ProgressBar(pfig,find(i==range),length(range));
end;
close(pfig);

return;