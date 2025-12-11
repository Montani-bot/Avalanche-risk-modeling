function [X, y, feature_names] = build_features(T, var_names_base)
%% Construit les features avec gestion robuste des données manquantes
    
    % ========== EXTRACTION ET VALIDATION DES VARIABLES DE BASE ==========
    required_vars = {'wind_speed', 'radiation', 'snow_depth_6UTC', ...
                     'precipitation_daily_sum_0UTC', 'sunshine_duration', ...
                     'temperature_5cm', 'humidity', 'risk_index'};
    
    missing_vars = setdiff(required_vars, T.Properties.VariableNames);
    if ~isempty(missing_vars)
        error('❌ Variables manquantes dans la table : %s', ...
              strjoin(missing_vars, ', '));
    end
    
    % Extraction avec conversion en double
    wind_speed = double(T.wind_speed);
    radiation = double(T.radiation);
    snow_depth = double(T.snow_depth_6UTC);
    precipitation = double(T.precipitation_daily_sum_0UTC);
    sunshine = double(T.sunshine_duration);
    temperature = double(T.temperature_5cm);
    humidity = double(T.humidity);
    
    % ========== IMPUTATION DES VALEURS MANQUANTES ==========
    % Remplacer les NaN par la médiane de la colonne
    data_matrix = [wind_speed, radiation, snow_depth, precipitation, ...
                   sunshine, temperature, humidity];
    
    for i = 1:size(data_matrix, 2)
        col = data_matrix(:, i);
        nan_idx = isnan(col);
        if any(nan_idx)
            col_median = median(col(~nan_idx), 'omitnan');
            if isnan(col_median)
                col_median = 0; % Fallback si toutes les valeurs sont NaN
            end
            col(nan_idx) = col_median;
            data_matrix(:, i) = col;
        end
    end
    
    % Réassigner les variables imputées
    [wind_speed, radiation, snow_depth, precipitation, ...
     sunshine, temperature, humidity] = deal(...
        data_matrix(:,1), data_matrix(:,2), data_matrix(:,3), ...
        data_matrix(:,4), data_matrix(:,5), data_matrix(:,6), ...
        data_matrix(:,7));
    
    % ========== FONCTION AUXILIAIRE POUR SOMMES MOBILES ==========
    function s = safe_movsum(data, window)
        % Gestion robuste des sommes mobiles
        s = movsum_c(data, window);
        % Remplacer les NaN aux bords par la valeur disponible la plus proche
        if any(isnan(s))
            for i = 1:length(s)
                if isnan(s(i))
                    % Chercher la première valeur non-NaN dans les fenêtres voisines
                    search_start = max(1, i - window);
                    search_end = min(length(s), i + window);
                    valid_vals = s(search_start:search_end);
                    valid_vals = valid_vals(~isnan(valid_vals));
                    if ~isempty(valid_vals)
                        s(i) = valid_vals(1);
                    else
                        s(i) = 0;
                    end
                end
            end
        end
    end
    
    % ========== CALCUL DES FEATURES AVEC GESTION DES ERREURS ==========
    try
        %% === Sommes mobiles ===
        precip_35j_sum = safe_movsum(precipitation, 35);
        precip_20j_sum = safe_movsum(precipitation, 20);
        precip_5j_sum = safe_movsum(precipitation, 5);
        precip_2j_sum = safe_movsum(precipitation, 2);
        
        % Pour temperature_5j_sum, utiliser ignore_nan pour cohérence
        temperature_5j_sum = movsum_ignore_nan_c(temperature, 5);
        
        % Remplacer les NaN résiduels
        if any(isnan(temperature_5j_sum))
            temperature_5j_sum(isnan(temperature_5j_sum)) = ...
                median(temperature_5j_sum, 'omitnan');
        end
        
        radiation_5j_sum = safe_movsum(radiation, 5);
        sunshine_10j_sum = safe_movsum(sunshine, 10);
        sunshine_2j_sum = safe_movsum(sunshine, 2);
        windspeed_10j_sum = safe_movsum(wind_speed, 10);
        humidity_30j_sum = safe_movsum(humidity, 30);
        
        %% === Variations ===
        temp_delta_1j = diff_c(temperature, 1);
        % Remplacer les NaN en début de série
        if any(isnan(temp_delta_1j))
            temp_delta_1j(isnan(temp_delta_1j)) = 0;
        end
        
        %% === Extrêmes ===
        precip_extreme_5j = movquantil_c(precipitation, 15, 0.90);
        % Gestion des NaN pour les quantiles
        if any(isnan(precip_extreme_5j))
            precip_extreme_5j(isnan(precip_extreme_5j)) = ...
                quantile(precipitation(~isnan(precip_extreme_5j)), 0.90);
        end
        
        windspeed_extrem = movquantil_c(wind_speed, 10, 0.95);
        if any(isnan(windspeed_extrem))
            windspeed_extrem(isnan(windspeed_extrem)) = ...
                quantile(wind_speed(~isnan(windspeed_extrem)), 0.95);
        end
        
        %% === Relations non linéaires ===
        % Éviter la division par zéro
        precip_35j_sum_safe = precip_35j_sum;
        precip_35j_sum_safe(precip_35j_sum_safe == 0) = eps;
        
        precip_recent_proportion = precip_5j_sum ./ precip_35j_sum_safe;
        % Limiter les valeurs extrêmes
        precip_recent_proportion(precip_recent_proportion > 10) = 10;
        precip_recent_proportion(precip_recent_proportion < 0) = 0;
        
        temperature_square = temperature .^ 2;
        
        % Produits avec vérification des NaN
        temperature_radiation_product = product_c(temperature_5j_sum, radiation_5j_sum);
        if any(isnan(temperature_radiation_product))
            nan_idx = isnan(temperature_radiation_product);
            temperature_radiation_product(nan_idx) = ...
                temperature_5j_sum(nan_idx) .* radiation_5j_sum(nan_idx);
        end
        
        sunshine_radiation_product = radiation_5j_sum .* sunshine_2j_sum;
        
        windspeed_recent_snowfall_product = product_c(windspeed_10j_sum, precip_20j_sum);
        if any(isnan(windspeed_recent_snowfall_product))
            nan_idx = isnan(windspeed_recent_snowfall_product);
            windspeed_recent_snowfall_product(nan_idx) = ...
                windspeed_10j_sum(nan_idx) .* precip_20j_sum(nan_idx);
        end
        
        %% === MATRICE DES FEATURES FINALE ===
        % Sélection des features les plus pertinentes (basé sur votre choix)
        X = [temperature_radiation_product, temp_delta_1j, temperature_square, ...
             snow_depth, ...
             precip_35j_sum, precip_recent_proportion, precip_extreme_5j, ...
             sunshine_radiation_product, ...
             humidity_30j_sum, humidity, ...
             windspeed_recent_snowfall_product, windspeed_extrem];
        
        feature_names = {'temperature_radiation_product', 'temp_delta_1j', ...
                         'temperature_square', 'snow_depth_6UTC', ...
                         'precip_35j_sum', 'precip_recent_proportion', ...
                         'precip_extreme_5j', 'sunshine_radiation_product', ...
                         'humidity_30j_sum', 'humidity', ...
                         'windspeed_recent_snowfall_product', 'windspeed_extrem'};
        
    catch ME
        error('❌ Erreur dans le calcul des features : %s', ME.message);
    end
    
    % ========== VERIFICATION FINALE ==========
    % Vérifier qu'il n'y a pas de NaN
    nan_count = sum(isnan(X), 'all');
    if nan_count > 0
        warning('⚠️ %d valeurs NaN restantes après imputation', nan_count);
        % Imputation finale par la médiane colonne par colonne
        for col = 1:size(X, 2)
            col_data = X(:, col);
            nan_idx = isnan(col_data);
            if any(nan_idx)
                col_median = median(col_data(~nan_idx), 'omitnan');
                if isnan(col_median)
                    col_median = 0;
                end
                col_data(nan_idx) = col_median;
                X(:, col) = col_data;
            end
        end
    end
    
    % Vérifier les valeurs infinies
    inf_count = sum(isinf(X), 'all');
    if inf_count > 0
        warning('⚠️ %d valeurs infinies détectées', inf_count);
        X(isinf(X)) = sign(X(isinf(X))) * realmax('single');
    end
    
    % ========== VECTEUR CIBLE ==========
    y = double(T.risk_index);
    
    % Vérifier la cohérence des dimensions
    if length(y) ~= size(X, 1)
        error('❌ Incohérence de dimensions : X a %d lignes, y a %d éléments', ...
              size(X, 1), length(y));
    end
    
    fprintf('✅ Features construites : %d observations, %d variables\n', ...
            size(X, 1), size(X, 2));
end