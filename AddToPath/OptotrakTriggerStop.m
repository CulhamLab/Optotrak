%OptotrakTriggerStop
%
%A trigger consists of:
% OptotrakPrepareTrigger (slow, call this well before the trial begins)
% OptotrakTriggerStart (fast, sets pin high to trigger OTCollect to start
%                       recording immediately)
% OptotrakTriggerEnd (fast unless Start was called too recently because
%                     OTCollect needs some time to detect the signal,
%                     should be called before recording ends to prevent a 
%                     potential false trigger, sets pin low)
%
%Must be called after OptotrakPrepareTrigger and OptotrakTriggerStart
%
%If opto.TIMING.MINIMUM_BETWEEN_HIGH_LOW_MSEC is >0, this script **WILL WAIT**
%until the minimum time has passed after the trigger start before setting
%the pin low.
%
%If trigger end occurs after a recording is expected to have completed,
%then a false trigger may be detected. In this case, the next trial
%recording will be delayed by one sample duration + buffer to prevent
%potential issues.
function OptotrakTriggerStop
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
if ~opto.DEBUG
    putvalue(dio.line(opto.DIO.PIN), optodio.LOW);
end
time_stop = GetSecs;
opto.trigger.stopped = true;

%if recording had already ended, delay next trigger in case a false trigger was created by setting pin low
if GetSecs > opto.trigger.time_expected_recording_end
    OptotrakWarning('This trigger end is very late so the next trigger will be delayed in case a false trigger was just sent.')
    opto.trigger.time_allow_trigger_start = time_stop + (opto.RECORD_MSEC / 1000) +(opto.TIMING.BUFFER_TRIGGER_MSEC / 1000);
end