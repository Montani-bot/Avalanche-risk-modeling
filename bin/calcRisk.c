/* ==========================================================
 * Project: Avalanche Risk Estimation Tool
 * File: calcRisk.c
 * Author: [Your Name]
 * Description: Core C function to compute avalanche risk index
 *              based on normalized input parameters.
 * Language: C (MEX-compatible)
 * Date: October 2025
 * ========================================================== */

#include "mex.h"

/* 
 * Input arguments:
 *  prhs[0] = slope (array)
 *  prhs[1] = snowfall (array)
 *  prhs[2] = wind (array)
 *  prhs[3] = temp (array)
 *
 * Output:
 *  plhs[0] = risk index (array)
 */

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    // Vérification du nombre d'arguments
    if (nrhs != 4) {
        mexErrMsgTxt("Usage: calcRisk(slope, snow, wind, temp)");
    }

    size_t n = mxGetNumberOfElements(prhs[0]);
    plhs[0] = mxCreateDoubleMatrix(n, 1, mxREAL);

    double *slope = mxGetPr(prhs[0]);
    double *snow  = mxGetPr(prhs[1]);
    double *wind  = mxGetPr(prhs[2]);
    double *temp  = mxGetPr(prhs[3]);
    double *risk  = mxGetPr(plhs[0]);

    // Coefficients de pondération (empiriques)
    double a_slope = 0.4;
    double a_snow  = 0.3;
    double a_wind  = 0.2;
    double a_temp  = 0.1;

    // Calcul de l'indice de risque pour chaque entrée
    for (size_t i = 0; i < n; i++) {
        risk[i] = 5*(a_slope * slope[i]
                + a_snow  * snow[i]
                + a_wind  * wind[i]
                + a_temp  * temp[i]);
    }
}
