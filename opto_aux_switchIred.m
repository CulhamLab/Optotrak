function opto_aux_switchIred

field_names = 'XYZVA';

[filename,folder] = uigetfile([pwd '\Step 1 Output - Opto Data\*.mat']);
if length(filename) <= 1
    disp('No file was loaded. Aborting')
    return
end
load([folder filename])
numIRED = size(odat.X,2);
disp(['Loaded "...\Step 1 Output - Opto Data\' filename '".'])

answer = inputdlg({'Select first IRED to switch' 'Select second IRED to switch' 'OR enter the new order of IREDs (e.g., 3 2 1)'},sprintf('Select IREDs To Swap (there are %d)', numIRED),1);

filename = filename(1:find(filename=='.',1,'last')-1);

if ~isempty(answer{3}) %entered new order
    
    order_string = answer{3};
    order = str2num(strrep(order_string,',',' '));
    
    if isempty(order)
        error('Order could not be determined from string %s', order_string)
    end
    
    fprintf('New Order: %s\n', sprintf('%d ', order));
    
    if any(order<1) || any(order>numIRED)
        error('IRED number invalid')
    end
    
    if length(order) ~= length(unique(order))
        error('New order contains repeats')
    end
    
    if length(order) < numIRED
        warning('One or more IRED is removed by this reorder (contained %d IREDs)', numIRED)
    end
    
    for name = field_names
        eval(['odat.' name ' = odat.' name '(:,order,:);'])
    end
    
    filename = sprintf('%s_Reorder%s',filename,sprintf('_%d',order));
    
else %switch 2 IREDs (old)
    
    answer = answer(1:2);

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

    if min([IRED1 IRED2])<1 | max([IRED1 IRED2])>numIRED
        disp(['IREDs numbers exceeded possible range(1-' num2str(numIRED) '). Aborting.'])
        return
    end

    disp('Processing...')
    
    for name = field_names
        %backup IRED1
        backup = [];
        eval(['backup = odat.' name '(:,IRED1,:);'])

        %overwrite IRED1 with IRED2
        eval(['odat.' name '(:,IRED1,:) = odat.' name '(:,IRED2,:);'])

        %overwrite IRED2 with backup of IRED1
        eval(['odat.' name '(:,IRED2,:) = backup;'])
    end
    
    filename = sprintf('%s_Switched%dAnd%d',filename,IRED1,IRED2);

end

disp('Saving...')

save([folder filename],'odat')

disp('Saved.')

end