#include "mex.h"
#include <math.h>

/*
 *  MEX FUNCTION calcRisk_c
 *  Usage in MATLAB:
 *     risk = calcRisk_c(coeffs, mu, sigma, x_today)
 *
 *  All inputs must be row or column vectors of doubles.
 *  coeffs : (n_features + 1)  → intercept + coefficients
 *  mu     : (n_features)
 *  sigma  : (n_features)
 *  x_today: (n_features)
 *
 *  Output:
 *     scalar double : risk
 */

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    if (nrhs != 4) {
        mexErrMsgTxt("calcRisk_c requires 4 input arguments: coeffs, mu, sigma, x_today");
    }
    if (nlhs != 1) {
        mexErrMsgTxt("calcRisk_c returns exactly one output.");
    }

    /* Récupère les pointeurs vers les tableaux MATLAB */
    double *coeffs = mxGetPr(prhs[0]);
    double *mu     = mxGetPr(prhs[1]);
    double *sigma  = mxGetPr(prhs[2]);
    double *x_today = mxGetPr(prhs[3]);

    /* Vérifie les dimensions */
    int n_coeffs = mxGetNumberOfElements(prhs[0]);
    int n_feat_mu = mxGetNumberOfElements(prhs[1]);
    int n_feat_sigma = mxGetNumberOfElements(prhs[2]);
    int n_feat_x = mxGetNumberOfElements(prhs[3]);

    int n_features = n_coeffs - 1;  // car coeffs = [intercept, w1, w2, ..., wn]

    if (n_feat_mu != n_features || n_feat_sigma != n_features || n_feat_x != n_features) {
        mexErrMsgTxt("Dimension mismatch: coeffs must be length N+1, mu/sigma/x_today must be length N.");
    }

    /* Calcul du risque */
    double risk = coeffs[0];  // intercept

    for (int i = 0; i < n_features; i++) {
        double x_norm = (x_today[i] - mu[i]) / sigma[i];
        risk += coeffs[i + 1] * x_norm;
    }

    /* Crée la sortie MATLAB */
    plhs[0] = mxCreateDoubleScalar(risk);
}




