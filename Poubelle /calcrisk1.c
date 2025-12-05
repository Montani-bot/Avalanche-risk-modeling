/* ==========================================================
 * Project: Avalanche Risk Estimation Tool
 * File: calcRisk.c
 * Author: [Your Name]
 * Description: Compute avalanche risk index for single input set
 * ========================================================== */

#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    if (nrhs != 4) {
        mexErrMsgTxt("Usage: calcRisk(slope, snow, wind, temp)");
    }

    // Get scalar values
    double slope = mxGetScalar(prhs[0]);
    double snow  = mxGetScalar(prhs[1]);
    double wind  = mxGetScalar(prhs[2]);
    double temp  = mxGetScalar(prhs[3]);
    

    // Create output (scalar)
    plhs[0] = mxCreateDoubleScalar(0);
    double *risk = mxGetPr(plhs[0]);

    // Coefficients (empirical)
    double a_slope = 0.4;
    double a_snow  = 0.3;
    double a_wind  = 0.2;
    double a_temp  = 0.1;

    // Compute risk (scaled to 0–5)
    double R = 5.0 * (a_slope * slope +
                      a_snow  * snow +
                      a_wind  * wind +
                      a_temp  * temp);

    if (R < 0.0) R = 0.0;
    if (R > 5.0) R = 5.0;

    *risk = R;
}
