clc
clear

% 1) carico i dati nel workspace
load(fullfile(matlabroot, 'toolbox', 'predmaint', 'predmaintdemos', ...
  'motorDrivetrainDiagnosis', 'machineDataRUL3'), 'motor_rul3')

diagnosticFeatureDesigner

%% procedimento su DFD
% 2) apro il diagnostic feature designer

% 3) Import the data. To do so, in the Feature Designer tab, click New Session. 
% Then, in the Select more variables area of the New Session window,
% select motor_rul3 as your source variable.

% 4) selezione la variabile e la plotto usando signal trace

% 5) segmento il segnale
% clicco su frame policy poi dentro la finestra che si apre metto data
% handling mondel su frame based poi imposto sia il frame size che il frame
% rate a 0.21 s

% 6) faccio la TSA
% Time-synchronous averaging (TSA) averages a signal over one rotation,
% substantially reducing noise that is not coherent with the rotation

% To compute the TSA signal, select Filtering & Averaging > Time-Synchronous Signal Averaging.
% In the dialog box:
% Confirm the selection in Signal.
% In Tacho Information, select Constant rotation speed (RPM) and set the value to 1800.
% Accept all other settings.

% 7) estraggo le feature
% torno sul feature designer seleziono la TSA e vado su
% time-domain rotating machinery features
% mi interessano RMS, curtosis e crest factor

% 8) guardo come le feature variano nel tempo
% You can also look at the feature trace plots to see how the features change 
% over time.To do so, in Feature Tables, select FeatureTable1. 
% In the plot gallery, select Feature Trace

% 9) Faccio un power spectrum 
 % prendo la TSA e faccio un power spectrum selezionando il welch method
 % Start by computing a power spectrum. To do so, 
 % select Spectral Estimation > Power Spectrum.
 % Select the TSA signal and change Algorithm to Welch's method.

% 10) Estraggo le feature spettrali
% Extract spectral features from your TSA signal. 
% Extract spectral features. To do so, click Spectral Features and confirm
% that Spectrum is set to your power spectrum. Using the slider, limit the 
% range to about 4000 Hz to bound the region to the peaks. 
% The power spectrum plot automatically changes from a log to a linear 
% scale and zooms in to the range you select.

% 11) plotto le feature trace
% Plot the band-power feature trace to see how it compares with the all-segment 
% power spectrum. Use Select Features to clear the other feature traces


