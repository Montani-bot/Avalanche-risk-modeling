/* ==========================================================
 * Project: Avalanche Risk Estimation Tool
 * File: calcRisk.c
 * Description: Compute avalanche risk index for a single input set
 * ========================================================== */

#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    if (nrhs != 7) {
        mexErrMsgTxt("Usage: calcRisk(slope, snow, wind, temp, rain, altitude, depth)");
    }

    // Get normalized scalar values
    double slope    = mxGetScalar(prhs[0]);
    double snow     = mxGetScalar(prhs[1]);
    double wind     = mxGetScalar(prhs[2]);
    double temp     = mxGetScalar(prhs[3]);
    double rain     = mxGetScalar(prhs[4]);
    double altitude = mxGetScalar(prhs[5]);
    double depth    = mxGetScalar(prhs[6]);

    // Create scalar output
    plhs[0] = mxCreateDoubleScalar(0);
    double *risk = mxGetPr(plhs[0]);

    // Weight coefficients (sum ≈ 1)
    double a_slope    = 0.25;
    double a_snow     = 0.20;
    double a_wind     = 0.15;
    double a_temp     = 0.10;
    double a_rain     = 0.10;
    double a_altitude = 0.10;
    double a_depth    = 0.10;

    // Weighted sum
    double R = 5.0 * (a_slope * slope +
                      a_snow  * snow +
                      a_wind  * wind +
                      a_temp  * temp +
                      a_rain  * rain +
                      a_altitude * altitude +
                      a_depth * depth);

    if (R < 0.0) R = 0.0;
    if (R > 5.0) R = 5.0;

    *risk = R;
}
