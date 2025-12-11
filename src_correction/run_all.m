%% MODELE DE PREDICTION D'AVALANCHE PERSONNALISE - VERSION CORRIGEE

clear; clc; close all;

%% === Configuration ===
script_dir = fileparts(mfilename('fullpath'));
project_root = fullfile(script_dir, '..');

config = struct();
config.station_of_interest = fullfile(project_root, 'data', 'meteo_pilatus.csv');
config.sector_of_interest = 2111; % Pilatus
config.train_ratio = 0.7;  % Réduit pour laisser plus de test
config.val_ratio = 0.15;   % 70% train, 15% val, 15% test
config.high_risk_threshold = 2.33; % Niveau SLF 2.33 = 3- (risque marqué)
config.alphas = 0:1:15;    % Pas plus fin
config.rng_seed = 42;      % Seed reproductible
config.resultDir = fullfile(project_root, 'results');

% Créer le dossier results
if ~isfolder(config.resultDir)
    mkdir(config.resultDir);
end

%% === Journalisation ===
log_file = fullfile(config.resultDir, ...
    sprintf('log_%s.txt', datestr(now, 'yyyymmdd_HHMMSS')));
diary(log_file);

fprintf('=== DEBUT DE L''EXECUTION ===\n');
fprintf('Date: %s\n', datetime('now'));
fprintf('Station: %s\n', config.station_of_interest);
fprintf('Secteur SLF: %d\n', config.sector_of_interest);
fprintf('Seed aléatoire: %d\n', config.rng_seed);
fprintf('Seuil high-risk: %.2f\n', config.high_risk_threshold);
fprintf('Alphas testés: %s\n', mat2str(config.alphas));

%% === Étape 1: Chargement ===
fprintf('\n[1/6] CHARGEMENT DES DONNEES\n');
try
    [T, var_names_base] = load_and_prepare_data(...
        config.station_of_interest, config.sector_of_interest);
catch ME
    fprintf('❌ ERREUR chargement: %s\n', ME.message);
    diary off;
    rethrow(ME);
end

%% === Étape 2: Construction des features ===
fprintf('\n[2/6] CONSTRUCTION DES FEATURES\n');
try
    [X, y, feature_names] = build_features(T, var_names_base);
catch ME
    fprintf('❌ ERREUR features: %s\n', ME.message);
    diary off;
    rethrow(ME);
end

%% === Informations sur les données ===
fprintf('\n=== INFORMATIONS SUR LES DONNEES ===\n');
fprintf('Nombre total de jours: %d\n', length(y));
fprintf('Nombre de features: %d\n', length(feature_names));
fprintf('Features utilisées:\n');
for i = 1:length(feature_names)
    fprintf('  %d. %s\n', i, feature_names{i});
end

% Distribution du risque
fprintf('\nDistribution du risque SLF:\n');
slf_levels = [1, 1.33, 1.67, 2, 2.33, 2.67, 3, 3.33, 3.67, 4, 4.33];
for level = slf_levels
    count = sum(abs(y - level) < 0.01);
    if count > 0
        fprintf('  Niveau %.2f: %d jours (%.1f%%)\n', ...
                level, count, count/length(y)*100);
    end
end

%% === Étape 3: Séparation des données ===
fprintf('\n[3/6] SEPARATION DES DONNEES\n');
try
    [X_train, X_val, X_test, y_train, y_val, y_test, mu, sigma] = ...
        split_data(X, y, config.train_ratio, config.val_ratio, config.rng_seed);
catch ME
    fprintf('❌ ERREUR séparation: %s\n', ME.message);
    diary off;
    rethrow(ME);
end

%% === Étape 4: Entraînement ===
fprintf('\n[4/6] ENTRAINEMENT DU MODELE\n');
try
    [best_alpha, b_final, performance] = train_model(...
        X_train, X_val, X_test, y_train, y_val, y_test, ...
        mu, sigma, config.alphas, config.high_risk_threshold);
catch ME
    fprintf('❌ ERREUR entraînement: %s\n', ME.message);
    diary off;
    rethrow(ME);
end

%% === Étape 5: Évaluation ===
fprintf('\n[5/6] EVALUATION FINALE\n');
try
    [y_pred_final, metrics, y_pred_all] = evaluate_model(...
        X_test, y_test, b_final, mu, sigma, config.high_risk_threshold);
catch ME
    fprintf('❌ ERREUR évaluation: %s\n', ME.message);
    diary off;
    rethrow(ME);
end

%% === Affichage des performances ===
fprintf('\n===============================================\n');
fprintf('🌟 PERFORMANCES FINALES SUR TEST 🌟\n');
fprintf('===============================================\n\n');

fprintf('🔹 PERFORMANCES GLOBALES\n');
fprintf('   R²        : %.4f\n', metrics.R2_test);
fprintf('   RMSE      : %.4f\n', metrics.RMSE_test);
fprintf('   MAE       : %.4f\n', metrics.MAE_test);

fprintf('\n🔸 PERFORMANCES HIGH-RISK (≥%.2f)\n', config.high_risk_threshold);
fprintf('   R²        : %.4f\n', metrics.R2_high_final);
fprintf('   MAE       : %.4f\n', metrics.MAE_high_final);
fprintf('   Recall    : %.4f\n', metrics.recall_final);
fprintf('   Précision : %.4f\n', metrics.precision_final);
fprintf('   F1-score  : %.4f\n', metrics.f1_final);
fprintf('   AUC approx: %.4f\n', metrics.auc_final);

fprintf('\n🔹 STATISTIQUES DES RESIDUS\n');
fprintf('   Moyenne   : %.4f\n', metrics.residual_mean);
fprintf('   Écart-type: %.4f\n', metrics.residual_std);
fprintf('   Normalité (p-value): %.4f\n', metrics.residual_normality_p);

%% === Affichage des coefficients ===
fprintf('\n===============================================\n');
fprintf('📊 COEFFICIENTS DU MODELE (alpha=%.1f)\n', best_alpha);
fprintf('===============================================\n');

fprintf('\n%-40s %12s\n', 'Variable', 'Coefficient');
fprintf('%s\n', repmat('-', 1, 55));

fprintf('%-40s %12.4f\n', '(Intercept)', b_final(1));

for i = 1:length(feature_names)
    fprintf('%-40s %12.4f\n', feature_names{i}, b_final(i+1));
end

%% === Étape 6: Visualisations ===
fprintf('\n[6/6] GENERATION DES VISUALISATIONS\n');
try
    export_figures(...
        X_test, y_test, y_pred_final, ...
        config.alphas, performance.alpha_results, best_alpha, ...
        b_final, feature_names, ...
        metrics, config.high_risk_threshold, ...
        config.resultDir);
    
    fprintf('✅ Figures sauvegardées dans: %s\n', config.resultDir);
catch ME
    fprintf('⚠️ Erreur visualisations: %s\n', ME.message);
end

%% === Sauvegarde du modèle ===
model_file = fullfile(config.resultDir, 'avalanche_model.mat');
save(model_file, ...
    'b_final', 'mu', 'sigma', 'feature_names', ...
    'best_alpha', 'config', 'metrics', ...
    'X_test', 'y_test', 'y_pred_final');

fprintf('\n✅ Modèle sauvegardé: %s\n', model_file);

%% === Fin ===
fprintf('\n=== EXECUTION TERMINEE AVEC SUCCES ===\n');
fprintf('Temps total: %s\n', datetime('now'));

diary off;