function export_figures(y_test, y_pred_final, ...
    alphas, alpha_results, best_alpha, ...
    b_final, var_names, ...
    resultDir)
    %% Generate and export all figures to the Results folder
    % Create the Results folder if necessary
    if ~isfolder(resultDir)
        mkdir(resultDir);
    end
    
    timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    
    %% === Figure 1: Alpha calibration === 
    % Visual of the high-risk versus overall performance trade-off made during alpha selection 

    fig1 = figure('Visible', 'off', 'Name', 'Weight calibration via alpha');
    
    subplot(3, 1, 1);
    plot(alphas, alpha_results.R2_global, '-o'); hold on;
    plot(best_alpha, alpha_results.R2_global(best_alpha == alphas), ...
         'ro', 'MarkerSize', 10, 'LineWidth', 2);
    ylabel('R² global'); grid on;
    
    subplot(3, 1, 2);
    plot(alphas, alpha_results.R2_high, '-o'); hold on;
    plot(best_alpha, alpha_results.R2_high(best_alpha == alphas), ...
         'ro', 'MarkerSize', 10);
    ylabel('R² high-risk'); grid on;
    
    subplot(3, 1, 3);
    plot(alphas, alpha_results.recall_high, '-o'); hold on;
    plot(best_alpha, alpha_results.recall_high(best_alpha == alphas), ...
         'ro', 'MarkerSize', 10);
    xlabel('alpha'); ylabel('Recall high-risk'); grid on;
    
    sgtitle('Calibration de alpha pour WLS');
    
    save_figure(fig1, 'alpha_calibration', resultDir, timestamp);
    
    %% === Figure 2: Variables importance === 
    fig2 = figure('Visible', 'off', 'Name', 'Importance of variables');
    bar(b_final(2:end));
    
    set(gca, 'XTickLabel', var_names, ...
             'XTickLabelRotation', 45, ...
             'FontSize', 14, ...
             'FontWeight', 'bold', ...
             'TickLabelInterpreter', 'none');
    
    title('Importance of weather parameters in avalanche risk prediction', ...
          'FontSize', 18, 'FontWeight', 'bold');
    ylabel('Linear regression coefficient', 'FontSize', 16);
    xlabel('Meteorological Variables', 'FontSize', 16);
    grid on;
    
    save_figure(fig2, 'variable_importance', resultDir, timestamp);
    
    %% === Figure 3: Prédictions vs Observations === 
    fig3 = figure('Visible', 'off', 'Name', 'Model predictions VS SLF risk');
    scatter(y_test, y_pred_final, 'filled');
    hold on;
    plot([0 5], [0 5], 'r--', 'LineWidth', 1.5);
    xlabel('Observed risk (SLF)');
    ylabel('Predicted risk');
    title('Prediction vs Observation');
    grid on;
    
    save_figure(fig3, 'predictions_vs_observations', resultDir, timestamp);
    
    %% === Figure 4: Error analysis by risk level ===
    % Here, a significant error is considered to be a prediction with a deviation from the SLF risk greater than 0.165
    risk_levels = [1, 1.33, 1.67, 2, 2.33, 2.67, 3, 3.33, 3.67, 4, 4.33];
    errors_per_level = zeros(length(risk_levels), 1);
    error_threshold = 0.165;
    
    for i = 1:length(risk_levels)
        L = risk_levels(i);
        idx = abs(y_test - L) < 1e-6;
        y_true_L = y_test(idx);
        y_pred_L = y_pred_final(idx);
        
        if ~isempty(y_true_L)
            errors = abs(y_true_L - y_pred_L) > error_threshold;
            errors_per_level(i) = sum(errors);
        end
    end
    
    fig4 = figure('Visible', 'off', 'Name', 'errors number per risk level');
    bar(risk_levels, errors_per_level);
    xlabel('Niveau de risque SLF (réel)');
    ylabel('Nombre d''erreurs');
    title('Erreurs de prédiction par niveau de risque SLF');
    grid on;
    
    save_figure(fig4, 'errors_by_risk_level', resultDir, timestamp);
end

%% This function saves the plots as PNG files in the Results folder 
function save_figure(fig, name, resultDir, timestamp)
 % Save an individual figure
    set(fig, 'Visible', 'on');
    pngName = fullfile(resultDir, sprintf('%s_%s.png', name, timestamp));
    
    try
        exportgraphics(fig, pngName, 'Resolution', 300);
    catch
        print(fig, pngName, '-dpng', '-r300');
    end
end
