%[dio] = GetDIO
%
%Returns the digital aquisition structure created by Initialize.
%This can be useful if you are using the TMS or PLATO goggle ports on the
%same device.
function [dio] = GetDIO
global opto
if isfield(opto, 'dio')
    dio = opto.dio;
else
    error('Optotrak scripts have not been initialized. Run Initialize first.')
end