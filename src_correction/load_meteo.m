function data_meteo = load_meteo(meteo_filepath)

% LOAD_METEO Read + normalize MeteoSwiss-style CSV into a table with canonical names
%
%   data_meteo = load_meteo(meteo_filepath)
%
% - Renomme automatiquement les colonnes brutes (fkl010d0, gre000d0, ...) en :
%   {'wind_speed','radiation','snow_depth_6UTC','precipitation_daily_sum_0UTC',...
%    'sunshine_duration','temperature_5cm','temperature_20cm_sol','humidity'}
% - Convertit la colonne date 'reference_timestamp' en datetime si elle existe.
% - Gère les colonnes manquantes en les créant avec NaN.
%
% INPUT
%   meteo_filepath : string, chemin vers le CSV
% OUTPUT
%   data_meteo : table, colonnes normalisées

assert(ischar(meteo_filepath) || isstring(meteo_filepath), 'meteo_filepath must be a string.');

raw = readtable(meteo_filepath);

% Ensure date column exists and convert
if any(strcmp(raw.Properties.VariableNames,'reference_timestamp'))
    try
        raw.reference_timestamp = datetime(raw.reference_timestamp, 'InputFormat', 'dd.MM.yyyy HH:mm');
    catch
        raw.reference_timestamp = datetime(raw.reference_timestamp); % fallback
    end
else
    warning('No reference_timestamp column found in meteo file.');
end

% mapping from common MeteoSwiss names to canonical names
map_from = {'fkl010d0','gre000d0','htoautd0','rka150d0','sre000d0','tre005d0','tso020d0','ure200d0'};
map_to   = {'wind_speed','radiation','snow_depth_6UTC','precipitation_daily_sum_0UTC',...
            'sunshine_duration','temperature_5cm','temperature_20cm_sol','humidity'};

% Create output table initially as raw
data_meteo = raw;

% Rename columns if present; if absent, create NaN column
for k = 1:numel(map_from)
    if any(strcmp(raw.Properties.VariableNames, map_from{k}))
        data_meteo = renamevars(data_meteo, map_from{k}, map_to{k});
    elseif ~any(strcmp(data_meteo.Properties.VariableNames, map_to{k}))
        % create column of NaN (same height as table)
        data_meteo.(map_to{k}) = nan(height(data_meteo),1);
        warning('Column %s not found — created as NaN.', map_from{k});
    end
end

% Keep only relevant columns if they exist
wanted = [{'reference_timestamp'}, map_to];
existing = intersect(wanted, data_meteo.Properties.VariableNames, 'stable');
data_meteo = data_meteo(:, existing);

% Make sure date column is called 'date' for downstream consistency
if any(strcmp(data_meteo.Properties.VariableNames,'reference_timestamp'))
    data_meteo = renamevars(data_meteo, 'reference_timestamp', 'date');
end

end
