function [X, y, var_names] = build_features(T)
    %% ========== SIMPLE ADDITION OF BIN PATH FOR EXECUTABLE USAGE ==========
    % Ensure that bin/ is in the MATLAB path
    script_dir = fileparts(mfilename('fullpath'));
    project_root = fullfile(script_dir, '..');
    bin_dir = fullfile(project_root, 'bin');
    
    if ~contains(path, bin_dir)
        addpath(bin_dir);
        fprintf('✅ Dossier bin/ ajouté au chemin MATLAB\n');
    end

    %% Build features for the model
    % Some features have been kept even if not used. They serve as suggestions for adding new variables and may help improve the model's predictions for the station of interest.
    % Base variables
    wind_speed = T.wind_speed;
    radiation = T.radiation;
    snow_depth = T.snow_depth_6UTC;
    precipitation = T.precipitation_daily_sum_0UTC;
    sunshine = T.sunshine_duration;
    temperature = T.temperature_5cm;
    humidity = T.humidity;

    % Add winter season as a variable 
    T.month = month(T.date);
    winter_days = ismember(T.month, [12, 1, 2, 3]);
    
    %% === Moving sums computed with  the movsum_c.c function ===
    precip_35j_sum = movsum_c(precipitation, 35);
    precip_20j_sum = movsum_c(precipitation, 20);
    precip_10j_sum = movsum_c(precipitation, 10);
    
    temperature_5j_sum = movsum_ignore_nan_c(temperature, 5);
    radiation_5j_sum = movsum_c(radiation, 5);
    
    sunshine_10j_sum = movsum_c(sunshine, 10); 
    sunshine_2j_sum = movsum_c(sunshine, 2);
    
    windspeed_10j_sum = movsum_c(wind_speed, 10);
    
    humidity_30j_sum = movsum_c(humidity, 30);

    %% === Variations ===
    temp_delta_1j = diff_c(temperature, 1);
    snowdepth_delta_2j = diff_c(snow_depth, 2);
    
    %% === Extremes ===
    precip_extreme_15j = movquantil_c(precipitation, 15, 0.90);
    temp_extrem = movquantil_c(temperature, 7, 0);
    windspeed_extrem = movquantil_c(wind_speed, 10, 0.95);
    
    %% === Non-linear relations ===
    temperature_square = temperature .^ 2;
    precip_recent_proportion = precip_10j_sum ./ (precip_35j_sum + eps); % + eps avoid dividing by 0 
    sunshine_radiation_product = radiation_5j_sum .* sunshine_2j_sum;
    temp_5j_sum_square = temperature_5j_sum .^ 2;
    temperature_radiation_product = product_c(temperature_5j_sum, radiation_5j_sum);
    windspeed_recent_snowfall_product = product_c(windspeed_10j_sum, precip_20j_sum);
    
    %% === Final matrix of meteorological parameters used for model training and testing ===
    X = [temp_delta_1j, temperature_square, ...
         snow_depth, winter_days,...
         precip_35j_sum, precip_extreme_15j, ...
         sunshine_radiation_product, ...
         humidity_30j_sum, humidity, ...
         windspeed_recent_snowfall_product, windspeed_extrem];
    
    %% === Names of selected parameters ===
    % usefull for display 
    var_names = { 'temp_delta_1j', 'temperature_square', ...
                     'snow_depth_6UTC', 'winter_days', ...
                     'precip_35j_sum', 'precip_extreme_5j', ...
                     'sunshine_radiation_product', ...
                     'humidity_30j_sum', 'humidity', ...
                     'windspeed_recent_snowfall_product', 'windspeed_extrem'};
    
    %% === Cleaning of NAN columns ===
    cols_nan = all(isnan(X), 1);
    if any(cols_nan)
        removed_vars = var_names(cols_nan);
        fprintf("⚠️ Suppression de %d variable(s) météo absente(s) : %s\n", ...
                sum(cols_nan), strjoin(removed_vars, ', '));
        X(:, cols_nan) = [];
        var_names(cols_nan) = [];
    end
    
    %% === SLF risk vector on which the model will train and be tested ===
    y = T.risk_index;
    
    %% === Suppress NaN-including rows ===
    valid_idx = all(~isnan(X), 2) & ~isnan(y);
    X = X(valid_idx, :);
    y = y(valid_idx);
end



