function display_final_performance(metrics, high_risk_threshold)
%% Affiche les performances finales
    
    fprintf("\n   ===========================================================================\n");
    fprintf("                 🌟 PERFORMANCES FINALES DU MODEL SUR L'ECHANTILLON TEST 🌟\n");
    fprintf("   ============================================================================\n");
    
    fprintf("🔹 Global Performance\n");
    fprintf("   • R² global        : %8.4f\n", metrics.R2_test);
    fprintf("   • MSE global       : %8.4f\n", metrics.MSE_test);
    
    fprintf("\n🔸 High-Risk Performance (Risk index ≥ %.1f)\n", high_risk_threshold);
    fprintf("   • R² high-risk     : %8.4f\n", metrics.R2_high_final);
    fprintf("   • MSE high-risk    : %8.4f\n", metrics.MSE_high_final);
    fprintf("   • MAE high-risk    : %8.4f\n", metrics.MAE_high_final);
    fprintf("   • Recall high-risk : %8.4f\n", metrics.recall_final);
    
    fprintf("=======================================================================\n\n");
    
    % Affichage des coefficients
    fprintf("\n=================== Coefficients de la régression ===================\n");
    fprintf("%-35s %10s\n", 'Variable', 'Coefficient');
    fprintf('%s\n', repmat('-', 1, 50));
end