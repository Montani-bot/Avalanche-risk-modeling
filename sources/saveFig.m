function saveFig(name)
    results_dir = fullfile(pwd, 'results');
    if ~exist(results_dir, 'dir')
        mkdir(results_dir);
    end
    saveas(gcf, fullfile(results_dir, [name, '.png']));
end
