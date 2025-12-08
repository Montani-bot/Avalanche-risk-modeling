#include "mex.h"
#include <math.h>

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    /* Inputs:
     * prhs[0] -> vector X
     * prhs[1] -> window size (int)
     */

    double *X = mxGetPr(prhs[0]);
    mwSize n = mxGetNumberOfElements(prhs[0]);
    int w = (int) mxGetScalar(prhs[1]);

    /* Output vector */
    plhs[0] = mxCreateDoubleMatrix(n, 1, mxREAL);
    double *Y = mxGetPr(plhs[0]);

    double sum = 0.0;

    for (mwSize i = 0; i < n; i++) {
        sum += X[i];
        if (i >= w) {
            sum -= X[i - w];
        }
        Y[i] = sum;
    }
}
