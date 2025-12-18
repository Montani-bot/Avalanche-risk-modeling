%% cette fonction permet de stocker les coefficients du model dans le folder Results
function coeff_saver(b_final, var_names, station_path, resultDir)
% Vérifie si le dossier de résultats existe, sinon le crée
    if ~exist(resultDir, 'dir')
        mkdir(resultDir);
    end

    % Récupère le nom propre de la station (ex: meteo_pilatus)
    [~, station_name, ~] = fileparts(station_path);

    % Fichier de sortie
    output_file = fullfile(resultDir, sprintf('model_coeffs_%s.txt', station_name));

    fid = fopen(output_file, 'w');
    if fid == -1
        error('❌ Impossible d écrire dans %s', output_file);
    end

    fprintf(fid, "=============================================\n");
    fprintf(fid, "   Avalanche Risk Model – Coefficients\n");
    fprintf(fid, "   Station: %s\n", station_name);
    fprintf(fid, "=============================================\n\n");

    fprintf(fid, "Intercept:\n");
    fprintf(fid, "   b0 = %.6f\n\n", b_final(1));

    fprintf(fid, "Feature Coefficients:\n");
    for i = 2:length(b_final)
        fprintf(fid, "   %-25s  %.6f\n", var_names{i-1}, b_final(i));
    end

    fclose(fid);

    % Affichage propre et portable
    relative_path = fullfile('results', sprintf('model_coeffs_%s.txt', station_name));
    fprintf("💾 Coefficients saved to: %s\n", relative_path);
end

