HOME = 'D:\Works';
dbName = 'SampleDataSetHighorderTest';
testName = 'testDPH';
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
compileLOROptUndirectedHighOrder; % compile mexOpt
compilePottsOptQPBO; % compile mexOpt
fprintf('\n');

% Set Environment for the code of Tighe and Lazebnik
SetupEnv;

% Set default parameters for the code of Tighe and Lazebnik
fprintf('**************************************************\n');
fprintf('****** Set default parameters for SuperParsing\n');
fprintf('**************************************************\n');
SPparam = SetDefaultSuperParsingParams(HOME,dbName,testName,testSetName);
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
LORparam.retSetSize = 16;
LORparam.alpha = 0.5;
LORparam.beta = 0.5;
LORparam.numMultiStart = 1;
LORparam.dataInitFlag = 2; % randomly mixed
LORparam.QPBOpreFlag = 1; % QPBO init
fprintf('\n');

% Construct segment graph
fprintf('**************************************************\n');
fprintf('****** Construct segment graph\n');
fprintf('**************************************************\n');
One2oneSegmentGraphConstruction(SPdata,SPparam,LORparam);
fprintf('\n');

% Do label propagation
fprintf('**************************************************\n');
fprintf('****** Do second-order object relations propagation\n');
fprintf('**************************************************\n');
% LORparam.recomputeLabelPropagation = 1;
One2oneLabelPropagation(SPdata,SPparam,LORparam);
fprintf('\n');

% Parsing image
fprintf('**************************************************\n');
fprintf('****** Parsing image\n');
fprintf('**************************************************\n');
% DataTest(SPdata,SPparam,LORparam);
% One2onePropagatedLabelSumTest(SPdata,SPparam,LORparam);
% One2onePropagatedLabelMaxTest(SPdata,SPparam,LORparam);
% One2oneNonsmoothPairwiseSumTest(SPdata,SPparam,LORparam);
% One2oneNonsmoothPairwiseMaxTest(SPdata,SPparam,LORparam);
% One2oneDataNonsmoothPairwiseSumTest(SPdata,SPparam,LORparam);
% One2oneDataNonsmoothPairwiseMaxTest(SPdata,SPparam,LORparam);
% One2oneNonsmoothHighorderMaxTest(SPdata,SPparam,LORparam);
% One2oneNonsmoothHighorderSumTest(SPdata,SPparam,LORparam);
% One2oneDataNonsmoothHighorderMaxTest(SPdata,SPparam,LORparam);
% One2oneDataNonsmoothHighorderSumTest(SPdata,SPparam,LORparam);
% DataSmoothPairwiseTest(SPdata,SPparam,LORparam);
% DataSmoothPairwiseICMTest(SPdata,SPparam,LORparam);
One2oneDataSmoothPairwiseNonsmoothHighorderMaxTest(SPdata,SPparam,LORparam);
One2oneDataSmoothPairwiseNonsmoothHighorderSumTest(SPdata,SPparam,LORparam);
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
% LORGenerateResultImages(SPdata,SPparam);
% LORGenerateSimpleSelectedWeb(SPdata,SPparam);
fprintf('\n');