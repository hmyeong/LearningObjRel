% Test script

RunLearningObjRel_CVPR12_siftflow_original;

retSetSizePool = [16 24 32 40 48];

for retSetSize = retSetSizePool
    LORparam.retSetSize = retSetSize;
    testScriptInner;
end;

kNNPool = [10 50 100 150];

for kNN = kNNPool
    LORparam.kNN = kNN;
    testScriptInner;
end;

alphaPool = [0.5 1 2 3 4 5];

for alpha = alphaPool
    LORparam.alpha = alpha;
    testScriptInner;
end;