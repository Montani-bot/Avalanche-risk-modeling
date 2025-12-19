%% Splitting the data into training, validation, and test sets
% the internal validation set is used to calibrate the alpha parameter
% the test set is used to evaluate the performance of my model

function [X_train, X_val, X_test, y_train, y_val, y_test, mu, sigma] = ...
    split_data(X, y, train_ratio, val_ratio, rng_seed)

    rng(rng_seed);
    n = size(X, 1);
    idx = randperm(n);
    n_train = round(train_ratio * n);
    
    train_idx = idx(1:n_train);
    test_idx = idx(n_train+1:end);
    
    X_train_full = X(train_idx, :);
    y_train_full = y(train_idx);
    
    X_test = X(test_idx, :);
    y_test = y(test_idx);
    
    % Separation train/validation
    n_val = round(val_ratio * n_train);
    X_val = X_train_full(1:n_val, :);
    y_val = y_train_full(1:n_val);
    
    X_train = X_train_full(n_val+1:end, :);
    y_train = y_train_full(n_val+1:end);
    
    % Normalisation (Only on the training set data to avoid data leakage)
    mu = mean(X_train);
    sigma = std(X_train);
    sigma(sigma == 0) = 1;  % avoid the 0 division problem 
end

