function Kaitlin_Analysis_Step1_Parse

% These variables can be changed to match the flags in the EDF file sent by
% project manager.
TRIAL_SIZE = 6000; % set the length of the trial data collector
TRIAL_START = 'StartTrial';  % trial start flag
TRIAL_END = 'EndTrial'; % trial end flag
IMAGE_PRESENT = 'Stimulus:'; % stimulus presented

fol_out_step1 = ['.' filesep 'Step1_Parse' filesep];
if ~exist(fol_out_step1,'dir')
    mkdir(fol_out_step1)
end

fol_asc = ['.' filesep 'EDFs' filesep];

list_asc = dir([fol_asc '*.asc']);

try

tab = sprintf('\t');
list_length = length(list_asc);
    
for fid_asc = 1:list_length
    clearvars -except fol_asc list_asc tab fid_asc fol_out_step1 list_length TRIAL_ID IMAGE_PRESENT TRIAL_END TRIAL_START TRIAL_SIZE
    
    fn = list_asc(fid_asc).name;
    fn_part = fn(1:find(fn=='.',1,'last')-1);
    
    fid = fopen([fol_asc fn],'r');
    
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
            ind_ip = strfind(line,IMAGE_PRESENT); % ip = image present
            ind_trial_id = strfind(line,TRIAL_ID);
            if ~started
                
                % get trial id (information is only available before trial
                % starts)
                if any(ind_trial_id) & exist('trial_xy','var')
                    face_id = line(ind_trial_id+8:end);
                    trial_data(trial).frame_data = trial_xy{trial};
                    trial_data(trial).trial_id = face_id;
                end
                
                %set up a new trial package
                if any(ind_trial_start)
                    trial = trial + 1;
                    trial_xy{trial} = nan(TRIAL_SIZE,5);
                    row = 0;
                    pic_num = nan;
                    fix_num = nan;
                    fix_count = 0;
                    started = true;
                end
                
            else
                if any(ind_ip)
                    pic_num = str2num(line(ind_ip+6:end));
                elseif any(ind_trial_end)
                    started = false;
                    trial_xy{trial} = trial_xy{trial}(1:row,:);
                end
            end
            
        elseif started && ~is_msg && ~isempty(line)

            % is start/end fixation
            if is_sfix
                fix_count = fix_count + 1;
                fix_num = fix_count;
            elseif is_efix
                fix_num = nan;

                %is data
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
                trial_xy{trial}(row,:) = [time,xy,pic_num,fix_num];
            end        
        end
    end
    
    save([fol_out_step1 fn_part '.mat'])
    disp(['file created for ' fn_part])
end
disp Done.

catch err
    save
    rethrow(err)
end