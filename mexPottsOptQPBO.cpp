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

REAL SCORE_MAX = 200;
REAL beta = 1;
int numIter = 5;
bool dispLabelsFlag = false;

REAL dCost( int s_i, int c_i )
{
    return data[c_i*numSites+s_i];
}

REAL fnCost( int s_i, int s_j, int c_i, int c_j )
{
    return 0;
}

REAL computeDataSmoothPottsQPBO( int* functional, int numLabels, int numSites, int numEdges );

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
    REAL* betaIterValFlag = (REAL *)mxGetData(prhs[2]);
    //mexPrintf("%e %e  - Empty\n",maxMinVal[0],maxMinVal[1]);
    beta = betaIterValFlag[0];
    numIter = betaIterValFlag[1];
    dispLabelsFlag = betaIterValFlag[2];
    
    /* get adjacent pairs */
    int adjPairsNDim = mxGetNumberOfDimensions(prhs[0]);
    const int *adjPairsDims = mxGetDimensions(prhs[0]);
    adjPairs = (int*)mxGetData(prhs[0]);
    
    /* get input arguments */
    numEdges = adjPairsDims[0];
    
//     mexPrintf("%i\n",adjPairsNDim);
//     mexPrintf("%i %i\n",adjPairsDims[0],adjPairsDims[1]);
//     mexPrintf("%i %i\n",adjPairs[0],adjPairs[1]);
    
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
    
    // check numX
    //mexPrintf("%i %i %i\n",numSites,numLabels,numEdges);
    
    /* define QPBO */
    if ( dispLabelsFlag )
        mexPrintf("*******Start QPBO *****\n");
    
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
        functionalEnergy = computeDataSmoothPottsQPBO(functional,numLabels,numSites,numEdges);
    }
    //computeSampling(functional,numLabels,numSites,out_fname);
    
    if ( dispLabelsFlag )
        printf("*******End QPBO *****\n");
    
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
}

// Function to compute QPBO using Data + Smooth (Potts)
REAL computeDataSmoothPottsQPBO( int* functional, int numLabels, int numSites, int numEdges )
{
    QPBO<REAL>* q;
    q = new QPBO<REAL>(numSites, numEdges); // max number of nodes & edges
    
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
        
        // For each edge pair
        for ( int i = 0; i < numEdges; ++i ) {
            int e_i = adjPairs[i] - 1;
            int e_j = adjPairs[numEdges + i] - 1;
            
            if ( e_i < e_j ) {
                REAL E00 = DBL_MAX, E01 = DBL_MAX, E10 = DBL_MAX, E11 = DBL_MAX;
                
                if ( functional[e_i] != functional[e_j] ) {
                    E00 = beta;
                } else {
                    E00 = 0;
                }
                
                if ( functional[e_i] != k ) {
                    E01 = beta;
                } else {
                    E01 = 0;
                }
                
                if ( k != functional[e_j] ) {
                    E10 = beta;
                } else {
                    E10 = 0;
                }
                
                E11 = 0;
                
                // mexPrintf("%d %d\n",e_i,e_j);
                q->AddPairwiseTerm(e_i, e_j, E00, E01, E10, E11);
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