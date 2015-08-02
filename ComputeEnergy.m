function [EnergyData,EnergyPair] = ComputeEnergy(Lsp,secondOrderObjRel,dataCost,maxVal,minVal,alpha)

EnergyData = 0; EnergyPair = 0;
for i = 1:length(Lsp)
    if ~isempty(dataCost)
        EnergyData = EnergyData + dataCost(i,Lsp(i)); % data
    end;
    
    for j = 1:length(Lsp) % pairwise
        if i ~= j
            if ~isempty(secondOrderObjRel{Lsp(i),Lsp(j)})
                EnergyPair = EnergyPair + alpha * ((secondOrderObjRel{Lsp(i),Lsp(j)}(i,j) + secondOrderObjRel{Lsp(j),Lsp(i)}(j,i)) / (2*maxVal));
            else
                EnergyPair = EnergyPair + alpha;
            end;
        end;
    end;
end;