function [y_pred, metrics, y_pred_all] = evaluate_model(...
    X_test, y_test, b_final, mu, sigma, high_risk_threshold)
%% Évaluation complète du modèle
    
    % ========== PREDICTION ==========
    X_test_n = (X_test - mu) ./ sigma;
    X_test_d = [ones(size(X_test_n,1),1), X_test_n];
    y_pred = X_test_d * b_final;
    
    % Limiter les prédictions aux plages plausibles
    y_pred = max(min(y_pred, 5), 1);  % Entre 1 et 5 comme le risque SLF
    
    % ========== METRIQUES GLOBALES ==========
    % R² et MSE
    ss_res = sum((y_test - y_pred).^2);
    ss_tot = sum((y_test - mean(y_test)).^2);
    
    if ss_tot == 0
        metrics.R2_test = NaN;
    else
        metrics.R2_test = 1 - ss_res / ss_tot;
    end
    
    metrics.MSE_test = mean((y_test - y_pred).^2);
    metrics.RMSE_test = sqrt(metrics.MSE_test);
    metrics.MAE_test = mean(abs(y_test - y_pred));
    
    % ========== METRIQUES HIGH-RISK ==========
    high_mask = y_test >= high_risk_threshold;
    
    if any(high_mask)
        y_h = y_test(high_mask);
        y_ph = y_pred(high_mask);
        
        % R² high-risk
        ss_res_high = sum((y_h - y_ph).^2);
        ss_tot_high = sum((y_h - mean(y_h)).^2);
        
        if ss_tot_high == 0
            metrics.R2_high_final = NaN;
        else
            metrics.R2_high_final = 1 - ss_res_high / ss_tot_high;
        end
        
        metrics.MSE_high_final = mean((y_h - y_ph).^2);
        metrics.MAE_high_final = mean(abs(y_h - y_ph));
        
        % Métriques de classification binaire
        TP = sum((y_ph >= high_risk_threshold) & (y_h >= high_risk_threshold));
        FP = sum((y_ph >= high_risk_threshold) & (y_h < high_risk_threshold));
        FN = sum((y_ph < high_risk_threshold) & (y_h >= high_risk_threshold));
        TN = sum((y_ph < high_risk_threshold) & (y_h < high_risk_threshold));
        
        % Recall (Sensibilité)
        if (TP + FN) > 0
            metrics.recall_final = TP / (TP + FN);
        else
            metrics.recall_final = NaN;
        end
        
        % Précision
        if (TP + FP) > 0
            metrics.precision_final = TP / (TP + FP);
        else
            metrics.precision_final = NaN;
        end
        
        % F1-score
        if (metrics.precision_final + metrics.recall_final) > 0
            metrics.f1_final = 2 * (metrics.precision_final * metrics.recall_final) / ...
                              (metrics.precision_final + metrics.recall_final);
        else
            metrics.f1_final = NaN;
        end
        
        % Spécificité
        if (TN + FP) > 0
            metrics.specificity_final = TN / (TN + FP);
        else
            metrics.specificity_final = NaN;
        end
        
        % AUC approximative (simplifiée)
        try
            [~,~,~,metrics.auc_final] = perfcurve(y_h >= high_risk_threshold, ...
                                                   y_ph, true);
        catch
            metrics.auc_final = NaN;
        end
        
    else
        % Aucun high-risk dans le test set
        warning('⚠️ Aucun high-risk dans l''ensemble test');
        metrics.R2_high_final = NaN;
        metrics.MSE_high_final = NaN;
        metrics.MAE_high_final = NaN;
        metrics.recall_final = NaN;
        metrics.precision_final = NaN;
        metrics.f1_final = NaN;
        metrics.specificity_final = NaN;
        metrics.auc_final = NaN;
    end
    
    % ========== METRIQUES PAR NIVEAU DE RISQUE ==========
    % Niveaux SLF discrets
    slf_levels = [1, 1.33, 1.67, 2, 2.33, 2.67, 3, 3.33, 3.67, 4, 4.33];
    metrics.by_level = struct();
    
    for i = 1:length(slf_levels)
        level = slf_levels(i);
        
        % Trouver les observations à ce niveau (tolérance ±0.01)
        idx_level = abs(y_test - level) < 0.01;
        
        if sum(idx_level) >= 3  % Au moins 3 observations pour être significatif
            y_true_level = y_test(idx_level);
            y_pred_level = y_pred(idx_level);
            
            metrics.by_level(i).level = level;
            metrics.by_level(i).count = sum(idx_level);
            metrics.by_level(i).MAE = mean(abs(y_true_level - y_pred_level));
            metrics.by_level(i).bias = mean(y_pred_level - y_true_level);
            metrics.by_level(i).std_error = std(y_pred_level - y_true_level);
        end
    end
    
    % ========== INTERVALLES DE CONFIANCE ==========
    % Erreur standard des prédictions
    residuals = y_test - y_pred;
    metrics.residual_std = std(residuals);
    metrics.residual_mean = mean(residuals);
    
    % Test de normalité des résidus
    try
        [~, metrics.residual_normality_p] = lillietest(residuals);
    catch
        metrics.residual_normality_p = NaN;
    end
    
    % ========== EVALUATION TEMPORELLE ==========
    % Vérifier si les erreurs sont corrélées dans le temps
    if length(residuals) > 10
        try
            [acf, lags] = xcorr(residuals - mean(residuals), 'coeff');
            % Autocorrélation au lag 1
            lag1_idx = find(lags == 1);
            if ~isempty(lag1_idx)
                metrics.autocorr_lag1 = acf(lag1_idx);
            else
                metrics.autocorr_lag1 = NaN;
            end
        catch
            metrics.autocorr_lag1 = NaN;
        end
    else
        metrics.autocorr_lag1 = NaN;
    end
    
    % ========== RETOUR COMPLET ==========
    y_pred_all = struct();
    y_pred_all.raw = y_pred;
    y_pred_all.residuals = residuals;
    y_pred_all.high_risk_mask = high_mask;
    
    fprintf('✅ Évaluation terminée sur %d observations test\n', length(y_test));
end