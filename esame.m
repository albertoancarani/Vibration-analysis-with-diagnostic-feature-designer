clc
clear

load(fullfile(matlabroot, 'toolbox', 'predmaint', 'predmaintdemos', ...
  'motorDrivetrainDiagnosis', 'machineDataRUL3'), 'motor_rul3')

diagnosticFeatureDesigner

