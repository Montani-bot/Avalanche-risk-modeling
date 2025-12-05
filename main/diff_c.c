#include "mex.h"
#include <math.h>

/*
 * diffN_c(X, N)
 *
 * Equivalent MATLAB :
 *   Y = [NaN(N,1); X(N+1:end) - X(1:end-N)];
 *
 * INPUTS:
 *   X : vecteur double (colonne)
 *   N : entier positif (nombre de jours de différence)
 *
 * OUTPUT:
 *   Y : vecteur double des variations
 *
 * Exemples d'utilisation:
 *   diff1 = diffN_c(T.temp_A5, 1);   % diff classique
 *   diff3 = diffN_c(T.temp_A5, 3);   % variation sur 3 jours
 *
 * Compilation:
 *   mex diffN_c.c
 */

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    /* Vérification du nombre d'arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Usage: Y = diffN_c(X, N)");
    }

    /* Vérification du type de X */
    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0])) {
        mexErrMsgTxt("X doit être un vecteur double non complexe.");
    }

    /* Extraction de X */
    double *X = mxGetPr(prhs[0]);
    mwSize n = mxGetNumberOfElements(prhs[0]);

    /* Extraction de N */
    int N = (int) mxGetScalar(prhs[1]);
    if (N < 1 || N >= n) {
        mexErrMsgTxt("N doit être >= 1 et < taille(X).");
    }

    /* Création du vecteur de sortie */
    plhs[0] = mxCreateDoubleMatrix(n, 1, mxREAL);
    double *Y = mxGetPr(plhs[0]);

    /* Remplir les N premières valeurs par NaN */
    double nanv = mxGetNaN();
    for (int i = 0; i < N; i++) {
        Y[i] = nanv;
    }

    /* Calcul des différences sur N jours */
    for (mwSize i = N; i < n; i++) {
        Y[i] = X[i] - X[i - N];
    }
}
