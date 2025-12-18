---
Title: Avalanche Risk Prediction for Swiss Regions
— Final Report author: Pablo Montani 
geometry: margin = 2.5cm
---

# Deviations from project proposal

Brief summary of deviations from the original proposal:
- I decided to design my model to give 1-5 risk prediction imitating the SLF risk mesurement system instead of 


- Switched from a single monolithic MATLAB script to a modular pipeline (src/*.m) and small C/MEX helpers for heavy operations (movsum, product).
- Replaced a pure OLS baseline with a Weighted Least Squares (WLS) calibration to prioritize correct detection of high-risk days.
- Added a validation split and explicit alpha calibration routine (grid search over weights) to ensure calibration is done *only* on training/validation data.
- Expanded feature engineering: moving sums, quantiles, interactions (products), squared terms, and lagged deltas were added after exploratory tests.
- No major changes in the geographic scope: still uses SLF risk indices and MeteoSwiss station data for Swiss sectors.

# Introduction to the problem

Avalanches are a serious hazard in alpine regions. Operational avalanche forecasting relies on human analysis of snowpack, weather history and terrain. Automating parts of this process—producing a quantitatively calibrated risk index from local meteorological time series—can support forecasters and enable more frequent, consistent screening of risk.

This project develops a data-driven model that maps routine meteorological observations (temperature, precipitation, wind, radiation, sunshine, snow depth and derived history statistics) to the SLF (Swiss Federal Institute for Snow and Avalanche Research) risk index. The output is a daily continuous risk estimate aligned with SLF's published daily risk indices.

Scope:
- Included: daily meteorological station data (MeteoSwiss format), SLF risk index time series, feature engineering based on lagged sums/quantiles, linear regression with weighted losses to favor high-risk detection, model calibration and evaluation on held-out data.
- Excluded: terrain-specific spatial modeling, avalanche incident catalog matching, detailed physical snowpack simulation (e.g., full energy-balance models), and transfer learning across sectors (left for future work).

Motivation & implications:
- Societal: improved detection of high-risk days supports safety in mountain recreation and infrastructure management.
- Practical: produces a reproducible pipeline (MATLAB + small C/MEX functions) that can be run per-station and exported as a compact C risk-evaluator for deployment.

# Approach used

## Data sources & format
- Meteorological data: MeteoSwiss station CSV exports (timestamped daily fields).
- Target: SLF daily risk index (`level_detail_numeric`) for the sector corresponding to the station.
- Preprocessing aligns timestamps, renames standard columns and inner-joins station data with the SLF timeseries.

## Feature engineering
Main features (examples used in the final pipeline):
- Direct daily observations: temperature, radiation, humidity, wind_speed, precipitation, sunshine_duration, snow_depth.
- Moving-window aggregated features (implemented in optimized C/MEX functions):
  - `movsum` / `movsum_ignore_nan`: precipitation_35d_sum, precipitation_20d_sum, precipitation_5d_sum, sunshine_10d_sum, humidity_30d_sum, windspeed_10d_sum, temperature_5d_sum, etc.
  - `movquantil`: e.g., 90th percentile of precipitation over preceding 15 days for extreme-event detection.
- Short-term deltas: `diff_c(temperature, 1)` (1-day temperature change), snowdepth change.
- Non-linear interactions: radiation × temperature, windspeed × recent-precipitation, squares of key variables (temperature², windspeed²), and proportions (precip_5d / precip_35d).
- Missing values: columns entirely NaN are dropped; row-wise NaNs removed to keep temporal alignment. For some aggregated features an alternative `movsum_ignore_nan` was implemented to avoid exploding NaNs.

Rationale: avalanche risk depends strongly on cumulative effects (multi-day precipitation, sunshine history) and on interactions (warm sunny days after heavy snow). Summaries and interactions are the primary way the empirical linear model attempts to capture this.

## Model
- Base: linear regression (ordinary least squares) used as interpretable baseline.
- Weighted training: Weighted Least Squares (WLS) where observations with `risk_index > threshold` are upweighted by `1 + alpha` to prioritize capturing high-risk days.
- Alpha calibration: grid search on a validation split (train→train/validation) over candidate alphas (0:2:20). Selection criterion enforces constraints on high-risk performance (recall, MSE_high, R²_high) and chooses the alpha that maximizes R²_global among acceptable candidates.
- Normalization: features standardized (mean, standard deviation) computed on the training subset; the same µ and σ are used for validation/test and for creating the final C evaluator.

## Implementation notes
- Pipeline in MATLAB split into modular functions: `load_and_prepare_data`, `build_features`, `split_data`, `train_model`, `evaluate_model`, `export_figures`.
- Heavy windowed operations and elementwise products implemented in C and compiled as MEX functions for speed (e.g., `movsum_c`, `movsum_ignore_nan_c`, `product_c`).
- Final model coefficients exported and embedded into a small generated C `calcrisk_c` function so a compact risk evaluator per station can be produced.

# Results

> Short summary of results for the evaluated station (example numbers from final run):
- Global R² (test): **0.47**
- Global MSE (test): **0.11**
- High-risk (risk ≥ 2.3) R²: **0.47**
- High-risk MSE: **0.053**
- High-risk MAE: **0.19**
- High-risk recall: **0.955**
- High-risk precision: **0.76**

These metrics indicate:
- The model explains ≈47% of variance overall — strong for a linear empirical model on noisy natural processes.
- High-risk detection is excellent (very high recall) and precision is acceptable: the model finds most dangerous days while producing a moderate number of false positives (acceptable for safety-focused systems).
- MSE and MAE on high-risk days are low, so numeric predictions are close to SLF labels in magnitude.

### How reasonableness was assessed
- **Cross-validation & held-out test**: alpha calibration used only training/validation split. Final metrics computed on an untouched test subset.
- **Targeted high-risk evaluation**: separate metrics (recall, precision, MSE, MAE, R² restricted to high-risk days).
- **Error-by-level analysis**: counts of predictions that differ from the true SLF level by more than 0.25 for each discrete SLF value (1.00, 1.33, 1.67, 2.00, 2.33..., 4.33) to inspect systematic bias by category.
- **Visual diagnostics**: scatter plots of observed vs predicted risk; calibration plots; variable importance barplots (regression coefficients).

### Representative figure placeholders (to include in final PDF)
- Observed vs Predicted risk scatter with identity line.
- Barplot: number of misclassifications per SLF level.
- Alpha calibration plots: R²_global, R²_high, recall_high vs alpha.
- Coefficient barplot sorted by absolute effect.

# Conclusion and outlook

## Summary
- A reproducible pipeline was developed to build a per-station avalanche risk predictor using routine meteorological data and SLF labels.
- Feature engineering focusing on multi-day aggregates and interactions plus WLS calibration allowed strong detection of high-risk days while preserving reasonable global accuracy.
- The pipeline generates an exportable C function containing the standardized coefficients and µ/σ, enabling compact deployment.

## Limitations
- The model is empirical and linear — it cannot capture highly non-linear or threshold behaviors beyond engineered interactions.
- Performance depends on the quality and completeness of station data; missing records and mismatching time ranges limit usable samples.
- Sector-level SLF labels integrate area-wide knowledge; mapping single-station inputs to sector risk is inherently lossy.
- No spatial or topographic features included (aspect, slope, terrain) that are known to influence avalanches strongly.

## Improvements and future work
- Add more robust missing-data handling and imputation strategies; compare `movsum_ignore_nan` vs imputation.
- Try non-linear models (random forests, gradient boosting, or simple neural nets) and calibrate for recall/precision trade-offs.
- Incorporate terrain/topographic covariates if available, or merge multiple stations per sector.
- Add time-series cross-validation (block CV) to better respect temporal dependencies.
- Create an ensemble that blends an interpretable linear model for baseline with a better high-risk specialist model.

# Authorship statement

List contributions of team members (example):

- Alice — overall pipeline design, feature engineering, MATLAB implementation.
- Bob — C/MEX function implementations, performance optimization, deployment packaging.
- Charlie — model calibration, statistical evaluation and figures, report writing.

(Replace with actual contributors and describe who wrote which functions and parts of the report.)

# References

1. SLF — Interpretationshilfe zum Lawinenbulletin. (link or citation).
2. MeteoSwiss datasets documentation.
3. Hastie, Tibshirani, Friedman — *The Elements of Statistical Learning* (for WLS, evaluation metrics).
4. Bishop — *Pattern Recognition and Machine Learning* (for calibration concepts).
5. Relevant domain papers about avalanche forecasting with statistical models (add specific references you used).

---

## Appendix (optional)
- Full list of variables used in `X`.
- Exported final coefficients and µ/σ (or path to `results/model_coeffs_station.txt`).
- Command line or exact MATLAB command to regenerate the report and figures, e.g.:

```bash
matlab -batch "run_all"
# or
cd docs
pandoc report.md -o report.pdf --pdf-engine=xelatex
