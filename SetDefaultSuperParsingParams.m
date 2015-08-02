function [SPparam] = SetDefaultSuperParsingParams(HOME,DATASET,testName,testSetName)

SPparam.SPCODE = fullfile(pwd,'im_parser');

SPparam.HOME = HOME;
SPparam.DATASET = DATASET;
SPparam.HOMEDATA = fullfile(HOME,DATASET);

SPparam.HOMEIMAGES = fullfile(SPparam.HOMEDATA,'Images');
SPparam.HOMEANNOTATIONS = fullfile(SPparam.HOMEDATA,'Annotations');
SPparam.HOMELABELSETS = {fullfile(SPparam.HOMEDATA,'SemanticLabels')};

SPparam.testName = testName;
SPparam.testSetName = testSetName;
SPparam.HOMETESTDATA = fullfile(SPparam.HOMEDATA,testName);

SPparam.UseLabelSet = [1];
SPparam.UseClassifier = [0];

SPparam.globalDescriptors = {'spatialPryScaled','colorGist','coHist'};

% superpixel parameter
SPparam.K = 200;
SPparam.segSuffix = [];

SPparam.segmentDescriptors = {
    'centered_mask_sp', 'bb_extent', 'pixel_area', ...  % Shape
    'absolute_mask', 'top_height',... % Location
    'int_text_hist_mr','dial_text_hist_mr',... % Texture
    'sift_hist_int_','sift_hist_dial','sift_hist_bottom','sift_hist_top','sift_hist_right','sift_hist_left'... % SIFT
    'mean_color','color_std','color_hist','dial_color_hist',... % Color
    'color_thumb','color_thumb_mask','gist_int'}; % Appearance

% Naive bayesian classifier parameters (Tighe and Lazebnik, ECCV'10)
SPparam.retSetSize = 200;               % # of retrieved image
SPparam.minSPinRetSet = 1500;        % minimum number of superpixel
SPparam.targetNN = 20;

% MRF parameters
SPparam.LabelSmoothing = [0, 8];
SPparam.LabelPenality = {'conditional'};
SPparam.InterLabelSmoothing = [0, 8];
SPparam.InterLabelPenality = {'pots','conditional'};

SPparam.claParams.stopval = .001;
SPparam.claParams.num_iterations = 100;
SPparam.claParams.subSample = 0;
SPparam.claParams.balancedsubSample = 1;
SPparam.claParams.testsetnum = 1;
SPparam.claParams.init_weight = 'cFreq';

SPparam.claParams.num_nodes = 8;
SPparam.claParams.K = SPparam.K;
SPparam.claParams.segSuffix = SPparam.segSuffix;
SPparam.claParams.segmentDescriptors = SPparam.segmentDescriptors;

disp(SPparam);

return;