%PrepareTrigger(optional_trial_number)
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
%Must be called before triggering a recording. This function may take
%several seconds to complete so it should be called before a trial begins
%during a non-time-sensitive period.
%
%If a trial number is provided, then the filename and trigger time will be
%stored in the global opto struct.
%
%PrepareTrigger may be called multiple times between recordings if
%needed, but cannot be called between a trigger start and stop.
%
%Script will hault until next trigger would be allowed (may be several
%seconds)
function PrepareTrigger(optional_trial_number)
global opto

%wait until allowed to start trigger
while GetSecs < opto.trigger.time_allow_trigger_start
    [~,~,keys] = KbCheck(-1);
    if keys(opto.KEYS.STOP.VALUE)
        error('Stop key pressed.')
    end
end

%error if prior trigger was not started and stopped
if ~opto.trigger.started
    error('Prior trigger was not started!');
elseif ~opto.trigger.stopped
    error('Prior trigger was not stopped!');
end

%initialize
%opto.trigger.time_allow_trigger_start is not set here
opto.trigger.time_allow_trigger_stop = nan;
opto.trigger.time_expected_recording_end = nan;
opto.trigger.time_file_search_timeout = nan;
opto.trigger.time_allow_file_read = nan;

opto.trigger.file_searched = false;
opto.trigger.file_found = false;
opto.trigger.file_checked = false;
opto.trigger.file_located_filepath = [];

opto.trigger.started = false;
opto.trigger.stopped = false;

%check files to see what filename should come next
opto = CheckNextFile(opto);

%setup trial record if trial number is provided
if exist('optional_trial_number', 'var')
    opto.trigger.trial = optional_trial_number;
    
    opto.trial(optional_trial_number).expected_filename = opto.trigger.filename;
    opto.trial(optional_trial_number).time_trigger_start = nan;
else
    opto.trigger.trial = nan;
end



function [opto] = CheckNextFile(opto)
%debug
if opto.NO_FILES
    opto.trigger.filename_number = 1;
    opto.trigger.filename = 'DEBUG';
end

%get list of all dat files
list = dir([opto.DIRECTORY_DATA strrep(opto.FILENAME_DATA, '###', '*')]);

%restrict to matches
list = list(~cellfun(@isempty, regexp({list.name}, strrep(opto.FILENAME_DATA, '#', '\d'))));

%if no match, expect first trial 001
if isempty(list)
    opto.trigger.filename_number = 1;
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
    opto.trigger.filename_number = optos(end)+1;
end

%name of expected next file
opto.trigger.filename = strrep(opto.FILENAME_DATA, '###', sprintf('%03d', opto.trigger.filename_number));