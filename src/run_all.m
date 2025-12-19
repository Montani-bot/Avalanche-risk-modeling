%% Customized Avalanche Prediction Model for Swiss Stations
%Main script that orchestrates the entire pipeline
clear; clc; close all;

%% === Path configuration ===
script_dir = fileparts(mfilename('fullpath'));
project_root = fullfile(script_dir, '..');

%% Compilation of C functions used in the model with GCC
compile_mex ()

%% === Model parameters configuration ===
% To get the model for another station, simply provide the corresponding CSV file
config.station_of_interest = fullfile(project_root, 'data', 'meteo_zermatt.csv'); 
config.sector_of_interest = get_sector_id(config.station_of_interest);
config.train_ratio = 0.8;
config.val_ratio = 0.25;
config.high_risk_threshold = 2.3;
config.alphas = 0:20;
config.rng_seed = 1;
config.resultDir = fullfile(project_root, 'results');

%% === Displaying the title ===
fprintf("\n=============================================================\n");
fprintf("   AVALANCHE RISK PREDICTION MODEL FOR A SPECIFIC SWISS STATION \n");
fprintf("=============================================================\n");

%% === Step 1: Data loading and preparation ===
fprintf("\n[ÉTAPE 1] Loading and preparing data sets...\n");
[T] = load_and_prepare_data(...
    config.station_of_interest, config.sector_of_interest);

%% === Step 2: Feature construction ===
fprintf("\n[ÉTAPE 2] Building the features...\n");
[X, y, var_names] = build_features(T);

%% === Displaying data statistics ===
display_data_info(X, y, config.station_of_interest, config.sector_of_interest);

%% === Step 3: Data splitting ===
fprintf("\n[ÉTAPE 3] Data splitting...\n");
[X_train, X_val, X_test, y_train, y_val, y_test, mu, sigma] = ...
    split_data(X, y, config.train_ratio, config.val_ratio, config.rng_seed);

%% === Step 4: Model training ===
fprintf("\n[ÉTAPE 4] Model training...\n");
[best_alpha, b_final, performance] = train_model(...
    X_train, X_val, y_train, y_val, ...
    mu, sigma, config.alphas, config.high_risk_threshold);

%% === Step 5: Final evaluation ===
fprintf("\n[ÉTAPE 5] Finale evaluation...\n");
[y_pred_final, metrics] = evaluate_model(...
    X_test, y_test, b_final, mu, sigma, config.high_risk_threshold);

display_final_performance(metrics, config.high_risk_threshold, b_final, var_names);

%% === Step 6: Visualisations ===
fprintf("\n[ÉTAPE 6] Creation of the visualisations...\n");
export_figures(...
    y_test, y_pred_final, ...
    config.alphas, performance.alpha_results, best_alpha, ...
    b_final, var_names, config.resultDir);

fprintf("\n✅ Pipeline completed successfully !\n");

%% === Step 7: Saving the model coefficients ===
fprintf("\n[ÉTAPE 7] Saving the model coefficients...\n");
coeff_saver(b_final, var_names, ...
    config.station_of_interest, config.resultDir);
