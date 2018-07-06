function opto_aux_switchIred
[filename,folder] = uigetfile([pwd '\Step 1 Output - Opto Data\*.mat']);
if length(filename) <= 1
    disp('No file was loaded. Aborting')
    return
end
load([folder filename])
disp(['Loaded "...\Step 1 Output - Opto Data\' filename '".'])

answer = inputdlg({'Select first IRED' 'Select second IRED'},'Select IREDs To Swap',1);

isgood = cellfun(@length,answer)';
if min(isgood) == 0 %nothing entered
    disp('IREDs could not be determined. Aborting.')
    return
end

IRED1 = str2num(answer{1});
IRED2 = str2num(answer{2});

if ~length(IRED1) | ~length(IRED2) %not string
    disp('IREDs could not be determined. Aborting.')
    return
end

numIRED = size(odat.X,2);
if min([IRED1 IRED2])<1 | max([IRED1 IRED2])>numIRED
    disp(['IREDs numbers exceeded possible range(1-' num2str(numIRED) '). Aborting.'])
    return
end

disp('Processing...')

names = 'XYZVA';
for n = 1:length(names)
    %XYZVA
    name = names(n);
    
    %backup IRED1
    backup = [];
    eval(['backup = odat.' name '(:,IRED1,:);'])
    
    %overwrite IRED1 with IRED2
    eval(['odat.' name '(:,IRED1,:) = odat.' name '(:,IRED2,:);'])
    
    %overwrite IRED2 with backup of IRED1
    eval(['odat.' name '(:,IRED2,:) = backup;'])
end

disp('Saving...')

filename = filename(1:find(filename=='.',1,'last')-1);

filename = sprintf('%s_Switched%dAnd%d',filename,IRED1,IRED2);

save([folder filename],'odat')

disp('Saved.')

end