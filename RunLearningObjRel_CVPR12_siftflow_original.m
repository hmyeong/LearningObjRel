HOME = 'D:\Works';
dbName = 'SiftFlowDataset_original';
testName = 'testDP';
testSetName = 'TestSet1';

% Add library
fprintf('**************************************************\n');
fprintf('****** Add library\n');
fprintf('**************************************************\n');
HOMECODE = fullfile(pwd,'im_parser');
addpath(HOMECODE);  % the code of Tighe and Lazebnik
addpath(fullfile(pwd,'pwmetric')); % for fast metric computation
tmp = pwd; slmetric_pw_compile; cd(tmp); % compile pwmetric
compileLOROptUndirectedQPBO; % compile mexOpt
compilePottsOptQPBO; % compile mexOpt
fprintf('\n');

% Set Environment for the code of Tighe and Lazebnik
SetupEnv;

% Set default parameters for the code of Tighe and Lazebnik
fprintf('**************************************************\n');
fprintf('****** Set default parameters for SuperParsing\n');
fprintf('**************************************************\n');
SPparam = SetDefaultSuperParsingParams(HOME,dbName,testName,testSetName);
SPparam.globalDescriptors = {'spatialPryScaled','colorGist','tinyIm','coHist'};
fprintf('\n');

% Run the preprocessing stage for the code of Tighe and Lazebnik
fprintf('**************************************************\n');
fprintf('****** Run the preprocessing stage for SuperParsing\n');
fprintf('**************************************************\n');
SPdata = SuperParsingPreprocessing(SPparam);
fprintf('\n');

% Set default parameters for learning object relationships
fprintf('**************************************************\n');
fprintf('****** Set default parameters for LearningObjRel\n');
fprintf('**************************************************\n');
LORparam = SetDefaultLearningObjRelParams(SPparam);
LORparam.lambda = 0.9; % CVPR'12
fprintf('\n');

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