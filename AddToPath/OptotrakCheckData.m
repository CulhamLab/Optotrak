%[data_passes_checks] = OptotrakCheckData
%
%TODO
%
function [data_passes_checks] = OptotrakCheckData
global opto

%error if already checked
if opto.trigger.file_checked
    error('Data from prepared trigger has already been checked!')
end

%look for data if not already done
if ~opto.trigger.file_searched
    OptotrakLookForData;
end

%if file was not found, data not okay
if ~opto.trigger.file_found
    OptotrakWarning('Data cannot be checked because file could not be found!')
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
    opto.trigger.data = OptotrakReadDat(opto.trigger.file_located_filepath);

    %check data
    data_passes_checks = CheckData(opto);
end

%(optional) if a trial number was set, record the data struct and result
if ~isnan(opto.trigger.trial)
    opto.trial(opto.trigger.trial).data = opto.trigger.data;
    opto.trial(opto.trigger.trial).data_passes_checks = data_passes_checks;
end

%data_passes_checks is returned



function [data_passes_checks] = CheckData(opto)
%TODO
error