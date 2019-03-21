%Optotrak_Experiment_Template(participant_number, override_start_trial_number)
%
%TODO: description
%
function Optotrak_Experiment_Template(participant_number, override_start_trial_number)

%% Inputs
if ~exist('participant_number', 'var')
    help(mfilename);
    error('Invalid inputs')
else
    d.participant_number = participant_number;
end

if exist('override_start_trial_number', 'var')
    d.trial_start = override_start_trial_number;
else
    d.trial_start = 1;
end

%% Debug mode (disable hardware)
p.DEBUG = true;

%% Check PsychToolbox
AssertOpenGL();

%% Timestamp
d.timestamp = GetTimestamp;

%% Parameters (make changes here)

%paths (directories should end with a file separator, use filesep instead of / or \ for compatibility)
p.PATH.DIR_ORDERS = ['.' filesep 'Orders' filesep];
p.PATH.DIR_MAT_DATA = ['.' filesep 'Data' filesep];
p.PATH.DIR_OPTO_DATA = ['.' filesep 'Opto' filesep sprintf('P%02d', participant_number) filesep];
p.PATH.FILE_ORDER = sprintf('P%02d.xlsx', participant_number);
p.PATH.FILE_DATA = sprintf('P%02d_Start%03d_%s.mat', participant_number, d.trial_start, d.timestamp);
p.PATH.FILE_OPTO = sprintf('P%02d', participant_number); %do not include _###.dat
p.PATH.FILE_WHITENOISE = 'Noise_10sec_0.1amp.wav';

%keys (must match PTB KbName for values to be set automatically)
p.KEYS.CONTINUE.NAME = 'SPACE';
p.KEYS.CHANGE_BLOCK.NAME = 'RETURN';
p.KEYS.STOP.NAME = 'ESCAPE';
p.KEYS.REPEAT.NAME = 'R';

%Optotrak (required fields)
p.OPTO.NUMBER_IREDS = 3;
p.OPTO.RECORD_MSEC = 2000;
p.OPTO.SAMPLE_RATE_HZ = 200;
p.OPTO.DIRECTORY_DATA = p.PATH.DIR_OPTO_DATA;
p.OPTO.FILENAME_DATA = p.PATH.FILE_OPTO;

%Optotrak (optional overrides)
p.OPTO.DEBUG = p.DEBUG;
p.OPTO.NO_FILES = p.DEBUG;
p.OPTO.TIMEOUT_MSEC = 1000;
p.OPTO.DEFAULT_CHECK.ireds_for_percent_check = 2:3; %example: default to require >80% unblocked frames in ireds 2 and 3 unless override is passed to OptotrakCheckData
p.OPTO.DEFAULT_CHECK.minimum_percent_present = 80;  %example: default to require >80% unblocked frames in ireds 2 and 3 unless override is passed to OptotrakCheckData
p.OPTO.KEYS = p.KEYS; %use same STOP and CONTINUE keys

%sound
p.SOUND.LATENCY = .050;
p.SOUND.CHANNELS = 2;
p.SOUND.PLAY_FREQUENCY = 44100;
p.SOUND.VOLUME = 1; %1 = 100%

%% Preparations

%set key values
KbName('UnifyKeyNames');
for key = fields(p.KEYS)'
    key = key{1};
    eval(sprintf('p.KEYS.%s.VALUE = KbName(p.KEYS.%s.NAME);', key, key))
end

%make data folder
if ~exist(p.PATH.DIR_MAT_DATA, 'dir')
    mkdir(p.PATH.DIR_MAT_DATA);
end

%load whitenoise
[noise_amp, noise_freq] = audioread(p.PATH.FILE_WHITENOISE);
if size(noise_amp,2)==1 && p.SOUND.CHANNELS>1
    noise_amp = repmat(noise_amp, [1 p.SOUND.CHANNELS]);
end
noise_amp = noise_amp';
noise_duration_seconds = (size(noise_amp,2)/noise_freq) - 0.25; %treat as 0.25sec shorter for smoother loop
if noise_freq ~= p.SOUND.PLAY_FREQUENCY
    warning('Whitenoise frequency does not match sound handler frequency so it might not sound right')
end

%read and process order file
[~,~,xls] = xlsread([p.PATH.DIR_ORDERS p.PATH.FILE_ORDER]);
[d.trial_info, d.number_trials_in_order, d.number_blocks] = ProcessOrder(xls);
if d.trial_start > d.number_trials_in_order
    error('Start trial exceeds number of trials!')
end

%% Warn + require key if any debug setting is true

if p.DEBUG
    warning('One or more debug settings is enabled! Press %s to continue or %s to exit.', p.KEYS.CONTINUE.NAME, p.KEYS.STOP.NAME)
    WaitForKeysReleased(p);
    while 1
        [~,keys,~] = KbWait(-1);
        if any(keys(p.KEYS.STOP.VALUE))
            error('Exit key pressed.')
        elseif any(keys(p.KEYS.CONTINUE.VALUE))
            break;
        end
    end
    WaitForKeysReleased(p);
end

%% Try...
try

%% SOUND

%sound player
InitializePsychSound(1);
sound_handle = PsychPortAudio('Open', [], 1, [], p.SOUND.PLAY_FREQUENCY, p.SOUND.CHANNELS, [], p.SOUND.LATENCY);
PsychPortAudio('Volume', sound_handle, p.SOUND.VOLUME);

%make some beeps
beep_high = repmat(MakeBeep(500, 0.25, p.SOUND.PLAY_FREQUENCY), [p.SOUND.CHANNELS 1]);
beep_low = repmat(MakeBeep(300, 0.25, p.SOUND.PLAY_FREQUENCY), [p.SOUND.CHANNELS 1]) * 1.2;

%pre-play a beep for better timing later
if ~p.DEBUG
    PsychPortAudio('FillBuffer', sound_handle, beep_high);
    PsychPortAudio('Start', sound_handle);
    PsychPortAudio('Stop', sound_handle, 1);
    WaitSecs(0.1);
    PsychPortAudio('FillBuffer', sound_handle, beep_low);
    PsychPortAudio('Start', sound_handle);
    PsychPortAudio('Stop', sound_handle, 1);
end

%% Optotrak Initialization
OptotrakInitialize(p.OPTO);

%% Wait for key to begin (could display some info to experimenter here)

fprintf('Ready to begin! Press %s to continue or %s to exit.\n', p.KEYS.CONTINUE.NAME, p.KEYS.STOP.NAME)
WaitForKeysReleased(p);
while 1
    [~,keys,~] = KbWait(-1);
    if any(keys(p.KEYS.STOP.VALUE))
        error('Exit key pressed.')
    elseif any(keys(p.KEYS.CONTINUE.VALUE))
        break;
    end
end
WaitForKeysReleased(p);

%% Trials

prior_block = 'none';
trial = d.trial_start;
t0 = GetSecs;
d.trials_start_time = t0;
do_auto_repeat = false;

while 1 %repeating trials is much more simples in a while loop than a for loop
    %release keys
    WaitForKeysReleased(p);
    
    %auto repeat if problem in prior opto
    if do_auto_repeat
        d = RepeatTrial(d, trial, trial_repeat_data, true);
        do_auto_repeat = false;
        %this loop becomes the repeat trial
    end
    
    %stop if no more trials
    d.number_trials = length(d.trial_info);
    if trial > d.number_trials
        fprintf('End of Experiment\n\nPress %s to end\nPress %s to repeat trial', p.KEYS.CHANGE_BLOCK.NAME, p.KEYS.REPEAT.NAME);
        end_exp = false;
        while 1
            [~, keys] = KbWait(-1);
            if any(keys(p.KEYS.STOP.VALUE))
                %end of experiment
                end_exp = true;
                break
            elseif any(keys(p.KEYS.CHANGE_BLOCK.VALUE))
                %end of experiment
                end_exp = true;
                break;
            elseif any(keys(p.KEYS.REPEAT.VALUE))
                d = RepeatTrial(d, trial, trial_repeat_data, true);
                break;
            end
        end
        if end_exp
            %end experiment
            break;
        end
    end
    
    %can repeat?
    if trial>1 & ~d.trial_info(trial-1).repeated
        repeat_string = sprintf('\nPress %s to repeat trial', p.KEYS.REPEAT.NAME);
        can_repeat = true;
    else 
        repeat_string = '';
        can_repeat = false;
    end
    
    %detect change in block + wait for key press
    block = d.trial_info(trial).block;
    if ~strcmp(d.trial_info(trial).block, prior_block)
        fprintf('~~~~~~~~~~~\nNEW BLOCK\n%d of %d\n%s\n\nPress %s to continue%s\n~~~~~~~~~~~\n', d.trial_info(trial).block_number, d.number_blocks, block, p.KEYS.CHANGE_BLOCK.NAME, repeat_string);
        do_repeat = false;
        while 1
            [~, keys] = KbWait(-1);
            if any(keys(p.KEYS.STOP.VALUE))
                error('Exit key pressed.')
            elseif any(keys(p.KEYS.CHANGE_BLOCK.VALUE))
                break;
            elseif any(keys(p.KEYS.REPEAT.VALUE))
                d = RepeatTrial(d, trial, trial_repeat_data, true);
                do_repeat = true;
                break;
            end
        end
        if do_repeat
            continue;
        end
    end
    prior_block = block;
    
    %release keys
    WaitForKeysReleased(p);
    
    %display trial info
    d.trial_info(trial)
    
    %DON'T call OptotrakPrepareTrigger yet! Could still loop back to repeat prior trial
    
    %name of condition
    label_string = [d.trial_info(trial).task ' ' d.trial_info(trial).target];
    
    %loop noise until key press to start trial
    time_start_trial_prep = GetSecs;
    PsychPortAudio('FillBuffer', sound_handle, noise_amp);
    time_loop_noise = 0;
    do_repeat = false;
    fprintf('Trial %d of %d\nBlock: %s\nCondition: %s\nPress %s to start%s\n', trial, d.number_trials, block, label_string, p.KEYS.CONTINUE.NAME, repeat_string);
    while 1
        %loop noise
        if ~d.trial_info(trial).is_calibration
            if (GetSecs - time_loop_noise) > noise_duration_seconds
                time_loop_noise = GetSecs;
                PsychPortAudio('Stop', sound_handle);
                PsychPortAudio('Start', sound_handle);
            end
        end
        
        %check keys
        [~, ~, keys] = KbCheck(-1);
        if any(keys(p.KEYS.STOP.VALUE))
            PsychPortAudio('Stop', sound_handle);
            error('Exit key pressed.')
        elseif any(keys(p.KEYS.CONTINUE.VALUE))
            break;
        elseif can_repeat && any(keys(p.KEYS.REPEAT.VALUE))
            PsychPortAudio('Stop', sound_handle);
            d = RepeatTrial(d, trial, trial_repeat_data, true);
            do_repeat = true;
            break;
        end
    end
    %stop noise
    PsychPortAudio('Stop', sound_handle);
    %repeat trial?
    if do_repeat
        continue;
    end
    
    %prepare optotrak for trial
    OptotrakPrepareTrigger(trial);
    
    %make a backup for trial repeat
    trial_repeat_data = d.trial_info(trial);
    
    %record how long trial prep took
    d.trial_info(trial).timing.duration_prepare_trial = GetSecs - time_start_trial_prep;
    
    %prepare high beep
    PsychPortAudio('FillBuffer', sound_handle, beep_high);
    
    %start opto trigger
    d.trial_info(trial).timing.trigger_opto_start = OptotrakTriggerStart;
    
    %any other time-sensitive start-of-trial actions
    PsychPortAudio('Start', sound_handle); %start high beep
    
    %finish opto triggering
    d.trial_info(trial).timing.trigger_opto_stop = OptotrakTriggerStop;
    
    %trial plays out...
    PsychPortAudio('Stop', sound_handle, 1); %stop beep once finished to prevent potential noise
    PsychPortAudio('FillBuffer', sound_handle, beep_low);
    tend = d.trial_info(trial).timing.trigger_opto_start + (p.OPTO.RECORD_MSEC / 1000);
    while 1
        %time to end trial?
        if GetSecs >= tend
            break;
        end
        
        %check if stop key pressed
        [~, ~, keys] = KbCheck(-1);
        if any(keys(p.KEYS.STOP.VALUE))
            PsychPortAudio('Stop', sound_handle);
            error('Exit key pressed.')
        end
    end
    
    %end of trial
    d.trial_info(trial).timing.trial_end = GetSecs;
    PsychPortAudio('Start', sound_handle); %start low beep
    
    %check optotrak
    [d.trial_info(trial).opto_data_passes_checks, d.trial_info(trial).opto_data] = OptotrakCheckData;
    
    %auto-repeat if issue in opto data
    if ~d.trial_info(trial).opto_data_passes_checks
        warning('Issues detected! Trial will repeated!')
        do_auto_repeat = true;
    end
    
    %save
    save([p.PATH.DIR_MAT_DATA p.PATH.FILE_DATA], 'p', 'd');
    
    %next trial
    trial = trial + 1;
end

%% Complete!
TryCloseAudio(sound_handle);
global opto
save([p.PATH.DIR_MAT_DATA p.PATH.FILE_DATA], 'p', 'd', 'opto');
OptotrakComplete
disp Complete!

%% Catch
catch err
    if exist('sound_handle', 'var')
        TryCloseAudio(sound_handle);
    end
    
    save(['error_dump_' d.timestamp])
    
    rethrow(err)
end

%% Functions

function [timestamp, timestamp_short] = GetTimestamp
c = round(clock);
timestamp = sprintf('%d-%d-%d_%d-%d_%d',c([4 5 6 3 2 1]));
timestamp_edf = sprintf('%02d%02d', c(5:6)); %4 digit MMSS timestamp for Eyelink edf which require short names

function [trial_info, number_trials, block_number] = ProcessOrder(xls)
headers = lower(strrep(xls(1,:),' ','_'));
data = xls(2:end,:);
number_trials = size(data,1);
number_headers = length(headers);
block_number = 0;
prior_block = 'none';
for trial = 1:number_trials
    for h = 1:number_headers
        eval(sprintf('trial_info(trial).%s = data{trial, h};', headers{h}))
    end
    trial_info(trial).original = true;
    trial_info(trial).repeated = false;
    
    if ~strcmp(trial_info(trial).block, prior_block)
        block_number = block_number + 1;
        prior_block = trial_info(trial).block;
    end
    trial_info(trial).block_number = block_number;
    
    %insert any extra order processing here
    trial_info(trial).is_calibration = ~isempty(strfind(lower(trial_info(trial).block), 'calibration'));
    
end

function WaitForKeysReleased(p)
key_values = [];
for f = fields(p.KEYS)'
    values = getfield(getfield(p.KEYS, f{1}), 'VALUE');
    key_values = [key_values values];
end
t = GetSecs;
while 1
    [~,~,keys] = KbCheck(-1);
    
    %all keys released?
    if ~any(keys(key_values))
        return
    end
    
    %stop key still pressed after a few seconds?
    if any(keys(p.KEYS.STOP.VALUE)) && ((GetSecs - t) > 2)
        error('Stop key pressed')
    end
end

function [d] = RepeatTrial(d, trial, trial_repeat_data, immediate)
if ~d.trial_info(trial-1).repeated
    %insert at end of block
    ind = trial;
    if immediate
        ind = trial;
    else
        ind = trial;
        while ind < d.number_trials
            if ind==1 || ~strcmp(d.trial_info(ind-1).block_condition, d.trial_info(ind).block_condition)
                break;
            end
            ind = ind + 1;
        end
    end
    %mark this trial as repeated
    d.trial_info(trial-1).repeated = true;
    %move later trials back one
    d.trial_info((ind+1):(end+1)) = d.trial_info(ind:end);
    %insert copied trial
    trial_repeat_data.original = false;
    trial_repeat_data.repeated = false;
    d = ReplaceTrial(d, ind, trial_repeat_data);
    %count new number of trials
    d.number_trials = length(d.trial_info);
    
%     cellfun(@(x,y) [x '-' y], {d.trial_info.block_condition}, {d.trial_info.label}, 'UniformOutput', false)
else
    warning('Trial to repeat an already repeated trial?')
end

function [d] = ReplaceTrial(d, ind, trial_repeat_data)
%clear prior if exists
if ind <= d.number_trials
    list = fields(d.trial_info);
    while 1
        list_next = cell(0);
        for f = list'
            f = f{1};
            eval(sprintf('is_struct = isstruct(d.trial_info(ind).%s);', f))
            if is_struct
                eval(sprintf('fs = fields(d.trial_info(ind).%s);', f))
                fs = cellfun(@(x) [f '.' x], fs, 'UniformOutput', false);
                list_next = [list_next; fs];
            else
                eval(sprintf('d.trial_info(ind).%s = [];', f))
            end
        end

        list = list_next;
        if isempty(list)
            break;
        end
    end
end
%copy trial_repeat_data
list = fields(trial_repeat_data);
while 1
    list_next = cell(0);
    for f = list'
        f = f{1};
        eval(sprintf('is_struct = isstruct(trial_repeat_data.%s);', f))
        if is_struct
            eval(sprintf('fs = fields(trial_repeat_data.%s);', f))
            fs = cellfun(@(x) [f '.' x], fs, 'UniformOutput', false);
            list_next = [list_next; fs];
        else
            eval(sprintf('d.trial_info(ind).%s = trial_repeat_data.%s;', f, f))
        end
    end
    
    list = list_next;
    if isempty(list)
        break;
    end
end

function TryCloseAudio(handle)
try
    PsychPortAudio('Close', handle')
end