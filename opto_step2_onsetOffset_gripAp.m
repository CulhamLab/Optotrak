function opto_step2_onsetOffset_gripAp
try
closeAllFigures
%% GUI- Load
fig = hgload([pwd filesep 'GUI' filesep 'opto_step2_onsetOffset_gripAp' '.fig']);

%% GUI - Global vars that need to transfer to/from GUI
global globals

%% Set save folder name
globals.saveFolName = [];

%% GUI - Set text and get IDs
name = 'Script 2: Calculate Onsets, Offsets, and GripAps';
set(fig,'name',name);
texts = findall(fig, 'style', 'text');
for t = texts'
    text  = get(t,'tag');
    switch text
        case 'textTitle'
            set(t,'string',name)
        case 'textInstructions'
            inst = sprintf('1. Fill in parameters or load parameter set\n2. Press "Go" and select the mat file from prior step\n3. Wait for the display to indicate completion\n*In onset/offset thresholds, ired is ignored for grip apertures.');
            set(t,'string',inst)
        case 'label_IREDs'
            set(t,'string','IRED:')
        case 'label_Threshold'
            set(t,'string','Threshold:')  
        case 'label_Type'
            set(t,'string','Type:')
        case 'label_IRED'
            set(t,'string','IRED:')
        case 'textProcessedL'
            set(t,'string','Processing: ')
        case 'textProcessed'
            set(t,'string','')
            globals.processing = t;
    end
end
edits = findall(fig, 'style', 'edit');
for t = edits'
    text  = get(t,'tag');
    text = text(5:end);
    switch text(1:4)
        case 'IRED'
            x = find(text=='_',1);
            n = str2num(text(end));
            if text(x+1:x+2)=='On'
                set(t,'string','')
                globals.onset.IREDs(n) = t;
            else
                set(t,'string','')
                globals.offset.IREDs(n) = t;
            end
        case 'Thre'
            x = find(text=='_',1);
            n = str2num(text(end));
            if text(x+1:x+2)=='On'
                set(t,'string','')
                globals.onset.thresh(n) = t;
            else
                set(t,'string','')
                globals.offset.thresh(n) = t;
            end
        case 'pmen'
            x = find(text=='_',1);
            n = str2num(text(end));
            n2 = str2num(text(x+1));
            globals.gripap.IREDs(n2,n) = t; %(pair 1-3, 1or2)
            set(t,'string','')
        case 'Fram'
            x = find(text=='_',1);
            n = str2num(text(end));
            if text(x+1:x+2)=='On'
                set(t,'string','')
                globals.onset.frames(n) = t;
            else
                set(t,'string','')
                globals.offset.frames(n) = t;
            end
        case 'MinF'
            globals.MinFrame = t;
        otherwise
            %no action
    end
end
edits = findall(fig, 'style', 'popupmenu');
for t = edits'
    text  = get(t,'tag');
    text = text(10:end);
    switch text(1:4)
        case 'AndO'
            x = find(text=='_',1);
            if text(x+1:x+2)=='On'
                set(t,'string',{'Just Upper' 'Upper AND Lower' 'Upper OR Lower'})
                globals.onset.AndOr = t;
            else
                set(t,'string',{'Just Upper' 'Upper AND Lower' 'Upper OR Lower'})
                globals.offset.AndOr = t;
            end
        case 'Type'
            x = find(text=='_',1);
            n = str2num(text(end));
            if text(x+1:x+2)=='On'
                set(t,'string',{'Greater Than' 'Less Than'})
                globals.onset.type(n) = t;
            else
                set(t,'string',{'Less Than' 'Greater Than'})
                globals.offset.type(n) = t;
            end
        case 'Thre'
            x = find(text=='_',1);
            n = str2num(text(end));
            if text(x+1:x+2)=='On'
                globals.onset.measure(n) = t;
            else
                globals.offset.measure(n) = t;
            end
            set(t,'string',opto_functions('measure_getList'))
%             {'X' 'Y' 'Z' 'Velocity' 'Acceleration' 'X-Velocity' ... 
%                 'Y-Velocity' 'Z-Velocity' 'Grip Aperture 1' 'Grip Aperture 1 Velocity' ...
%                 'Grip Aperture 2' 'Grip Aperture 2 Velocity' 'Grip Aperture 3' 'Grip Aperture 3 Velocity'})
            set(t,'callback',@MeasureChange)
        otherwise
            %no action
    end
end
buttons = findall(fig, 'style', 'pushbutton');
for t = buttons'
    text  = get(t,'tag');
    text = text(7:end);
    switch text
        case 'Go'
            set(t,'string','Go')
            globals.buttons.go = t;
        case 'Close'
            set(t,'string','Close')
            globals.buttons.close = t;
        case 'Save'
            set(t,'string','Save')
            globals.buttons.save = t;
        case 'Load'
            set(t,'string','Load')
            globals.buttons.load = t;
    end
end
checks = findall(fig, 'style', 'checkbox');
for t = checks'
    text  = get(t,'tag');
    switch text
        case 'checkAbs_On_1'
            n = str2num(text(end));
            globals.onset.abs(n) = t;
        case 'checkAbs_On_2'
            n = str2num(text(end));
            globals.onset.abs(n) = t;
        case 'checkAbs_Off_1'
            n = str2num(text(end));
            globals.offset.abs(n) = t;
        case 'checkAbs_Off_2'
            n = str2num(text(end));
            globals.offset.abs(n) = t;
        otherwise
            n = str2num(text(end));
            globals.gripap.include(n) = t;
            set(t,'string','Include IRED Pair')
    end
end

%% GUI - Set font sizes
set(findall(fig, '-property', 'FontSize'), 'FontSize', 15);

%% GUI - Give callback instructions to buttons
set(globals.buttons.go,'callback',@buttonGo)
set(globals.buttons.close,'callback',@closeAllFigures)
set(globals.buttons.save,'callback',@buttonSave)
set(globals.buttons.load,'callback',@buttonLoad)

%% Make folders if needed
if ~exist([pwd filesep 'Saved Parameters'])
    mkdir('Saved Parameters');
end
if ~exist([pwd filesep 'Step 2 Output - OnsetOffset and GripAp'])
    mkdir('Step 2 Output - OnsetOffset and GripAp');
end

%% SET ABS visiblity
MeasureChange([],[]);

catch err
closeAllFigures
rethrow(err)
end
end

function closeAllFigures(fig, evt)
%working with gui figs so "close all" won't work
delete(findall(0, 'type', 'figure'))
end

function MeasureChange(fig, evt)
global globals
%REFERENCE: set(t,'string',{'X' 'Y' 'Z' 'Velocity' 'Acceleration' 'X-Velocity'
%            'Y-Velocity' 'Z-Velocity''Grip Aperture 1' 'Grip Aperture 1 Velocity' ...
%            'Grip Aperture 2' 'Grip Aperture 2 Velocity' 'Grip Aperture 3'
%            'Grip Aperture 3 Velocity' })
optsCanBeAbs = opto_functions('measure_getIndAbsAllow');
for n = 1:2
    if length(find(get(globals.onset.measure(n),'value') == optsCanBeAbs))
        set(globals.onset.abs(n),'visible','on');
    else
        set(globals.onset.abs(n),'value',0);
        set(globals.onset.abs(n),'visible','off');
    end
end
for n = 1:2
    if length(find(get(globals.offset.measure(n),'value') == optsCanBeAbs))
        set(globals.offset.abs(n),'visible','on');
    else
        set(globals.offset.abs(n),'value',0);
        set(globals.offset.abs(n),'visible','off');
    end
end

end

function buttonSave(fig, evt)
try
global globals
params = whatsOnTheBoard;
curClock = clock;
filename = sprintf('%d-%d-%d_%d%d.mat',curClock(1),curClock(2),curClock(3),curClock(4),curClock(5));
uisave('params',[pwd filesep 'Saved Parameters' filesep filename])
set(globals.processing,'String','Parameters Saved.')
catch err
closeAllFigures
rethrow(err)
end
end

function buttonLoad(fig, evt)
try
global globals
filename = uigetfile([pwd filesep 'Saved Parameters' filesep '*.mat']);
if ~filename
    return
end
load([pwd filesep 'Saved Parameters' filesep filename])

%Onset/Offset: IREDs
set(globals.offset.IREDs(1),'string',params.offset.IREDs{1});
set(globals.offset.IREDs(2),'string',params.offset.IREDs{2});
set(globals.onset.IREDs(1),'string',params.onset.IREDs{1});
set(globals.onset.IREDs(2),'string',params.onset.IREDs{2});

%Onset/Offset: Thresholds
set(globals.offset.thresh(1),'string',params.offset.thresh{1});
set(globals.offset.thresh(2),'string',params.offset.thresh{2});
set(globals.onset.thresh(1),'string',params.onset.thresh{1});
set(globals.onset.thresh(2),'string',params.onset.thresh{2});

%Onset/Offset: Frames
set(globals.offset.frames(1),'string',params.offset.frames{1});
set(globals.offset.frames(2),'string',params.offset.frames{2});
set(globals.onset.frames(1),'string',params.onset.frames{1});
set(globals.onset.frames(2),'string',params.onset.frames{2});

%Onset/Offset: Threshold Measures
set(globals.offset.measure(1),'value',params.offset.measure{1});
set(globals.offset.measure(2),'value',params.offset.measure{2});
set(globals.onset.measure(1),'value',params.onset.measure{1});
set(globals.onset.measure(2),'value',params.onset.measure{2});

%Onset/Offset: Type
set(globals.offset.type(1),'value',params.offset.type{1});
set(globals.offset.type(2),'value',params.offset.type{2});
set(globals.onset.type(1),'value',params.onset.type{1});
set(globals.onset.type(2),'value',params.onset.type{2});

%Onset/Offset: Upper/AND/OR
set(globals.offset.AndOr,'value',params.offset.andor{1});
set(globals.onset.AndOr,'value',params.onset.andor{1});

%GripAp: IREDs
for i = 1:3%pair
    for ii = 1:2%first and second
        set(globals.gripap.IREDs(i,ii),'string',params.gripap.IREDs{i,ii});
    end
end

%GripAp: Includes
for i = 1:3%pair
    set(globals.gripap.include(i),'value',params.gripap.include{i});
end

%Min frames between on/off
if any(strcmp(fields(params),'minFramesBetweenOnOff'))
    set(globals.MinFrame,'string',num2str(params.minFramesBetweenOnOff))
else
    set(globals.MinFrame,'string','0')
end

%%set abs checkbox
if sum(cellfun(@(x) strcmp(x,'abs'),fields(params.onset)))
    set(globals.onset.abs(1),'value',params.onset.abs(1));
    set(globals.onset.abs(2),'value',params.onset.abs(2));
    set(globals.offset.abs(1),'value',params.offset.abs(1));
    set(globals.offset.abs(2),'value',params.offset.abs(2));
else
    set(globals.onset.abs(1),'value',0);
    set(globals.onset.abs(2),'value',0);
    set(globals.offset.abs(1),'value',0);
    set(globals.offset.abs(2),'value',0);
end
MeasureChange;

set(globals.processing,'String','Parameters Loaded.')

globals.saveFolName = filename(1:find(filename=='.',1,'last')-1);

catch err
closeAllFigures
rethrow(err)
end
end

function [params] = whatsOnTheBoard
try
global globals

%Onset/Offset: IREDs
params.offset.IREDs{1} = get(globals.offset.IREDs(1),'string');
params.offset.IREDs{2} = get(globals.offset.IREDs(2),'string');
params.onset.IREDs{1} = get(globals.onset.IREDs(1),'string');
params.onset.IREDs{2} = get(globals.onset.IREDs(2),'string');

%Onset/Offset: Thresholds
params.offset.thresh{1} = get(globals.offset.thresh(1),'string');
params.offset.thresh{2} = get(globals.offset.thresh(2),'string');
params.onset.thresh{1} = get(globals.onset.thresh(1),'string');
params.onset.thresh{2} = get(globals.onset.thresh(2),'string');

%Onset/Offset: Frames
params.offset.frames{1} = get(globals.offset.frames(1),'string');
params.offset.frames{2} = get(globals.offset.frames(2),'string');
params.onset.frames{1} = get(globals.onset.frames(1),'string');
params.onset.frames{2} = get(globals.onset.frames(2),'string');

%Onset/Offset: Threshold Measures
params.offset.measure{1} = get(globals.offset.measure(1),'value');
params.offset.measure{2} = get(globals.offset.measure(2),'value');
params.onset.measure{1} = get(globals.onset.measure(1),'value');
params.onset.measure{2} = get(globals.onset.measure(2),'value');

%Onset/Offset: Type
params.offset.type{1} = get(globals.offset.type(1),'value');
params.offset.type{2} = get(globals.offset.type(2),'value');
params.onset.type{1} = get(globals.onset.type(1),'value');
params.onset.type{2} = get(globals.onset.type(2),'value');

%Onset/Offset: Upper/AND/OR
params.offset.andor{1} = get(globals.offset.AndOr,'value');
params.onset.andor{1} = get(globals.onset.AndOr,'value');

%GripAp: IREDs
for i = 1:3%pair
    for ii = 1:2%first and second
        params.gripap.IREDs{i,ii} = get(globals.gripap.IREDs(i,ii),'string');
    end
    if ~sum(cellfun(@isempty,{params.gripap.IREDs{i,:}}))
        params.gripap.include{i} = 1;
    else
        params.gripap.include{i} = 0;
    end
end

%Abs
params.onset.abs(1) = get(globals.onset.abs(1),'value');
params.onset.abs(2) = get(globals.onset.abs(2),'value');
params.offset.abs(1) = get(globals.offset.abs(1),'value');
params.offset.abs(2) = get(globals.offset.abs(2),'value');

% %GripAp: Includes
% for i = 1:3%pair
%     params.gripap.include{i} = get(globals.gripap.include(i),'value');
% end

%Minimum frames between on/off (min is 0)
minFramesBetweenOnOff = get(globals.MinFrame,'string');
minFramesBetweenOnOff = str2num(minFramesBetweenOnOff(minFramesBetweenOnOff == '-' | minFramesBetweenOnOff<='9' & minFramesBetweenOnOff>='0'));
if isempty(minFramesBetweenOnOff), minFramesBetweenOnOff = 0;, end
if (minFramesBetweenOnOff<0), minFramesBetweenOnOff = 0;, end
params.minFramesBetweenOnOff = minFramesBetweenOnOff;
set(globals.MinFrame,'string',num2str(minFramesBetweenOnOff));

catch err
closeAllFigures
rethrow(err)
end
end

function buttonGo(fig, evt)
try
global globals
params = whatsOnTheBoard;
% filename = uigetfile([pwd '\Step 1 Output - Opto Data\*.mat']);
filenames = uigetfile([pwd filesep 'Step 1 Output - Opto Data' filesep '*.mat'],'MultiSelect','on');
if ~length(filenames), return, end

if ~iscell(filenames)
filenames = {filenames};
end

for filename = filenames
filename = filename{1};
clearvars -except filename filenames params globals fig evt

set(globals.processing,'String','Loading...')
load([pwd filesep 'Step 1 Output - Opto Data' filesep filename])
set(globals.processing,'String','Processing...')

numFrames = size(odat.X,1);
numIREDs = size(odat.X,2);
numTrials = size(odat.X,3);

ocalc.gripap.IREDs = [];
ocalc.gripap.ga = [];

for trial = 1:numTrials
    set(globals.processing,'String',sprintf('Processing %d of %d',trial,numTrials))
    drawnow
    
    %eventually, the onset/offset upper/lower steps should be combined into
    %one - there is much redundancy here (product of adding unplanned features)
    
    %% Grip Aperture
    %CHANGE: moved up from being after onset/offset to allow use of this
    %measure in onset/offset
    whichPairsToUseAsArray = cellfun(@any,params.gripap.include);
    pairsToUse = find(whichPairsToUseAsArray);
    if ~isempty(pairsToUse)
        for p = 1:length(pairsToUse)
            ired1 = str2num(params.gripap.IREDs{p,1});
            ired2 = str2num(params.gripap.IREDs{p,2});
            if trial == 1
                ocalc.gripap.IREDs{p} = sprintf('%d-%d',ired1,ired2);
            end
            
            for f = 1:numFrames
                loc1 = [odat.X(f,ired1,trial) odat.Y(f,ired1,trial) odat.Z(f,ired1,trial)];
                loc2 = [odat.X(f,ired2,trial) odat.Y(f,ired2,trial) odat.Z(f,ired2,trial)];
                ocalc.gripap.ga{trial}(f,p) = pdist([loc1;loc2],'euclidean');
            end
        end
    end
    
    %% Onset
    %Upper Test
    onsetFrame = zeros(1,numFrames);
    ired = str2num(params.onset.IREDs{1});
    mstr = get(globals.onset.measure(1),'string');
    measure = mstr{params.onset.measure{1}};
    frames = str2num(params.onset.frames{1});
%     if strcmp(measure,'Z-Velocity')
%         measure = 'ZV';
%         measureWeCareAbout = [0; diff(odat.Z(:,ired,trial))];
%     elseif strcmp(measure,'Y-Velocity')
%         measure = 'YV';
%         measureWeCareAbout = [0; diff(odat.Y(:,ired,trial))];
%     elseif strcmp(measure,'X-Velocity')
%         measure = 'XV';
%         measureWeCareAbout = [0; diff(odat.X(:,ired,trial))];
%         
%     elseif strcmp(measure,'Grip Aperture 1')
%         ired = [];
%         measure = 'GA1';
%         if ~any(pairsToUse==1), error('No grip aperture 1 was defined!'), end
%         measureWeCareAbout = ocalc.gripap.ga{trial}(:,1);
%     elseif strcmp(measure,'Grip Aperture 1 Velocity')
%         ired = [];
%         measure = 'GA1Vel';
%         if ~any(pairsToUse==1), error('No grip aperture 1 was defined!'), end
%         measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,1))];
%         
%     elseif strcmp(measure,'Grip Aperture 2')
%         ired = [];
%         measure = 'GA2';
%         if ~any(pairsToUse==2), error('No grip aperture 2 was defined!'), end
%         measureWeCareAbout = ocalc.gripap.ga{trial}(:,2);
%     elseif strcmp(measure,'Grip Aperture 2 Velocity')
%         ired = [];
%         measure = 'GA2Vel';
%         if ~any(pairsToUse==2), error('No grip aperture 2 was defined!'), end
%         measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,2))];
%         
%     elseif strcmp(measure,'Grip Aperture 3')
%         ired = [];
%         measure = 'GA3';
%         if ~any(pairsToUse==3), error('No grip aperture 3 was defined!'), end
%         measureWeCareAbout = ocalc.gripap.ga{trial}(:,3);
%     elseif strcmp(measure,'Grip Aperture 3 Velocity')
%         ired = [];
%         measure = 'GA3Vel';
%         if ~any(pairsToUse==3), error('No grip aperture 3 was defined!'), end
%         measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,3))];
%         
%     else
%         measure = measure(1);
%         eval(['measureWeCareAbout = odat.' measure '(:,ired,trial);'])
%     end
%         
    measureWeCareAbout = opto_functions('measure_getValue',odat,ocalc,pairsToUse,measure,ired,trial);
    measure = opto_functions('measure_getShortform',measure);
    if strfind('measure','Grip')
        ired = [];
    end
    
    if get(globals.onset.abs(1),'value')
        measure = ['Abs' measure];
        measureWeCareAbout = abs(measureWeCareAbout);
    end
    
    ocalc.onset.measureOfInterest{trial,1} = measureWeCareAbout;
    thresh = str2num(params.onset.thresh{1});
    if params.onset.type{1}==1 %Greater Than
        sign = '>';
        measureWeCareAbout(measureWeCareAbout>=thresh) = inf;
    else %Less than
        sign = '<';
        measureWeCareAbout(measureWeCareAbout<=thresh) = inf;
    end
    s = strfind(measureWeCareAbout',inf(1,frames));
    onsetFrame(1,s) = 1;
    if trial == 1
        ocalc.onset.test = sprintf('%s%d%s%d(%d)',measure,ired,sign,thresh,frames);
    end
    
    %Lower Test (if desired)
    if params.onset.andor{1} > 1
        onsetFrame(2,:) = zeros(1,numFrames);
        ired = str2num(params.onset.IREDs{2});
        mstr = get(globals.onset.measure(2),'string');
        measure = mstr{params.onset.measure{2}};
        frames = str2num(params.onset.frames{2});
        if strcmp(measure,'Z-Velocity')
            measure = 'ZV';
            measureWeCareAbout = [0; diff(odat.Z(:,ired,trial))];
        elseif strcmp(measure,'Y-Velocity')
            measure = 'YV';
            measureWeCareAbout = [0; diff(odat.Y(:,ired,trial))];
        elseif strcmp(measure,'X-Velocity')
            measure = 'XV';
            measureWeCareAbout = [0; diff(odat.X(:,ired,trial))];
        
        elseif strcmp(measure,'Grip Aperture 1')
            ired = [];
            measure = 'GA1';
            if ~any(pairsToUse==1), error('No grip aperture 1 was defined!'), end
            measureWeCareAbout = ocalc.gripap.ga{trial}(:,1);
        elseif strcmp(measure,'Grip Aperture 1 Velocity')
            ired = [];
            measure = 'GA1Vel';
            if ~any(pairsToUse==1), error('No grip aperture 1 was defined!'), end
            measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,1))];

        elseif strcmp(measure,'Grip Aperture 2')
            ired = [];
            measure = 'GA2';
            if ~any(pairsToUse==2), error('No grip aperture 2 was defined!'), end
            measureWeCareAbout = ocalc.gripap.ga{trial}(:,2);
        elseif strcmp(measure,'Grip Aperture 2 Velocity')
            ired = [];
            measure = 'GA2Vel';
            if ~any(pairsToUse==2), error('No grip aperture 2 was defined!'), end
            measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,2))];

        elseif strcmp(measure,'Grip Aperture 3')
            ired = [];
            measure = 'GA3';
            if ~any(pairsToUse==3), error('No grip aperture 3 was defined!'), end
            measureWeCareAbout = ocalc.gripap.ga{trial}(:,3);
        elseif strcmp(measure,'Grip Aperture 3 Velocity')
            ired = [];
            measure = 'GA3Vel';
            if ~any(pairsToUse==3), error('No grip aperture 3 was defined!'), end
            measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,3))];
            
        else
            measure = measure(1);
            eval(['measureWeCareAbout = odat.' measure '(:,ired,trial);'])
        end
        
        if get(globals.onset.abs(2),'value')
            measure = ['Abs' measure];
            measureWeCareAbout = abs(measureWeCareAbout);
        end
        
        ocalc.onset.measureOfInterest{trial,2} = measureWeCareAbout;
        thresh = str2num(params.onset.thresh{2});
        if params.onset.type{2}==1 %Greater Than
            sign = '>';
            measureWeCareAbout(measureWeCareAbout>=thresh) = inf;
        else %Less than
            sign = '<';
            measureWeCareAbout(measureWeCareAbout<=thresh) = inf;
        end
        s = strfind(measureWeCareAbout',inf(1,frames));
        onsetFrame(2,s) = 1;
    end
    
    %Conclusion
    if params.onset.andor{1} == 2 %AND
        onsetFrame = min(onsetFrame);
        if trial == 1
            ocalc.onset.test = sprintf('%s AND %s%d%s%d(%d)',ocalc.onset.test,measure,ired,sign,thresh,frames);
        end
    elseif params.onset.andor{1} == 3 %OR
        onsetFrame = max(onsetFrame);
        if trial == 1
            ocalc.onset.test = sprintf('%s OR %s%d%s%d(%d)',ocalc.onset.test,measure,ired,sign,thresh,frames);
        end
    end
    if length(find(onsetFrame==1,1))
        ocalc.onset.onsetFrame(trial) = find(onsetFrame==1,1);
        ocalc.onset.found(trial) = 1;
    else
        ocalc.onset.onsetFrame(trial) = 1;
        ocalc.onset.found(trial) = 0;
    end
    
    %% Offset
    %Upper Test
    offsetFrame = zeros(1,numFrames);
    ired = str2num(params.offset.IREDs{1});
    mstr = get(globals.offset.measure(1),'string');
    measure = mstr{params.offset.measure{1}};
    frames = str2num(params.offset.frames{1});
    if strcmp(measure,'Z-Velocity')
        measure = 'ZV';
        measureWeCareAbout = [0; diff(odat.Z(:,ired,trial))];
    elseif strcmp(measure,'Y-Velocity')
        measure = 'YV';
        measureWeCareAbout = [0; diff(odat.Y(:,ired,trial))];
    elseif strcmp(measure,'X-Velocity')
        measure = 'XV';
        measureWeCareAbout = [0; diff(odat.X(:,ired,trial))];
    
    elseif strcmp(measure,'Grip Aperture 1')
        ired = [];
        measure = 'GA1';
        if ~any(pairsToUse==1), error('No grip aperture 1 was defined!'), end
        measureWeCareAbout = ocalc.gripap.ga{trial}(:,1);
    elseif strcmp(measure,'Grip Aperture 1 Velocity')
        ired = [];
        measure = 'GA1Vel';
        if ~any(pairsToUse==1), error('No grip aperture 1 was defined!'), end
        measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,1))];
        
    elseif strcmp(measure,'Grip Aperture 2')
        ired = [];
        measure = 'GA2';
        if ~any(pairsToUse==2), error('No grip aperture 2 was defined!'), end
        measureWeCareAbout = ocalc.gripap.ga{trial}(:,2);
    elseif strcmp(measure,'Grip Aperture 2 Velocity')
        ired = [];
        measure = 'GA2Vel';
        if ~any(pairsToUse==2), error('No grip aperture 2 was defined!'), end
        measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,2))];
        
    elseif strcmp(measure,'Grip Aperture 3')
        ired = [];
        measure = 'GA3';
        if ~any(pairsToUse==3), error('No grip aperture 3 was defined!'), end
        measureWeCareAbout = ocalc.gripap.ga{trial}(:,3);
    elseif strcmp(measure,'Grip Aperture 3 Velocity')
        ired = [];
        measure = 'GA3Vel';
        if ~any(pairsToUse==3), error('No grip aperture 3 was defined!'), end
        measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,3))];
        
    else
        measure = measure(1);
        eval(['measureWeCareAbout = odat.' measure '(:,ired,trial);'])
    end
    
    if get(globals.offset.abs(1),'value')
        measure = ['Abs' measure];
        measureWeCareAbout = abs(measureWeCareAbout);
    end
    
    ocalc.offset.measureOfInterest{trial,1} = measureWeCareAbout;
    thresh = str2num(params.offset.thresh{1});
    if params.offset.type{1}==2 %Greater Than
		sign = '>';
        measureWeCareAbout(measureWeCareAbout>=thresh) = inf;
    else %Less than
		sign = '<';
        measureWeCareAbout(measureWeCareAbout<=thresh) = inf;
    end
    s = strfind(measureWeCareAbout',inf(1,frames));
    offsetFrame(1,s) = 1;
    if trial == 1
        ocalc.offset.test = sprintf('%s%d%s%d(%d)',measure,ired,sign,thresh,frames);
    end
    
    %Lower Test (if desired)
    if params.offset.andor{1} > 1
        offsetFrame(2,:) = zeros(1,numFrames);
        ired = str2num(params.offset.IREDs{2});
        mstr = get(globals.offset.measure(2),'string');
        measure = mstr{params.offset.measure{2}};
        frames = str2num(params.offset.frames{2});
        if strcmp(measure,'Z-Velocity')
            measure = 'ZV';
            measureWeCareAbout = [0; diff(odat.Z(:,ired,trial))];
        elseif strcmp(measure,'Y-Velocity')
            measure = 'YV';
            measureWeCareAbout = [0; diff(odat.Y(:,ired,trial))];
        elseif strcmp(measure,'X-Velocity')
            measure = 'XV';
            measureWeCareAbout = [0; diff(odat.X(:,ired,trial))];
        
        elseif strcmp(measure,'Grip Aperture 1')
            ired = [];
            measure = 'GA1';
            if ~any(pairsToUse==1), error('No grip aperture 1 was defined!'), end
            measureWeCareAbout = ocalc.gripap.ga{trial}(:,1);
        elseif strcmp(measure,'Grip Aperture 1 Velocity')
            ired = [];
            measure = 'GA1Vel';
            if ~any(pairsToUse==1), error('No grip aperture 1 was defined!'), end
            measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,1))];

        elseif strcmp(measure,'Grip Aperture 2')
            ired = [];
            measure = 'GA2';
            if ~any(pairsToUse==2), error('No grip aperture 2 was defined!'), end
            measureWeCareAbout = ocalc.gripap.ga{trial}(:,2);
        elseif strcmp(measure,'Grip Aperture 2 Velocity')
            ired = [];
            measure = 'GA2Vel';
            if ~any(pairsToUse==2), error('No grip aperture 2 was defined!'), end
            measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,2))];

        elseif strcmp(measure,'Grip Aperture 3')
            ired = [];
            measure = 'GA3';
            if ~any(pairsToUse==3), error('No grip aperture 3 was defined!'), end
            measureWeCareAbout = ocalc.gripap.ga{trial}(:,3);
        elseif strcmp(measure,'Grip Aperture 3 Velocity')
            ired = [];
            measure = 'GA3Vel';
            if ~any(pairsToUse==3), error('No grip aperture 3 was defined!'), end
            measureWeCareAbout = [0; diff(ocalc.gripap.ga{trial}(:,3))];
            
        else
            measure = measure(1);
            eval(['measureWeCareAbout = odat.' measure '(:,ired,trial);'])
        end
        
        if get(globals.offset.abs(2),'value')
            measure = ['Abs' measure];
            measureWeCareAbout = abs(measureWeCareAbout);
        end
        
        ocalc.offset.measureOfInterest{trial,2} = measureWeCareAbout;
        thresh = str2num(params.offset.thresh{2});
        if params.offset.type{2}==2 %Greater Than
			sign = '>';
            measureWeCareAbout(measureWeCareAbout>=thresh) = inf;
        else %Less than
			sign = '<';
            measureWeCareAbout(measureWeCareAbout<=thresh) = inf;
        end
        s = strfind(measureWeCareAbout',inf(1,frames));
        offsetFrame(2,s) = 1;
    end
    
    %Conclusion
    if params.offset.andor{1} == 2 %AND
        offsetFrame = min(offsetFrame);
        if trial == 1
            ocalc.offset.test = sprintf('%s AND %s%d%s%d(%d)',ocalc.offset.test,measure,ired,sign,thresh,frames);
        end
    elseif params.offset.andor{1} == 3 %OR
        offsetFrame = max(offsetFrame);
        if trial == 1
            ocalc.offset.test = sprintf('%s OR %s%d%s%d(%d)',ocalc.offset.test,measure,ired,sign,thresh,frames);
        end
    end
    offsetFrame(1: (ocalc.onset.onsetFrame(trial) + params.minFramesBetweenOnOff) ) = 0;
    if find(offsetFrame==1,1)
        ocalc.offset.offsetFrame(trial) = find(offsetFrame==1,1);
        ocalc.offset.found(trial) = 1;
    else
        newOff = find(~isnan(measureWeCareAbout),1,'last');
        if isempty(newOff), newOff = numFrames;, end
        ocalc.offset.offsetFrame(trial) = newOff; %numFrames;
        ocalc.offset.found(trial) = 1;
    end 
end

saveFol = [pwd filesep 'Step 2 Output - OnsetOffset and GripAp' filesep];
if length(globals.saveFolName)
    saveFol = [saveFol globals.saveFolName filesep];
end
if ~exist(saveFol)
    mkdir(saveFol)
end

save([saveFol filename],'odat','ocalc','params')

if ispc %is windows
    winopen(saveFol)
elseif ismac
    system(['open ',saveFol]);
end

set(globals.processing,'string',['Complete. (' filename ')'])
end
catch err
closeAllFigures
rethrow(err)
end
end