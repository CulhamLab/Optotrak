%Checks the Optotrak data folder to determine what the next file should be called
%Use the parameters set by OptotrakInitialize
function [filename] = OptotrakGetNextFilename

%use parameters from OptotrakInitialize
global opto

%get list of all dat files
list = dir([opto.DIRECTORY_DATA '*.dat']);

%restrict to matches
list = list(~cellfun(@isempty, regexp({list.name}, strrep(opto.FILENAME_DATA, '#', '\d'))));

%if no match, expect first trial 001
if isempty(list)
    expected_trial = 1;
else
    %get trial numbers from matches
    ind_trial = strfind(opto.FILENAME_DATA, '###');
    ind_trial = ind_trial:ind_trial+2;
    trial_numbers = cellfun(@(x) str2num(x(ind_trial)), {list.name});

    %check that trial numbers are continuous
    if any(diff(trial_numbers) ~= 1)
        error('Trial numbers in dat files are not continuous! %s', sprintf('%d ', trial_numbers))
    end

    %expect next in series
    expected_trial = trial_numbers(end)+1;
end

%name of expected next file (returned)
filename = strrep(opto.FILENAME_DATA, '###', sprintf('%03d', expected_trial));