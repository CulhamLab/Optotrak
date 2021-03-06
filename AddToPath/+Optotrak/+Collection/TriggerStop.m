%TriggerStop
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
%Must be called after PrepareTrigger and TriggerStart
%
%If opto.TIMING.MINIMUM_BETWEEN_HIGH_LOW_MSEC is >0, this script **WILL WAIT**
%until the minimum time has passed after the trigger start before setting
%the pin low.
%
%If trigger end occurs after a recording is expected to have completed,
%then a false trigger may be detected. In this case, the next trial
%recording will be delayed by one sample duration + buffer to prevent
%potential issues.
function [time_stopped] = TriggerStop
global opto

%error if trigger already stopped
if opto.trigger.stopped
    error('Prepared trigger was already stopped!')
end

%wait until allowed to stop trigger
if opto.TIMING.MINIMUM_BETWEEN_HIGH_LOW_MSEC > 0
    while GetSecs < opto.trigger.time_allow_trigger_stop
        [~,~,keys] = KbCheck(-1);
        if keys(opto.KEYS.STOP.VALUE)
            error('Stop key pressed.')
        end
    end
end

%stop trigger
if opto.DEBUG
    Optotrak.Collection.Warning('DEBUG: trigger would have stopped');
else
    putvalue(opto.dio.line(opto.DIO.PIN), opto.DIO.LOW);
end
time_stop = GetSecs;
opto.trigger.stopped = true;

%if recording had already ended, delay next trigger in case a false trigger was created by setting pin low
if GetSecs > opto.trigger.time_expected_recording_end
    Optotrak.Collection.Warning('This trigger end is very late so the next trigger will be delayed in case a false trigger was just sent.')
    opto.trigger.time_allow_trigger_start = time_stop + (opto.TRIAL_DURATION_MSEC / 1000) +(opto.TIMING.BUFFER_TRIGGER_MSEC / 1000);
end

%return time
time_stopped = GetSecs;