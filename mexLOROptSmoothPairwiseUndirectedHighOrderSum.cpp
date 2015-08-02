#include "mex.h"
#include "./QPBO-v1.3/QPBO.h"

#include <ctime>
#include <algorithm>
#include <vector>

typedef double REAL;

int dataFlag = 0;
REAL* data;
int* adjPairs;
REAL** unfoldPropagatedLabels;

int numSites = NULL;
int numLabels = NULL;
int numEdges = NULL;
int retSetSize = NULL;

REAL HO_SCORE_MAX = 200;
REAL SO_SCORE_MAX = 200;
REAL alpha = 1;
REAL beta = 1;
int numIter = 5;
bool QPBOpreFlag = false;
bool dispLabelsFlag = false;

REAL dCost(int s_i, int c_i)
{
    return data[c_i*numSites+s_i];
}

REAL hnCost(int s_i, int s_j, int s_k, int c_i, int c_j, int c_k)
{
    REAL score = 0;
    for ( int retSetIdx = 0; retSetIdx < retSetSize; ++retSetIdx )
        score += unfoldPropagatedLabels[retSetIdx][c_i * numSites + s_i] * unfoldPropagatedLabels[retSetIdx][c_j * numSites + s_j] * unfoldPropagatedLabels[retSetIdx][c_k * numSites + s_k];
    
    if ( score == 0 )
        return alpha;
    else
        return alpha * (-log(score) / HO_SCORE_MAX);
}

REAL fnCost(int s_i, int s_j, int c_i, int c_j)
{
    REAL score = 0;
    for ( int retSetIdx = 0; retSetIdx < retSetSize; ++retSetIdx )
        score += unfoldPropagatedLabels[retSetIdx][c_i * numSites + s_i] * unfoldPropagatedLabels[retSetIdx][c_j * numSites + s_j];
    
    if ( score == 0 )
        return alpha;
    else
        return alpha * (-log(score) / SO_SCORE_MAX);
}

REAL computeDataNonsmoothQPBO( int* functional, int numLabels, int numSites );
REAL computeDataSmoothPairwiseNonsmoothHighorderICM( int* functional, int numLabels, int numSites );
REAL computeDataSmoothPairwiseNonsmoothHighorderSampling( int* functional, int numLabels, int numSites );

/*
 * main enterance point
 */
void mexFunction(
        int		  nlhs, 	/* number of expected outputs */
        mxArray	  *plhs[],	/* mxArray output pointer array */
        int		  nrhs, 	/* number of inputs */
        const mxArray	  *prhs[]	/* mxArray input pointer array */
        ) {
    if ( nrhs != 4 )
        mexErrMsgIdAndTxt("mexLOROptUndirectedHighorderSum:main", "Must have four input");
    
    if ( nlhs != 2 )
        mexErrMsgIdAndTxt("mexLOROptUndirectedHighorderSum:main", "Must have two output");
    
    // check unfoldPropagatedLabels
    if ( !mxIsCell(prhs[0]) )
        mexErrMsgTxt("First input expects cell");
    
    // check unfoldPropagatedLabels - omitted
    int         nsubs = 2; // prhs[0] = retSetSize X 1 cell
    int         subs[] = {0,0};
    
    // check params
    if ( mxIsCell(prhs[3]) )
        mexErrMsgTxt("Fourth input not expects cell");
    
    //mexPrintf("%d",mxGetNumberOfDimensions(prhs[1]));
    if ( mxGetNumberOfDimensions(prhs[3]) != 2 ) {
        mexErrMsgTxt("Fourth input should be [maxHighOrderObjRelVal maxSecondOrderObjRelVal minHighOrderObjRelVal alpha beta numIter dataFlag QPBOpreFlag dispLabelsFlag]");
    } else {
        const int* paramSubDims = mxGetDimensions(prhs[3]);
        //mexPrintf("%d %d  - Empty\n",paramSubDims[0],paramSubDims[1]);
        if ( paramSubDims[0] != 1 || paramSubDims[1] != 9 ) {
            mexErrMsgTxt("Fourth input should be [maxHighOrderObjRelVal maxSecondOrderObjRelVal minHighOrderObjRelVal alpha beta numIter dataFlag QPBOpreFlag dispLabelsFlag]");
        }
    }
    
    /* get param */
    REAL* maxDoubleMinAlphaBetaIterValTripleFlag = (REAL *)mxGetData(prhs[3]);
    HO_SCORE_MAX = maxDoubleMinAlphaBetaIterValTripleFlag[0];
    SO_SCORE_MAX = maxDoubleMinAlphaBetaIterValTripleFlag[1];
    alpha = maxDoubleMinAlphaBetaIterValTripleFlag[3];
    beta = maxDoubleMinAlphaBetaIterValTripleFlag[4];
    numIter = maxDoubleMinAlphaBetaIterValTripleFlag[5];
    dataFlag = maxDoubleMinAlphaBetaIterValTripleFlag[6];
    QPBOpreFlag = maxDoubleMinAlphaBetaIterValTripleFlag[7];
    dispLabelsFlag = maxDoubleMinAlphaBetaIterValTripleFlag[8];
    
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
    
    /* get adjacent pairs */
    int adjPairsNDim = mxGetNumberOfDimensions(prhs[1]);
    const int *adjPairsDims = mxGetDimensions(prhs[1]);
    adjPairs = (int*)mxGetData(prhs[1]);
    
    /* get input arguments */
    numEdges = adjPairsDims[0];
    
    /* get data cost */
    if ( mxIsEmpty(prhs[2]) ) {
        dataFlag = 0;
    } else {
        int dataNDim = mxGetNumberOfDimensions(prhs[2]);
        const int *dataDims = mxGetDimensions(prhs[2]);
        data = (REAL*)mxGetData(prhs[2]);
        
        //         mexPrintf("%i\n",dataNDim);
        //         mexPrintf("%i %i\n",dataDims[0],dataDims[1]);
        //         mexPrintf("%e %e\n",data[0],data[1]);
    }
    
    // check numSites
    //mexPrintf("%i\n",numSites);
    
    /* define QPBO */
    if ( dispLabelsFlag )
        mexPrintf("*******Started Optimization *****\n");
    
    int* functional = new int[numSites];
    
    srand(unsigned(time(NULL)));
    
    for ( int i = 0; i < numSites; ++i ) {
        if ( dataFlag == 2 ) {
            if ( rand() % 2 == 1 )
                dataFlag = 1;
            else
                dataFlag = 0;
        }
        
        if ( dataFlag == 1 ) {
            // Assign initial state using dataCost
            int minimum = 0;
            double minVal = DBL_MAX;
            
            for ( int k = 0; k < numLabels; ++k ) {
                if ( dCost(i,k) < minVal ) {
                    minVal = dCost(i,k);
                    minimum = k;
                }
            }
            functional[i] = minimum;
        } else {
            // Randomly selected initial state
            functional[i] = rand() % numLabels;
        }
    }
    
    if ( dispLabelsFlag ) {
        // show result
        for ( int i = 0; i < numSites; ++i ) {
            mexPrintf("%d ",functional[i]+1);
        }
        mexPrintf("\n");
    }
    
    REAL functionalEnergy;
    
    if ( QPBOpreFlag )
        for ( int i = 0; i < numIter; ++i )
            functionalEnergy = computeDataNonsmoothQPBO(functional,numLabels,numSites);
    
    //for ( int i = 0; i < numIter; ++i )
    //functionalEnergy = computeDataSmoothPairwiseNonsmoothHighorderICM(functional,numLabels,numSites);
    functionalEnergy = computeDataSmoothPairwiseNonsmoothHighorderSampling(functional,numLabels,numSites);
    
    if ( dispLabelsFlag )
        mexPrintf("*******End Optimization *****\n");
    
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
        for ( int i = 0; i < numSites; ++i ) {
            q->AddUnaryTerm(i,dCost(i,functional[i]),dCost(i,k));
        }
        
        // For each pixel
        for ( int i = 0; i < numSites; ++i ) {
            for ( int j = 0; j < numSites; ++j ) {
                REAL E00 = DBL_MAX, E01 = DBL_MAX, E10 = DBL_MAX, E11 = DBL_MAX;
                
                E00 = (fnCost(i,j,functional[i],functional[j]) + fnCost(j,i,functional[j],functional[i])) / 2;
                E01 = (fnCost(i,j,functional[i],k) + fnCost(j,i,k,functional[i])) / 2;
                E10 = (fnCost(i,j,k,functional[j]) + fnCost(j,i,functional[j],k)) / 2;
                E11 = (fnCost(i,j,k,k) + fnCost(j,i,k,k)) / 2;
                
                if ( i != j ) { // preventing library error
                    q->AddPairwiseTerm(i, j, E00, E01, E10, E11);
                }
            }
        }
        
        q->Solve();
        q->ComputeWeakPersistencies();
        
        // Commit obtained label
        for ( int i = 0; i < numSites; ++i )
            if ( q->GetLabel(i) == 1 )
                functional[i] = k;
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

// Function to compute ICM easy
REAL computeDataSmoothPairwiseNonsmoothHighorderICM( int* functional, int numLabels, int numSites )
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
    
    REAL *totalEd = new REAL[numLabels];
    REAL *totalEp = new REAL[numLabels];
    REAL *totalEh = new REAL[numLabels];
    REAL minEh;
    int minEhIdx;
    
    for ( it=myvector.begin(); it!=myvector.end(); ++it ) {
        int i_new = *it;
        
        // ComputeE
        for ( int j = 0; j < numLabels; ++j ) {
            totalEd[j] = 0;
            totalEp[j] = 0;
            totalEh[j] = 0;
        }
        
        for ( int j = 0; j < numSites; ++j ) {
            if ( j != i_new ) {
                for ( int f_new = 0; f_new < numLabels; ++f_new )
                    totalEd[f_new] += dCost(j,functional[j]);
            } else {
                for ( int f_new = 0; f_new < numLabels; ++f_new )
                    totalEd[f_new] += dCost(j,f_new);
            }
        }
        
        // For each edge pair
        for ( int i = 0; i < numEdges; ++i ) {
            int e_i = adjPairs[i] - 1;
            int e_j = adjPairs[numEdges + i] - 1;
            
            if ( e_i < e_j ) {
                if ( e_i != i_new && e_j != i_new ) {
                    for ( int f_new = 0; f_new < numLabels; ++f_new )
                        if ( functional[e_i] != functional[e_j] ) totalEp[f_new] += beta;
                } else if ( e_i == i_new ) {
                    for ( int f_new = 0; f_new < numLabels; ++f_new )
                        if ( f_new != functional[e_j] ) totalEp[f_new] += beta;
                } else if ( i_new == e_j ) {
                    for ( int f_new = 0; f_new < numLabels; ++f_new )
                        if ( functional[e_i] != f_new ) totalEp[f_new] += beta;
                }
            }
        }
        
        for ( int j = 0; j < numSites; ++j ) {
            for ( int k = 0; k < numSites; ++k ) {
                for ( int f_new = 0; f_new < numLabels; ++f_new ) {
                    if ( i_new != j && j != k && i_new != k ) {
                        totalEh[f_new] += hnCost(i_new,j,k,f_new,functional[j],functional[k]) / 6;
                        totalEh[f_new] += hnCost(j,i_new,k,functional[j],f_new,functional[k]) / 6;
                        totalEh[f_new] += hnCost(j,k,i_new,functional[j],functional[k],f_new) / 6;
                    }
                }
            }
        }
        
        // find max
        minEh = 1e+100;
        minEhIdx = -1;
        for ( int j = 0; j < numLabels; ++j ) {
            if ( totalEd[j] + totalEp[j] + totalEh[j] < minEh ) {
                minEh = totalEd[j] + totalEp[j] + totalEh[j];
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
    }
    
    // Compute Total E
    REAL Ed = 0;
    REAL Ep = 0;
    REAL Eh = 0;
    
    // Data cost
    for ( int i = 0; i < numSites; ++i )
        Ed += dCost(i,functional[i]);
    
    // Pairwise cost
    for ( int i = 0; i < numEdges; ++i ) {
        int e_i = adjPairs[i] - 1;
        int e_j = adjPairs[numEdges + i] - 1;
        
        if ( e_i < e_j )
            if ( functional[e_i] != functional[e_j] )
                Ep += beta;
    }
    
    // High-order cost
    for ( int i = 0; i < numSites; ++i ) {
        for ( int j = 0; j < numSites; ++j ) {
            for ( int k = 0; k < numSites; ++k ) {
                if ( i != j && j != k && i != k ) {
                    Eh += hnCost(i,j,k,functional[i],functional[j],functional[k]) / 6;
                }
            }
        }
    }
    
    functionalEnergy = Ed + Ep + Eh;
    
    if ( dispLabelsFlag )
        mexPrintf("Ed : %f, Ep : %f, Eh : %f\n",Ed,Ep,Eh);
    
    delete[] totalEd;
    delete[] totalEp;
    delete[] totalEh;
    
    if ( dispLabelsFlag ) {
        // show result
        for ( int i = 0; i < numSites; ++i ) {
            mexPrintf("%d ",functional[i]+1);
        }
        mexPrintf("\n");
    }
    
    return functionalEnergy;
}

// Function to compute Sampling
REAL computeDataSmoothPairwiseNonsmoothHighorderSampling( int* functional, int numLabels, int numSites )
{
    int COOLING_STEPS = 20 * numLabels;
    double COOLING_FRACTION = 0.97;
    double K = 0.01;
    
    double temperature = 1;
    for ( int i = 0; i < COOLING_STEPS; ++i ) {
        temperature *= COOLING_FRACTION;
        for ( int ii = 0; ii < 5 * numSites; ++ii ) {
            int i_new = rand() % numSites;
            int f_old = functional[i_new];
            int f_new = rand() % numLabels;
            
            REAL totalEcurrent = 0;
            REAL totalEnew = 0;
            
            totalEcurrent += dCost(i_new,f_old);
            totalEnew += dCost(i_new,f_new);
            
            // For each edge pair
            for ( int j = 0; j < numEdges; ++j ) {
                int e_i = adjPairs[j] - 1;
                int e_j = adjPairs[numEdges + j] - 1;
                
                if ( e_i == i_new ) {
                    if ( f_old != functional[e_j] )
                        totalEcurrent += beta;
                    
                    if ( f_new != functional[e_j] )
                        totalEnew += beta;
                }
            }
            
            for ( int j = 0; j < numSites; ++j ) {
                for ( int k = 0; k < numSites; ++k ) {
                    if ( i_new != j && j != k && i_new != k ) {
                        totalEcurrent += hnCost(i_new,j,k,f_old,functional[j],functional[k]) / 6;
                        totalEcurrent += hnCost(j,i_new,k,functional[j],f_old,functional[k]) / 6;
                        totalEcurrent += hnCost(j,k,i_new,functional[j],functional[k],f_old) / 6;
                        
                        totalEnew += hnCost(i_new,j,k,f_new,functional[j],functional[k]) / 6;
                        totalEnew += hnCost(j,i_new,k,functional[j],f_new,functional[k]) / 6;
                        totalEnew += hnCost(j,k,i_new,functional[j],functional[k],f_new) / 6;
                    }
                }
            }
            
            REAL r = double(rand()) / double(RAND_MAX);
            REAL delta = totalEnew - totalEcurrent;
            REAL merit = exp((-delta/totalEcurrent)/(K*temperature));
            //mexPrintf("%f ",merit);
            
            if ( totalEnew < totalEcurrent ) { // ACCEPT-WIN
                functional[i_new] = f_new;
            } else if ( merit > r ) { // ACCEPT-COND
                //mexPrintf("happend?\n");
                functional[i_new] = f_new;
            }
        }
        //mexPrintf("\n");
    }
    
    // Compute Total E
    REAL Ed = 0;
    REAL Ep = 0;
    REAL Eh = 0;
    
    // Data cost
    for ( int i = 0; i < numSites; ++i )
        Ed += dCost(i,functional[i]);
    
    // Pairwise cost
    for ( int i = 0; i < numEdges; ++i ) {
        int e_i = adjPairs[i] - 1;
        int e_j = adjPairs[numEdges + i] - 1;
        
        if ( e_i < e_j )
            if ( functional[e_i] != functional[e_j] )
                Ep += beta;
    }
    
    // High-order cost
    for ( int i = 0; i < numSites; ++i ) {
        for ( int j = 0; j < numSites; ++j ) {
            for ( int k = 0; k < numSites; ++k ) {
                if ( i != j && j != k && i != k ) {
                    Eh += hnCost(i,j,k,functional[i],functional[j],functional[k]) / 6;
                }
            }
        }
    }
    
    REAL functionalEnergy = Ed + Ep + Eh;
    
    if ( dispLabelsFlag )
        mexPrintf("Ed : %f, Ep : %f, Eh : %f\n",Ed,Ep,Eh);
    
    if ( dispLabelsFlag ) {
        // show result
        for ( int i = 0; i < numSites; ++i ) {
            mexPrintf("%d ",functional[i]+1);
        }
        mexPrintf("\n");
    }
    
    return functionalEnergy;
}