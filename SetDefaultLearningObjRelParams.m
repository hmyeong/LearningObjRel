function [LORparam] = SetDefaultLearningObjRelParams(SPparam)

LORparam.HOMEDATA = SPparam.HOMEDATA;

LORparam.HOMEIMAGES = SPparam.HOMEIMAGES;
LORparam.HOMEANNOTATIONS = SPparam.HOMEANNOTATIONS;
LORparam.HOMELABELSETS = SPparam.HOMELABELSETS;

LORparam.testName = SPparam.testName;
LORparam.testSetName = SPparam.testSetName;
LORparam.HOMETESTDATA = SPparam.HOMETESTDATA;

LORparam.globalDescriptors = {'spatialPryScaled','colorGist','coHist'};

LORparam.segmentDescriptors = {
    'centered_mask_sp', 'bb_extent', 'pixel_area', ...  % Shape
    'absolute_mask', 'top_height',... % Location
    'int_text_hist_mr','dial_text_hist_mr',... % Texture
    'sift_hist_int_','sift_hist_dial','sift_hist_bottom','sift_hist_top','sift_hist_right','sift_hist_left'... % SIFT
    'mean_color','color_std','color_hist','dial_color_hist',... % Color
    'color_thumb','color_thumb_mask','gist_int'}; % Appearance

% Retrieval parameters
LORparam.retSetSize = 40;
LORparam.minSPinRetSet = 100;

% Graph construction parameters
LORparam.w_Q = 1;
LORparam.w_U = 1;
LORparam.kNN = 100; % 0: fully-connected, not implemented
LORparam.reconstructGraph = 0;

% Label propagation parameters
LORparam.lambda = 100; % different meaning for CVPR'12 and CVPR'13 version
LORparam.recomputeLabelPropagation = 0;

% Optimization with QPBO parameters
LORparam.alpha = 3;
LORparam.numQPBOIter = 3;
LORparam.numMultiStart = 100;
LORparam.recomputeSolutionWithQPBO = 0;

LORparam.outFileSuffix = 'LearningObjRel';

disp(LORparam);

return;