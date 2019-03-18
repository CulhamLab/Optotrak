%A complete Optotrak trigger
%Will hault script until trigger is complete (see OptotrakTriggerStart and OptotrakTriggerStop scripts for more detail)
%If another action must immediately follow the start of the trigger, call OptotrakTriggerStart, perform those actions, and then call OptotrakTriggerStop
%For very time-sensitive actions, you might need to split up OptotrakTriggerStart
function [time_started] = OptotrakTriggerFull
time_started = OptotrakTriggerStart;
OptotrakTriggerStop;