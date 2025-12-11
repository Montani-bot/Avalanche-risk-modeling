function [X_train, X_val, X_test, y_train, y_val, y_test, mu, sigma] = ...
    split_data(X, y, train_ratio, val_ratio, rng_seed)
%% Séparation stratifiée des données avec préservation temporelle
    
    % ========== INITIALISATION ==========
    rng(rng_seed, 'twister');  % Plus reproductible
    n = size(X, 1);
    
    % ========== VERIFICATIONS ==========
    if n < 50
        warning('⚠️ Très peu de données (%d observations)', n);
    end
    
    if train_ratio + val_ratio >= 1
        error('❌ Les ratios train + val doivent être < 1');
    end
    
    % ========== STRATIFICATION PAR NIVEAU DE RISQUE ==========
    % Créer des bins pour le risque (simplifié en 3 niveaux)
    risk_bins = discretize(y, [1, 2, 3, 5]);  % [1-2[, [2-3[, [3-5]
    
    % Initialiser les indices
    train_idx = [];
    val_idx = [];
    test_idx = [];
    
    % Pour chaque niveau de risque, séparer proportionnellement
    unique_bins = unique(risk_bins);
    
    for bin = unique_bins'
        bin_indices = find(risk_bins == bin);
        n_bin = length(bin_indices);
        
        if n_bin < 3  % Trop peu d'observations pour séparer
            % Tout mettre dans train
            train_idx = [train_idx; bin_indices];
            continue;
        end
        
        % Mélanger les indices de ce bin
        bin_indices = bin_indices(randperm(n_bin));
        
        % Calculer les tailles
        n_train_bin = round(train_ratio * n_bin);
        n_val_bin = round(val_ratio * n_bin);
        
        % Assigner aux ensembles
        train_idx = [train_idx; bin_indices(1:n_train_bin)];
        if n_val_bin > 0
            val_idx = [val_idx; bin_indices(n_train_bin+1:n_train_bin+n_val_bin)];
            test_start = n_train_bin + n_val_bin + 1;
        else
            test_start = n_train_bin + 1;
        end
        test_idx = [test_idx; bin_indices(test_start:end)];
    end
    
    % ========== MELANGER FINAL (sans briser la stratification) ==========
    train_idx = train_idx(randperm(length(train_idx)));
    val_idx = val_idx(randperm(length(val_idx)));
    test_idx = test_idx(randperm(length(test_idx)));
    
    % ========== CREATION DES ENSEMBLES ==========
    X_train = X(train_idx, :);
    y_train = y(train_idx);
    
    X_val = X(val_idx, :);
    y_val = y(val_idx);
    
    X_test = X(test_idx, :);
    y_test = y(test_idx);
    
    % ========== NORMALISATION ==========
    % Calculer les statistiques sur le train seulement
    mu = mean(X_train);
    sigma = std(X_train);
    
    % Éviter la division par zéro
    sigma_zero = sigma == 0;
    if any(sigma_zero)
        warning('⚠️ %d variables avec écart-type nul', sum(sigma_zero));
        sigma(sigma_zero) = 1;  % Pas de normalisation pour ces variables
    end
    
    % Normaliser tous les ensembles avec les stats du train
    X_train = (X_train - mu) ./ sigma;
    X_val = (X_val - mu) ./ sigma;
    X_test = (X_test - mu) ./ sigma;
    
    % ========== VERIFICATION DE LA DISTRIBUTION ==========
    fprintf('\n=== DISTRIBUTION DES ENSEMBLES ===\n');
    fprintf('Train : %d observations (%.1f%%)\n', ...
            length(y_train), length(y_train)/n*100);
    fprintf('Val   : %d observations (%.1f%%)\n', ...
            length(y_val), length(y_val)/n*100);
    fprintf('Test  : %d observations (%.1f%%)\n', ...
            length(y_test), length(y_test)/n*100);
    
    % Vérifier la distribution des risques
    fprintf('\n=== DISTRIBUTION DES RISQUES ===\n');
    for set_name = {'Train', 'Val', 'Test'}
        name = set_name{1};
        switch name
            case 'Train', y_set = y_train;
            case 'Val', y_set = y_val;
            case 'Test', y_set = y_test;
        end
        
        high_risk = sum(y_set >= 2.3);
        fprintf('%s : %.1f%% high-risk (≥2.3)\n', ...
                name, high_risk/length(y_set)*100);
    end
    
    % ========== VERIFICATION FINALE ==========
    % Vérifier qu'il n'y a pas de doublons entre ensembles
    all_indices = sort([train_idx; val_idx; test_idx]);
    if length(unique(all_indices)) ~= length(all_indices)
        error('❌ Chevauchement détecté entre les ensembles');
    end
    
    if length(all_indices) ~= n
        warning('⚠️ %d observations non assignées', n - length(all_indices));
    end
end

