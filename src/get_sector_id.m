%% cette fonction à pour but de determiner automatiquement le bon secteur SLF pour la station entrée en input
function sector_id = get_sector_id(station_path)

    % Extraire le nom du fichier sans extension
    [~, station_name, ~] = fileparts(station_path);
    station_name = lower(station_name);   % normalisation

    % === Dictionnaire station -> sector_id ===
    switch station_name
        case 'meteo_weissfluhjoch'
            sector_id = 5123;  % Davos 
        case 'meteo_mottec'
            sector_id = 4124;  % Anniviers
        case 'meteo_zermatt'
            sector_id = 4222;
        case 'meteo_evolene'
            sector_id = 4122;  % Val d'Hérens
        case 'meteo_pilatus'
            sector_id = 2111;
        otherwise
            error("❌ Station inconnue : %s\nAjoute-la dans get_sector_id.m", station_name);
    end
end
