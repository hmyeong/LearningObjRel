Learning Object Relationships for Semantic Scene Segmentation

INSTALL
--------------------------------------------------------------------------------------------------------------
This code was tested in MATLAB 2013b under Windows 8 64-bit.

You need to download the following software:

a) image parser by J. Tighe and S. Lazebnik
http://www.cs.unc.edu/~jtighe/Papers/ECCV10/eccv10-jtighe-code.zip

b) pwmetric by D. Lin
http://www.mathworks.com/matlabcentral/fileexchange/15935-computing-pairwise-distances-and-metrics

c) QPBO v1.3 by V. Kolmogorov
http://pub.ist.ac.at/~vnk/software/QPBO-v1.3.src.tar.gz

EXAMPLE
--------------------------------------------------------------------------------------------------------------
Before starting the codes, you should set up the path in the following m files.

For the experiment in the Siftflow dataset (CVPR2012)
	RunLearningObjRel_CVPR12_siftflow.m

For the experiment in the Siftflow dataset (CVPR2013)
	RunLearningObjRel_CVPR13_siftflow.m

REFERENCES
--------------------------------------------------------------------------------------------------------------
Please acknowledge the use of our code with a citation:

Heesoo Myeong, Ju Yong Chang, and Kyoung Mu Lee, Learning Object Relationships via Graph-based Context Model, IEEE Conference on Computer Vision and Pattern Recognition (CVPR), 2012.

Heesoo Myeong and Kyoung Mu Lee, Tensor-based High-order Semantic Relation Transfer for Semantic Scene Segmentation, IEEE Conference on Computer Vision and Pattern Recognition (CVPR), 2013.


This code is largely depends on the image parser system of J. Tighe and S. Lazebnik

Joseph Tighe and Svetlana Lazebnik, SuperParsing: Scalable Nonparametric Image Parsing with Superpixels, European Conference on Computer Vision (ECCV), 2010.
