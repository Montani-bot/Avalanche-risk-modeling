function display_data_info(X, y, var_names, station_path)
%% Affiche les informations sur les données
    
    [~, station_name, station_ext] = fileparts(station_path);
    station_filename = strcat(station_name, station_ext);
    
    fprintf("\n=============================================================\n");
    fprintf("  ➤ Station météorologique : %s\n", station_filename);
    fprintf("=============================================================\n\n");
    
    n_days = length(y);
    n_vars = size(X, 2);
    
    fprintf("\n-------------------------------------------------------------\n");
    fprintf("     Données restantes après préparation / nettoyage\n");
    fprintf("-------------------------------------------------------------\n");
    fprintf("  ➤ Nombre total de jours conservés : %d\n", n_days);
    fprintf("  ➤ Nombre de variables météo utilisées : %d\n", n_vars);
    fprintf("  ➤ Ces données seront utilisées pour :\n");
    fprintf("        - l'entraînement du modèle\n");
    fprintf("        - le test final du modèle\n");
    fprintf("-------------------------------------------------------------\n\n");
end

