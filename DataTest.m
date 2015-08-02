function [] = DataTest(SPdata,SPparam,LORparam)

pfig = ProgressBar('Parsing Images (Data Term Test)');
range = 1:length(SPdata.testFileList);
for i = range
    fprintf('Test image number : %d ',i);
    [folder,onlyName] = fileparts(SPdata.testFileList{i});
    baseFileName = fullfile(folder,onlyName);
    fprintf('filename : %s\n',baseFileName);
    
    %% Get data term
    [dataCost,imSP,~] = GetSuperParsingDataCost(baseFileName,i,SPdata,SPparam);
    
    %% Assign label using data term
    Lsp = MinDataCost(dataCost{1}); % only one label
    L = ProjectLabelToImage(imSP,Lsp);
    
    GenOutFile(baseFileName,L,Lsp,LORparam.HOMETESTDATA,LORparam.outFileSuffix,'D_',SPdata.Labels{1,1}); % note: Labels{1,1} = Labels{labelType,Kndx}
    
    ProgressBar(pfig,find(i==range),length(range));
end;
close(pfig);

return;