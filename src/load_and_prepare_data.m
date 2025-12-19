function [T] = load_and_prepare_data(station_path, sector_id)
%% Load and prepare meteorological and risk data
% Returns a table T sorted by date containing several variable columns and one SLF risk column
    
% Determine the project directory    
    script_dir = fileparts(mfilename('fullpath'));
    project_root = fullfile(script_dir, '..');
    
    % load the meteo data 
    data_meteo = readtable(station_path);
    
    % Convert dates 
    data_meteo.date = datetime(data_meteo.reference_timestamp, ...
        'InputFormat', 'dd.MM.yyyy HH:mm');
    
    % Rename variables
    data_meteo = renamevars(data_meteo, ...
        {'fkl010d0','gre000d0','htoautd0','rka150d0','sre000d0','tre005d0','tso020d0','ure200d0'}, ...
        {'wind_speed','radiation','snow_depth_6UTC','precipitation_daily_sum_0UTC', ...
         'sunshine_duration','temperature_5cm','temperature_20cm_sol','humidity'});
    
    % Select variable of interest 
    vars_to_keep = {'date','wind_speed','radiation','snow_depth_6UTC', ...
        'precipitation_daily_sum_0UTC','sunshine_duration','temperature_5cm', ...
        'temperature_20cm_sol','humidity'};
    data_meteo = data_meteo(:, vars_to_keep);
    
    % load SLF risk data 
    filename = fullfile(project_root, 'data', 'risk_index_slf.csv');
    data_risk_swiss = readtable(filename);
    
    % Filtre by sector 
    data_station_risk = data_risk_swiss(data_risk_swiss.sector_id == sector_id, :);
    
% Sort and format the risk data    
    sorted_data_risk = sortrows(data_station_risk, 'date');
    sorted_data_risk.date = datetime(sorted_data_risk.date, 'InputFormat', 'dd.MM.yyyy HH:mm');
    sorted_data_risk = renamevars(sorted_data_risk, 'level_detail_numeric', 'risk_index');
    sorted_data_risk = sorted_data_risk(:, {'date', 'risk_index'});
    
    % Join the two tables
    T = innerjoin(data_meteo, sorted_data_risk, 'Keys', 'date');
    
end
