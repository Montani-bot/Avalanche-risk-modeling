#include "mex.h"
#include <math.h>
#include <stdlib.h>

/* comparaison pour qsort */
int cmpfunc(const void *a, const void *b) {
    double fa = *(const double*)a;
    double fb = *(const double*)b;
    return (fa > fb) - (fa < fb);
}

/* ============================================================
   movquantile_c(X, N, q)
   X : vecteur double
   N : taille de fenêtre (int)
   q : quantile entre 0 et 1
   ============================================================ */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *X, *Y;
    mwSize n, i, start, end, len;
    mwSize N;
    double q;

    /* ------------ Vérification des arguments ------------ */
    if (nrhs != 3) {
        mexErrMsgTxt("Usage: Y = movquantile_c(X, window, q)");
    }

    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0])) {
        mexErrMsgTxt("X must be a real double vector.");
    }

    X = mxGetPr(prhs[0]);
    n = mxGetNumberOfElements(prhs[0]);

    N = (mwSize) mxGetScalar(prhs[1]);
    if (N < 1 || N > n)
        mexErrMsgTxt("Window size must be >=1 and <= length(X)");

    q = mxGetScalar(prhs[2]);
    if (q < 0.0 || q > 1.0)
        mexErrMsgTxt("Quantile q must be between 0 and 1");

    /* ------------ Allocation de la sortie ------------ */
    plhs[0] = mxCreateDoubleMatrix(n, 1, mxREAL);
    Y = mxGetPr(plhs[0]);

    /* Buffer pour fenêtre */
    double *window = (double*) malloc(N * sizeof(double));
    if (!window)
        mexErrMsgTxt("Memory allocation failed.");

    /* ------------ Calcul du quantile mobile ------------ */
    for (i = 0; i < n; i++) {
        /* Début et fin de fenêtre */
        start = (i >= N-1) ? i-(N-1) : 0;
        end = i;
        len = end - start + 1;

        /* Copie des éléments */
        for (mwSize k = 0; k < len; k++)
            window[k] = X[start + k];

        /* Tri des valeurs */
        qsort(window, len, sizeof(double), cmpfunc);

        /* Index du quantile */
        double idx = q * (len - 1);
        mwSize i0 = (mwSize) floor(idx);
        mwSize i1 = (mwSize) ceil(idx);

        if (i0 == i1) {
            Y[i] = window[i0];
        } else {
            double t = idx - i0;
            Y[i] = (1.0 - t) * window[i0] + t * window[i1];
        }
    }

    free(window);
}
