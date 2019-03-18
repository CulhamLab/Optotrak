%A complete Optotrak trigger
%Will hault script until trigger is complete (see OptotrakTriggerStart and OptotrakTriggerStop scripts for more detail)
function [time_started] = OptotrakTriggerFull
time_started = OptotrakTriggerStart;
OptotrakTriggerStop;