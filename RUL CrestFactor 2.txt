% Carica il file .mat
load('matlab_FEATURE TABLE.mat');

% Parametro per il numero di picchi da considerare
numPeaksToConsider = 50; % Modifica questo valore per aumentare o diminuire il numero di picchi

% Verifica se la variabile FeatureTable1 esiste
if exist('FeatureTable1', 'var')
    % Estrai i valori del Crest Factor
    crestFactorValues = FeatureTable1.('FRM_1/Signal_tsa_rotmac/CrestFactor');

    % Rimuovi eventuali valori NaN
    crestFactorValues = crestFactorValues(~isnan(crestFactorValues));

    % Trova i picchi del Crest Factor
    [pks, locs] = findpeaks(crestFactorValues);

    % Limita il numero di picchi considerati
    if length(pks) > numPeaksToConsider
        pks = pks(1:numPeaksToConsider);
        locs = locs(1:numPeaksToConsider);
    end

    % Calcola l'inviluppo dei massimi
    maxEnvelope = interp1(locs, pks, 1:length(crestFactorValues), 'linear', 'extrap');

    % Calcola la soglia del 130% basata sui primi picchi
    numInitialPeaks = min(10, length(pks)); % Usa i primi 10 picchi o il numero effettivo di picchi se minore di 10
    initialPeaks = pks(1:numInitialPeaks);
    threshold = 1.3 * mean(initialPeaks);

    % Calcola il tasso di crescita medio dei picchi recenti
    numPoints = min(23, length(pks)); % Usa il numero minimo tra 20 e il numero effettivo di picchi
    if length(pks) >= numPoints
        recentPeaks = pks(end-numPoints+1:end);
        recentLocs = locs(end-numPoints+1:end);
        p = polyfit(recentLocs, recentPeaks, 1); % Fit lineare
        growthRate = p(1); % Tasso di crescita
    else
        error('Non ci sono abbastanza punti per la proiezione.');
    end

    % Converti il tempo di locs in secondi
    totalTime = 31.5; % Tempo totale in secondi
    numSamples = length(crestFactorValues);
    timePerSample = totalTime / numSamples;
    locsSeconds = locs * timePerSample;

    % Proietta l'inviluppo dei massimi nel futuro fino a quando non supera la soglia
    projected = false;
    maxExtendedTime = 100000; % Massimo tempo di proiezione in unità di campioni
    extendedTimeIncrement = 1000; % Incremento del tempo di proiezione
    while ~projected && length(crestFactorValues) + extendedTimeIncrement <= maxExtendedTime
        extendedTime = (length(crestFactorValues)+1:length(crestFactorValues)+extendedTimeIncrement)'; % Estendi il tempo di proiezione
        futureEnvelope = polyval(p, extendedTime);

        % Determina quando il max envelope supera la soglia
        timeToThreshold = find(futureEnvelope > threshold, 1);
        if ~isempty(timeToThreshold)
            timeToThreshold = extendedTime(timeToThreshold);
            projected = true;
        else
            extendedTimeIncrement = extendedTimeIncrement * 2; % Raddoppia l'incremento se non supera la soglia
        end
    end

    if ~projected
        disp('Il max envelope non supera la soglia nel periodo di proiezione massimo.');
    else
        timeToThresholdSeconds = timeToThreshold * timePerSample;
        fprintf('Il max envelope supera la soglia del 130%% in %d unità di tempo.\n', timeToThreshold - length(crestFactorValues));
        fprintf('La soglia del 130%% sarà superata tra circa %.2f secondi.\n', timeToThresholdSeconds);

        % Calcola il Remaining Useful Life (RUL)
        RUL = timeToThresholdSeconds;
        fprintf('Il Remaining Useful Life (RUL) è di circa %.2f secondi.\n', RUL);
    end

    % Plot dei valori del Crest Factor, dell'inviluppo dei massimi e della proiezione futura
    futureTime = (1:length(crestFactorValues))';
    futureTimeSeconds = futureTime * timePerSample;
    extendedTimeSeconds = (length(crestFactorValues)+1:timeToThreshold)' * timePerSample;
    futureEnvelope = polyval(p, length(crestFactorValues)+1:timeToThreshold);

    figure;
    plot(futureTimeSeconds, crestFactorValues, 'b-', 'DisplayName', 'Crest Factor Values');
    hold on;
    plot(locsSeconds, pks, 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Peaks');
    plot(futureTimeSeconds, maxEnvelope, 'g-', 'LineWidth', 2, 'DisplayName', 'Max Envelope');
    plot(extendedTimeSeconds, futureEnvelope, 'k--', 'LineWidth', 2, 'DisplayName', 'Projected Max Envelope');
    yline(threshold, '--r', '130% Threshold', 'LineWidth', 2, 'DisplayName', '130% Threshold');
    xlabel('Time (seconds)');
    ylabel('Crest Factor');
    legend('show', 'Location', 'Best');
    title('Crest Factor Values, Max Envelope, and Projected Max Envelope');
    grid on;
    hold off;
else
    disp('La variabile FeatureTable1 non esiste nel workspace. Assicurati che il file .mat contenga questa variabile.');
end