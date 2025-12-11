#include "mex.h"
#include <math.h>
#include <stdlib.h>
/*
 * product_c(X, Y)
 * Renvoie Z = X .* Y
 */

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    /* Vérification du nombre d'inputs */
    if (nrhs != 2) {
        mexErrMsgIdAndTxt("MyToolbox:product_c:nrhs",
                          "Deux inputs requis : X et Y.");
    }

    /* Vérification du nombre d'outputs */
    if (nlhs > 1) {
        mexErrMsgIdAndTxt("MyToolbox:product_c:nlhs",
                          "Un seul output renvoyé.");
    }

    /* Vérification que les inputs sont des vecteurs double */
    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) ||
        !mxIsDouble(prhs[1]) || mxIsComplex(prhs[1])) {
        mexErrMsgIdAndTxt("MyToolbox:product_c:notDouble",
                          "Inputs must be type double.");
    }

    /* Récupération des pointeurs */
    double *X = mxGetPr(prhs[0]);
    double *Y = mxGetPr(prhs[1]);

    /* Vérification de la taille */
    mwSize nX = mxGetNumberOfElements(prhs[0]);
    mwSize nY = mxGetNumberOfElements(prhs[1]);

    if (nX != nY) {
        mexErrMsgIdAndTxt("MyToolbox:product_c:dimMismatch",
                          "Les deux vecteurs doivent avoir la même longueur.");
    }

    /* Création du vecteur de sortie */
    plhs[0] = mxCreateDoubleMatrix(nX, 1, mxREAL);
    double *Z = mxGetPr(plhs[0]);

    /* Produit élément par élément */
    for (mwSize i = 0; i < nX; i++) {
        Z[i] = X[i] * Y[i];
    }
}
