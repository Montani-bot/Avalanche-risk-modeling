% ==========================================================
% Project: Avalanche Risk Estimation Tool (Simple GUI)
% File: avalancheGUI.m
% Description: Simple interactive GUI for avalanche risk estimation
% ==========================================================

function maingui
    % Create main figure
    fig = uifigure('Name', 'Avalanche Risk Estimation Tool', ...
                   'Position', [500 300 400 500]);

    % Title label
    uilabel(fig, 'Text', 'Avalanche Risk Estimation', ...
        'FontSize', 16, 'FontWeight', 'bold', ...
        'Position', [80 450 300 30]);

    % --- Input fields --------------------------------------------------
    % Slope
    uilabel(fig, 'Text', 'Slope (°):', 'Position', [50 390 100 22]);
    slopeField = uieditfield(fig, 'numeric', 'Position', [180 390 100 22], 'Limits', [0 60]);

    % Snow
    uilabel(fig, 'Text', 'Snowfall (cm / 24h):', 'Position', [50 340 120 22]);
    snowField = uieditfield(fig, 'numeric', 'Position', [180 340 100 22], 'Limits', [0 100]);

    % Wind
    uilabel(fig, 'Text', 'Wind speed (m/s):', 'Position', [50 290 120 22]);
    windField = uieditfield(fig, 'numeric', 'Position', [180 290 100 22], 'Limits', [0 25]);

    % Temp
    uilabel(fig, 'Text', 'Temp. variation (°C):', 'Position', [50 240 140 22]);
    tempField = uieditfield(fig, 'numeric', 'Position', [180 240 100 22], 'Limits', [-5 10]);

    % --- Button --------------------------------------------------------
    calcButton = uibutton(fig, 'Text', 'Calculate Risk', ...
        'Position', [130 190 150 30], ...
        'ButtonPushedFcn', @(btn, event) computeRisk);

    % --- Display results ----------------------------------------------
    resultLabel = uilabel(fig, 'Text', '', 'FontSize', 14, ...
        'FontWeight', 'bold', 'Position', [100 140 250 30]);

    % --- Axes for bar chart -------------------------------------------
    ax = uiaxes(fig, 'Position', [60 30 280 100]);
    title(ax, 'Risk Level (0–5)');
    ylabel(ax, 'Risk Index');
    ylim(ax, [0 5]);
    colormap(ax, jet(6));

    % --- Nested function ----------------------------------------------
    function computeRisk
        % Get user input
        slope = slopeField.Value;
        snow  = snowField.Value;
        wind  = windField.Value;
        temp  = tempField.Value;

        % Normalize inputs
        slopeN = min(max((slope - 0) / 60, 0), 1);
        snowN  = min(max((snow - 0) / 100, 0), 1);
        windN  = min(max((wind - 0) / 25, 0), 1);
        tempN  = min(max((temp - (-5)) / (10 - (-5)), 0), 1);

        % Call C risk function (MEX)
        try
            risk = calcRisk(slopeN, snowN, windN, tempN);
        catch
            % fallback if MEX not compiled
            risk = 5 * (0.4*slopeN + 0.3*snowN + 0.2*windN + 0.1*tempN);
        end

        % Clamp 0–5
        risk = max(min(risk, 5), 0);

        % Define text level
        if risk < 1
            level = 'Very Low';
        elseif risk < 2
            level = 'Low';
        elseif risk < 3
            level = 'Moderate';
        elseif risk < 4
            level = 'High';
        else
            level = 'Very High';
        end

        % Update label and chart
        resultLabel.Text = sprintf('Risk: %.2f (%s)', risk, level);
        bar(ax, risk, 'FaceColor', 'flat');
        caxis(ax, [0 5]);
        ax.YLim = [0 5];
        grid(ax, 'on');
    end
end
