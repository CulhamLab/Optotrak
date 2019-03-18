%The second part of an Optotrak trigger (sets pin low)
%
%Must follow OptotrakTriggerStart (before recording ends)
%
%If opto.TIMING.MINIMUM_BETWEEN_HIGH_LOW_MSEC is >0, this script **WILL WAIT**
%until the minimum time has passed after the trigger start before setting
%the pin low.
function OptotrakTriggerStop(wait)
global opto

%return if latest trigger was already ended
if ~isnan(opto.trigger.time_stop)
    OptotrakWarning('Latest trigger was already ended.')
    return
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
opto.trigger.time_stop = GetSecs;

%if recording has already ended, delay next trigger in case a false
%trigger is created
if GetSecs > opto.trigger.time_expected_recording_end
    OptotrakWarning('This trigger end is very late so the next trigger will be delayed in case a false trigger was sent.')
    opto.trigger.time_allow_trigger_start = opto.trigger.time_expected_recording_end + (opto.TIMING.BUFFER_TRIGGER_MSEC / 1000);
end