function opto_step5_Resample
try
closeAllFigures
%% GUI- Load
fig = hgload([pwd filesep 'GUI' filesep 'opto_step5_Resample' '.fig']);

%% GUI - Global vars that need to transfer to/from GUI
global globals
globals = [];

%% GUI - Set text and get IDs
globals.name = 'Script 5: Resample';
set(fig,'name',globals.name);
texts = findall(fig, 'style', 'text');
for t = texts'
    text  = get(t,'tag');
    switch text
        case 'textTitle'
            set(t,'string',globals.name)
        case 'textStatus'
            set(t,'string','Waiting...')
            globals.FigID.textStatus = t;
        case 'textFile'
            globals.FigID.textFile = t;
            globals.textDefaults.textDataset = 'No file loaded';
            set(t,'string',globals.textDefaults.textDataset)
    end
end
buttons = findall(fig, 'style', 'pushbutton');
for t = buttons'
    text  = get(t,'tag');
    switch text
        case 'buttonGMax'
            globals.FigID.buttonGMax = t;
            set(t,'string','Set to Global Max')
        case 'buttonIMax'
            globals.FigID.buttonIMax = t;
            set(t,'string','Set to Indiv max')
        case 'buttonClear'
            globals.FigID.buttonClear = t;
            set(t,'string','Clear')
        case 'buttonLoad'
            globals.FigID.buttonLoad = t;
            set(t,'string','Load')
        case 'buttonSet100'
            globals.FigID.buttonSet100 = t;
            set(t,'string','Set to X')
        case 'buttonResample'
            globals.FigID.buttonResample = t;
            set(t,'string','Resample')
    end
end
t = findall(fig, 'tag', 'uitable');
globals.FigID.table = t;
set(t,'data',[])

%% GUI - Set font sizes
set(findall(fig, '-property', 'FontSize'), 'FontSize', 15);

%% GUI - Give callback instructions to buttons
set(globals.FigID.buttonGMax,'callback',@buttonGMax)
set(globals.FigID.buttonIMax,'callback',@buttonIMax)
set(globals.FigID.buttonClear,'callback',@buttonClear)
set(globals.FigID.buttonLoad,'callback',@buttonLoad)
set(globals.FigID.buttonSet100,'callback',@buttonSet100)
set(globals.FigID.buttonResample,'callback',@buttonResample)

%% GUI - defaults
globals.filename = [];
globals.load = [];

%% Folders
if ~exist([pwd filesep 'Step 5 Output - Resample'])
    mkdir([pwd filesep 'Step 5 Output - Resample'])
end

catch err
rethrow(err)
end
end

function closeAllFigures
%%
%working with gui figs so "close all" won't work
delete(findall(0, 'type', 'figure'))
end

function buttonGMax(fig,evt)
%%
global globals
table = get(globals.FigID.table,'data');
if isempty(table)
    return
end
for cond = 1:length(globals.load.condName)
    if length(globals.load.data.cond(cond).trial)
        frameNums(cond) = max([globals.load.data.cond(cond).trial(:).numFrames]);
    else
        frameNums(cond) = 0;
    end
end
m = max(frameNums);
for cond = 1:length(globals.load.condName)
    table{cond+1,1} = m;
end
set(globals.FigID.table,'data',table);
set(globals.FigID.textStatus,'string','Frames set to global max.')
end

function buttonIMax(fig,evt)
%%
global globals
table = get(globals.FigID.table,'data');
if isempty(table)
    return
end
for cond = 1:length(globals.load.condName)
    if length(globals.load.data.cond(cond).trial)
        frameNums = [globals.load.data.cond(cond).trial(:).numFrames];
    else
        frameNums = 0;
    end
    table{cond+1,1} = max(frameNums);
end
set(globals.FigID.table,'data',table);
set(globals.FigID.textStatus,'string','Frames set to condition maxes.')
end

function buttonClear(fig,evt)
%%
global globals
table = get(globals.FigID.table,'data');
if isempty(table)
    return
end
l = size(table,1);
for i = 2:l
    table{i,1} = [];
end
set(globals.FigID.table,'data',table);
set(globals.FigID.textStatus,'string','Frames cleared for manual entry.')
end

function buttonLoad(fig,evt)
%%
global globals
[filename,folder] = uigetfile([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep '*.mat']);
if length(folder) > 1
    globals.filename = filename;
    set(globals.FigID.textFile,'string',filename)
else
    globals.filename = [];
    set(globals.FigID.textFile,'string',globals.textDefaults.textDataset)
    return
end
globals.load = [];
globals.load = load([folder filename]);

for var = 1:globals.load.conditions.numVar
    table{1,var+1} = globals.load.conditions.varNames{var};
    for i = 1:size(globals.load.conditions.conditionRows,1)
        table{1+i,var+1} = globals.load.conditions.levelNames{var}{globals.load.conditions.conditionRows(i,var)};
    end
end
table{1,1} = 'Frames';

set(globals.FigID.table,'ColumnEditable',[true(1,1) false(1,var)])

set(globals.FigID.table,'ColumnWidth','auto')

set(globals.FigID.table,'data',table)

set(globals.FigID.textStatus,'string',['Loaded ' filename '.'])
end

function buttonSet100(fig,evt)
%%
global globals
table = get(globals.FigID.table,'data');
if isempty(table)
    return
end
answer = inputdlg('Value','Value');
answer = answer{1};
if isempty(answer) | ~length(str2num(answer))
    msgbox('Please enter a number.','Error','Error')
    return
end
x = str2num(answer);
l = size(table,1);
for i = 2:l
    table{i,1} = x;
end
x = num2str(x);
set(globals.FigID.table,'data',table);
set(globals.FigID.textStatus,'string',['Frames set to ' x '.'])
end

function buttonResample(fig,evt)
%%
global globals
set(globals.FigID.textStatus,'string','Processing...')
drawnow
table = get(globals.FigID.table,'data');
if isempty(table)
    msgbox('Please load a file.','error','error')
    return
end
numFrames = cell2mat({table{2:end,1}});
numFrames(isnan(numFrames)) = [];
if isempty(numFrames) | length(numFrames)<size(table,1)-1
    msgbox('Please enter the number of frames you wish to resample to for each condition.','error','error')
    return
end

for cond = 1:length(globals.load.condName)
    if length(globals.load.data.cond(cond).trial)
        trials = [globals.load.data.cond(cond).trial(:).trial];
    else
        trials = [];
    end
    numTrial = length(trials);
    numFrameCond = numFrames(cond);
    
    resample.cond(cond).trial = [];
    
    for t = 1:numTrial
        trial = trials(t);
        numFrameTrial = globals.load.data.cond(cond).trial(t).numFrames;
        resample.cond(cond).trial(t).trial = trial;
        
        %which frame to take, in decimal format
        ind = (1:(numFrameTrial-1)/(numFrameCond-1):numFrameTrial);
        resample.cond(cond).trial(t).ind = ind;
        
        on = globals.load.data.cond(cond).trial(t).on;
        off = globals.load.data.cond(cond).trial(t).off;
        
        %XYZVA
        what = 'XYZVA';
        for i = 1:length(what)
            w = what(i);
            eval(['measureOfInterest = globals.load.odat.' w '(on:off,:,trial);']) %motion frames, all ired, this trial
            
            for f = 1:numFrameCond
                frame = ind(f);
                difFromBefore = frame-floor(frame);
                difFromAfter = ceil(frame)-frame;
                
                if min([difFromAfter difFromBefore]) == 0
                    %integer, could mean that this is first or last frame
                    eval(['resample.cond(cond).trial(t).' w '(f,:) = measureOfInterest(frame,:);'])
                else
                    %decminal
                    prior = measureOfInterest(floor(frame),:) * (1-difFromBefore);
                    post = measureOfInterest(ceil(frame),:) * (1-difFromAfter);
                    
                    eval(['resample.cond(cond).trial(t).' w '(f,:) = prior+post;'])
                end
            end
        end
        
        %GripAp
        for g = 1:3
            if g>length(globals.load.ocalc.gripap.IREDs) | isempty(globals.load.ocalc.gripap.IREDs{g})
                continue %if this ga was not used
            end
            
            measureOfInterest = globals.load.ocalc.gripap.ga{trial}(on:off,g);
            measureOfInterestVel = globals.load.data.cond(cond).trial(t).ga(g).gaABSVel;
            
            resample.cond(cond).trial(t).gripap = nan(numFrameCond,3);
            resample.cond(cond).trial(t).gripapABSVel = nan(numFrameCond,3);
            
            for f = 1:numFrameCond
                frame = ind(f);
                difFromBefore = frame-floor(frame);
                difFromAfter = ceil(frame)-frame;
                
                if min([difFromAfter difFromBefore]) == 0
                    %integer, could mean that this is first or last frame
                    resample.cond(cond).trial(t).gripap(f,g) = measureOfInterest(frame,:);
                    resample.cond(cond).trial(t).gripapABSVel(f,g) = measureOfInterestVel(frame,:);
                else
                    %decminal
                    prior = measureOfInterest(floor(frame),:) * (1-difFromBefore);
                    post = measureOfInterest(ceil(frame),:) * (1-difFromAfter);
                    resample.cond(cond).trial(t).gripap(f,g) = prior+post;
                    
                    prior = measureOfInterestVel(floor(frame),:) * (1-difFromBefore);
                    post = measureOfInterestVel(ceil(frame),:) * (1-difFromAfter);
                    resample.cond(cond).trial(t).gripapABSVel(f,g) = prior+post;
                end
            end
        end

    end
end
set(globals.FigID.textStatus,'string','Resampling complete - writing to excel.')
drawnow
warning off MATLAB:xlswrite:AddSheet
fn = globals.filename(1:find(globals.filename=='.')-1);
%remove existing xls if they exist
list = dir([pwd filesep 'Step 5 Output - Resample' filesep fn '_Measures.xls*']);
for i = 1:length(list)
    delete([pwd filesep 'Step 5 Output - Resample' filesep list(i).name])
end
list = dir([pwd filesep 'Step 5 Output - Resample' filesep fn '_MotionFrames.xls*']);
for i = 1:length(list)
    delete([pwd filesep 'Dtep 5 Output - Resample' filesep list(i).name])
end
%which GAs
GAs = [];
for g = 1:3
    if g>length(globals.load.ocalc.gripap.IREDs) | isempty(globals.load.ocalc.gripap.IREDs{g})
        continue %if this ga was not used
    end
    GAs = [GAs g];
end
numIREDs = length(globals.load.odat.X(1,:,1));
names = 'XYZVA';
%write
for cond = 1:length(globals.load.condName)
    numTrial = length(resample.cond(cond).trial);
    outputMeasures = cell(0);
    outputMotionFrames = cell(0);
    
    outputMeasures{1,1} = 'Trial';
    outputMeasures{1,2} = 'Raw Onset Frame';
    outputMeasures{1,3} = 'Raw Number of Motion Frames';
    outputMeasures{1,4} = 'Resampled Number of Motion Frames';
    r1=1;
    
    outputMotionFrames{1,1} = 'Trial';
    outputMotionFrames{1,2} = 'Resample Frame';
    outputMotionFrames{1,3} = 'Raw Frame';
    r2=1;
    
    for t = 1:numTrial
        trial = resample.cond(cond).trial(t).trial;
        
        %%Measures Excel File
        r1=r1+1;
        outputMeasures{r1,1} = trial;
        outputMeasures{r1,2} = globals.load.data.cond(cond).trial(t).on; 
        outputMeasures{r1,3} = globals.load.data.cond(cond).trial(t).numFrames;
        outputMeasures{r1,4} = length(resample.cond(cond).trial(t).ind);
        c1=4;
        
        nf = globals.load.data.cond(cond).trial(t).numFrames;
        
        %gripaps
        for g = GAs
            %init, fin, peak, peak frame as percent (0-100), oversizing
            if t==1
                ga = globals.load.ocalc.gripap.IREDs{g};
                outputMeasures{1,c1+1} = ['GripAp(' ga ') Initial (mm)'];
                outputMeasures{1,c1+2} = ['GripAp(' ga ') Final (mm)'];
                outputMeasures{1,c1+3} = ['GripAp(' ga ') Peak (mm)'];
                outputMeasures{1,c1+4} = ['GripAp(' ga ') Peak Frame as Percent Through Motion (0-100)'];
                outputMeasures{1,c1+5} = ['GripAp(' ga ') Oversizing (mm)'];
                outputMeasures{1,c1+6} = ['GripAp(' ga ') Peak Absolute Velocity (mm/FRAME)'];
                outputMeasures{1,c1+7} = ['GripAp(' ga ') Peak Absolute Velocity Frame as Percent Through Motion (0-100)'];
            end
            
            c1=c1+1;
            outputMeasures{r1,c1} = globals.load.data.cond(cond).trial(t).ga(g).init;
            
            c1=c1+1;
            outputMeasures{r1,c1} = globals.load.data.cond(cond).trial(t).ga(g).fin;
            
            c1=c1+1;
            outputMeasures{r1,c1} = globals.load.data.cond(cond).trial(t).ga(g).peak;
            
            c1=c1+1;
            f = globals.load.data.cond(cond).trial(t).ga(g).peakFrame;
            outputMeasures{r1,c1} = (f-1)/(nf-1)*100;
            
            c1=c1+1;
            outputMeasures{r1,c1} = globals.load.data.cond(cond).trial(t).ga(g).oversizing;
            
            %3 new grip-ap measures requested by TC (Added Oct 24, 2014)
            %1. grip-ap velocity (change)
            %not a single value - can't plot here
            %2. grip-ap peak velocity (peak change)
            c1=c1+1;
            outputMeasures{r1,c1} = globals.load.data.cond(cond).trial(t).ga(g).gaABSVelocityPeak;
            %3. frame of grip-ap peak velocity
            c1=c1+1;
            f = globals.load.data.cond(cond).trial(t).ga(g).gaABSVelocityPeakFrameInMotion;
            outputMeasures{r1,c1} = (f-1)/(nf-1)*100;
            
        end
        
        %vel/accel/decel
        for IRED = 1:numIREDs
            if t==1
                outputMeasures{1,c1+1} = ['IRED-' num2str(IRED) ' Vel Peak (mm/sec)'];
                outputMeasures{1,c1+2} = ['IRED-' num2str(IRED) ' Vel Peak Frame as Percent Through Motion (0-100)'];
                outputMeasures{1,c1+3} = ['IRED-' num2str(IRED) ' Accel Peak (mm/sec2)'];
                outputMeasures{1,c1+4} = ['IRED-' num2str(IRED) ' Accel Peak Frame as Percent Through Motion (0-100)'];
                outputMeasures{1,c1+5} = ['IRED-' num2str(IRED) ' Decel Peak (mm/sec2)'];
                outputMeasures{1,c1+6} = ['IRED-' num2str(IRED) ' Decel Peak Frame as Percent Through Motion (0-100)'];
            end
            c1=c1+1;
            outputMeasures{r1,c1} = globals.load.data.cond(cond).trial(t).velPeak(IRED);
            
            c1=c1+1;
            f = globals.load.data.cond(cond).trial(t).velPeakFrame(IRED);
            outputMeasures{r1,c1} = (f-1)/(nf-1)*100;
            
            c1=c1+1;
            outputMeasures{r1,c1} = globals.load.data.cond(cond).trial(t).accelPeak(IRED);
            
            c1=c1+1;
            f = globals.load.data.cond(cond).trial(t).accelPeakFrame(IRED);
            outputMeasures{r1,c1} = (f-1)/(nf-1)*100;
            
            c1=c1+1;
            outputMeasures{r1,c1} = globals.load.data.cond(cond).trial(t).decelPeak(IRED);
            
            c1=c1+1;
            f = globals.load.data.cond(cond).trial(t).decelPeakFrame(IRED);
            outputMeasures{r1,c1} = (f-1)/(nf-1)*100;
            
        end
        
        %%MotionFrames Excel File
        ind = resample.cond(cond).trial(t).ind;
        for f = 1:length(ind) %frame
            r2=r2+1;
            outputMotionFrames{r2,1} = trial;
            outputMotionFrames{r2,2} = f;
            outputMotionFrames{r2,3} = ind(f);
            c2=3;
            
            %GAs
            for g = GAs
                c2=c2+1;
                if f == 1
                    ga = globals.load.ocalc.gripap.IREDs{g};
                    outputMotionFrames{1,c2} = ['GripAp(' ga ') (mm)'];
                end
                outputMotionFrames{r2,c2} = resample.cond(cond).trial(t).gripap(f,g);
                
                c2=c2+1;
                if f == 1
                    ga = globals.load.ocalc.gripap.IREDs{g};
                    outputMotionFrames{1,c2} = ['GripAp(' ga ') Absolute Velocity (mm/FRAME)'];
                end
                outputMotionFrames{r2,c2} = resample.cond(cond).trial(t).gripapABSVel(f,g);
            end
            
            %XYZVAs
            for IRED = 1:numIREDs
                for n = 1:length(names)
                    name = names(n);
                    c2 = c2+1;
                    if f == 1
                        outputMotionFrames{1,c2} = [name num2str(IRED)];
                    end
                    
                    eval(['val = resample.cond(cond).trial(t).' name '(f,IRED);'])

                    outputMotionFrames{r2,c2} = val;

                end
            end
            
        end
    end
    
    fnadd = globals.load.condName{cond};
    xlswrite([pwd filesep 'Step 5 Output - Resample' filesep fn '_Measures'],outputMeasures,fnadd)
    xlswrite([pwd filesep 'Step 5 Output - Resample' filesep fn '_MotionFrames'],outputMotionFrames,fnadd)
    
end
%remove default pages
list = dir([pwd filesep 'Step 5 Output - Resample' filesep fn '_Measures.xls*']);
excelFileName = list(1).name;
sheetName = 'Sheet';
objExcel = actxserver('Excel.Application');
objExcel.Workbooks.Open([pwd filesep 'Step 5 Output - Resample' filesep excelFileName]);
try
objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
catch
end
objExcel.ActiveWorkbook.Save;
objExcel.ActiveWorkbook.Close;
objExcel.Quit;
objExcel.delete;

list = dir([pwd filesep 'Step 5 Output - Resample' filesep fn '_MotionFrames.xls*']);
excelFileName = list(1).name;
sheetName = 'Sheet';
objExcel = actxserver('Excel.Application');
objExcel.Workbooks.Open([pwd filesep 'Step 5 Output - Resample' filesep excelFileName]);
try
objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
catch
end
objExcel.ActiveWorkbook.Save;
objExcel.ActiveWorkbook.Close;
objExcel.Quit;
objExcel.delete;

%save mat
data = globals.load;
data.resample = resample;
save([pwd filesep 'Step 5 Output - Resample' filesep fn],'data')
set(globals.FigID.textStatus,'string',['Saved ' globals.filename])

saveFol = [pwd filesep 'Step 5 Output - Resample'];
if ispc %is windows
    winopen(saveFol)
elseif ismac
    system(['open ',saveFol]);
end

globals.filename = [];
set(globals.FigID.textFile,'string',globals.textDefaults.textDataset)
globals.load = [];
set(globals.FigID.table,'data',[])

end