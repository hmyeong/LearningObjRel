function [] = One2oneLabelPropagation(SPdata,SPparam,LORparam)

if ~exist(fullfile(SPparam.HOMEDATA,'PropagatedLabels'),'dir')
    mkdir(fullfile(SPparam.HOMEDATA,'PropagatedLabels'));
end;

timeFileStr = fopen(fullfile(SPparam.HOMEDATA,LORparam.testName,...
    ['label_propagataion_time_one2one_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
    '_w_Q_' num2str(LORparam.w_Q) '_w_U_' num2str(LORparam.w_U)...
    '_K_' num2str(SPparam.K) '.txt']),'w');

pfig = ProgressBar('Label Propagation');
range = 1:length(SPdata.testFileList);
for i = range
    fprintf('Test image number : %d ',i);
    [folder,onlyName] = fileparts(SPdata.testFileList{i});
    baseFileName = fullfile(folder,onlyName);
    fprintf('filename : %s\n',baseFileName);
    
    %Get Retrieval Set
    retInds = FindRetrievalSet(SPdata.trainGlobalDesc,SelectDesc(SPdata.testGlobalDesc,i,1),...
        SPparam.HOMEDATA,baseFileName,LORparam.globalDescriptors);
    
    tic;
    nWnOutFileName = fullfile(SPparam.HOMEDATA,'WeightMat',...
        [baseFileName '_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
        '_w_Q_' num2str(LORparam.w_Q) '_w_U_' num2str(LORparam.w_U)...
        '_K_' num2str(SPparam.K) '_one2one_nWn_app_geo.mat']);
    
    if ~exist(nWnOutFileName,'file')
        fprintf('%s does not exist..! exiting..\n',nWnOutFileName);
        error('Error in One2oneLabelPropagation.m');
    else
        load(nWnOutFileName,'W','D','nW','Wn','nWn','testSize','trainSize'); % W D nW Wn nWn trainingSize testSize
        
        context2ndIdx = cell(LORparam.retSetSize,1);
        context3rdIdx = cell(LORparam.retSetSize,1);
        propagatedLabels = cell(LORparam.retSetSize,1);
        reducedLabels = cell(LORparam.retSetSize,1);
        
        labelOutFileName = fullfile(SPparam.HOMEDATA,'PropagatedLabels',...
            [baseFileName '_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
            '_w_Q_' num2str(LORparam.w_Q) '_w_U_' num2str(LORparam.w_U)...
            '_K_' num2str(SPparam.K) '_lambda_' num2str(LORparam.lambda) '_one2one_propagatedLabel_app_geo.mat']);
        
        if exist(labelOutFileName,'file') && ~LORparam.recomputeLabelPropagation
            % load(labelOutFileName);
        else
            for j = 1:LORparam.retSetSize
                retSetIndex = PruneIndexNum(SPdata.trainIndex{1},retInds,j); %% check
                if isempty(retSetIndex.image)
                    propagatedLabels{j} = [];
                    reducedLabels{j} = [];
                    continue;
                end;
                reducedLabels{j} = unique(retSetIndex.label);
                
                % mask is not needed
                %                 mask = false(trainSize,trainSize);
                %                 for l = 1:max(retSetIndex.image) % build mask to remove inter-context between image
                %                     mask(retSetIndex.image == l,retSetIndex.image == l) = 1;
                %                 end;
                
                context2ndIdx{j}  = ones(length(reducedLabels{j}),length(reducedLabels{j}));
                context3rdIdx{j}  = ones(length(reducedLabels{j}),length(reducedLabels{j}),length(reducedLabels{j}));
                propagatedLabels{j} = zeros(trainSize(j)+testSize,length(reducedLabels{j}));
                tic;
                for c_a = 1:length(reducedLabels{j})
                    for c_b = 1:length(reducedLabels{j})
                        for c_c = 1:length(reducedLabels{j})
                            %                                 fprintf(1,'%s %s\n',Labels{labelType}{a},Labels{labelType}{b});
                            % Build context link matrix
                            A = [(retSetIndex.label == reducedLabels{j}(c_a)) zeros(1,testSize)];
                            B = [(retSetIndex.label == reducedLabels{j}(c_b)) zeros(1,testSize)];
                            C = [(retSetIndex.label == reducedLabels{j}(c_c)) zeros(1,testSize)];
                            if sum(A) == 0 || sum(B) == 0 % no 2nd-order context
                                context2ndIdx{j}(c_a,c_b) = 0;
                            end;
                            if sum(A) == 0 || sum(B) == 0 || sum(C) == 0 % no 3rd-order context
                                context3rdIdx{j}(c_a,c_b,c_c) = 0;
                            end;
                        end;
                    end;
                end;
                for c_a = 1:length(reducedLabels{j})
                    A = [(retSetIndex.label == reducedLabels{j}(c_a)) zeros(1,testSize)];
                    if sum(A) ~= 0
                        Fh = (D{j} - W{j} + LORparam.lambda*eye(testSize + trainSize(j))) \ A';
                        propagatedLabels{j}(:,c_a) = Fh; % store all for score computation
                    end;
                end;
            end; % for each candidate image
            
            labelPropagationTime = toc;
            fprintf(timeFileStr,'%d ',labelPropagationTime);
            for j = 1:LORparam.retSetSize
                fprintf(timeFileStr,'%d ',trainSize(j)+testSize);
                fprintf(timeFileStr,'%d ',length(reducedLabels{j}));
            end;
            fprintf(timeFileStr,'\n');
            
            make_dir(labelOutFileName);
            save(labelOutFileName,'context2ndIdx','context3rdIdx','propagatedLabels','reducedLabels','testSize','-v7.3');
        end;
    end;
    ProgressBar(pfig,find(i==range),length(range));
end;

close(pfig); fclose(timeFileStr);

return;