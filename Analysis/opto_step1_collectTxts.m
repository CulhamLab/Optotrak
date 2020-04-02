function opto_step1_collectTxts
try
closeAllFigures
%% GUI- Load
fig = hgload([pwd filesep 'GUI' filesep 'opto_step1_collectTxts' '.fig']);

%% GUI - Global vars that need to transfer to GUI
global globals
globals = struct;

%% GUI - Set text
name = 'Script 1: Collect Data (txt or mat)';
set(fig,'name',name);
texts = findall(fig, 'style', 'text');
for t = texts'
    text  = get(t,'tag');
    switch text
        case 'textTitle'
            set(t,'string',name)
        case 'textInstructions'
            inst = sprintf('New Method:\nSelect any number of .mat data files\n\nOld Method:\nSelect any one OTDisplay .txt file in a series');
            set(t,'string',inst)
        case 'textMissingL'
            set(t,'string','Files: ')
        case 'textMissing'
            set(t,'string','')
            globals.files = t;
        case 'textNumIREDL'
            set(t,'string','IREDs Found: ')
        case 'textNumIRED'
            set(t,'string','')
            globals.numIRED = t;
        case 'textProcessedL'
            set(t,'string','Processing: ')
        case 'textProcessed'
            set(t,'string','')
            globals.processing = t;
    end
end

checkboxNoRound = findall(fig, 'tag', 'checkboxNoRound');
set(checkboxNoRound,'string','Use non-rounded values (New Method)');
set(checkboxNoRound,'value',1);
globals.checkboxNoRound = checkboxNoRound;

bClose = findall(fig, 'tag', 'buttonClose');
set(bClose,'string','Close');
set(bClose,'callback',@button_callback);
bLoad = findall(fig, 'tag', 'buttonLoad');

%% GUI - Set font sizes
set(findall(fig, '-property', 'FontSize'), 'FontSize', 15);

%% GUI - Give callback instructions to button
set(bClose,'callback',@closeAllFigures);
set(bLoad,'callback',@button_callback);

catch err
closeAllFigures
rethrow(err)
end
end

function closeAllFigures(fig, evt)
%working with gui figs so "close all" won't work
delete(findall(0, 'type', 'figure'))
end

function button_callback(fig, evt)
try
global globals
%% Pick file
[FileName,PathName,FilterIndex] = uigetfile('*.mat;*.txt', 'MultiSelect', 'on');
if ~FilterIndex %closed window
    return
elseif FilterIndex > 1 %selected non-txt
    DoError('Please select a txt file.')
    return
end

%% Clear GUI
set(globals.processing,'string','')
set(globals.numIRED,'string','')
set(globals.files,'string','')

%% Handle Single MAT
if ~iscell(FileName) && strcmp(FileName(end-3:end),'.mat')
    FileName = {FileName};
end

%% Detect Mode: mat(s) or txt
if iscell(FileName)
    %mat mode...
    
    %round or no?
    noround = get(globals.checkboxNoRound, 'value') == 1;
    fprintf('No Round: %d\n', noround);
    
    %check no txt
    if any(cellfun(@(x) strcmp(x(end-3:end), '.txt'), FileName))
        DoError('Select exactly one .txt file ~OR~ any number of .mat files.')
        return;
    end
    
    %count files
    number_files = length(FileName);
    
    %load and check files
    set(globals.files,'string','loading and checking files...')
    for fid = 1:number_files
        fn = FileName{fid};
        
        set(globals.processing,'string',sprintf('loading: %s', fn))
        file{fid} = load([PathName fn]);
        
        set(globals.processing,'string',sprintf('checking: %s', fn))
        
        %if no .opto, look for p.OPTO
        if ~isfield(file{fid}, 'opto')
            if isfield(file{fid}.p, 'OPTO')
                file{fid}.opto = file{fid}.p.OPTO;
            else
                DoError('Cannot locate opto info struct')
            end
        end
        
        %rename fields in old data
        file{fid}.opto = RenameFields(file{fid}.opto);
        
        %number ireds
        if fid == 1
            IRED_NUMBER_PER_TRIAL = file{fid}.opto.IRED_NUMBER_PER_TRIAL;
            set(globals.numIRED,'string',num2str(IRED_NUMBER_PER_TRIAL))
        elseif IRED_NUMBER_PER_TRIAL ~= file{fid}.opto.IRED_NUMBER_PER_TRIAL
            DoError('The number of IREDs is not consistent across mat files.')
            return;
        end
        
        %duration
        if fid == 1
            duration_msec = file{fid}.opto.TRIAL_DURATION_MSEC;
        elseif duration_msec ~= file{fid}.opto.TRIAL_DURATION_MSEC
            DoError('The duration is not consistent across mat files.')
            return;
        end
        
        %sample rate
        if fid == 1
            sample_rate = file{fid}.opto.FRAME_RATE;
        elseif sample_rate ~= file{fid}.opto.FRAME_RATE
            DoError('The sample rate is not consistent across mat files.')
            return;
        end
        
    end
    
    %expected number of frames
    expected_frames = duration_msec / 1000 * sample_rate;
    
    %invalid flags
    trial_data_names = {'trial_data' 'trial_info' 'trials'};
    required_data_fields = {'trial_id' 'opto_data_passes_checks', 'opto_data'};
    invalid_flags = {'repeat' 'repeated' 'flag' 'flagged' 'invalid' 'bad'};
    
    %process files
    for fid = 1:number_files
        fn = FileName{fid};
        set(globals.files,'string',fn)
        fprintf('\nProcessing file %d of %d: %s\n', fid, number_files, fn);
        
        set(globals.processing,'string','checking data format...')
        
        %trial_data field
        fprintf('\n\tSearching for trial_data struct in (file.d): %s\n', sprintf('%s ', trial_data_names{:}));
        found = false;
        for name = trial_data_names
            name = name{1};
            if isfield(file{fid}.d, name)
                trial_data = getfield(file{fid}.d, name);
                found = true;
                fprintf('\t-Found "%s"\n', name);
                break;
            end
        end
        if ~found
            DoError(sprintf('Could not find trial_data in %s', fn));
            return;
        end
        
        %required subfields in trial_data
        fprintf('\n\tChecking required fields in trial_data: %s\n', sprintf('%s ', required_data_fields{:}));
        for name = required_data_fields
            name = name{1};
            if ~isfield(trial_data, name)
                trial_data = getfield(trial_data, name);
                DoError(sprintf('Could not find %s in trial_data of %s', name, fn));
                return;
            end
        end
        
        set(globals.processing,'string','selecting trials...')
        
        %number trials init
        number_trials = length(trial_data);
        is_valid = true(1, number_trials);
        
        %select trials - failed checks
        fprintf('\n\tRemoving trials that failed checks during experiment...\n')
        is_valid(~[trial_data.opto_data_passes_checks]) = false;
        trial_data = trial_data(is_valid);
        fprintf('\t-removed %d trials\n', sum(~is_valid));
        number_trials = length(trial_data);
        fprintf('\t-there are %d trials\n', number_trials);
        
        %select trials - extra flags
        fprintf('\n\tRemoving trials with any of the following flags: %s\n', sprintf('%s ', invalid_flags{:}));
        is_valid = true(1, number_trials);
        for flag_name = invalid_flags
            flag_name = flag_name{1};
            if isfield(trial_data,flag_name)
                eval(sprintf('is_valid([trial_data.%s]) = false;', flag_name))
            end
        end
        trial_data = trial_data(is_valid);
        fprintf('\t-removed %d trials\n', sum(~is_valid));
        number_trials = length(trial_data);
        fprintf('\t-there are %d trials\n', number_trials);
        
        %any trials left?
        if ~number_trials
            DoError(sprintf('No valid trials in %s', fn))
            return;
        end
        
        fprintf('\n\tProcessing trials...\n');
        set(globals.processing,'string','processing trials...')
        clear odat;
        for trial = 1:number_trials
            data = trial_data(trial);
            
            %is old version with no vel/accel?
            if isfield(data.opto_data, 'notice')
                DoError(sprintf('This file was created with an old version before vel/accel was fixed: %s', fn))
                return;
            end
            
            %rename old fields
            data.opto_data = RenameFields(data.opto_data);
            
            %more checks on each recording
            if data.opto_data.IRED_NUMBER ~= IRED_NUMBER_PER_TRIAL
                DoError(sprintf('The number of IREDs is not consistent in trial %d of %s (expected %d, found %d)', trial, fn, IRED_NUMBER_PER_TRIAL, data.opto_data.IRED_NUMBER))
                return;
            elseif data.opto_data.framerate ~= sample_rate
                DoError(sprintf('The sample rate is not consistent in trial %d of %s', trial, fn))
                return;
            elseif data.opto_data.duration_msec ~= duration_msec
                DoError(sprintf('The duration is not consistent in trial %d of %s', trial, fn))
                return;
            elseif data.opto_data.frame_total ~= expected_frames
                DoError(sprintf('The total frames is not expected in trial %d of %s', trial, fn))
                return;
            end
            
            %gather data
            if noround
                ired_data = data.opto_data.ired;
            else
                ired_data = data.opto_data.ired_rounded;
            end
            odat.X(:,:,trial) = [ired_data.X];
            odat.Y(:,:,trial) = [ired_data.Y];
            odat.Z(:,:,trial) = [ired_data.Z];
            odat.V(:,:,trial) = [ired_data.Velocity];
            odat.A(:,:,trial) = [ired_data.Accelation];
            
            %condition if present
            if isfield(data, 'condition')
                odat.conditions{trial} = data.condition;
            end
                
            %store trial id
            odat.trial_id(trial) = data.trial_id;
        end
        
        %store filepath
        odat.noround = noround;
        odat.sample_rate = sample_rate;
        odat.number_IREDs = IRED_NUMBER_PER_TRIAL;
        odat.duration_msec = duration_msec;
        odat.number_frames = expected_frames;
        odat.number_trials = number_trials;
        odat.filepath_mat = [PathName fn];
        odat.legend = 'var(frame,ired,trial)';
        
        %save
        set(globals.processing,'string','saving...')
        fprintf('\n\tSaving...\n');
        
        fn_out = fn(1:find(fn=='.',1,'last')-1);
        if noround
            fn_out = [fn_out '_NonRoundedValues'];
        else
            fn_out = [fn_out '_RoundedValues'];
        end
        
        saveFol = [pwd filesep 'Step 1 Output - Opto Data'];
        
        save([saveFol filesep fn_out],'odat');
        set(globals.processing,'string',['Complete (' fn_out '.mat)'])

        if ispc %is windows
            winopen(saveFol)
        elseif ismac
            system(['open ',saveFol]);
        end
        
    end
    fprintf('\nComplete\n');
    
else
    %txt mode...


    %% Create list of all similar files
    fn = [PathName FileName];
    fn = fn(1:find(fn=='_',1,'last'));
    list = dir([fn '*.txt']);
    numFile = length(list);

    %% Indicate missing
    minNum = list(1).name([length(fn)+1:length(fn)+3]-length(PathName));
    maxNum = str2num(list(numFile).name([length(fn)+1:length(fn)+3]-length(PathName)));
    missing=[];
    if maxNum > numFile
        for i = 1:maxNum
            if ~exist(sprintf('%s%03d.txt',fn,i))
                missing=[missing i];
            end
        end
        set(globals.files,'string',[minNum '-' num2str(maxNum) ' except ' num2str(missing)])
    else
        set(globals.files,'string',[minNum '-' num2str(maxNum)])
    end

    %% Cycle through, loading into a matrix
    trial = 0;
    for i = 1:numFile
        str = sprintf('%03d of %03d',i,numFile);
        set(globals.processing,'string',str)
        drawnow

        %read in
        file = load([PathName list(i).name]);

        %params
        trial = trial + 1;
        numIred(trial) = (size(file,2)-2)/5;

        if i == 1
            set(globals.numIRED,'string',num2str(numIred(trial)))
        end

        %check that we can work with it
        if numIred(trial) ~= round(numIred(trial))
            DoError('Incorrect number of columns found.')
            return
        end

        %convert blocked from 100000.0 to NaN
        file(file==100000) = nan;

        for row = 1:size(file,1)
            %put in XYZVA
            IRED = 1;
            for col = 1:(numIred*5)
                which = mod(col-1,5)+1;
                switch which
                    case 1%X
                        odat.X(row,IRED,trial) = file(row,col);
                    case 2%Y
                        odat.Y(row,IRED,trial) = file(row,col);
                    case 3%Z
                        odat.Z(row,IRED,trial) = file(row,col);
                    case 4%V
                        odat.V(row,IRED,trial) = file(row,col);
                    case 5%A
                        odat.A(row,IRED,trial) = file(row,col);
                        IRED = IRED + 1;
                end
            end
        end
    end

    %% Any warnings
    if sum(numIred ~= min(numIred))
        DoError('The number of IREDs is not consistent across trials.')
        return
    end

    %% Create output folder if it doesn't exist
    if ~exist([pwd filesep 'Step 1 Output - Opto Data'])
        mkdir('Step 1 Output - Opto Data')
    end

    %% Save
    f = fn(find(fn==filesep,1,'last')+1:end-1);
    odat.optoFiles = [fn '###.txt'];
    odat.legend = 'var(frame,ired,trial)';
    save([pwd filesep 'Step 1 Output - Opto Data' filesep f],'odat');
    set(globals.processing,'string',['Complete (' f '.mat)'])

    saveFol = [pwd filesep 'Step 1 Output - Opto Data'];
    if ispc %is windows
        winopen(saveFol)
    elseif ismac
        system(['open ',saveFol]);
    end
end

catch err
closeAllFigures
rethrow(err)
end
end

function DoError(message)
warning('ERROR: %s', message)
msgbox(message,'Error','error')
global globals
set(globals.processing,'string','error')
set(globals.numIRED,'string','error')
set(globals.files,'string','error')
end

function [struct] = RenameFields(struct)
if ~isfield(struct, 'IRED_NUMBER') && isfield(struct, 'number_IREDs')
    struct.IRED_NUMBER = struct.number_IREDs;
end
if ~isfield(struct, 'IRED_NUMBER') && isfield(struct, 'NUMBER_IREDS')
    struct.IRED_NUMBER = struct.NUMBER_IREDS;
end
if ~isfield(struct, 'IRED_NUMBER_PER_TRIAL') && isfield(struct, 'IRED_NUMBER')
    struct.IRED_NUMBER_PER_TRIAL = struct.IRED_NUMBER;
end
if ~isfield(struct, 'TRIAL_DURATION_MSEC') && isfield(struct, 'RECORD_MSEC')
    struct.TRIAL_DURATION_MSEC = struct.RECORD_MSEC;
end
if ~isfield(struct, 'FRAME_RATE') && isfield(struct, 'SAMPLE_RATE_HZ')
    struct.FRAME_RATE = struct.SAMPLE_RATE_HZ;
end
end
