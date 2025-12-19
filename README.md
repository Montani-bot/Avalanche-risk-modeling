# Avalanche Risk Prediction Model

## Project Description

- This project implements a **Weighted Least Squares (WLS) regression model** to predict avalanche risk levels in Swiss mountainous regions. The model links meteorological observations from MeteoSwiss stations with daily avalanche risk indices published by the Swiss Federal Institute for Snow and Avalanche Research (SLF).

## Important note: 
- to obtain the model for another station, simply load a different CSV table at line 14 of the run_all.m file.
- The available csv files are stored in the data folder. 
- I arbitrary choosed to load a few stations but my model is built to work with every meteoswiss stations.  

### Main Objectives
- Develop an operational decision-support tool for avalanche risk assessment  
- Exploit readily available meteorological data  
- Prioritize accurate detection of high-risk avalanche days  

### Key Features
- **Automatic mapping** from meteorological station → SLF sector  
- **Dynamic feature engineering** using temporal aggregations  
- **Weighted regression** emphasizing accuracy for high-risk situations  
- **Comprehensive evaluation framework** tailored to avalanche-risk scenarios  

## File Structure

- `src/` : Main MATLAB source code (data loading, feature engineering, training, evaluation)
- `data/` : Input meteorological and avalanche risk datasets
- `bin/` : Compiled MEX binaries (C-accelerated numerical routines)
- `results/` : Model outputs, figures, and saved coefficients
- `docs/` : Final report and documentation

---

## Input Data

### Files in `data/`

1. **Meteorological data** (`meteo_[station].csv`)
   - Standard MeteoSwiss format  
   - Columns include:  
     - `reference_timestamp` (date)
     - `fkl010d0` (wind speed)  
     - `gre000d0` (global radiation)
     - `htoautd0` (snow depth) ...
   - Available stations (datasets already downloaded): pilatus, zermatt, evolene, mottec, weissfluhjoch 
   - The model is compatible with any Swiss region equipped with a MeteoSwiss station  

2. **Avalanche risk data** (`risk_index_slf.csv`)
   - Daily SLF avalanche risk indices for all Swiss regions (2022–2024)  
   - Risk levels range from 1 (low) to 5 (very high) with 0.33 granularity
   - Public dataset disponible on the envidat.ch website 

---

## Output Files

### Generated in `results/`

- `model_coeffs_meteo_[STATION-OF-INTEREST].txt`  
  Model coefficients (weight of each variable in avalanche risk estimation for the selected station)

- `alpha_calibration_[timestamp].png`  
  Visualization of the calibration and optimization of the weighting parameter α

- `variable_importance_[timestamp].png`  
  Relative importance of meteorological variables in risk estimation

- `predictions_vs_observations_[timestamp].png`  
  Model predictions compared to observed SLF risk indices

- `errors_by_risk_level_[timestamp].png`  
  Error analysis by risk level (useful for calibration, with a focus on minimizing errors for high-risk cases)

---

## Running the Program

### Dependencies

**Operating System**  
- Linux (tested and intended for portability across Linux environments)

**MATLAB**  
- Version: R2021b or newer
- Required Toolboxes: None (does not rely on the Statistics and Machine Learning Toolbox)

**C Compiler**  
- GCC 7.0 or newer  
- MATLAB MEX compiler properly configured  

### Build

- Compile the C acceleration routines (MEX files) into the `bin/` directory:

- this step has been added to the run_all.m script to simplifie the process but you can still compile the c code manually the following way:

- matlab -batch "run('src/compile_mex.m')"

### Execute

- Run the full modeling pipeline (data loading, training, evaluation, and output generation):

- matlab -batch "run('src/run_all.m')"

- All outputs will be automatically written to the results/ directory.

## Contributors

- Pablo Montani – Model design, MATLAB implementation, data analysis, and report writing

## Acknowledgments

### Data Sources

- MeteoSwiss: meteorological station data

- SLF (WSL Institute for Snow and Avalanche Research): avalanche risk indices

### Code

- Numerical acceleration routines implemented in C and compiled via MATLAB MEX

- Documentation and portions of code structure assisted by Large Language Models (LLMs), specifically ChatGPT (OpenAI), Deepseek and copilot.