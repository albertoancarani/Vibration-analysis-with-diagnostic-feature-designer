load('matlab_FEATURE TABLE.mat');

% Parametro per il numero di picchi da considerare
numPeaksToConsider = 50; % Modifica questo valore per aumentare o diminuire il numero di picchi

if exist('FeatureTable1', 'var')
    % Estrai i valori della kurtosis
    kurtosisValues = FeatureTable1.('FRM_1/Signal_tsa_rotmac/Kurtosis');

    % Rimuovi eventuali valori NaN
    kurtosisValues = kurtosisValues(~isnan(kurtosisValues));

    % Trova i picchi della kurtosis, escludendo il primo picco vicino allo zero
    [pks, locs] = findpeaks(kurtosisValues);
    if locs(1) <= 2 % Assumiamo che il primo picco sia molto vicino all'inizio (entro i primi due campioni)
        pks(1) = [];
        locs(1) = [];
    end

    % Escludi i picchi inferiori a 2.1
    validIdx = pks >= 2.1;
    pks = pks(validIdx);
    locs = locs(validIdx);

    % Limita il numero di picchi considerati
    if length(pks) > numPeaksToConsider
        pks = pks(1:numPeaksToConsider);
        locs = locs(1:numPeaksToConsider);
    end

    % Calcola l'inviluppo dei massimi
    maxEnvelope = interp1(locs, pks, 1:length(kurtosisValues), 'linear', 'extrap');

    % Calcola la soglia del 130% basata sui primi picchi
    numInitialPeaks = min(10, length(pks)); % Usa i primi 10 picchi o il numero effettivo di picchi se minore di 10
    initialPeaks = pks(1:numInitialPeaks);
    threshold = 1.3 * mean(initialPeaks);

    % Calcola il tasso di crescita medio dei picchi recenti
    numPoints = min(20, length(pks)); % Usa il numero minimo tra 20 e il numero effettivo di picchi
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
    numSamples = length(kurtosisValues);
    timePerSample = totalTime / numSamples;
    locsSeconds = locs * timePerSample;

    % Proietta l'inviluppo dei massimi nel futuro fino a quando non supera la soglia
    projected = false;
    maxExtendedTime = 100000; % Massimo tempo di proiezione in unità di campioni
    extendedTimeIncrement = 1000; % Incremento del tempo di proiezione
    while ~projected && length(kurtosisValues) + extendedTimeIncrement <= maxExtendedTime
        extendedTime = (length(kurtosisValues)+1:length(kurtosisValues)+extendedTimeIncrement)'; % Estendi il tempo di proiezione
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
        fprintf('Il max envelope supera la soglia del 130%% in %d unità di tempo.\n', timeToThreshold - length(kurtosisValues));
        fprintf('La soglia del 130%% sarà superata tra circa %.2f secondi.\n', timeToThresholdSeconds);

        % Calcola il Remaining Useful Life (RUL)
        RUL = timeToThresholdSeconds;
        fprintf('Il Remaining Useful Life (RUL) è di circa %.2f secondi.\n', RUL);
    end

    futureTime = (1:length(kurtosisValues))';
    futureTimeSeconds = futureTime * timePerSample;
    extendedTimeSeconds = (length(kurtosisValues)+1:timeToThreshold)' * timePerSample;
    futureEnvelope = polyval(p, length(kurtosisValues)+1:timeToThreshold);

    figure;
    plot(futureTimeSeconds, kurtosisValues, 'b-', 'DisplayName', 'Kurtosis Values');
    hold on;
    plot(locsSeconds, pks, 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Kurtosis Peaks');
    plot(futureTimeSeconds, maxEnvelope, 'g-', 'LineWidth', 2, 'DisplayName', 'Max Envelope');
    plot(extendedTimeSeconds, futureEnvelope, 'k--', 'LineWidth', 2, 'DisplayName', 'Projected Max Envelope');
    yline(threshold, '--r', '130% Threshold', 'LineWidth', 2, 'DisplayName', '130% Threshold');
    xlabel('Time (seconds)');
    ylabel('Kurtosis');
    legend('show', 'Location', 'Best');
    title('Kurtosis Values, Max Envelope, and Projected Max Envelope');
    grid on;
    hold off;
else
    disp('La variabile FeatureTable1 non esiste nel workspace. Assicurati che il file .mat contenga questa variabile.');
end
