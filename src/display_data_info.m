function display_data_info(X, y, station_path, sector_of_interest)

%% Display information about the data    
    [~, station_name, station_ext] = fileparts(station_path);
    station_filename = strcat(station_name, station_ext);

    
    fprintf("\n=============================================================\n");
    fprintf("  ➤ Meteorological station : %s\n", station_filename);
    fprintf("  ➤ Corresponding SLF Region : %d\n", sector_of_interest);
    fprintf("=============================================================\n\n");
    
    n_days = length(y);
    n_vars = size(X, 2);
    
    fprintf("\n-------------------------------------------------------------\n");
    fprintf("     Data remaining after preparation / cleaning\n");
    fprintf("-------------------------------------------------------------\n");
    fprintf("  ➤ Total number of remaining days : %d\n", n_days);
    fprintf("  ➤ Number of meteorological variables used : %d\n", n_vars);
    fprintf("  ➤ Those data will be use for :\n");
    fprintf("        - model training\n");
    fprintf("        - model final testing\n");
    fprintf("-------------------------------------------------------------\n\n");
end

