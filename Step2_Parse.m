function Step2_Parse

% These variables can be changed to match the flags in the EDF file sent by
% project manager.
TRIAL_SIZE = 6000; % set the length of the trial data collector
TRIAL_START = 'Start Trial';  % trial start flag
TRIAL_END = 'End Trial'; % trial end flag
STIMULUS = 'Stimulus'; % stimulus presented
TRIAL_ID = 'Condition'; % which condition is presented

fol_out_step2 = ['.' filesep 'Step2_Parse' filesep];
if ~exist(fol_out_step2,'dir')
    mkdir(fol_out_step2)
end

% select which files are going to be used
[file,path] = uigetfile('*.asc', 'MultiSelect', 'on');
while isempty (file)
    disp ('No files selected')
    [file,path] = uigetfile('*.mat', 'MultiSelect', 'on');
end

% convert single file selection into a cell array
if ~iscell(file)
    file = {file};
end

try

tab = sprintf('\t');
list_length = length(file);
    
for fid_asc = 1:list_length
    clearvars -except file path tab fid_asc fol_out_step2 list_length STIMULUS TRIAL_END TRIAL_START TRIAL_SIZE TRIAL_ID
    
    %read in the current file
    fn = file{fid_asc};
    fn_part = fn(1:find(fn=='.',1,'last')-1);
    
    fid = fopen([path,fn],'r');
    
    started = false;
    trial = 0;
    
   while 1
        line = fgetl(fid);
        if isnumeric(line)
            break
        end
        
        %check to see if line is a message/fixation
        is_msg = length(line)>=3 && strcmp(line(1:3),'MSG');
        is_efix = length(line)>=4 && strcmp(line(1:4),'EFIX');
        is_sfix = length(line)>=4 && strcmp(line(1:4),'SFIX');
        
        if is_msg

            ind_trial_start = strfind(line,TRIAL_START);
            ind_trial_end = strfind(line,TRIAL_END);
            ind_ip = strfind(line,STIMULUS); % ip = image present
            ind_trial_id = strfind(line,TRIAL_ID);
                
                % get trial id (information is only available before trial
                % starts)
                if any(ind_trial_id) & exist('trial_xy','var')
                    face_id = line(ind_trial_id+8:end);
                    trial_data(trial).frame_data = trial_xy{trial};
                    trial_data(trial).trial_id = face_id;
                    trial_data(trial).start_frame = {trial_data(trial).start_frame,str2num(ind_trial_start)};
                    trial_data(trial).end_frame = {trial_data(trial).end_frame,str2num(ind_trial_end)};
                end
                
                %set up a new trial package
                if any(ind_trial_start)
                    trial = trial + 1;
                    trial_xy{trial} = cell(TRIAL_SIZE,6);
                    row = 0;
                    stimulus = nan;
                    fix_num = nan;
                    fix_count = 0;
                end
                
                if any(ind_ip)
                    stimulus = line(ind_ip+6:end);
                elseif any(ind_trial_end)
                    trial_xy{trial} = trial_xy{trial}(1:row,:);
                end
            
        elseif ~is_msg && ~isempty(line)

            % is start/end fixation
            if is_sfix
                fix_count = fix_count + 1;
                fix_num = fix_count;
            elseif is_efix
                fix_num = nan;

            % is data
            elseif any(str2num(line(1)))
                ind_dot = find(line=='.',2,'first');
                time = str2num(line(1:find((line == ' ' | line == tab),1,'first')-1));
                for j = 1:2
                    i = ind_dot(j);
                    ind_start = find(( line(1:i)==' ' | line(1:i)==tab ),1,'last')+1;
                    ind_end = find(line(i:end)==' ' | line(i:end)==tab,1,'first')-1+i;
                    if ind_start == i
                        xy(j) = nan;
                    else
                        xy(j) = str2num(line(ind_start:ind_end));
                    end
                end
                row = row + 1;
                trial_xy{trial}(row,:) = {trial,time,xy(2),xy(1),fix_num,stimulus, started};
            end
        end
    end
    
    save([fol_out_step2 fn_part '.mat'])
    disp(['file created for ' fn_part])
end
disp Done.

catch err
    save
    rethrow(err)
end