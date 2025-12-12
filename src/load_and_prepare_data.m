function [T] = load_and_prepare_data(station_path, sector_id)
%% Charge et prépare les données météo et de risque
% retourne un tableau T trié par date contenant plusieurs collones de variable et une collone de risque SLF
    
    % Déterminer le répertoire du projet
    script_dir = fileparts(mfilename('fullpath'));
    project_root = fullfile(script_dir, '..');
    
    % Charger les données météo
    data_meteo = readtable(station_path);
    
    % Convertir les dates
    data_meteo.date = datetime(data_meteo.reference_timestamp, ...
        'InputFormat', 'dd.MM.yyyy HH:mm');
    
    % Renommer les variables
    data_meteo = renamevars(data_meteo, ...
        {'fkl010d0','gre000d0','htoautd0','rka150d0','sre000d0','tre005d0','tso020d0','ure200d0'}, ...
        {'wind_speed','radiation','snow_depth_6UTC','precipitation_daily_sum_0UTC', ...
         'sunshine_duration','temperature_5cm','temperature_20cm_sol','humidity'});
    
    % Sélectionner les variables d'intérêt
    vars_to_keep = {'date','wind_speed','radiation','snow_depth_6UTC', ...
        'precipitation_daily_sum_0UTC','sunshine_duration','temperature_5cm', ...
        'temperature_20cm_sol','humidity'};
    data_meteo = data_meteo(:, vars_to_keep);
    
    % Charger les données de risque
    filename = fullfile(project_root, 'data', 'risk_index_slf.csv');
    data_risk_swiss = readtable(filename);
    
    % Filtrer par secteur
    data_station_risk = data_risk_swiss(data_risk_swiss.sector_id == sector_id, :);
    
    % Trier et formater les risques
    sorted_data_risk = sortrows(data_station_risk, 'date');
    sorted_data_risk.date = datetime(sorted_data_risk.date, 'InputFormat', 'dd.MM.yyyy HH:mm');
    sorted_data_risk = renamevars(sorted_data_risk, 'level_detail_numeric', 'risk_index');
    sorted_data_risk = sorted_data_risk(:, {'date', 'risk_index'});
    
    % Fusionner les tableaux
    T = innerjoin(data_meteo, sorted_data_risk, 'Keys', 'date');
    
end
