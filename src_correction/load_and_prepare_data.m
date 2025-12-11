function [T, var_names_base] = load_and_prepare_data(station_path, sector_id)
%% Charge et prépare les données météo et de risque avec validation
    
    % ========== VALIDATION DES ENTREES ==========
    if ~isfile(station_path)
        error('❌ Fichier station introuvable : %s', station_path);
    end
    
    % ========== CHARGEMENT METEO ==========
    try
        data_meteo = readtable(station_path);
    catch ME
        error('❌ Erreur lecture fichier météo : %s', ME.message);
    end
    
    % Vérifier les colonnes requises
    required_cols = {'reference_timestamp', 'fkl010d0', 'gre000d0', ...
                     'htoautd0', 'rka150d0', 'sre000d0', 'tre005d0', ...
                     'tso020d0', 'ure200d0'};
    missing_cols = setdiff(required_cols, data_meteo.Properties.VariableNames);
    if ~isempty(missing_cols)
        warning('⚠️ Colonnes manquantes dans données météo : %s', ...
                strjoin(missing_cols, ', '));
    end
    
    % ========== TRAITEMENT DES DATES ==========
    % Conversion avec gestion d'erreurs
    try
        data_meteo.date = datetime(data_meteo.reference_timestamp, ...
            'InputFormat', 'dd.MM.yyyy HH:mm');
    catch
        % Essayer un autre format si nécessaire
        data_meteo.date = datetime(data_meteo.reference_timestamp);
    end
    
    % Supprimer les dates invalides
    invalid_dates = isnat(data_meteo.date);
    if any(invalid_dates)
        warning('⚠️ %d dates invalides supprimées', sum(invalid_dates));
        data_meteo(invalid_dates, :) = [];
    end
    
    % ========== RENOMMAGE DES VARIABLES ==========
    rename_map = containers.Map(...
        {'fkl010d0','gre000d0','htoautd0','rka150d0','sre000d0','tre005d0','tso020d0','ure200d0'}, ...
        {'wind_speed','radiation','snow_depth_6UTC','precipitation_daily_sum_0UTC', ...
         'sunshine_duration','temperature_5cm','temperature_20cm_sol','humidity'});
    
    for old_name = keys(rename_map)
        old_name = old_name{1};
        if ismember(old_name, data_meteo.Properties.VariableNames)
            new_name = rename_map(old_name);
            data_meteo = renamevars(data_meteo, old_name, new_name);
        end
    end
    
    % ========== SELECTION DES VARIABLES ==========
    vars_to_keep = {'date','wind_speed','radiation','snow_depth_6UTC', ...
        'precipitation_daily_sum_0UTC','sunshine_duration','temperature_5cm', ...
        'temperature_20cm_sol','humidity'};
    
    % Ne garder que les variables disponibles
    available_vars = intersect(vars_to_keep, data_meteo.Properties.VariableNames);
    data_meteo = data_meteo(:, available_vars);
    
    % ========== CHARGEMENT DES RISQUES ==========
    script_dir = fileparts(mfilename('fullpath'));
    project_root = fullfile(script_dir, '..');
    risk_file = fullfile(project_root, 'data', 'risk_index_slf.csv');
    
    if ~isfile(risk_file)
        error('❌ Fichier risque SLF introuvable : %s', risk_file);
    end
    
    try
        data_risk_swiss = readtable(risk_file);
    catch ME
        error('❌ Erreur lecture fichier risque : %s', ME.message);
    end
    
    % Vérifier la présence du secteur
    if ~ismember(sector_id, data_risk_swiss.sector_id)
        error('❌ Secteur %d non trouvé dans les données SLF', sector_id);
    end
    
    % ========== FILTRAGE ET TRI DES RISQUES ==========
    data_station_risk = data_risk_swiss(data_risk_swiss.sector_id == sector_id, :);
    
    if isempty(data_station_risk)
        error('❌ Aucune donnée risque pour le secteur %d', sector_id);
    end
    
    % Trier et convertir les dates
    sorted_data_risk = sortrows(data_station_risk, 'date');
    sorted_data_risk.date = datetime(sorted_data_risk.date, ...
        'InputFormat', 'dd.MM.yyyy HH:mm');
    
    % Supprimer dates invalides dans les risques
    invalid_risk_dates = isnat(sorted_data_risk.date);
    sorted_data_risk(invalid_risk_dates, :) = [];
    
    % Renommer et sélectionner
    sorted_data_risk = renamevars(sorted_data_risk, ...
        'level_detail_numeric', 'risk_index');
    sorted_data_risk = sorted_data_risk(:, {'date', 'risk_index'});
    
    % ========== FUSION DES DONNEES ==========
    % Vérifier le chevauchement temporel
    min_meteo_date = min(data_meteo.date);
    max_meteo_date = max(data_meteo.date);
    min_risk_date = min(sorted_data_risk.date);
    max_risk_date = max(sorted_data_risk.date);
    
    if max_meteo_date < min_risk_date || min_meteo_date > max_risk_date
        warning('⚠️ Pas de chevauchement temporel entre météo (%s-%s) et risque (%s-%s)', ...
                datestr(min_meteo_date), datestr(max_meteo_date), ...
                datestr(min_risk_date), datestr(max_risk_date));
    end
    
    % Fusionner avec inner join (garder seulement les dates communes)
    T = innerjoin(data_meteo, sorted_data_risk, 'Keys', 'date');
    
    if isempty(T)
        error('❌ Aucune date commune entre données météo et risques');
    end
    
    % Trier par date
    T = sortrows(T, 'date');
    
    % ========== VERIFICATION DE LA QUALITE ==========
    % Vérifier les valeurs manquantes
    missing_percent = sum(ismissing(T)) / height(T) * 100;
    high_missing = missing_percent > 50;
    
    if any(high_missing)
        high_missing_vars = T.Properties.VariableNames(high_missing);
        warning('⚠️ Variables avec >50%% valeurs manquantes : %s', ...
                strjoin(high_missing_vars, ', '));
    end
    
    % Vérifier les plages de valeurs
    if ismember('risk_index', T.Properties.VariableNames)
        valid_risk = all(T.risk_index >= 1 & T.risk_index <= 5);
        if ~valid_risk
            warning('⚠️ Valeurs de risk_index hors limites [1,5]');
        end
    end
    
    % ========== RETOUR DES VARIABLES ==========
    var_names_base = T.Properties.VariableNames;
    
    fprintf('✅ Données chargées : %d jours, %d variables\n', ...
            height(T), width(T));
end
