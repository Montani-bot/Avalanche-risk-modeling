function [best_alpha, b_final, performance] = train_model(...
    X_train, X_val, X_test, y_train, y_val, y_test, ...
    mu, sigma, alphas, high_risk_threshold)
%% Entraîne avec validation croisée pour choisir alpha
    
    % ========== FONCTION INTERNE POUR WLS ==========
    function b = train_wls(X, y, alpha, threshold)
        % Entraîne un modèle WLS avec alpha donné
        X_d = [ones(size(X,1),1), X];
        w = 1 + alpha * (y > threshold);
        sqrt_w = sqrt(w);
        X_weighted = sqrt_w .* X_d;
        y_weighted = sqrt_w ..* y;
        b = (X_weighted' * X_weighted) \ (X_weighted' * y_weighted);
    end
    
    % ========== VALIDATION CROISEE MANUELLE POUR ALPHA ==========
    fprintf('\n=== VALIDATION CROISEE POUR ALPHA (5 folds) ===\n');
    
    n_train = size(X_train, 1);
    k_folds = min(5, floor(n_train / 20)); % Au moins 20 obs par fold
    
    if k_folds < 2
        warning('⚠️ Trop peu de données pour CV, utilisation de validation simple');
        k_folds = 1;
    end
    
    cv_scores = struct();
    cv_scores.R2_global = zeros(length(alphas), k_folds);
    cv_scores.R2_high = zeros(length(alphas), k_folds);
    cv_scores.recall = zeros(length(alphas), k_folds);
    cv_scores.MSE_high = zeros(length(alphas), k_folds);
    
    if k_folds > 1
        % ========== IMPLEMENTATION MANUELLE DE LA CV ==========
        % Stratification manuelle basée sur les niveaux de risque
        risk_levels = discretize(y_train, [1, 2, 2.33, 3, 5]); % Bins simplifiés
        unique_levels = unique(risk_levels);
        
        % Initialiser les indices par fold
        fold_indices = cell(k_folds, 1);
        for f = 1:k_folds
            fold_indices{f} = [];
        end
        
        % Répartir chaque niveau de risque dans les folds
        for level = unique_levels'
            level_indices = find(risk_levels == level);
            n_level = length(level_indices);
            
            if n_level < k_folds
                % Si trop peu d'observations, toutes dans le premier fold
                fold_indices{1} = [fold_indices{1}; level_indices];
            else
                % Mélanger et répartir équitablement
                level_indices = level_indices(randperm(n_level));
                
                % Calculer combien par fold
                n_per_fold = floor(n_level / k_folds);
                remainder = mod(n_level, k_folds);
                
                start_idx = 1;
                for f = 1:k_folds
                    % Nombre pour ce fold
                    n_this_fold = n_per_fold + (f <= remainder);
                    end_idx = start_idx + n_this_fold - 1;
                    
                    fold_indices{f} = [fold_indices{f}; 
                                       level_indices(start_idx:end_idx)];
                    start_idx = end_idx + 1;
                end
            end
        end
        
        % Vérifier que tous les indices sont assignés
        all_assigned = sort(cell2mat(fold_indices));
        if length(all_assigned) ~= n_train
            warning('⚠️ Toutes les observations ne sont pas assignées aux folds');
            % Assigner les manquantes au hasard
            missing = setdiff(1:n_train, all_assigned);
            for i = 1:length(missing)
                random_fold = randi(k_folds);
                fold_indices{random_fold} = [fold_indices{random_fold}; missing(i)];
            end
        end
        
        % ========== EXECUTION DE LA CV ==========
        for fold = 1:k_folds
            fprintf('  Fold %d/%d...', fold, k_folds);
            
            % Indices pour ce fold
            val_cv_idx = fold_indices{fold};
            train_cv_idx = setdiff(1:n_train, val_cv_idx);
            
            X_train_cv = X_train(train_cv_idx, :);
            y_train_cv = y_train(train_cv_idx);
            X_val_cv = X_train(val_cv_idx, :);
            y_val_cv = y_train(val_cv_idx);
            
            % Tester chaque alpha
            for a_idx = 1:length(alphas)
                alpha = alphas(a_idx);
                
                % Entraîner
                b_cv = train_wls(X_train_cv, y_train_cv, alpha, high_risk_threshold);
                
                % Prédire
                X_val_cv_d = [ones(size(X_val_cv,1),1), X_val_cv];
                y_pred_cv = X_val_cv_d * b_cv;
                
                % Métriques globales
                ss_res = sum((y_val_cv - y_pred_cv).^2);
                ss_tot = sum((y_val_cv - mean(y_val_cv)).^2);
                
                if ss_tot > 0
                    cv_scores.R2_global(a_idx, fold) = 1 - ss_res/ss_tot;
                else
                    cv_scores.R2_global(a_idx, fold) = 0;
                end
                
                cv_scores.MSE_global(a_idx, fold) = mean((y_val_cv - y_pred_cv).^2);
                
                % Métriques high-risk
                high_mask = y_val_cv >= high_risk_threshold;
                if any(high_mask)
                    y_h = y_val_cv(high_mask);
                    y_ph = y_pred_cv(high_mask);
                    
                    ss_res_high = sum((y_h - y_ph).^2);
                    ss_tot_high = sum((y_h - mean(y_h)).^2);
                    
                    if ss_tot_high > 0
                        cv_scores.R2_high(a_idx, fold) = 1 - ss_res_high/ss_tot_high;
                    else
                        cv_scores.R2_high(a_idx, fold) = 0;
                    end
                    
                    cv_scores.MSE_high(a_idx, fold) = mean((y_h - y_ph).^2);
                    
                    % Recall correct
                    TP = sum((y_ph >= high_risk_threshold) & (y_h >= high_risk_threshold));
                    FN = sum((y_ph < high_risk_threshold) & (y_h >= high_risk_threshold));
                    if (TP + FN) > 0
                        cv_scores.recall(a_idx, fold) = TP / (TP + FN);
                    else
                        cv_scores.recall(a_idx, fold) = 0;
                    end
                else
                    cv_scores.R2_high(a_idx, fold) = 0;
                    cv_scores.MSE_high(a_idx, fold) = 0;
                    cv_scores.recall(a_idx, fold) = 0;
                end
            end
            fprintf(' terminé\n');
        end
        
        % Moyenne sur les folds
        mean_R2_global = mean(cv_scores.R2_global, 2);
        mean_R2_high = mean(cv_scores.R2_high, 2);
        mean_recall = mean(cv_scores.recall, 2);
        mean_MSE_high = mean(cv_scores.MSE_high, 2);
        
    else
        % ========== VALIDATION SIMPLE (fallback) ==========
        warning('Utilisation validation simple (données insuffisantes pour CV)');
        
        % Séparer train/val à partir du train
        n_val_simple = floor(0.2 * n_train);
        simple_idx = randperm(n_train);
        
        train_simple_idx = simple_idx(1:end-n_val_simple);
        val_simple_idx = simple_idx(end-n_val_simple+1:end);
        
        X_train_simple = X_train(train_simple_idx, :);
        y_train_simple = y_train(train_simple_idx);
        X_val_simple = X_train(val_simple_idx, :);
        y_val_simple = y_train(val_simple_idx);
        
        % Initialiser les résultats
        mean_R2_global = zeros(length(alphas), 1);
        mean_R2_high = zeros(length(alphas), 1);
        mean_recall = zeros(length(alphas), 1);
        mean_MSE_high = zeros(length(alphas), 1);
        
        for a_idx = 1:length(alphas)
            alpha = alphas(a_idx);
            b_simple = train_wls(X_train_simple, y_train_simple, alpha, high_risk_threshold);
            
            X_val_simple_d = [ones(size(X_val_simple,1),1), X_val_simple];
            y_pred_simple = X_val_simple_d * b_simple;
            
            % Métriques globales
            ss_res = sum((y_val_simple - y_pred_simple).^2);
            ss_tot = sum((y_val_simple - mean(y_val_simple)).^2);
            
            if ss_tot > 0
                mean_R2_global(a_idx) = 1 - ss_res/ss_tot;
            end
            
            % Métriques high-risk
            high_mask = y_val_simple >= high_risk_threshold;
            if any(high_mask)
                y_h = y_val_simple(high_mask);
                y_ph = y_pred_simple(high_mask);
                
                ss_res_high = sum((y_h - y_ph).^2);
                ss_tot_high = sum((y_h - mean(y_h)).^2);
                
                if ss_tot_high > 0
                    mean_R2_high(a_idx) = 1 - ss_res_high/ss_tot_high;
                end
                
                mean_MSE_high(a_idx) = mean((y_h - y_ph).^2);
                
                % Recall
                TP = sum((y_ph >= high_risk_threshold) & (y_h >= high_risk_threshold));
                FN = sum((y_ph < high_risk_threshold) & (y_h >= high_risk_threshold));
                if (TP + FN) > 0
                    mean_recall(a_idx) = TP / (TP + FN);
                end
            end
        end
    end
    
    % ========== SELECTION DU MEILLEUR ALPHA ==========
    % Critères de sélection
    valid_alphas = find(mean_recall >= 0.8 & ...
                        mean_MSE_high < 0.1 & ...
                        mean_R2_high > 0.25);
    
    if isempty(valid_alphas)
        warning('❌ Aucun alpha ne satisfait tous les critères');
        fprintf('Relaxation des critères...\n');
        
        % Relaxer progressivement
        for recall_thresh = [0.7, 0.6, 0.5]
            for mse_thresh = [0.15, 0.2, 0.25]
                valid_alphas = find(mean_recall >= recall_thresh & ...
                                    mean_MSE_high < mse_thresh & ...
                                    mean_R2_high > 0.2);
                if ~isempty(valid_alphas)
                    fprintf('Critères relaxés : recall≥%.1f, MSE<%.2f\n', ...
                            recall_thresh, mse_thresh);
                    break;
                end
            end
            if ~isempty(valid_alphas), break; end
        end
        
        % Dernier recours : meilleur R² global
        if isempty(valid_alphas)
            warning('Dernier recours : alpha avec meilleur R² global');
            [~, best_alpha_idx] = max(mean_R2_global);
        else
            [~, local_best] = max(mean_R2_global(valid_alphas));
            best_alpha_idx = valid_alphas(local_best);
        end
    else
        [~, local_best] = max(mean_R2_global(valid_alphas));
        best_alpha_idx = valid_alphas(local_best);
    end
    
    best_alpha = alphas(best_alpha_idx);
    
    % ========== AFFICHAGE DES RESULTATS CV ==========
    fprintf('\n=== RESULTATS DE LA VALIDATION CROISEE ===\n');
    fprintf('Meilleur alpha : %.1f\n', best_alpha);
    fprintf('R² global (CV moyen) : %.3f\n', mean_R2_global(best_alpha_idx));
    fprintf('R² high-risk (CV moyen) : %.3f\n', mean_R2_high(best_alpha_idx));
    fprintf('Recall high-risk (CV moyen) : %.3f\n', mean_recall(best_alpha_idx));
    fprintf('MSE high-risk (CV moyen) : %.3f\n', mean_MSE_high(best_alpha_idx));
    
    % ========== ENTRAINEMENT FINAL SUR TRAIN+VAL ==========
    fprintf('\n=== ENTRAINEMENT FINAL ===\n');
    
    % Concaténer train et val pour l'entraînement final
    X_train_full = [X_train; X_val];
    y_train_full = [y_train; y_val];
    
    % Réentraîner avec le meilleur alpha
    b_final = train_wls(X_train_full, y_train_full, best_alpha, high_risk_threshold);
    
    % ========== PERFORMANCE SUR VALIDATION (pour référence) ==========
    X_val_d = [ones(size(X_val,1),1), X_val];
    y_pred_val = X_val_d * b_final;
    
    % Métriques sur validation
    ss_res_val = sum((y_val - y_pred_val).^2);
    ss_tot_val = sum((y_val - mean(y_val)).^2);
    if ss_tot_val > 0
        val_R2 = 1 - ss_res_val/ss_tot_val;
    else
        val_R2 = 0;
    end
    
    high_mask_val = y_val >= high_risk_threshold;
    if any(high_mask_val)
        y_h_val = y_val(high_mask_val);
        y_ph_val = y_pred_val(high_mask_val);
        
        ss_res_val_high = sum((y_h_val - y_ph_val).^2);
        ss_tot_val_high = sum((y_h_val - mean(y_h_val)).^2);
        if ss_tot_val_high > 0
            val_R2_high = 1 - ss_res_val_high/ss_tot_val_high;
        else
            val_R2_high = 0;
        end
        
        % Recall correct pour validation
        TP_val = sum((y_ph_val >= high_risk_threshold) & (y_h_val >= high_risk_threshold));
        FN_val = sum((y_ph_val < high_risk_threshold) & (y_h_val >= high_risk_threshold));
        if (TP_val + FN_val) > 0
            val_recall = TP_val / (TP_val + FN_val);
        else
            val_recall = 0;
        end
    else
        val_R2_high = 0;
        val_recall = 0;
    end
    
    fprintf('Performance sur validation (pour info) :\n');
    fprintf('  R² global (val) : %.3f\n', val_R2);
    fprintf('  R² high-risk (val) : %.3f\n', val_R2_high);
    fprintf('  Recall high-risk (val) : %.3f\n', val_recall);
    
    % ========== STOCKAGE DES RESULTATS ==========
    performance = struct();
    performance.alpha_results.mean_R2_global = mean_R2_global;
    performance.alpha_results.mean_R2_high = mean_R2_high;
    performance.alpha_results.mean_recall = mean_recall;
    performance.alpha_results.mean_MSE_high = mean_MSE_high;
    performance.best_alpha_idx = best_alpha_idx;
    performance.best_alpha = best_alpha;
    performance.alphas = alphas;
    performance.cv_scores = cv_scores;
    performance.val_R2 = val_R2;
    performance.val_R2_high = val_R2_high;
    performance.val_recall = val_recall;
    
    fprintf('✅ Modèle entraîné avec alpha = %.1f\n', best_alpha);
end