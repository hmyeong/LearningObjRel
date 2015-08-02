#include "mex.h"
#include "./QPBO-v1.3/QPBO.h"

#include <ctime>
#include <algorithm>
#include <vector>

typedef double REAL;

bool dataFlag;
REAL* data;
REAL** secondOrderObjRel;

int numSites = NULL;
int numLabels = NULL;

REAL SCORE_MAX = 200;
REAL alpha = 1;
int numIter = 5;
bool dispLabelsFlag = false;

REAL dCost( int s_i, int c_i )
{
    return data[c_i*numSites+s_i];
}

REAL fnCost( int s_i, int s_j, int c_i, int c_j )
{
    if ( secondOrderObjRel[c_i*numLabels+c_j] == NULL ) {
        return alpha * SCORE_MAX / SCORE_MAX;
    } else {
        return alpha * (secondOrderObjRel[c_i*numLabels+c_j][s_j*numSites+s_i] + secondOrderObjRel[c_j*numLabels+c_i][s_i*numSites+s_j]) / (2*SCORE_MAX);
    }
}

REAL computeDataNonsmoothQPBO( int* functional, int numLabels, int numSites );

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
        mexErrMsgIdAndTxt("mexLOROptUndirectedQPBO:main", "Must have three input");
    
    if ( nlhs != 2 )
        mexErrMsgIdAndTxt("mexLOROptUndirectedQPBO:main", "Must have two output");
    
    // check secondOrderObjRel
    if ( !mxIsCell(prhs[0]) )
        mexErrMsgTxt("First input expects cell");
    
    // check secondOrderObjRel - omitted
    int         nsubs = 2; // prhs[0] = numLabels X numLabels cell
    int         subs[] = {0,0};
    
    // check params
    if ( mxIsCell(prhs[2]) )
        mexErrMsgTxt("Third input not expects cell");
    
    //mexPrintf("%d",mxGetNumberOfDimensions(prhs[1]));
    if ( mxGetNumberOfDimensions(prhs[2]) != 2 ) {
        mexErrMsgTxt("Third input should be [maxSecondOrderObjRelVal minSecondOrderObjRelVal alpha numIter dispLabelsFlag]");
    } else {
        const int* paramSubDims = mxGetDimensions(prhs[2]);
        //mexPrintf("%d %d  - Empty\n",paramSubDims[0],paramSubDims[1]);
        if ( paramSubDims[0] != 1 || paramSubDims[1] != 5 ) {
            mexErrMsgTxt("Third input should be [maxSecondOrderObjRelVal minSecondOrderObjRelVal alpha numIter dispLabelsFlag]");
        }
    }
    
    /* get param */
    REAL* maxMinAlphaIterValFlag = (REAL *)mxGetData(prhs[2]);
    SCORE_MAX = maxMinAlphaIterValFlag[0];
    alpha = maxMinAlphaIterValFlag[2];
    numIter = maxMinAlphaIterValFlag[3];
    dispLabelsFlag = maxMinAlphaIterValFlag[4];
    
    int         index;
    mxArray     *secondOrderObjRelSubsPtr;
    
    /* get input arguments */
    numLabels = (int)sqrt((double)mxGetNumberOfElements(prhs[0]));
    
    int secondOrderObjRelSubsNDim;
    const int* secondOrderObjRelSubsDims;
    secondOrderObjRel = new REAL*[numLabels*numLabels];
    
    /* get secondOrderObjRel */
    numSites = NULL;
    for ( int i = 0; i < numLabels; ++i ) {
        subs[0] = i;
        for ( int j = 0; j < numLabels; ++j ) {
            subs[1] = j;
            index = mxCalcSingleSubscript(prhs[0],nsubs,subs);
            secondOrderObjRelSubsPtr = mxGetCell(prhs[0],index);
            //mexPrintf("index: %i %i\n",i,j);
            //mexPrintf("index: %i\n",index);
            
            if ( secondOrderObjRelSubsPtr != NULL ) { // Do not use mxIsEmpty(secondOrderObjRelSubsPtr)
                secondOrderObjRelSubsNDim = mxGetNumberOfDimensions(secondOrderObjRelSubsPtr);
                secondOrderObjRelSubsDims = mxGetDimensions(secondOrderObjRelSubsPtr);
                secondOrderObjRel[i*numLabels + j] = (REAL*)mxGetData(secondOrderObjRelSubsPtr);
                
                // omitted exception:
                if ( secondOrderObjRelSubsNDim != 2 )
                    mexErrMsgTxt("secondOrderObjRel must have two dims.");
                
                // secondOrderObjRelSubsNDim = 2
                if ( numSites == NULL && secondOrderObjRelSubsDims[0] == secondOrderObjRelSubsDims[1] ) {
                    numSites = secondOrderObjRelSubsDims[0];
                    //mexPrintf("%i\n",numSites);
                }
                
                //for ( int k = 0; k < secondOrderObjRelSubsDims[0]; ++k ) {
                //    for ( int l = 0; l < secondOrderObjRelSubsDims[1]; ++l ) {
                //        mexPrintf("%e\n",secondOrderObjRel[i*numLabels + j][k*secondOrderObjRelSubsDims[0] + l]);
                //    }
                //}
            } else {
                secondOrderObjRel[i*numLabels + j] = NULL;
                //mexPrintf("  - Empty\n");
            }
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
        mexPrintf("*******Start QPBO *****\n");
    
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
        functionalEnergy = computeDataNonsmoothQPBO(functional,numLabels,numSites);
    }
    //computeSampling(functional,numLabels,numSites,out_fname);
    
    if ( dispLabelsFlag )
        mexPrintf("*******End QPBO *****\n");
    
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
    //    delete[] secondOrderObjRel[i];
    //}
    delete[] secondOrderObjRel;
}

// Function to compute QPBO using Data + Nonsmooth
REAL computeDataNonsmoothQPBO( int* functional, int numLabels, int numSites )
{
    QPBO<REAL>* q;
    q = new QPBO<REAL>(numSites, numSites*numSites); // max number of nodes & edges
    
    std::vector<int> myvector;
    std::vector<int>::iterator it;
    
    srand (unsigned(time(NULL)));
    
    // set some values:
    for ( int i=0; i<numLabels; ++i ) myvector.push_back(i); // 1 2 3 4 5 6 7 8 9 ~ numLabels
    
    // using built-in random generator:
    random_shuffle(myvector.begin(), myvector.end());
    
    for ( it=myvector.begin(); it!=myvector.end(); ++it ) {
        int k = *it;
        
        q->Reset();
        q->AddNode(numSites); // add nodes
        
        // Add dataCost
        if ( dataFlag ) {
            for ( int i = 0; i < numSites; ++i ) {
                q->AddUnaryTerm(i,dCost(i,functional[i]),dCost(i,k));
            }
        }
        
        // For each pixel
        for ( int i = 0; i < numSites; ++i ) {
            for ( int j = 0; j < numSites; ++j ) {
                REAL E00 = DBL_MAX, E01 = DBL_MAX, E10 = DBL_MAX, E11 = DBL_MAX;
                
                E00 = fnCost(i,j,functional[i],functional[j]);
                E01 = fnCost(i,j,functional[i],k);
                E10 = fnCost(i,j,k,functional[j]);
                E11 = fnCost(i,j,k,k);
                
                if ( i != j ) { // preventing library error
                    q->AddPairwiseTerm(i, j, E00, E01, E10, E11);
                }
            }
        }
        
        q->Solve();
        q->ComputeWeakPersistencies();
        
        // Commit obtained label
        for ( int i = 0; i < numSites; ++i ) {
            if ( q->GetLabel(i) == 1 ) {
                functional[i] = k;
            }
        }
    }
    
    if ( dispLabelsFlag ) {
        // show result
        for ( int i = 0; i < numSites; ++i ) {
            mexPrintf("%d ",functional[i]+1);
        }
        mexPrintf("\n");
    }
    
    REAL functionalEnergy = q->ComputeTwiceEnergy();
    
    delete q; // memory leak problem solved!
    
    return functionalEnergy;
}