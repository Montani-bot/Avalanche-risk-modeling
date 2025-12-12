%% cette fonction à pour but d'entrainer/calibrer le model personnalisé pour la station choisie en input 
function [best_alpha, b_final, performance] = train_model(...
    X_train, X_val, y_train, y_val, ...
    mu, sigma, alphas, high_risk_threshold)
    %% === Normalisation ===
    X_train_n = (X_train - mu) ./ sigma; % mu et sigma proviennent du fichier split_data.m 
    X_val_n = (X_val - mu) ./ sigma; 
    
    X_train_d = [ones(size(X_train_n, 1), 1), X_train_n];
    X_val_d = [ones(size(X_val_n, 1), 1), X_val_n];
    
    %% === Calibration de alpha ===
    num_alphas = length(alphas);
    % metric choisies pour entrainer et calibrer le modèle
    R2_global = zeros(num_alphas, 1);
    MSE_global = zeros(num_alphas, 1);
    precision_high = zeros(num_alphas, 1);

    R2_high = zeros(num_alphas, 1);
    MSE_high = zeros(num_alphas, 1);
    MAE_high = zeros(num_alphas, 1);
    recall_high = zeros(num_alphas, 1);
    
    for i = 1:num_alphas
        alpha = alphas(i);
        
        % WLS sur TRAIN
        w = 1 + alpha * (y_train > high_risk_threshold);
        W = diag(w);
        b = (X_train_d' * W * X_train_d) \ (X_train_d' * W * y_train);
        
        % Prédiction sur VALIDATION
        y_pred_val = X_val_d * b;
        
        % Métriques globales
        R2_global(i) = 1 - sum((y_val - y_pred_val).^2) / sum((y_val - mean(y_val)).^2);
        MSE_global(i) = mean((y_val - y_pred_val).^2);
        
        % Métriques high-risk
        idx_high = (y_val > high_risk_threshold);
        y_h = y_val(idx_high);
        y_ph = y_pred_val(idx_high);
        
        
        if ~isempty(y_h)
            R2_high(i) = 1 - sum((y_h - y_ph).^2) / sum((y_h - mean(y_h)).^2);
            MSE_high(i) = mean((y_h - y_ph).^2);
            MAE_high(i) = mean(abs(y_h - y_ph));
        end

        % vrai high-risk
        true_high_mask = (y_val > high_risk_threshold);  % true si risque élevé
        
        % Prédictions high-risk
        pred_high_mask = (y_pred_val > high_risk_threshold);  % true si prédit élevé
        
        % Matrice de confusion 
        TP = sum(pred_high_mask & true_high_mask);    % Vrai positif
        FN = sum(~pred_high_mask & true_high_mask);   % Faux négatif
        FP = sum(pred_high_mask & ~true_high_mask);   % Faux positif
        TN = sum(~pred_high_mask & ~true_high_mask)
        confusion_matrix = [TP, FP, FN, TN];

        % Calcul du recall (sensibilité)
        if (TP + FN) > 0
            recall_high(i) = TP / (TP + FN);
        else
            % Si aucun vrai high-risk dans y_val
            recall_high(i) = 0;
        end

        % Precision
        if (TP + FP) > 0
            precision_high(i) = TP / (TP + FP);
        else
            precision_high(i) = 0;
        end
    end
    
    %% === Sélection du meilleur alpha ===
    valid_idx = find(recall_high >= 0.8 & precision_high >= 0.30 & MSE_high < 0.15 & R2_high > 0.2);
    
    if isempty(valid_idx)
        warning("❌ Aucun alpha ne satisfait les contraintes sur VALIDATION. Sélection par meilleur R² global.");
        [~, best_idx] = max(R2_global);
    else
        [~, local_best] = max(R2_global(valid_idx));
        best_idx = valid_idx(local_best);
    end
    
    best_alpha = alphas(best_idx);
    
    %% === Affichage des résultats de calibration ===
    fprintf("\n===== CALIBRATION DE ALPHA RESULTAT DU TEST INTERNE =====\n");
    fprintf("Best alpha = %.2f\n", best_alpha);
    fprintf("R² global (val) = %.3f\n", R2_global(best_idx));
    fprintf("R² high-risk (val) = %.3f\n", R2_high(best_idx));
    fprintf("Recall high-risk (val) = %.3f\n", recall_high(best_idx));
    fprintf("precision high-risk (val) = %.3f\n", precision_high(best_idx));
    fprintf("MSE high-risk (val) = %.3f\n", MSE_high(best_idx));
    
    %% === Entraînement final sur la partie du train n'ayant pas servit pour tester alpha (evite la fuite de donnée)=== 
    w_final = 1 + best_alpha * (y_train > high_risk_threshold);
    W_final = diag(w_final);
    
    b_final = (X_train_d' * W_final * X_train_d) \ ...
              (X_train_d' * W_final * y_train);
    
    %% === Stockage des performances ===
    performance.alpha_results.R2_global = R2_global;
    performance.alpha_results.R2_high = R2_high;
    performance.alpha_results.recall_high = recall_high;
    performance.alpha_results.precision_high = precision_high;
    performance.best_idx = best_idx;
    performance.best_alpha = best_alpha;
end

