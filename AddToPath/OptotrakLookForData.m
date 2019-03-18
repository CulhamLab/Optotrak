%[found] = OptotrakLookForData
%
%Look for the data file (.dat) of the planned trigger. The planned trigger
%must be stopped before beginning the search.
%
%Returs false under any of the following circumstances:
% 1. function called after the timeout window has already elapsed
% 2. file was not found within the timeout window
% 3. file was found too early (before it should have been possible)
function [found] = OptotrakLookForData
global opto

%error if trigger isn't yet stopped
if ~opto.trigger.stopped
    error('Will not search for data until after trigger is stopped!')
end

%error if already waited for this file
if opto.trigger.file_searched
    error('Already searched for this file!')
end

%error if looking for file after timeout window (cannot be confident that
%anything found is the result of a planned trigger)
if GetSecs > opto.trigger.time_timeout
    error('Cannot search for data after the timeout window has elapsed!')
end

%filepath to look for
filepath = [opto.DIRECTORY_DATA opto.trigger.filename];

%wait for file...
recording_should_be_done = false;
timed_out = false;
trigger_key_pressed = false;
while 1
    t = GetSecs;
    
    %look for file
    if exist(filepath, 'file')
        found = true;
		time_found = GetSecs;
        break;
    end
    
    %check if past timeout
    if ~timed_out && (t > opto.trigger.time_timeout)
        if opto.initialized
            %timeout, file not found
            OptotrakWarning(sprintf('Timeout occured while searching for file: %s', filepath));
            found = false;
            break;
        else
            %Initialization: warn if timeout would have occured but don't stop looking
            timed_out = true;
            warning('If this were a trial, it would have timed out waiting for data file to be found!')
        end
    end
    
    %Initialization: check if file should be available by now
    if ~opto.initialized && ~recording_should_be_done && (t > opto.trigger.time_expected_recording_end)
        recording_should_be_done = true;
        fprintf('Recording should be completed by now\n')
    end
    
    %handle keys
    [~,~,keys] = KbCheck(-1);
    if keys(opto.KEYS.STOP.VALUE)
        error('Stop key pressed.')
    elseif ~opto.initialized && ~trigger_key_pressed && keys(opto.KEYS.TRIGGER.VALUE)
        %Initialization: retrigger key
        fprintf('Sending another trigger (may be delayed if prior trigger was recent)...\n');
        OptotrakPrepareTrigger;
        OptotrakTriggerFull;
        global opto
        filepath = [opto.DIRECTORY_DATA opto.trigger.filename];
        fprintf('Trigger sent! Waiting for %s\n', opto.trigger.filename);
        recording_should_be_done = false;
        timed_out = false;
        trigger_key_pressed = true; %prevent repeated retriggers
    elseif ~keys(opto.KEYS.TRIGGER.VALUE)
        trigger_key_pressed = false; %prevent repeated retriggers
    end
end

%check if file was found before it should have been possible (would mean
%that file is from an unplanned trigger)
if time_found < opto.trigger.time_expected_recording_end
    %the file found is not from the planned trigger
    found = false;
    
    %warning
    OptotrakWarning('A data file was found earlier than should have been possible. This is likely the data from an unplanned trigger.');
end

%set whether latest file was found
opto.trigger.file_found = found;

%search complete
opto.trigger.file_searched = true;

%time to allow file read
opto.trigger.time_allow_file_read = time_found + (opto.TIMING.BUFFER_FILE_READ_MSEC / 1000);

%set latest data filepath
if found
    opto.trigger.file_located_filepath = filepath;
else
    opto.trigger.file_located_filepath = [];
end

%found is returned