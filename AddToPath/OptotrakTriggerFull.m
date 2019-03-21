%[time_started] = OptotrakTriggerFull
%
%Must call OptotrakPrepareTrigger before this.
%
%A trigger consists of:
% OptotrakPrepareTrigger (slow, call this well before the trial begins)
% OptotrakTriggerStart (fast, sets pin high to trigger OTCollect to start
%                       recording immediately)
% OptotrakTriggerStop (fast unless Start was called too recently because
%                      OTCollect needs some time to detect the signal,
%                      should be called before recording ends to prevent a 
%                      potential false trigger, sets pin low)
%
%This script combines the trigger start and stop meaning that it **WILL WAIT**
%for the duration of opto.TIMING.MINIMUM_BETWEEN_HIGH_LOW_MSEC
%
%If there is something time-sensitive that must immediately follow the
%trigger start, call OptotrakTriggerStart instead and then call
%OptotrakTriggerStop later (before recording finishes).
function [time_started, time_stopped] = OptotrakTriggerFull
time_started = OptotrakTriggerStart;
time_stopped = OptotrakTriggerStop;