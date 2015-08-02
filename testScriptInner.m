% Construct segment graph
fprintf('**************************************************\n');
fprintf('****** Construct segment graph\n');
fprintf('**************************************************\n');
SegmentGraphConstruction(SPdata,SPparam,LORparam);
fprintf('\n');

% Do label propagation
fprintf('**************************************************\n');
fprintf('****** Do second-order object relations propagation\n');
fprintf('**************************************************\n');
% LORparam.recomputeLabelPropagation = 1;
SecondOrderObjRelPropagation(SPdata,SPparam,LORparam);
fprintf('\n');

% Parsing image
fprintf('**************************************************\n');
fprintf('****** Parsing image\n');
fprintf('**************************************************\n');
% DataTest(SPdata,SPparam,LORparam);
% NonsmoothPairwiseTest(SPdata,SPparam,LORparam);
DataNonsmoothPairwiseTest(SPdata,SPparam,LORparam);
LORparam.beta = 0.5;
% DataSmoothPairwiseTest(SPdata,SPparam,LORparam);
DataNonsmoothAndSmoothPairwiseTest(SPdata,SPparam,LORparam);
fprintf('\n');

% Evaluate performance
fprintf('**************************************************\n');
fprintf('****** Evaluate performance\n');
fprintf('**************************************************\n');
EvaluateTests(LORparam.HOMEDATA,LORparam.HOMELABELSETS,{LORparam.testName},[],[],[],LORparam.outFileSuffix);
fprintf('\n');

% Generate result images and web page
fprintf('**************************************************\n');
fprintf('****** Generate result images and web page \n');
fprintf('**************************************************\n');
LORGenerateResultImages(SPdata,SPparam);
LORGenerateSimpleSelectedWeb(SPdata,SPparam);
fprintf('\n');