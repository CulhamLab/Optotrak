%[filepath, opto] = Complete
%
%An optional script to close the audio player if it is still open and save
%the opto struct to mat file. Saves to the dat file directory with a name
%containing the dat fileset name and a timestamp.
%
%Also returns the path to the saved file and a copy of the opto struct.
%
%When a trigger prep is given a trial number, it will have stored:
% 1. expected filename of dat file
% 2. time of trigger start
% 3. whether data passed checks or not
% 4. the data structure
function [filepath, opto] = Complete
global opto

%% Close audio player
if isfield(opto, 'sound_handle')
    try
        PsychPortAudio('Close', opto.sound_handle);
    end
end

%% Save global struct
filepath = [opto.DIRECTORY_DATA  opto.FILENAME_SAVE];
fprintf('Writing opto struct to: %s\n', filepath);
if exist(filepath, 'file')
    Optotrak.Collection.Warning('The mat file already exists so the complete script has already been run. The prior file will be overwritten.');
end
try
    save(filepath, 'opto')
catch
    warning('Could not save to: %s\nWill now attempt to save "%s" to the current directory...', filepath, opto.FILENAME_SAVE);
    if ~exist(opto.FILENAME_SAVE, 'file')
        save(opto.FILENAME_SAVE, 'opto')
    else
        error('File already exists!')
    end
end

%% Done
disp Completed!