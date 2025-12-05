#include "mex.h"
#include <math.h>

/* Fonction mex pour calculer une somme glissante en ignorant les NaN */
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

    /* Initialise le vecteur de sortie avec NaN */
    for (mwSize i = 0; i < n; i++) {
        Y[i] = mxGetNaN();
    }

    /* Calcul de la somme glissante en ignorant les NaN */
    for (mwSize i = 0; i < n; i++) {
        double sum = 0.0;
        int count_valid = 0;

        /* Fenêtre glissante : max w éléments précédents y compris le jour courant */
        for (mwSize j = (i >= w-1 ? i-w+1 : 0); j <= i; j++) {
            if (!mxIsNaN(X[j])) {
                sum += X[j];
                count_valid++;
            }
        }

        /* Si au moins un élément valide dans la fenêtre, on calcule la somme */
        if (count_valid > 0) {
            Y[i] = sum;
        } else {
            Y[i] = mxGetNaN(); // sinon reste NaN
        }
    }
}
