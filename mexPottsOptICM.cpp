#include "mex.h"
#include "./QPBO-v1.3/QPBO.h"

#include <ctime>
#include <algorithm>
#include <vector>

typedef double REAL;

bool dataFlag;
REAL* data;
int* adjPairs;

int numSites = NULL;
int numLabels = NULL;
int numEdges = NULL;

REAL beta = 1;
int numIter = 5;
bool dispLabelsFlag = false;

REAL dCost(int s_i, int c_i)
{
    return data[c_i*numSites+s_i];
}

REAL computeDataSmoothPairwiseICM( int* functional, int numLabels, int numSites );

/*
 * main enterance point
 */
void mexFunction(
        int		  nlhs, 	/* number of expected outputs */
        mxArray	  *plhs[],	/* mxArray output pointer array */
        int		  nrhs, 	/* number of inputs */
        const mxArray	  *prhs[]	/* mxArray input pointer array */
        ) {
    if ( nrhs != 3 )
        mexErrMsgIdAndTxt("mexPottsOptICM:main", "Must have three input");
    
    if ( nlhs != 2 )
        mexErrMsgIdAndTxt("mexPottsOptICM:main", "Must have two output");
    
    // check params
    if ( mxIsCell(prhs[2]) )
        mexErrMsgTxt("Third input not expects cell");
    
    //mexPrintf("%d",mxGetNumberOfDimensions(prhs[1]));
    if ( mxGetNumberOfDimensions(prhs[2]) != 2 ) {
        mexErrMsgTxt("Third input should be [beta numIter dispLabelsFlag]");
    } else {
        const int* paramSubDims = mxGetDimensions(prhs[2]);
        //mexPrintf("%d %d  - Empty\n",paramSubDims[0],paramSubDims[1]);
        if ( paramSubDims[0] != 1 || paramSubDims[1] != 3 ) {
            mexErrMsgTxt("Third input should be [beta numIter dispLabelsFlag]");
        }
    }
    
    /* get param */
    REAL* betaIterFlag = (REAL *)mxGetData(prhs[2]);
    beta = betaIterFlag[0];
    numIter = betaIterFlag[1];
    dispLabelsFlag = betaIterFlag[2];
    
    /* get adjacent pairs */
    int adjPairsNDim = mxGetNumberOfDimensions(prhs[0]);
    const int *adjPairsDims = mxGetDimensions(prhs[0]);
    adjPairs = (int*)mxGetData(prhs[0]);
    
    /* get input arguments */
    numEdges = adjPairsDims[0];
    
    /* get data cost */
    if ( mxIsEmpty(prhs[1]) ) {
        dataFlag = false;
    } else {
        int dataNDim = mxGetNumberOfDimensions(prhs[1]);
        const int *dataDims = mxGetDimensions(prhs[1]);
        data = (REAL*)mxGetData(prhs[1]);
        
        //         mexPrintf("%i\n",dataNDim);
        //         mexPrintf("%i %i\n",dataDims[0],dataDims[1]);
        //         mexPrintf("%e %e\n",data[0],data[1]);
        
        /* get input arguments */
        numSites = dataDims[0];
        numLabels = dataDims[1];
        
        dataFlag = true;
    }
    
    // check numSites
    //mexPrintf("%i\n",numSites);
    
    /* define QPBO */
    if ( dispLabelsFlag )
        mexPrintf("*******Started ICM *****\n");
    
    int* functional = new int[numSites];
    
    srand (unsigned(time(NULL)));
    
    for ( int i = 0; i < numSites; ++i ) {
        //if ( dataFlag == true ) {
        //    // Assign initial state using dataCost
        //    int minimum = 0;
        //    double minVal = DBL_MAX;
        //
        //    for ( int k = 0; k < numLabels; ++k ) {
        //        if ( dCost(i,k) < minVal ) {
        //            minVal = dCost(i,k);
        //            minimum = k;
        //        }
        //    }
        //    functional[i] = minimum;
        //} else {
        // Randomly selected initial state
        functional[i] = rand() % numLabels;
        //}
    }
    
    if ( dispLabelsFlag ) {
        // show result
        for ( int i = 0; i < numSites; ++i ) {
            mexPrintf("%d ",functional[i]+1);
        }
        mexPrintf("\n");
    }
    
    REAL functionalEnergy;
    for ( int i = 0; i < numIter; ++i ) {
        functionalEnergy = computeDataSmoothPairwiseICM(functional,numLabels,numSites);
    }
    
    if ( dispLabelsFlag )
        mexPrintf("*******End ICM *****\n");
    
    // First - output generation
    int disp_dims[] = {numSites};
    //mexPrintf("%i\n", numSites);
    plhs[0] = mxCreateNumericArray(1, disp_dims, mxINT32_CLASS, mxREAL);
    int* plabels = (int*)mxGetData(plhs[0]);
    for ( int i = 0; i < numSites; i++ )
        plabels[i] = functional[i] + 1;
    
    int energy_dims[] = {1};
    plhs[1] = mxCreateNumericArray(1, energy_dims, mxDOUBLE_CLASS, mxREAL);
    double* energy = (double*)mxGetData(plhs[1]);
    energy[0] = functionalEnergy;
    
    // deallocation
    delete[] functional;
    //for ( int i = 0; i < numLabels * numLabels; ++i ) {
    //    delete[] unfoldPropagatedLabels[i];
    //}
}

// Function to compute ICM easy
REAL computeDataSmoothPairwiseICM( int* functional, int numLabels, int numSites )
{
    //     mexPrintf("HO_MAX:%e\n",HO_MAX);
    //     mexPrintf("\n");
    
    std::vector<int> myvector;
    std::vector<int>::iterator it;
    
    srand (unsigned(time(NULL)));
    
    // set some values:
    for ( int i=0; i<numSites; ++i ) myvector.push_back(i); // 1 2 3 4 5 6 7 8 9 ~ numSites
    
    // using built-in random generator:
    random_shuffle(myvector.begin(), myvector.end());
    
    REAL functionalEnergy;
    
    for ( it=myvector.begin(); it!=myvector.end(); ++it ) {
        int i_new = *it;
        
        // ComputeE
        REAL *totalEh = new REAL[numLabels];
        for ( int j = 0; j < numLabels; ++j ) {
            totalEh[j] = 0;
        }
        
        if ( dataFlag ) {
            for ( int j = 0; j < numSites; ++j ) {
                if ( j != i_new ) {
                    for ( int f_new = 0; f_new < numLabels; ++f_new )
                        totalEh[f_new] += dCost(j,functional[j]);
                } else {
                    for ( int f_new = 0; f_new < numLabels; ++f_new )
                        totalEh[f_new] += dCost(j,f_new);
                }
            }
        }
        
        // For each edge pair
        for ( int i = 0; i < numEdges; ++i ) {
            int e_i = adjPairs[i] - 1;
            int e_j = adjPairs[numEdges + i] - 1;
            
            if ( e_i < e_j ) {
                if ( e_i != i_new && e_j != i_new ) {
                    for ( int f_new = 0; f_new < numLabels; ++f_new )
                        if ( functional[e_i] != functional[e_j] ) totalEh[f_new] += beta;
                } else if ( e_i == i_new ) {
                    for ( int f_new = 0; f_new < numLabels; ++f_new )
                        if ( f_new != functional[e_j] ) totalEh[f_new] += beta;
                } else if ( i_new == e_j ) {
                    for ( int f_new = 0; f_new < numLabels; ++f_new )
                        if ( functional[e_i] != f_new ) totalEh[f_new] += beta;
                }
            }
        }
        
        // find max
        REAL minEh = 1e+100;
        int minEhIdx = -1;
        for ( int j = 0; j < numLabels; ++j ) {
            if ( totalEh[j] < minEh ) {
                minEh = totalEh[j];
                minEhIdx = j;
            }
        }
        
        if ( minEhIdx == -1 ) {
            mexPrintf("minEhIdx error!!");
        }
        
        //         mexPrintf("i_new: %d f_new: %d minEh: %e\n",i_new+1,minEhIdx+1,minEh);
        
        // update
        functional[i_new] = minEhIdx;
        functionalEnergy = minEh;
        
        delete[] totalEh;
    }
    
    if ( dispLabelsFlag ) {
        // show result
        for ( int i = 0; i < numSites; ++i ) {
            mexPrintf("%d ",functional[i]+1);
        }
        mexPrintf("\n");
    }
    
    return functionalEnergy;
}