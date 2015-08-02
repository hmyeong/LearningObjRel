function [] = SecondOrderObjRelPropagation(SPdata,SPparam,LORparam)

if ~exist(fullfile(SPparam.HOMEDATA,'SecondOrderObjRel'),'dir')
    mkdir(fullfile(SPparam.HOMEDATA,'SecondOrderObjRel'));
end;

timeFileStr = fopen(fullfile(SPparam.HOMEDATA,LORparam.testName,...
    ['secondOrderObjRel_propagataion_time_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
    '_w_Q_' num2str(LORparam.w_Q) '_w_U_' num2str(LORparam.w_U)...
    '_K_' num2str(SPparam.K) '.txt']),'w');

pfig = ProgressBar('Second-Order Object Relations Propagation');
range = 1:length(SPdata.testFileList);
for i = range
    fprintf('Test image number : %d ',i);
    [folder,onlyName] = fileparts(SPdata.testFileList{i});
    baseFileName = fullfile(folder,onlyName);
    fprintf('filename : %s\n',baseFileName);
    
    tic;
    nWnOutFileName = fullfile(SPparam.HOMEDATA,'WeightMat',...
        [baseFileName '_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
        '_w_Q_' num2str(LORparam.w_Q) '_w_U_' num2str(LORparam.w_U)...
        '_K_' num2str(SPparam.K) '_nWn_app.mat']);
    
    if ~exist(nWnOutFileName,'file')
        fprintf('%s does not exist..! exiting..\n',nWnOutFileName);
        error('Error in SecondOrderObjRelPropagation.m');
    else
        objRelOutFileName = fullfile(SPparam.HOMEDATA,'SecondOrderObjRel',...
            [baseFileName '_retSetSize_' num2str(LORparam.retSetSize) '_kNN_' num2str(LORparam.kNN)...
            '_w_Q_' num2str(LORparam.w_Q) '_w_U_' num2str(LORparam.w_U)...
            '_K_' num2str(SPparam.K) '_lambda_' num2str(LORparam.lambda) '_secondOrderObjRel_app.mat']);
        
        if exist(objRelOutFileName,'file') && ~LORparam.recomputeLabelPropagation
            % load(objRelOutFileName);
        else
            load(nWnOutFileName,'W','D','nW','Wn','nWn','testSize','trainSize'); % W D nW Wn nWn trainingSize testSize
            
            %Get Retrieval Set
            retInds = FindRetrievalSet(SPdata.trainGlobalDesc,SelectDesc(SPdata.testGlobalDesc,i,1),...
                SPparam.HOMEDATA,baseFileName,LORparam.globalDescriptors);
            
            retSetIndex = PruneIndex(SPdata.trainIndex{1},retInds,LORparam.retSetSize,LORparam.minSPinRetSet); %% check
            
            mask = false(trainSize,trainSize);
            for l = 1:max(retSetIndex.image) % build mask to remove inter-context between image
                mask(retSetIndex.image == l,retSetIndex.image == l) = 1;
            end;
            
            secondOrderObjRel = cell(length(SPdata.Labels{1,1})); % note: Labels{1,1} = Labels{labelType,Kndx}
            tic;
            for c_a = 1:length(SPdata.Labels{1,1}) % note: Labels{1,1} = Labels{labelType,Kndx}
                for c_b = 1:length(SPdata.Labels{1,1}) % note: Labels{1,1} = Labels{labelType,Kndx}
                    
                    % Build observed second-order object relations matrix
                    A = (retSetIndex.label == c_a);
                    B = (retSetIndex.label == c_b);
                    if sum(A) == 0 || sum(B) == 0 % no second-order object relations
                        continue;
                    else
                        c_b_idx = find(retSetIndex.label == c_b);
                        Q_ab = sparse(double(A))' * sparse(double(B));
                        Q_ab(~mask) = 0;
                        
                        % check whether no context
                        if sum(Q_ab(:)) == 0
                            continue;
                        end;
                        
                        if c_a == c_b
                            Q_ab = Q_ab - diag(diag(Q_ab)); % make diagonal 0
                            % In case of siftflow class 20, only one labeled segment exist
                            % Hence, it failed
                        end;
                        
                        % recalculate if failed
                        if sum(Q_ab(:)) == 0
                            Q_ab = sparse(double(A))' * sparse(double(B));
                            Q_ab(~mask) = 0;
                        end; % no second-order object relations
                        
                        % rank-one reduction!!
                        [~,m_c_b_idx,n_c_b_idx] = unique(retSetIndex.image(c_b_idx));
                        reducedQ = [Q_ab(:,c_b_idx(m_c_b_idx)); zeros(testSize,size(c_b_idx(m_c_b_idx),2))];
                        
                        % Column-wise prediction
                        Fh = zeros(size(reducedQ));
                        for t = 1:20
                            Fh = (1-LORparam.lambda) * nWn * Fh + LORparam.lambda *  reducedQ*diag(1./sum(reducedQ)); % divide by # of labels
                            %Fh = (1-LORparam.lambda) * nWn * Fh + LORparam.lambda *  reducedQ; % w/o normalization
                        end;
                        
                        predictedCol = Fh(trainSize+1:end,:);
                        %                                     testColumnPrediction
                        
                        count = zeros(size(m_c_b_idx));
                        count(1) = m_c_b_idx(1);
                        for countIndex = 2:length(m_c_b_idx)
                            count(countIndex) = m_c_b_idx(countIndex) - m_c_b_idx(countIndex-1);
                        end;
                        
                        % Row-wise prediction
                        conv_Fh = zeros(testSize,trainSize+testSize);
                        for idx = 1:length(c_b_idx)
                            conv_Fh(:,c_b_idx(idx)) = 1/count(n_c_b_idx(idx))*predictedCol(:,n_c_b_idx(idx)); % divide by the number of b
                            %conv_Fh(:,c_b_idx(idx)) = predictedCol(:,n_c_b_idx(idx)); % w/o normalization
                        end;
                        
                        Fv = zeros(size(conv_Fh));
                        for t = 1:20
                            Fv = (1-LORparam.lambda) * Fv * nWn + LORparam.lambda * conv_Fh;
                        end;
                        
                        secondOrderObjRel{c_a,c_b} = Fv(:,trainSize+1:end);
                    end;
                end;
            end;
            
            secondOrderObjRelPropagationTime = toc;
            fprintf(timeFileStr,'%d ',secondOrderObjRelPropagationTime);
            fprintf(timeFileStr,'\n');
            
            make_dir(objRelOutFileName);
            save(objRelOutFileName,'secondOrderObjRel','-v7.3');
        end;
    end;
    ProgressBar(pfig,find(i==range),length(range));
end;

close(pfig); fclose(timeFileStr);

return;