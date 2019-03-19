%[time_started] = OptotrakTriggerStart
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
%Must be called after OptotrakPrepareTrigger and before OptotrakTriggerEnd
function [time_started] = OptotrakTriggerStart
global opto

%error if trigger already started
if opto.trigger.started
    error('Prepared trigger was already started!')
end

%start trigger
if opto.DEBUG
    OptotrakWarning('DEBUG: trigger would have started');
else
    putvalue(dio.line(opto.DIO.PIN), optodio.HIGH);
end
time_started = GetSecs;
opto.trigger.started = true;

%timing
opto.trigger.time_expected_recording_end = time_started + (opto.RECORD_MSEC / 1000);
opto.trigger.time_allow_trigger_stop =     time_started + (opto.TIMING.MINIMUM_BETWEEN_HIGH_LOW_MSEC / 1000);
opto.trigger.time_file_search_timeout =    opto.trigger.time_expected_recording_end + (opto.TIMING.TIMEOUT_MSEC / 1000);
opto.trigger.time_allow_trigger_start =    opto.trigger.time_expected_recording_end + (opto.TIMING.BUFFER_TRIGGER_MSEC / 1000);

%(optional) if trial number was provided to OptotrakPrepareTrigger, record start time
if ~isnan(opto.trigger.trial)
    opto.trial(opto.trigger.trial).time_trigger_start = time_started;
end

%return value
time_started = time_started;
