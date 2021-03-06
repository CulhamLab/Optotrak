%[data_passes_checks, data] = CheckData(override_check)
%
%This script checks that latest dat file:
% 1. Checks number of ireds, sample rate, and duration
% 2. Checks percentage of frames in which all required IREDs are unblocked
% 3. Checks if specified IREDs are blocked at specified frames
%
%If LookForData has not been run yet, this script will call it.
%
%If LookForData did not find the file, this script will return
%false.
%
%Settings for the checks are set during initialization, but can be
%overriden with each call (overriding the settings does NOT change the
%settings used on later calls). The override structure must contain:
% .ireds_for_percent_check:  [1-by-N] array of ireds to include in the percent check
% .minimum_percent_present:  minimum percentage of frames in which all required IREDs are unblocked (100 = 100%)
% .required_ireds_at_frames: [N-by-2] with rows of [ired# frame#] for an ired# that must be unblocked at frame#
%
%If a trial number was given during trigger prep, then the data loaded and
%check result will be stored for the trial in the global opto struct.
%
%If file is not valid or checks fail, beeps will be played (if
%opto.SOUND.PLAY_SOUNDS). **WILL WAIT** for beeps to finish before
%returning.
function [data_passes_checks, data] = CheckData(override_check)
global opto

%error if already checked
if opto.trigger.file_checked
    error('Data from prepared trigger has already been checked!')
end

%look for data if not already done
if ~opto.trigger.file_searched
    Optotrak.Collection.LookForData;
end

%debug NO_FILES
if opto.NO_FILES
    Optotrak.Collection.Warning('NO_FILES is enabled so CheckData is returning true without looking');
    data_passes_checks = true;
    data = struct();
    return
end

%create check criteria
check_settings = opto.DEFAULT_CHECK;
if exist('override_check', 'var')
    for f = fields(override_check)'
        f = f{1};
        if isfield(check_settings, f)
            check_settings = setfield(check_settings, f, getfield(override_check, f));
        end
    end
end

%if file was not found, data not okay
if ~opto.trigger.file_found
    Optotrak.Collection.Warning('Data cannot be checked because file could not be found!')
    data_passes_checks = false;
    opto.trigger.data = [];
else
    %check file
    if isempty(opto.trigger.file_located_filepath)
        error('File appears to have been found, but filepath is not set!')
    elseif ~exist(opto.trigger.file_located_filepath, 'file')
        error('File appears to have been found, but no longer exists!')
    end

    %wait until allowed to read
    while GetSecs < opto.trigger.time_allow_file_read
        [~,~,keys] = KbCheck(-1);
        if keys(opto.KEYS.STOP.VALUE)
            error('Stop key pressed.')
        end
    end

    %read data
    opto.trigger.data = Optotrak.Collection.ReadDat(opto.trigger.file_located_filepath);

    %check data
    data_passes_checks = CheckThisData(opto, check_settings);
end

%(optional) if a trial number was set, record the data struct and result
if ~isnan(opto.trigger.trial)
    opto.trial(opto.trigger.trial).data = opto.trigger.data;
    opto.trial(opto.trigger.trial).data_passes_checks = data_passes_checks;
    opto.trial(opto.trigger.trial).check_settings = check_settings;
end

%play beeps if data did not pass **WILL WAIT FOR BEEP TO FINISH**
if opto.SOUND.PLAY_SOUNDS && ~data_passes_checks
    try
        prior_volume = PsychPortAudio('Volume', opto.sound_handle, opto.SOUND.VOLUME);

        PsychPortAudio('FillBuffer', opto.sound_handle, opto.beep);
        PsychPortAudio('Start', opto.sound_handle);
        PsychPortAudio('Stop', opto.sound_handle, 1);

        PsychPortAudio('Volume', opto.sound_handle, prior_volume);
    end
end

%return data (and data_passes_checks)
data = opto.trigger.data;



function [data_passes_checks] = CheckThisData(opto, check_settings)
%default to true
data_passes_checks = true;

%check main parameters
if opto.trigger.data.framerate ~= opto.FRAME_RATE
    Optotrak.Collection.Warning(sprintf('Sample rate in file (%d hz) does not match parameters (%d hz)!', opto.trigger.data.framerate, opto.FRAME_RATE))
    data_passes_checks = false;
    return
elseif opto.trigger.data.IRED_NUMBER ~= opto.IRED_NUMBER
    Optotrak.Collection.Warning(sprintf('Number of IREDs in file (%d) does not match parameters (%d)!', opto.trigger.data.IRED_NUMBER, opto.IRED_NUMBER))
    data_passes_checks = false;
    return
elseif opto.trigger.data.duration_msec ~= opto.TRIAL_DURATION_MSEC
    Optotrak.Collection.Warning(sprintf('Duration in file (%d msec) does not match parameters (%d msec)!', opto.trigger.data.duration_msec, opto.TRIAL_DURATION_MSEC))
    data_passes_checks = false;
    return
end

%percent check
if ~isempty(check_settings.ireds_for_percent_check) && (check_settings.minimum_percent_present > 0)
    valid_frames = ~any(isnan([opto.trigger.data.ired([check_settings.ireds_for_percent_check]).X]),2);
    percent = sum(valid_frames) / length(valid_frames) * 100;
    if percent < check_settings.minimum_percent_present
        Optotrak.Collection.Warning(sprintf('Data contains too few valid frames: %g%% (set to require %g%%)!', round(percent, 2), round(check_settings.minimum_percent_present, 2)))
        data_passes_checks = false;
        return
    end
end

%specified frames check
if ~isempty(check_settings.required_ireds_at_frames) 
    ind_invalid = isnan(arrayfun(@(x, y) opto.trigger.data.ired(x).X(y), check_settings.required_ireds_at_frames(:,1), check_settings.required_ireds_at_frames(:,2)));
    if any(ind_invalid)
        Optotrak.Collection.Warning(sprintf('Data contains the following missing ired-frame pair(s):\n%s', sprintf('IRED %d at frame %d\n', check_settings.required_ireds_at_frames(ind_invalid,:))))
        data_passes_checks = false;
        return
    end
end

%if reach here, returns default (true)
