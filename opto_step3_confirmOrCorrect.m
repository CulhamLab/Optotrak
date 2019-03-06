function opto_step3_confirmOrCorrect
try
closeAllFigures
%% GUI - Global vars that need to transfer to/from GUI
global globals
globals = [];

%% Slider update timer
tic

%% Initialize flag setting mode
globals.enableSetFlag = nan;

%% GUI- Load
globals.FigID.fig = hgload([pwd filesep 'GUI' filesep 'opto_step3_confirmOrCorrect' '.fig']);

%% GUI - Colours
globals.colours.Onset1 = [1 0 0]; %red
globals.colours.Onset2 = [0.7 0 0]; %red2
globals.colours.Offset1 = [0 1 0]; %green
globals.colours.Offset2 = [0 0.7 0]; %green2
globals.colours.GripAp1 = [0 0 1]; %blue
globals.colours.GripAp2 = [0 0 0.7]; %blue2
globals.colours.GripAp3 = [0 0 0.5]; %blue3
globals.colours.MotionFrames = [1 1 0]; %yellow
globals.colours.Flag = [1 0 1]; %magenta
globals.colours.M1 = [0 1 1]; %cyan
globals.colours.M2 = [0 0.8 0.8]; %cyan
globals.colours.M3 = [0 0.6 0.6]; %cyan
globals.colours.M4 = [0 0.4 0.4]; %cyan

%% GUI - Set text and get IDs
globals.name = 'Script 3: Confirm/Correct Onsets and Offsets';
set(globals.FigID.fig,'name',globals.name);
texts = findall(globals.FigID.fig, 'style', 'text');
for t = texts'
    text  = get(t,'tag');
    switch text
        case 'textIREDs'
            set(t,'string','IRED(s):')
        case 'textDisplay'
            set(t,'string','Display Below:')
        case 'textStatus'
            set(t,'string','Waiting...')
            globals.FigID.status = t;
        case 'textTrial'
            set(t,'string','Trial:')
        case 'textTitle'
            globals.FigID.textTitle = t;
            set(t,'string',globals.name)
        case 'textFrameOnset'
            globals.FigID.textFrameOnset = t;
        case 'textFrameOffset'
            globals.FigID.textFrameOffset = t;
        case 'textFrameFlag'
            globals.FigID.textFrameFlag = t;
    end
end
edits = findall(globals.FigID.fig, 'style', 'edit');
for t = edits'
    text  = get(t,'tag');
    switch text
        case 'editIREDS'
            set(t,'string','')
            globals.FigID.editIREDS = t;
        case 'editTrialNum'
            set(t,'string','')
            globals.FigID.editTrialNum = t;
    end
    set(t,'callback',@buttonRedraw)
end
buttons = findall(globals.FigID.fig, 'style', 'pushbutton');
for t = buttons'
    text  = get(t,'tag');
    switch text
        case 'buttonClose'
            set(t,'string','Save & Close')
            globals.FigID.buttonClose = t;
        case 'buttonNext'
            set(t,'string','Next Trial')
            globals.FigID.buttonNext = t;
        case 'buttonRedraw'
            set(t,'string','Redraw')
            globals.FigID.buttonRedraw = t;
        case 'buttonRestore'
            set(t,'string','Restore')
            globals.FigID.buttonRestore = t;
        case 'buttonExport'
            set(t,'string','Export All')
            globals.FigID.buttonExport = t;
        case 'buttonExclude'
            set(t,'string','Exclude Trial')
            globals.FigID.buttonExclude = t;
        case 'buttonFlag'
            globals.FigID.buttonFlag = t;
        case 'buttonMore'
            globals.FigID.buttonMore = t;
        case 'buttonConnectIRED'
            globals.FigID.buttonConnectIRED = t;
        case 'buttonView2D'
            globals.FigID.buttonView2D = t;
    end
end
sliders = findall(globals.FigID.fig, 'style', 'slider');
for t = sliders'
    text  = get(t,'tag');
    switch text
        case 'sliderOnset'
            globals.FigID.sliderOnset = t;
        case 'sliderOffset'
            globals.FigID.sliderOffset = t;
        case 'sliderFlag'
            globals.FigID.sliderFlag = t;
    end
end
checkboxes = findall(globals.FigID.fig, 'style', 'checkbox');
for t = checkboxes'
    text  = get(t,'tag');
    text2 = text(9:end);
    eval(['globals.FigID.' text '=t;']);

    if any(strcmp(fields(globals.colours),text2))
        eval(['c=globals.colours.' text2 ';'])
    else
        c = [0 0 0]; %default colour is black
    end
    set(t,'foregroundcolor',c);
    set(t,'callback',@checkboxChange)
    if strcmp(text,'checkboxFlag')
        set(t,'string','Show Flag Indicator');
        set(t,'callback',@checkboxFlag)
    elseif strcmp(text,'checkboxPlotAll')
        set(t,'string','Plot All Frames');
        set(t,'callback',@checkboxFlag)
    else
        set(t,'string',text2);
        set(t,'callback',@checkboxChange)
    end
end
%no clean way to get axes (axes isn't a "style")
t = findall(globals.FigID.fig, 'tag', 'axesTraj');
    globals.FigID.axesTraj = t;
t = findall(globals.FigID.fig, 'tag', 'axesProfile');
    globals.FigID.axesProj = t;

%% GUI - Set font sizes
set(findall(globals.FigID.fig, '-property', 'FontSize'), 'FontSize', 15);
set(findall(globals.FigID.fig, 'style', 'checkbox'), 'FontSize', 8);
set(globals.FigID.editIREDS, 'FontSize', 8);

%% GUI - Give callback instructions
set(globals.FigID.buttonClose,'callback',@buttonSaveClose)
set(globals.FigID.buttonNext,'callback',@buttonNext)
set(globals.FigID.buttonRedraw,'callback',@buttonRedraw)
set(globals.FigID.buttonRestore,'callback',@buttonRestore)
set(globals.FigID.buttonExport,'callback',@buttonExport)
set(globals.FigID.buttonExclude,'callback',@buttonExclude)
set(globals.FigID.buttonFlag,'callback',@buttonFlag)
set(globals.FigID.buttonMore,'callback',@buttonMore)
set(globals.FigID.buttonConnectIRED,'callback',@buttonConnectIRED)
set(globals.FigID.buttonView2D,'callback',@buttonView2D)

set(globals.FigID.sliderOnset,'callback',@sliderChange)
set(globals.FigID.sliderOffset,'callback',@sliderChange)
set(globals.FigID.sliderFlag,'callback',@sliderFlag)

%% Make folder if needed
if ~exist([pwd filesep 'Step 3 Output - Confirm and Correct'])
    mkdir('Step 3 Output - Confirm and Correct');
end

%% Load in data
[globals.filename,folder] = uigetfile([pwd filesep 'Step 2 Output - OnsetOffset and GripAp' filesep '*.mat']);
figure(globals.FigID.fig) %give focus back to figure
drawnow
g = globals; %loading can potentially alter globals so keep a copy
if exist([pwd filesep 'Step 3 Output - Confirm and Correct' filesep globals.filename])
%     waitfor(msgbox(['Prior onset/offset data for ' globals.filename ' was found in the Step 3 folder and will be loaded instead. Rename or delete this file if you wish to overwrite with step 2 output.']))
%     folder = [pwd '\Step 3 Output - Confirm and Correct\'];
    answer = questdlg('Prior screening data was found. Would you like to use this data? If you do not use this data, the existing file will be renamed as a backup with the current time in the filename.','Prior Screening Found','Use Prior Data','Archive Prior Data','Use Prior Data');
    if strcmp(answer,'Use Prior Data')
       folder = [pwd filesep 'Step 3 Output - Confirm and Correct' filesep];
    else
        %rename old data
        curClock=clock;
        fileadd = sprintf('_PriorScreen_%d-%d-%d_%d%d.mat',curClock(1),curClock(2),curClock(3),curClock(4),curClock(5));
        fn = globals.filename(1:find(globals.filename=='.',1,'last')-1);
        movefile([pwd filesep 'Step 3 Output - Confirm and Correct' filesep globals.filename],[pwd filesep 'Step 3 Output - Confirm and Correct' filesep fn fileadd]);
    end
end
temp = load([folder globals.filename]);
globals = g; %restore globals
loadedFlag = false;
if length(fields(temp))==1 %is step3 file
    globals.load = temp.alldata.load;
    globals.includeTrial = temp.alldata.includeTrial;
    if any(strcmp(fields(temp.alldata),'flags'))
        globals.flags = temp.alldata.flags;
        loadedFlag = true;
    end
    globals.priorval.onsetFrame = temp.alldata.load.ocalc.onset.onsetFrame;
    globals.priorval.offsetFrame = temp.alldata.load.ocalc.offset.offsetFrame;
    if any(strcmp(fields(temp.alldata),'connectPairs'))
        globals.connectPairs = temp.alldata.connectPairs;
    else
        globals.connectPairs = [];
    end
else
    globals.load = temp; %step2 data file
    globals.includeTrial = ones(1,size(globals.load.odat.X,3));
    globals.priorval.onsetFrame = temp.ocalc.onset.onsetFrame;
    globals.priorval.offsetFrame = temp.ocalc.offset.offsetFrame;
    globals.connectPairs = [];
end
set(globals.FigID.status,'string',['Loaded: globals.filename'])

%% GUI - Parameters
[globals.params.numFrame,globals.params.numIRED,globals.params.numTrial] = size(globals.load.odat.X);

%% Fill flags if empty
if ~loadedFlag
    globals.flags = repmat(struct('Frames',[],'Names',[],'NumFlags',0),[globals.params.numTrial 1]);
end

%% GUI - names for onset/offset/gripaps
x = find(globals.load.ocalc.onset.test=='(');
globals.checkboxNames.on{1} = globals.load.ocalc.onset.test(1:(x(1)-1));
if length(x)>1
    i = find(globals.load.ocalc.onset.test==' ',1,'last');
    globals.checkboxNames.on{2} = globals.load.ocalc.onset.test(i+1:x(2)-1);
end

x = find(globals.load.ocalc.offset.test=='(');
globals.checkboxNames.off{1} = globals.load.ocalc.offset.test(1:(x(1)-1));
if length(x)>1
    i = find(globals.load.ocalc.offset.test==' ',1,'last');
    globals.checkboxNames.off{2} = globals.load.ocalc.offset.test(i+1:x(2)-1);
end

for x = 1:length(globals.load.ocalc.gripap.IREDs)
    eval(['globals.checkboxNames.ga{' num2str(x) '} = globals.load.ocalc.gripap.IREDs{' num2str(x) '};'])
end

%% GUI - Initialize
globals.trial = 1;
globals.iredsToShow = 1:globals.params.numIRED;

set(globals.FigID.sliderOnset,'min',1/globals.params.numFrame);
set(globals.FigID.sliderOnset,'max',1); 
set(globals.FigID.sliderOnset,'SliderStep',[1/globals.params.numFrame 1/globals.params.numFrame])
set(globals.FigID.sliderOffset,'min',1/globals.params.numFrame);
set(globals.FigID.sliderOffset,'max',1); 
set(globals.FigID.sliderOffset,'SliderStep',[1/globals.params.numFrame 1/globals.params.numFrame])
set(globals.FigID.sliderFlag,'min',1/globals.params.numFrame);
set(globals.FigID.sliderFlag,'max',1); 
set(globals.FigID.sliderFlag,'SliderStep',[1/globals.params.numFrame 1/globals.params.numFrame])

f = globals.load.ocalc.onset.onsetFrame(globals.trial) / globals.params.numFrame;
set(globals.FigID.sliderOnset,'value',f)
set(globals.FigID.sliderFlag,'value',f)
f = globals.load.ocalc.offset.offsetFrame(globals.trial) / globals.params.numFrame;
set(globals.FigID.sliderOffset,'value',f)

%% GUI - remove anything that has no use (checkboxes)
%do we need onset #2?
if size(globals.load.ocalc.onset.measureOfInterest,2) < 2
    %no
    set(globals.FigID.checkboxOnset2,'visible','off');
end
%do we need offset #2?
if size(globals.load.ocalc.offset.measureOfInterest,2) < 2
    %no
    set(globals.FigID.checkboxOffset2,'visible','off');
end
if length(fields(globals.load.ocalc)) < 3
    for ga = 1:3 %remove any gripaps we aren't using
        eval(['t = globals.FigID.checkboxGripAp' num2str(ga) ';'])
        set(t,'visible','off');
    end
else
    s = size(globals.load.ocalc.gripap.IREDs,2); %%%size(globals.load.ocalc.gripap.ga{1},2);
    for ga = (s+1):3
        eval(['t = globals.FigID.checkboxGripAp' num2str(ga) ';'])
        set(t,'visible','off');
    end
end

%prep extra measures
moreMeasureInit

%check all visible checkboxes
set(findall(globals.FigID.fig, 'style', 'checkbox', 'visible', 'on'),'value',1);

%% GUI - redraw
redraw

%% First Save
doSave

%% Catch
catch err
rethrow(err)
end
end

function closeAllFigures
%%
%working with gui figs so "close all" won't work
delete(findall(0, 'type', 'figure'))
end

function redraw
%% check/fill editbox values (could be empty or invalid)
global globals
set(globals.FigID.status,'string','Redrawing...')
drawnow

%trial
priorTrial = globals.trial;
t = globals.FigID.editTrialNum;
if ~length(str2num(get(t,'string')))
    set(t,'string',num2str(globals.trial));
end
trial = str2num(get(t,'string'));
trial = trial(1); %if a vector was entered for some reason, just take first
if trial < 1
    trial = 1;
elseif trial > globals.params.numTrial
    trial = globals.params.numTrial;
end
set(t,'string',num2str(trial));
globals.trial = trial;

%if trial is bad, change background
if globals.includeTrial(globals.trial)
    %include
    c = [0.941 0.941 0.941];
else
    %exclude
    c = [0.941 0 0];
end
set(globals.FigID.fig,'color',c)
set(globals.FigID.textTitle,'BackgroundColor',c)

set(globals.FigID.textTitle,'string',sprintf('%s\nTrial: %d',globals.name,trial))

%IREDs
%can enter ireds as "1 2 3" or "[1 2 3]" or "1,2,3" or "1, 2, 3" or "1:3" or [1:3 5 11] or even "1:3 5 11" ...
%basically any way that doesn't include characters other than these "[],"
iredsTxt = get(globals.FigID.editIREDS,'string');
iredsTxt = str2num(iredsTxt);
if length(iredsTxt) & max(iredsTxt)<=globals.params.numIRED
    globals.iredsToShow = iredsTxt;
else
    set(globals.FigID.editIREDS,'string',num2str(globals.iredsToShow));
end

%% check slider
if priorTrial ~= trial %trial changed
    %set to ocalc value
    f = globals.load.ocalc.onset.onsetFrame(trial) / globals.params.numFrame;
    set(globals.FigID.sliderOnset,'value',f)
    set(globals.FigID.sliderFlag,'value',f)
    f = globals.load.ocalc.offset.offsetFrame(trial) / globals.params.numFrame;
    set(globals.FigID.sliderOffset,'value',f)
else
    %keep slider value
end

%% Remove any flags which are now outside onset to offset
[on,off] = getOnOff;
indRem = find(globals.flags(globals.trial).Frames < on | globals.flags(globals.trial).Frames > off);
if length(indRem)
    globals.flags(globals.trial).Frames(indRem) = [];
    globals.flags(globals.trial).Names(indRem) = [];
    globals.flags(globals.trial).NumFlags = globals.flags(globals.trial).NumFlags - length(indRem);
end

%% profile plot
plotProfile

%% trajectory plot
plotTrajectory

%% update flag items
updateFlag

%%
set(globals.FigID.status,'string','Redrawn')
end

function plotProfile
%%
global globals
t = globals.FigID.axesProj;
axes(t)
cla(t,'reset')
hold(t,'on')
%% On/Off
[on,off] = getOnOff;
d = off-on;
rectangle('position',[on 0 d 1],'Parent',t,'FaceColor',globals.colours.MotionFrames,'EdgeColor','none')

%% Flags
if get(globals.FigID.checkboxFlag,'value')
    indFlag = globals.flags(globals.trial).Frames;
    for x = indFlag
        %rectangle('position',[x 0 1 1],'Parent',t,'FaceColor',globals.colours.Flag,'EdgeColor','none')
        plot(t,[x x],[0 1],'color',globals.colours.Flag)
    end
end

%% GripAp
for ga = 1:3
    if eval(['get(globals.FigID.checkboxGripAp' num2str(ga) ',''value'')'])
        x = globals.load.ocalc.gripap.ga{globals.trial}(:,ga);
        y = x - min(x);
        y = y / max(y);
        eval(['c=globals.colours.GripAp' num2str(ga) ';'])
        plot(t,y,'color',c,'linewidth',2)
        [m,w] = max(x(on:off)/max(x));
        w = w+on-1;
        plot(t,[w w],[0 m],':','color',c)
        eval(['t2 = globals.FigID.checkboxGripAp' num2str(ga) ';'])
        v = round([x(on) x(off)]*10)/10;
        v = [num2str(v(1)) ' | ' num2str(v(2))];
        set(t2,'string',['GA' num2str(ga) ': ' globals.checkboxNames.ga{ga} ' (' v ')'])
    end
end

%% Ons
for na = 1:2
    if eval(['get(globals.FigID.checkboxOnset' num2str(na) ',''value'')'])
        x = globals.load.ocalc.onset.measureOfInterest{globals.trial,na};
        y = x - min(x);
        y = y / max(y);
        eval(['c=globals.colours.Onset' num2str(na) ';'])
        plot(t,y,'color',c,'linewidth',2)
        [m,w] = max(y(on:off));
        w = w+on-1;
        plot(t,[w w],[0 m],':','color',c)
        eval(['t2 = globals.FigID.checkboxOnset' num2str(na) ';'])
        v = num2str(round(x(on)*10)/10);
        set(t2,'string',['ON' num2str(na) ': ' globals.checkboxNames.on{na} ' (' v ')'])
    end
end

%% Offs
for na = 1:2
    if eval(['get(globals.FigID.checkboxOffset' num2str(na) ',''value'')'])
        x = globals.load.ocalc.offset.measureOfInterest{globals.trial,na};
        y = x - min(x);
        y = y / max(y);
        eval(['c=globals.colours.Offset' num2str(na) ';'])
        plot(t,y,'color',c)
        [m,w] = max(y(on:off));
        w = w+on-1;
        plot(t,[w w],[0 m],':','color',c)
        eval(['t2 = globals.FigID.checkboxOffset' num2str(na) ';'])
        v = num2str(round(x(off)*10)/10);
        set(t2,'string',['OFF' num2str(na) ': ' globals.checkboxNames.off{na} ' (' v ')'])
    end
end

%% More
pairsToUse = find(cellfun(@(x) x,globals.load.params.gripap.include));
for more = 1:4
    if strcmp(globals.more(more).visible,'on') & eval(['get(globals.FigID.checkboxM' num2str(more) ',''value'')'])
        %x = opto_functions('measure_getValue',globals.load.odat,globals.load.ocalc,pairsToUse,globals.more(more).measure,globals.more(more).ired,globals.trial);
        globals.more(more).values = opto_functions('measure_getValue',globals.load.odat,globals.load.ocalc,pairsToUse,globals.more(more).measure,globals.more(more).ired,globals.trial);
        x = globals.more(more).values;
        y = x - min(x);
        y = y / max(y);
        eval(['c=globals.colours.M' num2str(more) ';'])
        plot(t,y,'color',c)
        [m,w] = max(y(on:off));
        w = w+on-1;
        plot(t,[w w],[0 m],':','color',c)
        
        eval(['t2 = globals.FigID.checkboxM' num2str(more) ';'])
        v = round([x(on) x(off)]*10)/10;
        v = [num2str(v(1)) ' | ' num2str(v(2))];
        set(t2,'string',[globals.more(more).label ' (' v ')'])
        
    end
end

%%
hold(t,'off')
set(t,'xtick',[],'ytick',[])
axis(t,[1 globals.params.numFrame 0 1])

end

function plotTrajectory
%%
global globals
%% IREDS
ireds = globals.iredsToShow;
ni = length(ireds);
for i = 1:ni
    ired = ireds(i);
    x(:,i) = globals.load.odat.X(:,ired,globals.trial);
    y(:,i) = globals.load.odat.Y(:,ired,globals.trial);
    z(:,i) = globals.load.odat.Z(:,ired,globals.trial);
end
%% Prep
t = globals.FigID.axesTraj;
axes(t)
[az,el] = view(t);
cla(t,'reset')
hold(t,'on')

%% Plot flag indicator
if get(globals.FigID.checkboxFlag,'value')
    f = round(get(globals.FigID.sliderFlag,'value') * globals.params.numFrame);
    plot3(t,x(f,:),y(f,:),z(f,:),'o','LineWidth',5,'Color',globals.colours.Flag);
end

%% Plot
if get(globals.FigID.checkboxPlotAll,'value')
    plot3(t,x,y,z)
end
[on,off] = getOnOff;
plot3(t,x(on:off,:),y(on:off,:),z(on:off,:),'LineWidth',3)
for i = 1:ni
    ired = ireds(i);
    
    firstNonNan = find(~isnan(x(:,i)),1);
    
    text(x(firstNonNan,i),y(firstNonNan,i),z(firstNonNan,i),num2str(ired),'Parent',t,'FontSize',20)
end

%% Plot connected pairs
defaultColours = get(t,'ColorOrder');
for i = 1:length(globals.connectPairs)
    indIRED1 = find(ireds==globals.connectPairs(i).IRED1);
    indIRED2 = find(ireds==globals.connectPairs(i).IRED2);
    
    if isempty(indIRED1) | isempty(indIRED2)
        continue
    end
    
    if size(defaultColours,1)<indIRED1
        colour = [0 0 0];
    else
        colour = defaultColours(indIRED1,:);
    end
    
    for frame = on:globals.connectPairs(i).FrameRate:off
        x_pair = x(frame,[indIRED1 indIRED2]);
        y_pair = y(frame,[indIRED1 indIRED2]);
        z_pair = z(frame,[indIRED1 indIRED2]);
        plot3(t,x_pair,y_pair,z_pair,'-','Color',colour,'LineWidth',1)
    end
    
end

%% Post
hold(t,'off')
rotate3d(t,'on')
extremeX = [min(x(:)) max(x(:))];
extremeY = [min(y(:)) max(y(:))];
extremeZ = [min(z(:)) max(z(:))];
maxRange = max(diff([extremeX; extremeY; extremeZ]'));
w = (maxRange*1.05)/2;
midX = mean(extremeX);
midY = mean(extremeY);
midZ = mean(extremeZ);
v = [midX-w midX+w midY-w midY+w midZ-w midZ+w];
axis(t,v)
view(t,az,el) 
axis(t,'square')

%% Update frame text
set(globals.FigID.textFrameOnset,'String',sprintf('Onset: %d',on))
set(globals.FigID.textFrameOffset,'String',sprintf('Offset: %d',off))

end

function doSave
%%
global globals
set(globals.FigID.status,'string','Saving...')
drawnow
%get potentially new on/off values
[on,off] = getOnOff;
%overwrite
globals.load.ocalc.onset.onsetFrame(globals.trial) = on;
globals.load.ocalc.offset.offsetFrame(globals.trial) = off;
%save
alldata = globals;

temp = alldata.FigID;
alldata.FigID = [];

save([pwd filesep 'Step 3 Output - Confirm and Correct' filesep globals.filename],'alldata')

alldata.FigID = temp;

set(globals.FigID.status,'string','Saved')
end

function buttonSaveClose(fig, evt)
%%
doSave
closeAllFigures
end

function buttonExclude(fig, evt)
%%
global globals
globals.includeTrial(globals.trial) = abs(globals.includeTrial(globals.trial)-1);
doSave
redraw
end

function buttonNext(fig, evt)
%%
doSave
global globals
set(globals.FigID.editTrialNum,'string',num2str(globals.trial+1));
redraw
end

function buttonRedraw(fig, evt)
%%
doSave
redraw
end

function buttonRestore(fig, evt)
%%
global globals
trial = globals.trial;

globals.load.ocalc.onset.onsetFrame(trial) = globals.priorval.onsetFrame(trial);
globals.load.ocalc.offset.offsetFrame(trial) = globals.priorval.offsetFrame(trial);

f = globals.load.ocalc.onset.onsetFrame(trial) / globals.params.numFrame;
set(globals.FigID.sliderOnset,'value',f)
set(globals.FigID.sliderFlag,'value',f)
f = globals.load.ocalc.offset.offsetFrame(trial) / globals.params.numFrame;
set(globals.FigID.sliderOffset,'value',f)

doSave
redraw
end

function sliderChange(fig, evt)
%%
% plotProfile %if the machine is slow, do this line INSTEAD of redraw
if toc<0.25
    global globals
    f = globals.priorval.on / globals.params.numFrame;
    set(globals.FigID.sliderOnset,'value',f)
    f = globals.priorval.off / globals.params.numFrame;
    set(globals.FigID.sliderOffset,'value',f)
    return
end
tic
redraw
updateFlag
end

function sliderFlag(fig,evt)
%%
updateFlag
plotProfile
plotTrajectory
end

function updateFlag
global globals
flagMin = get(globals.FigID.sliderOnset,'value');
flagMax = get(globals.FigID.sliderOffset,'value');
flagVal = get(globals.FigID.sliderFlag,'value');

if flagVal <= (flagMin + 0.5/globals.params.numFrame)
    flagVal = flagMin + 1/globals.params.numFrame;
elseif flagVal >= (flagMax - 0.5/globals.params.numFrame)
    flagVal = flagMax - 1/globals.params.numFrame;
end
set(globals.FigID.sliderFlag,'value',flagVal);
f = round(get(globals.FigID.sliderFlag,'value') * globals.params.numFrame);
set(globals.FigID.textFrameFlag,'String',sprintf('Current: %d',f));

if any(globals.flags(globals.trial).Frames == f)
    flagNum = find(globals.flags(globals.trial).Frames == f);
    flagName = globals.flags(globals.trial).Names{flagNum};
    set(globals.FigID.buttonFlag,'String',sprintf('Remove "%s"',flagName));
    globals.enableSetFlag = false;
else
    set(globals.FigID.buttonFlag,'String','Set Flag');
    globals.enableSetFlag = true;
end

end

function buttonFlag(fig, evt)
    global globals
    f = round(get(globals.FigID.sliderFlag,'value') * globals.params.numFrame);
    if globals.enableSetFlag
        %setting flag
        name = inputdlg('Flag name:','Flag Name',1);
        name = name{1};
        if strcmp(lower(name),'onset') | strcmp(lower(name),'offset')
            %invalid - reserved names
            errordlg('Flag name is invalid! "Onset" and "Offset" are reserved.')
        elseif length(name)
            %valid
            name(name==' ') = '_';
            flagNum = globals.flags(globals.trial).NumFlags + 1;
            globals.flags(globals.trial).NumFlags = flagNum;
            globals.flags(globals.trial).Frames(flagNum) = f;
            globals.flags(globals.trial).Names{flagNum} = name;
            
            updateFlag
            plotProfile
        else
            %invalid
            errordlg('Flag name is invalid!')
        end
    else
        %removing flag
        flagNum = find(globals.flags(globals.trial).Frames == f);
        if flagNum
            globals.flags(globals.trial).NumFlags = globals.flags(globals.trial).NumFlags - 1;
            globals.flags(globals.trial).Frames(flagNum) = [];
            globals.flags(globals.trial).Names(flagNum) = [];
            
            updateFlag
            plotProfile
        end
    end
    doSave
end

function checkboxChange(fig, evt)
%%
plotProfile
end

function checkboxFlag(fig, evt)
%%
plotProfile
plotTrajectory
end

function buttonExport(fig, evt)
%%
a = questdlg('This feature will export all motion frames from all trials to excel format. Exporting to excel can take anywhere from a few seconds to a few minutes. During this time, the interface will likely appear to have crashed. Do not close the interface during this time.','Exporting','Continue','Abort','Continue');
if strcmp(a,'Abort')
    return
end

try
global globals

output = cell(0);
output{1,1} = 'Trial';
output{1,2} = 'Frame';
c=2;
v = 'XYZVA';
for i = 1:globals.params.numIRED
    for ii = 1:5
        c=c+1;
        output{1,c} = [v(ii) num2str(i)];
    end
end

r=1;
for trial = 1:globals.params.numTrial
    on = globals.load.ocalc.onset.onsetFrame(trial);
    off = globals.load.ocalc.offset.offsetFrame(trial);

    for frame = on:off
        r=r+1;
        output{r,1} = trial;
        output{r,2} = frame;
        
        c=2;
        v = 'XYZVA';
        for IRED = 1:globals.params.numIRED
            for ii = 1:5 %XYZVA
                c=c+1;
                eval(['val = globals.load.odat.' v(ii) '(frame,IRED,trial);'])
                output{r,c} = val;
            end
        end
        
    end
    
end

fn = globals.filename(1:end-4);
xlswrite([pwd filesep 'Step 3 Output - Confirm and Correct' filesep fn],output);

saveFol = [pwd filesep 'Step 3 Output - Confirm and Correct'];
if ispc %is windows
    winopen(saveFol)
elseif ismac
    system(['open ',saveFol]);
end

msgbox('Export successful.')
catch err
    msgbox('Export was not successful. This could be caused by using an older matlab version. Version 2012a and later have been confirmed to work.') %I've seen xlswrite fail inexplicably on old matlab versions
    rethrow(err)
end

end

function [on,off] = getOnOff %gets onset and offset from sliders
global globals
on = round(get(globals.FigID.sliderOnset,'value') * globals.params.numFrame);
off = round(get(globals.FigID.sliderOffset,'value') * globals.params.numFrame);
if on < 1
    on = 1;
elseif on > globals.params.numFrame
    on = globals.params.numFrame;
end
if off < 1
    off = 1;
elseif off > globals.params.numFrame
    off = globals.params.numFrame;
end
if on > off
    temp = on;
    on = off;
    off = temp;
    set(globals.FigID.sliderOnset,'value',on / globals.params.numFrame)
    set(globals.FigID.sliderOffset,'value',off / globals.params.numFrame)
end
globals.priorval.on = on;
globals.priorval.off = off;
end

function moreMeasureInit
global globals
globals.more = repmat(struct('visible','off','label','','measure','','values',[],'ired',nan),[1 4]);
moreMeasureRefresh
end

function moreMeasureRefresh
global globals
for m = 1:4
    eval(sprintf('t = globals.FigID.checkboxM%d;',m));
    set(t,'visible',globals.more(m).visible);
    if strcmp(globals.more(m).visible,'off')
        set(t,'value',false);
    end
    set(t,'string',globals.more(m).label);
end
end

function buttonMore(fig, evt)
global globals
task = questdlg('Add/Change or Remove?','Task','Add/Change','Remove','Add/Change');
if isempty(task), return, end
position = listdlg('Name','Slot','ListString', cellfun(@(x,y) sprintf('Slot %d (%s)',x,y),num2cell(1:length(globals.more)), cellfun(@(x) strrep(strrep(x,'on','in use'),'off','empty'), {globals.more.visible},'UniformOutput',false) ,'UniformOutput',false) ,'SelectionMode','single','ListSize',[300 160]);
if isempty(position), return, end
if strcmp(task,'Add/Change')
    list = opto_functions('measure_getList');
    
    %remove grip ap that were never calculated ot prevent error
    pairsToUse = find(cellfun(@(x) x,globals.load.params.gripap.include));
    noPair = [1 1 1];
    noPair(pairsToUse) = 0;
    for i = length(list):-1:1
        for j = find(noPair)
            if length(strfind(list{i},sprintf('Grip Aperture %d',j)))
                list(i) = [];
                break
            end 
        end
    end
    
    measure = listdlg('Name','Measure','ListString',list,'SelectionMode','single','ListSize',[300 160]);
    if isempty(measure), return, end
    indNoIRED = opto_functions('measure_getIndNoIRED');
    if ~length(find(indNoIRED==measure))
        options = cellfun(@(x) sprintf('IRED %d',x),num2cell(1:globals.params.numIRED),'UniformOutput',false);
        ired = listdlg('Name','IRED','ListString',options,'SelectionMode','single','ListSize',[300 160]);
        if isempty(ired), return, end
        measure = list{measure};
        if isempty(measure), return, end
        globals.more(position).label = [measure ' ' num2str(ired)];
        globals.more(position).ired = ired;
    else
        measure = list{measure};
        if isempty(measure), return, end
        globals.more(position).label = opto_functions('measure_getShortform',measure); %measure;
        globals.more(position).ired = nan;
    end
    globals.more(position).visible = 'on';
    globals.more(position).measure = measure;
    globals.more(position).values = opto_functions('measure_getValue',globals.load.odat,globals.load.ocalc,pairsToUse,globals.more(position).measure,globals.more(position).ired,globals.trial);
    eval(sprintf('t = globals.FigID.checkboxM%d;',position));
    set(t,'value',1);
else
    globals.more(position).visible = 'off';
    eval(sprintf('t = globals.FigID.checkboxM%d;',position));
    set(t,'value',0);
end
moreMeasureRefresh
plotProfile
end

function buttonView2D(fig, evt)
global globals 
t = globals.FigID.axesTraj;
position = listdlg('Name','Dimensions','ListString',{'X and Y' 'X and Z' 'Y and Z'},'SelectionMode','single','ListSize',[200 100]);
if isempty(position)
    return
end
switch position
    case 1
        view(t,0,90) %x y
    case 2
        view(t,0,0) %x z
    case 3
        view(t,90,90) %y z
    otherwise
        %no change
end
end

function buttonConnectIRED(fig, evt)
global globals 
if ~any(strcmp(fields(globals),'connectPairs'))
    warning('Structure for IRED pair connections not found!')
    return
end

choice = questdlg('Add or remove connections?','Connect IREDs','Add','Remove','Add');
switch choice
    case 'Add'
        
        %input params
        paramNames = {'IRED1' 'IRED2' 'FrameRate'};
        param = inputdlg({'IRED #1' 'IRED #2' 'Draw connection every X frames'});
        param = cellfun(@str2num,param,'UniformOutput',false);
        
        if isempty(param)
            return
        end
        
        %check params
        for i = 1:3
            
            if isempty(param{i})
                errordlg(sprintf('%s is empty!',paramNames{i}),'Error')
                return
            end
            
            if ~isnumeric(param{i})
                errordlg(sprintf('%s must be a number!',paramNames{i}),'Error')
                return
            end
            
            if param{i}<1
                errordlg(sprintf('%s is not valid!',paramNames{i}),'Error')
                return
            end
            
            if i==1 | i==2
                if param{i}>globals.params.numIRED
                    errordlg(sprintf('%s is not valid!',paramNames{i}),'Error')
                    return
                end
            end
            
        end
        if param{1}==param{2}
            errordlg(sprintf('%s must be different than %s!',paramNames{1:2}),'Error')
        end
        
        %give names
        IRED1 = param{1};
        IRED2 = param{2};
        FrameRate = param{3};
        
        %always set IRED1 as smaller value
        if IRED1>IRED2
            temp = IRED1;
            IRED1 = IRED2;
            IRED2 = temp;
            clear temp;
        end
        
        %check existing pair
        for i = 1:length(globals.connectPairs)
            if globals.connectPairs(i).IRED1==IRED1 & globals.connectPairs(i).IRED2==IRED2
                globals.connectPairs(i).FrameRate = FrameRate;
                plotTrajectory
                return %success
            end
        end
        
        %pair does not exist, create
        ind = length(globals.connectPairs)+1;
        globals.connectPairs(ind).IRED1 = IRED1;
        globals.connectPairs(ind).IRED2 = IRED2;
        globals.connectPairs(ind).FrameRate = FrameRate;
        plotTrajectory
        return %success
        
    case 'Remove'
        
        numPairs = length(globals.connectPairs);
        if ~numPairs
            errordlg('No pairs to remove!','Error')
            return
        end
        
        pairOptions = [cellfun(@(x,y,z) sprintf('IREDs %d & %d, every %d frame(s)',x,y,z), {globals.connectPairs.IRED1}, {globals.connectPairs.IRED2}, {globals.connectPairs.FrameRate},'UniformOutput',false) 'All'];
        position = listdlg('Name','Select','ListString', pairOptions ,'SelectionMode','single','ListSize',[200 160]);
        if ~isempty(position)
            if position>length(globals.connectPairs)
                globals.connectPairs = []; %remove all
            else
                globals.connectPairs(position) = [];
            end
            plotTrajectory
            return %success
        end
        
        
    otherwise
        %do nothing'
end

end
