#include "mex.h"
#include "./QPBO-v1.3/QPBO.h"

#include <ctime>
#include <algorithm>
#include <vector>

typedef double REAL;

bool dataFlag;
REAL* data;
REAL** unfoldPropagatedLabels;

int numSites = NULL;
int numLabels = NULL;
int retSetSize = NULL;

REAL SCORE_MAX = 200;
REAL alpha = 1;
int numIter = 5;
bool dispLabelsFlag = false;


REAL dCost(int s_i, int c_i)
{
    return data[c_i*numSites+s_i];
}

REAL hnCost(int s_i, int s_j, int s_k, int c_i, int c_j, int c_k)
{
    REAL score = 0;
    for ( int retSetIdx = 0; retSetIdx < retSetSize; ++retSetIdx ) {
        if ( score < unfoldPropagatedLabels[retSetIdx][c_i * numSites + s_i] * unfoldPropagatedLabels[retSetIdx][c_j * numSites + s_j] * unfoldPropagatedLabels[retSetIdx][c_k * numSites + s_k] ) {
            score = unfoldPropagatedLabels[retSetIdx][c_i * numSites + s_i] * unfoldPropagatedLabels[retSetIdx][c_j * numSites + s_j] * unfoldPropagatedLabels[retSetIdx][c_k * numSites + s_k];
        }
    }
    
    if ( score == 0 ) {
        return alpha;
    } else {
        return alpha * (-log(score) / SCORE_MAX);
    }
}

REAL computeDataNonsmoothHighorderICM( int* functional, int numLabels, int numSites );

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
        mexErrMsgIdAndTxt("mexLOROptUndirectedHighorderMaxICM:main", "Must have three input");
    
    if ( nlhs != 2 )
        mexErrMsgIdAndTxt("mexLOROptUndirectedHighorderMaxICM:main", "Must have two output");
    
    // check unfoldPropagatedLabels
    if ( !mxIsCell(prhs[0]) )
        mexErrMsgTxt("First input expects cell");
    
    // check unfoldPropagatedLabels - omitted
    int         nsubs = 2; // prhs[0] = retSetSize X 1 cell
    int         subs[] = {0,0};
    
    // check params
    if ( mxIsCell(prhs[2]) )
        mexErrMsgTxt("Third input not expects cell");
    
    //mexPrintf("%d",mxGetNumberOfDimensions(prhs[1]));
    if ( mxGetNumberOfDimensions(prhs[2]) != 2 ) {
        mexErrMsgTxt("Third input should be [maxHighOrderObjRelVal minHighOrderObjRelVal alpha numIter dispLabelsFlag]");
    } else {
        const int* paramSubDims = mxGetDimensions(prhs[2]);
        //mexPrintf("%d %d  - Empty\n",paramSubDims[0],paramSubDims[1]);
        if ( paramSubDims[0] != 1 || paramSubDims[1] != 5 ) {
            mexErrMsgTxt("Third input should be [maxHighOrderObjRelVal minHighOrderObjRelVal alpha numIter dispLabelsFlag]");
        }
    }
    
    /* get param */
    REAL* maxMinAlphaIterValFlag = (REAL *)mxGetData(prhs[2]);
    SCORE_MAX = maxMinAlphaIterValFlag[0];
    alpha = maxMinAlphaIterValFlag[2];
    numIter = maxMinAlphaIterValFlag[3];
    dispLabelsFlag = maxMinAlphaIterValFlag[4];
    
    int         index;
    mxArray     *unfoldPropagatedLabelsSubPtr;
    
    /* get input arguments */
    retSetSize = (int)(double)mxGetNumberOfElements(prhs[0]);
    
    int unfoldPropagatedLabelsSubsNDim;
    const int* unfoldPropagatedLabelsSubsDims;
    unfoldPropagatedLabels = new REAL*[retSetSize];
    
    /* get unfoldPropagatedLabels */
    numSites = NULL;
    for ( int i = 0; i < retSetSize; ++i ) {
        subs[0] = i;
        subs[1] = 0;
        index = mxCalcSingleSubscript(prhs[0],nsubs,subs);
        unfoldPropagatedLabelsSubPtr = mxGetCell(prhs[0],index);
        //mexPrintf("index: %i\n",i);
        //mexPrintf("index: %i\n",index);
        
        if ( unfoldPropagatedLabelsSubPtr != NULL ) { // Do not use mxIsEmpty(unfoldPropagatedLabelsSubPtr)
            unfoldPropagatedLabelsSubsNDim = mxGetNumberOfDimensions(unfoldPropagatedLabelsSubPtr);
            unfoldPropagatedLabelsSubsDims = mxGetDimensions(unfoldPropagatedLabelsSubPtr);
            unfoldPropagatedLabels[i] = (REAL*)mxGetData(unfoldPropagatedLabelsSubPtr);
            
            // omitted exception:
            if ( unfoldPropagatedLabelsSubsNDim != 2 )
                mexErrMsgTxt("Not unfoldPropagatedLabels score");
            
            // unfoldPropagatedLabelsSubsNDim = 2
            if ( numSites == NULL || numLabels == NULL ) {
                numSites = unfoldPropagatedLabelsSubsDims[0];
                numLabels = unfoldPropagatedLabelsSubsDims[1];
                //                 mexPrintf("%i\n",numSites);
            }
            
            //             if ( i == 0 ) {
            //                 mexPrintf("%d %d  - Empty\n",unfoldPropagatedLabelsSubsDims[0],unfoldPropagatedLabelsSubsDims[1]);
            //                 for ( int k = 0; k < unfoldPropagatedLabelsSubsDims[0]; ++k ) {
            //                     for ( int l = 0; l < unfoldPropagatedLabelsSubsDims[1]; ++l ) {
            //                         mexPrintf("%e ",unfoldPropagatedLabels[i][k*unfoldPropagatedLabelsSubsDims[1] + l]);
            //                     }
            //                     mexPrintf("\n");
            //                 }
            //             }
        } else {
            unfoldPropagatedLabels[i] = NULL;
            //mexPrintf("  - Empty\n");
        }
    }
    
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
        
        dataFlag = true;
    }
    
    // check numSites
    //mexPrintf("%i\n",numSites);
    
    /* define QPBO */
    if ( dispLabelsFlag )
        mexPrintf("*******Started ICM *****\n");
    
    int* functional = new int[numSites];
    
    srand(unsigned(time(NULL)));
    
    for ( int i = 0; i < numSites; ++i ) {
        //         if ( dataFlag == true ) {
        //             // Assign initial state using dataCost
        //             int minimum = 0;
        //             double minVal = DBL_MAX;
        //
        //             for ( int k = 0; k < numLabels; ++k ) {
        //                 if ( dCost(i,k) < minVal ) {
        //                     minVal = dCost(i,k);
        //                     minimum = k;
        //                 }
        //             }
        //             functional[i] = minimum;
        //         } else {
        // Randomly selected initial state
        functional[i] = rand() % numLabels;
        //         }
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
        functionalEnergy = computeDataNonsmoothHighorderICM(functional,numLabels,numSites);
    }
    //computeSampling(functional,numLabels,numSites,out_fname);
    
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
    delete[] unfoldPropagatedLabels;
}

// Function to compute ICM easy
REAL computeDataNonsmoothHighorderICM( int* functional, int numLabels, int numSites )
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
                for ( int f_new = 0; f_new < numLabels; ++f_new ) {
                    totalEh[f_new] += dCost(i_new,f_new);
                }
            }
        }
        
        for ( int j = 0; j < numSites; ++j ) {
            for ( int k = 0; k < numSites; ++k ) {
                for ( int f_new = 0; f_new < numLabels; ++f_new ) {
                    if ( i_new != j && j != k && i_new != k ) {
                        totalEh[f_new] += hnCost(i_new,j,k,f_new,functional[j],functional[k]) / 6;
                    }
                }
            }
        }
        
        for ( int j = 0; j < numSites; ++j ) {
            for ( int k = 0; k < numSites; ++k ) {
                for ( int f_new = 0; f_new < numLabels; ++f_new ) {
                    if ( i_new != j && j != k && i_new != k ) {
                        totalEh[f_new] += hnCost(j,i_new,k,functional[j],f_new,functional[k]) / 6;
                    }
                }
            }
        }
        
        for ( int j = 0; j < numSites; ++j ) {
            for ( int k = 0; k < numSites; ++k ) {
                for ( int f_new = 0; f_new < numLabels; ++f_new ) {
                    if ( i_new != j && j != k && i_new != k ) {
                        totalEh[f_new] += hnCost(j,k,i_new,functional[j],functional[k],f_new) / 6;
                    }
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