function [y_pred, metrics] = evaluate_model(...
    X_test, y_test, b_final, mu, sigma, high_risk_threshold)
%% Evaluate the model on test data     
    % Normalisation of test data 
    X_test_n = (X_test - mu) ./ sigma;
    X_test_d = [ones(size(X_test_n, 1), 1), X_test_n];
    
    % Prédiction
    y_pred = X_test_d * b_final;
    
    % global metrics calculation 
    metrics.R2_test = 1 - sum((y_test - y_pred).^2) / sum((y_test - mean(y_test)).^2);
    metrics.MSE_test = mean((y_test - y_pred).^2);
    
    % high-risk metrics 
    idx_high = (y_test > high_risk_threshold);
    y_h = y_test(idx_high);
    y_ph = y_pred(idx_high);

    % True high-risk
    true_high_mask = (y_test >= high_risk_threshold);
    % Predicted high-risk
    pred_high_mask = (y_pred >= high_risk_threshold);
    
    % === Confusion Matrix  ===
    TP = sum(pred_high_mask & true_high_mask);       % vrai positif
    FN = sum(~pred_high_mask & true_high_mask);      % faux négatif
    FP = sum(pred_high_mask & ~true_high_mask);      % faux positif
    
    if ~isempty(y_h)
        metrics.R2_high_final = 1 - sum((y_h - y_ph).^2) / sum((y_h - mean(y_h)).^2);
        metrics.MSE_high_final = mean((y_h - y_ph).^2);
        metrics.MAE_high_final = mean(abs(y_h - y_ph));
    else
        metrics.R2_high_final = NaN;
        metrics.MSE_high_final = NaN;
        metrics.MAE_high_final = NaN;
    end

    % === Recall and Precision ===
    if (TP + FN) > 0
        metrics.recall_high_final = TP / (TP + FN);
    else
        metrics.recall_high_final = NaN;
    end

    if (TP + FP) > 0
        metrics.precision_high_final = TP / (TP + FP);
    else
        metrics.precision_high_final = NaN;
    end
end
