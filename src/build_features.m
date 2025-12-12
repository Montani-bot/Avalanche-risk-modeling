function [X, y, var_names] = build_features(T)
    % ========== AJOUT SIMPLE DU CHEMIN BIN ==========
    % S'assurer que bin/ est dans le chemin MATLAB
    script_dir = fileparts(mfilename('fullpath'));
    project_root = fullfile(script_dir, '..');
    bin_dir = fullfile(project_root, 'bin');
    
    if ~contains(path, bin_dir)
        addpath(bin_dir);
        fprintf('✅ Dossier bin/ ajouté au chemin MATLAB\n');
    end
    
    %% Construit les features pour le modèle
    % Variables de base
    wind_speed = T.wind_speed;
    radiation = T.radiation;
    snow_depth = T.snow_depth_6UTC;
    precipitation = T.precipitation_daily_sum_0UTC;
    sunshine = T.sunshine_duration;
    temperature = T.temperature_5cm;
    humidity = T.humidity;

    % Ajout de la saison comme variable
    T.month = month(T.date);
    winter_days = ismember(T.month, [12, 1, 2, 3]);
    
    %% === Sommes mobiles ===
    precip_35j_sum = movsum_c(precipitation, 35);
    precip_20j_sum = movsum_c(precipitation, 20);
    precip_5j_sum = movsum_c(precipitation, 5);
    precip_2j_sum = movsum_c(precipitation, 2);
    
    
    temperature_5j_sum = movsum_ignore_nan_c(temperature, 5);
    radiation_5j_sum = movsum_c(radiation, 5);
    
    sunshine_10j_sum = movsum_c(sunshine, 10);
    sunshine_2j_sum = movsum_c(sunshine, 2);
    
    windspeed_10j_sum = movsum_c(wind_speed, 10);
    
    humidity_30j_sum = movsum_c(humidity, 30);
    humidity_15j_sum = movsum_c(humidity, 15);
    
    %% === Variations ===
    temp_delta_1j = diff_c(temperature, 1);
    snowdepth_delta_2j = diff_c(snow_depth, 2);
    
    %% === Extrêmes ===
    precip_extreme_5j = movquantil_c(precipitation, 15, 0.90);
    temp_extrem = movquantil_c(temperature, 7, 0);
    windspeed_extrem = movquantil_c(wind_speed, 10, 0.95);
    
    %% === Relations non linéaires ===
    precip_product = precip_2j_sum .* precip_35j_sum;
    precip_2j_square = precip_2j_sum .^ 2;
    temperature_square = temperature .^ 2;
    sunshine_duration_square = sunshine_2j_sum .^ 2;
    windspeed_square = wind_speed .^ 2;
    precip_recent_proportion = precip_5j_sum ./ (precip_35j_sum + eps); % + eps evite la division par 0
    precip_5j_square = precip_5j_sum .^ 2;
    windspeed_10j_sum_square = windspeed_10j_sum .^ 2;
    sunshine_radiation_product = radiation_5j_sum .* sunshine_2j_sum;
    temp_5j_sum_square = temperature_5j_sum .^ 2;
    temperature_radiation_product = product_c(temperature_5j_sum, radiation_5j_sum);
    windspeed_recent_snowfall_product = product_c(windspeed_10j_sum, precip_20j_sum);
    
    %% === Matrice des features ===
    X = [temperature_radiation_product, temp_delta_1j, temperature_square, ...
         snow_depth, winter_days,...
         precip_35j_sum, precip_recent_proportion, precip_extreme_5j, ...
         sunshine_radiation_product, ...
         humidity_30j_sum, humidity, ...
         windspeed_recent_snowfall_product, windspeed_extrem];
    
    %% === Noms des features ===
    var_names = {'temperature_radiation_product', 'temp_delta_1j', 'temperature_square', ...
                     'snow_depth_6UTC', 'winter_days', ...
                     'precip_35j_sum', 'precip_recent_proportion', 'precip_extreme_5j', ...
                     'sunshine_radiation_product', ...
                     'humidity_30j_sum', 'humidity', ...
                     'windspeed_recent_snowfall_product', 'windspeed_extrem'};
    
    %% === Nettoyage des colonnes NaN ===
    cols_nan = all(isnan(X), 1);
    if any(cols_nan)
        removed_vars = var_names(cols_nan);
        fprintf("⚠️ Suppression de %d variable(s) météo absente(s) : %s\n", ...
                sum(cols_nan), strjoin(removed_vars, ', '));
        X(:, cols_nan) = [];
        var_names(cols_nan) = [];
    end
    
    %% === Vecteur cible ===
    y = T.risk_index;
    
    %% === Suppression des lignes avec NaN ===
    valid_idx = all(~isnan(X), 2) & ~isnan(y);
    X = X(valid_idx, :);
    y = y(valid_idx);
end



