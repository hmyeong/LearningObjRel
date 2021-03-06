HOME = 'D:\Works';
dbName = 'SampleDataSet';
testName = 'testD_';
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
fprintf('\n');

% Construct segment graph
fprintf('**************************************************\n');
fprintf('****** Construct segment graph\n');
fprintf('**************************************************\n');
One2oneSegmentGraphConstruction(SPdata,SPparam,LORparam);
fprintf('\n');

% Do label propagation
fprintf('**************************************************\n');
fprintf('****** Do label propagation\n');
fprintf('**************************************************\n');
One2oneLabelPropagation(SPdata,SPparam,LORparam);
fprintf('\n');

% Parsing image
fprintf('**************************************************\n');
fprintf('****** Parsing image\n');
fprintf('**************************************************\n');
DataTest(SPdata,SPparam,LORparam);
One2onePropagatedLabelSumTest(SPdata,SPparam,LORparam);
One2onePropagatedLabelMaxTest(SPdata,SPparam,LORparam);
One2oneNonsmoothPairwiseMaxTest(SPdata,SPparam,LORparam);
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