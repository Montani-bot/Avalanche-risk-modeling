function display_final_performance(metrics, high_risk_threshold, b_final, var_names)
%% Affiche les performances finales du modèle ainsi que les coefficients dans le terminal 
    
    fprintf("\n   ===========================================================================\n");
    fprintf("                 🌟 FINAL MODEL PERFORMANCE ON THE TEST SAMPLE 🌟\n");
    fprintf("   ============================================================================\n");
    
    fprintf("🔹 Global Performance\n");
    fprintf("   • R² global        : %8.4f\n", metrics.R2_test);
    fprintf("   • MSE global       : %8.4f\n", metrics.MSE_test);
    
    fprintf("\n🔸 High-Risk Performance (Risk index > %.1f)\n", high_risk_threshold);
    fprintf("   • R² high-risk        : %8.4f\n", metrics.R2_high_final);
    fprintf("   • MSE high-risk       : %8.4f\n", metrics.MSE_high_final);
    fprintf("   • MAE high-risk       : %8.4f\n", metrics.MAE_high_final);
    fprintf("   • Recall high-risk    : %8.4f\n", metrics.recall_high_final);
    fprintf("   • precision high-risk : %8.4f\n", metrics.precision_high_final);
    
    
    fprintf("=======================================================================\n\n");
end