%% MODELE DE PREDICTION D'AVALANCHE PERSONNALISE POUR STATIONS SUISSES
% Script principal qui orchestre l'ensemble du pipeline

clear; clc; close all;

%% === Configuration des chemins ===
script_dir = fileparts(mfilename('fullpath'));
project_root = fullfile(script_dir, '..');

%% compilation des fonction c utilisées dans le model avec GCC
%compile_mex ()

%% === Configuration des paramètres du modèle ===
config.station_of_interest = fullfile(project_root, 'data', 'meteo_zermatt.csv'); %% pour obtenir le model d'une autre station il suffit de mettre le csv correspondant 
config.sector_of_interest = get_sector_id(config.station_of_interest);
config.train_ratio = 0.8;
config.val_ratio = 0.25;
config.high_risk_threshold = 2.3;
config.alphas = 0:20;
config.rng_seed = 1;
config.resultDir = fullfile(project_root, 'results');

%% === Affichage du titre ===
fprintf("\n=============================================================\n");
fprintf("        MODELE DE PREDICTION D'AVALANCHE PERSONNALISE\n");
fprintf("=============================================================\n");

%% === Étape 1: Chargement et préparation des données ===
fprintf("\n[ÉTAPE 1] Chargement des données...\n");
[T] = load_and_prepare_data(...
    config.station_of_interest, config.sector_of_interest);

%% === Étape 2: Construction des features ===
fprintf("\n[ÉTAPE 2] Construction des features...\n");
[X, y, var_names] = build_features(T);

%% === Affichage des statistiques des données ===
display_data_info(X, y, config.station_of_interest, config.sector_of_interest);

%% === Étape 3: Séparation des données ===
fprintf("\n[ÉTAPE 3] Séparation des données...\n");
[X_train, X_val, X_test, y_train, y_val, y_test, mu, sigma] = ...
    split_data(X, y, config.train_ratio, config.val_ratio, config.rng_seed);

%% === Étape 4: Entraînement du modèle ===
fprintf("\n[ÉTAPE 4] Entraînement du modèle...\n");
[best_alpha, b_final, performance] = train_model(...
    X_train, X_val, y_train, y_val, ...
    mu, sigma, config.alphas, config.high_risk_threshold);

%% === Étape 5: Évaluation finale ===
fprintf("\n[ÉTAPE 5] Évaluation finale...\n");
[y_pred_final, metrics] = evaluate_model(...
    X_test, y_test, b_final, mu, sigma, config.high_risk_threshold);

display_final_performance(metrics, config.high_risk_threshold, b_final, var_names);

%% === Étape 6: Visualisations ===
fprintf("\n[ÉTAPE 6] Génération des visualisations...\n");
export_figures(...
    y_test, y_pred_final, ...
    config.alphas, performance.alpha_results, best_alpha, ...
    b_final, var_names, config.resultDir);

fprintf("\n✅ Pipeline terminé avec succès !\n");

%% === Étape 7: Sauvegarde des coefficients du modèle ===
fprintf("\n[ÉTAPE 7] Sauvegarde des coefficients du modèle...\n");
coeff_saver(b_final, var_names, ...
    config.station_of_interest, config.resultDir);
