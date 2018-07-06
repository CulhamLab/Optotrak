function opto_aux_setFailedOnOff
try
    closeAllFigures
    global globals
    globals = [];
    
    % GUI - Load template
    globals.fig = hgload([pwd filesep 'GUI' filesep 'opto_aux_setFailedOnOff.fig']);
    
    % GUI - Set font sizes
    set(findall(globals.fig, '-property', 'FontSize'), 'FontSize', 15);
    
    % GUI - Callback functions and list contents
    tagsOfInterest = {'buttonGo' 'buttonClose' 'textOn' 'textOff' 'menuOnUpper' 'menuOffUpper' 'menuOnLower' 'menuOffLower'};
    for t = 1:length(tagsOfInterest)
        tagname = tagsOfInterest{t};
        id = findall(globals.fig,'tag',tagname);
        set(id,'callback',eval(['@' tagname]))
        if length(strfind(tagname,'text'))
            set(id,'string','1')
        elseif length(strfind(tagname,'Lower'))
            set(id,'string',{'X' 'Y' 'Z'})
        elseif length(strfind(tagname,'Upper'))
            set(id,'string',{'DISABLED' 'Min' 'Max'})
        end
    end
    
    % GUI - Init (disable all)
    menuOffUpper(findall(globals.fig,'tag','menuOffUpper'))
    menuOnUpper(findall(globals.fig,'tag','menuOnUpper'))
    
catch err
    closeAllFigures
    rethrow(err)
end
end

function buttonGo(~,~)
global globals

% Collect IDs
tagsOfInterest = {'textOn' 'textOff' 'menuOnUpper' 'menuOffUpper' 'menuOnLower' 'menuOffLower'};
for t = 1:length(tagsOfInterest)
    tagname = tagsOfInterest{t};
    eval(['tag_' tagname ' = findall(globals.fig,''tag'',tagname);'])
end

% Check that all requirements are met
if get(tag_menuOnUpper,'value')==1 & get(tag_menuOffUpper,'value')==1
    waitfor(msgbox('Both onset and offset are disabled. Cannot proceed.','Error','error'))
    return
end

% Get file
if ~exist('Step 2 Output - OnsetOffset and GripAp')
    [filename,folder] = uigetfile('*.mat');
else
    [filename,folder] = uigetfile([pwd filesep 'Step 2 Output - OnsetOffset and GripAp' filesep '*.mat']);
end
    
% Load file
load([folder filename])

% check that the requisit IRED(s) exist
OnIRED = str2num(get(tag_textOn,'string'));
OffIRED = str2num(get(tag_textOff,'string'));
numIRED = size(odat.X,2);
if numIRED<OnIRED | numIRED<OffIRED
    waitfor(msgbox('An IRED could not be found in the data file. Cannot proceed.','Error','error'))
    return
end

% check if data is legacy
hasFoundVar = sum(cellfun(@(x) strcmp(x,'found'),fields(ocalc.onset)));
if ~hasFoundVar
    waitfor(msgbox('The selected file was created from a pipeline version prior to v7. This will probably still work, but assumptions will have to be made. Onset at frame 1 will be assumed erroneous. Offset at the final frame will be assumed erroneous.','Warning','Warn'))
end

% process - onset
if get(tag_menuOnUpper,'value')==1
    disp('ONset defaulting not requested. Continuing...')
else
    disp('ONset defaulting...')
    %trials to process
    if hasFoundVar
        trialsToCorrect = find(ocalc.onset.found==0);
    else
        trialsToCorrect = find(ocalc.onset.onsetFrame==1);
    end
    
    numToCorrect = length(trialsToCorrect);
    if numToCorrect
        fprintf('-Found %g trials to corect: %s\n',numToCorrect,num2str(trialsToCorrect))
        for trial = trialsToCorrect
            XYZ_This = get(tag_menuOnLower,'string');
            XYZ_This = XYZ_This{get(tag_menuOnLower,'value')}; %a string containing X, Y, or Z
            valsOfInterest = eval(['odat.' XYZ_This '(:,' num2str(OnIRED) ',' num2str(trial) ');']);
            MinMax_This = get(tag_menuOnUpper,'string');
            MinMax_This = lower(MinMax_This{get(tag_menuOnUpper,'value')});%a string containing min or max
            threshVal = eval([MinMax_This '(valsOfInterest);']);
            newOnset = find(valsOfInterest==threshVal,1,'last'); %last occurance
            ocalc.onset.onsetFrame(trial) = newOnset;
        end
        disp('-ONset defaulting complete')
    else
        disp('-No trials needed ONset corrected')
    end
end

% process - offset
if get(tag_menuOffUpper,'value')==1
    disp('OFFset defaulting not requested. Continuing...')
else
    disp('OFFset defaulting...')
    %trials to process
    if hasFoundVar
        trialsToCorrect = find(ocalc.offset.found==0);
    else
        trialsToCorrect = find(ocalc.offset.offsetFrame==1);
    end
    
    numToCorrect = length(trialsToCorrect);
    if numToCorrect
        fprintf('-Found %g trials to corect: %s\n',numToCorrect,num2str(trialsToCorrect))
        for trial = trialsToCorrect
            XYZ_This = get(tag_menuOffLower,'string');
            XYZ_This = XYZ_This{get(tag_menuOffLower,'value')}; %a string containing X, Y, or Z
            valsOfInterest = eval(['odat.' XYZ_This '(:,' num2str(OnIRED) ',' num2str(trial) ');']);
            MinMax_This = get(tag_menuOffUpper,'string');
            MinMax_This = lower(MinMax_This{get(tag_menuOffUpper,'value')});%a string containing min or max
            threshVal = eval([MinMax_This '(valsOfInterest);']);
            newOffset = find(valsOfInterest==threshVal,1); %first occurance
            if newOffset < ocalc.onset.onsetFrame(trial);
                newOffset = ocalc.onset.onsetFrame(trial) + 1; %must be after onset
                if newOffset > length(valsOfInterest)
                    newOffset = length(valsOfInterest);
                    ocalc.onset.onsetFrame(trial) = ocalc.onset.onsetFrame(trial) - 1;
                end
            end
            ocalc.offset.offsetFrame(trial) = newOffset;
        end
        disp('-OFFset defaulting complete')
    else
        disp('-No trials needed OFFset corrected')
    end
end

% resave (add suffix)
fprintf('Saving: %s...\n','temp')
newfp = [folder filename(1:end-4) '_setFailedOnOff'];
save(newfp,'ocalc','odat','params')
disp('-Saved.')

% complete
disp('All processes completed.')
waitfor(msgbox('Complete!'))
eval(mfilename) %reload function (clears everything)

end

function buttonClose(~,~)
closeAllFigures
end

function textOn(id,~)
input = get(id,'string');
input_asNum = str2num(input); %remove non-numeric char
if length(input_asNum)
    input_asNum = input_asNum(1);
else
    input_asNum = 1;
end
input_backToStr = num2str(input_asNum);
set(id,'string',input_backToStr);
end

function textOff(id,~)
input = get(id,'string');
input_asNum = str2num(input); %remove non-numeric char
if length(input_asNum)
    input_asNum = input_asNum(1);
else
    input_asNum = 1;
end
input_backToStr = num2str(input_asNum);
set(id,'string',input_backToStr);
end

function menuOnUpper(id,~)
global globals
tagsToVanish = {'menuOnLower' 'textOn' 'textOnLabel'};
for t = 1:length(tagsToVanish)
    tagname = tagsToVanish{t};
    if get(id,'value')==1
        set(findall(globals.fig,'tag',tagname),'Visible','off')
    else
        set(findall(globals.fig,'tag',tagname),'Visible','on')
    end
end
end

function menuOffUpper(id,~)
global globals
tagsToVanish = {'menuOffLower' 'textOff' 'textOffLabel'};
for t = 1:length(tagsToVanish)
    tagname = tagsToVanish{t};
    if get(id,'value')==1
        set(findall(globals.fig,'tag',tagname),'Visible','off')
    else
        set(findall(globals.fig,'tag',tagname),'Visible','on')
    end
end
end

function menuOnLower(~,~), end %nothing at the moment
function menuOffLower(~,~), end %nothing at the moment

function closeAllFigures(fig, evt)
%working with gui figs so "close all" won't work
delete(findall(0, 'type', 'figure'))
end