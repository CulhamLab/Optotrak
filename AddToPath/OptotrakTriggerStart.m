%The first part of an Optotrak trigger (sets pin high)
%
%Must be followed by OptotrakTriggerStop
%
%If prior trigger was too recent, this script **WILL WAIT** until it is
%allowed to trigger to prevent attempting to trigger during prior
%recording.
%
%The trigger is sent very early in this script (once allowed), but several
%other actions are performed afterwards that can take a little bit of time.
%The time at which the trigger began is returned.
%
%Ideally, time sensitive actions should be perform immediately prior to OptotrakTriggerStart
function [time_started] = OptotrakTriggerStart(trial_number)
global opto

%wait until allowed to trigger
while GetSecs < opto.trigger.time_allow_trigger_start
    [~,~,keys] = KbCheck(-1);
    if keys(opto.KEYS.STOP.VALUE)
        error('Stop key pressed.')
    end
end

%start trigger
if ~opto.DEBUG
    putvalue(dio.line(opto.DIO.PIN), optodio.LOW); %should guarentee that trigger is sent even if prior trigger wasn't ended
    putvalue(dio.line(opto.DIO.PIN), optodio.HIGH);
end
opto.trigger.time_start = GetSecs;

%warn if prior trigger was not stopped
if isnan(opto.trigger.time_stop)
    prior_trigger_stopped = false;
    OptotrakWarning('Prior trigger was not stopped. This can cause false triggers.');
else
    prior_trigger_stopped = true;
end

%timing
opto.trigger.time_stop = nan;
opto.trigger.time_expected_recording_end = opto.trigger.time_start + (opto.RECORD_MSEC / 1000);
opto.trigger.time_timeout = opto.trigger.time_expected_recording_end + (opto.TIMING.TIMEOUT_MSEC / 1000);
opto.trigger.time_allow_trigger_start = opto.trigger.time_expected_recording_end + (opto.TIMING.BUFFER_TRIGGER_MSEC / 1000);
opto.trigger.time_allow_trigger_stop = opto.trigger.time_start + (opto.TIMING.MINIMUM_BETWEEN_HIGH_LOW_MSEC / 1000);

%update expected file
opto = CheckNextFile(opto);

%(optional) if trial number is provided, record which file should be associated with it
if exist('trial_number', 'var')
    opto.trial(trial_number).expected_filename = opto.next_recording.filename;
    opto.trial(trial_number).time_trigger_start = opto.trigger.time_start;
    opto.trial(trial_number).prior_trigger_stopped = prior_trigger_stopped;
end

%return value
time_started = opto.trigger.time_start;

function [opto] = CheckNextFile(opto)
%get list of all dat files
list = dir([opto.DIRECTORY_DATA strrep(opto.FILENAME_DATA, '###', '*')]);

%restrict to matches
list = list(~cellfun(@isempty, regexp({list.name}, strrep(opto.FILENAME_DATA, '#', '\d'))));

%if no match, expect first trial 001
if isempty(list)
    opto.next_recording.trial_number = 1;
else
    %get trial numbers from matches
    ind_trial = strfind(opto.FILENAME_DATA, '###');
    ind_trial = ind_trial:ind_trial+2;
    optos = cellfun(@(x) str2num(x(ind_trial)), {list.name});

    %check that trial numbers are continuous
    if any(diff(optos) ~= 1)
        error('Trial numbers in dat files are not continuous! %s', sprintf('%d ', optos))
    end

    %expect next in series
    opto.next_recording.trial_number = optos(end)+1;
end

%name of expected next file
opto.next_recording.filename = strrep(opto.FILENAME_DATA, '###', sprintf('%03d', opto.next_recording.trial_number));