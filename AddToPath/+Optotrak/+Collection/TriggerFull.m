%[time_started] = TriggerFull
%
%Must call PrepareTrigger before this.
%
%A trigger consists of:
% PrepareTrigger (slow, call this well before the trial begins)
% TriggerStart (fast, sets pin high to trigger OTCollect to start
%                       recording immediately)
% TriggerStop (fast unless Start was called too recently because
%                      OTCollect needs some time to detect the signal,
%                      should be called before recording ends to prevent a 
%                      potential false trigger, sets pin low)
%
%This script combines the trigger start and stop meaning that it **WILL WAIT**
%for the duration of opto.TIMING.MINIMUM_BETWEEN_HIGH_LOW_MSEC
%
%If there is something time-sensitive that must immediately follow the
%trigger start, call TriggerStart instead and then call
%TriggerStop later (before recording finishes).
function [time_started, time_stopped] = TriggerFull
time_started = Optotrak.Collection.TriggerStart;
time_stopped = Optotrak.Collection.TriggerStop;