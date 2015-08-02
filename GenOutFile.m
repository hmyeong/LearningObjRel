function [] = GenOutFile(baseFileName,L,Lsp,HOMETESTDATA,outFileSuffix,testName,labelList)

[folder,~] = fileparts(baseFileName);
if ~exist(fullfile(HOMETESTDATA,outFileSuffix,'SemanticLabels',testName,folder),'dir')
    mkdir(fullfile(HOMETESTDATA,outFileSuffix,'SemanticLabels',testName,folder));
end;

outFileName = fullfile(HOMETESTDATA,outFileSuffix,'SemanticLabels',testName,[baseFileName '.mat']);
save(outFileName,'L','Lsp','labelList');

return;