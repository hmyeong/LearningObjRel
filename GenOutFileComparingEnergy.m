function [EnergyVal] = GenOutFileComparingEnergy(baseFileName,LCurrent,LspCurrent,EnergyValCurrent,HOMETESTDATA,outFileSuffix,testName,labelList)

[folder,~] = fileparts(baseFileName);
if ~exist(fullfile(HOMETESTDATA,outFileSuffix,'SemanticLabels',testName,folder),'dir')
    mkdir(fullfile(HOMETESTDATA,outFileSuffix,'SemanticLabels',testName,folder));
end;

outFileName = fullfile(HOMETESTDATA,outFileSuffix,'SemanticLabels',testName,[baseFileName '.mat']);

if exist(outFileName,'file')
    load(outFileName,'L','Lsp','labelList','EnergyVal');
    if EnergyValCurrent < EnergyVal
        L = LCurrent;
        Lsp = LspCurrent;
        EnergyVal = EnergyValCurrent;
        save(outFileName,'L','Lsp','labelList','EnergyVal');
    else
        % do nothing
    end;
else
    L = LCurrent;
    Lsp = LspCurrent;
    EnergyVal = EnergyValCurrent;
    save(outFileName,'L','Lsp','labelList','EnergyVal');
end;

return;