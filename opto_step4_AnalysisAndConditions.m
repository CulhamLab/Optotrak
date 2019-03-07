function opto_step4_AnalysisAndConditions
try
closeAllFigures
%% GUI- Load
fig = hgload([pwd filesep 'GUI' filesep 'opto_step4_AnalysisAndConditions' '.fig']);

%% GUI - Global vars that need to transfer to/from GUI
global globals
globals = [];

%% GUI - Set text and get IDs
globals.name = 'Script 4: Analysis and Conditions';
set(fig,'name',globals.name);
texts = findall(fig, 'style', 'text');
for t = texts'
    text  = get(t,'tag');
    switch text
        case 'textTitle'
            set(t,'string',globals.name)
        case 'textInstructions'
            set(t,'string',sprintf('1. Select Dataset\n2. Select Condition List (optional)\n3. Process'))
        case 'textDataset'
            globals.textDefaults.textDataset = 'No Dataset';
            set(t,'string',globals.textDefaults.textDataset)
            globals.FigID.textDataset = t;
        case 'textCondition'
            globals.textDefaults.textCondition = 'No Condition List (1)';
            set(t,'string',globals.textDefaults.textCondition)
            globals.FigID.textCondition = t;
        case 'textStatus'
            set(t,'string','Waiting...')
            globals.FigID.textStatus = t;
    end
end
buttons = findall(fig, 'style', 'pushbutton');
for t = buttons'
    text  = get(t,'tag');
    switch text
        case 'buttonDataset'
            set(t,'string','Select Dataset')
            globals.FigID.buttonDataset = t;
        case 'buttonCondition'
            set(t,'string','Select Condition List')
            globals.FigID.buttonCondition = t;
        case 'buttonProcess'
            set(t,'string','Process')
            globals.FigID.buttonProcess = t;
        case 'buttonUseOld'
            set(t,'string','About Legacy')
            globals.FigID.buttonUseOld = t;
    end
end
checks = findall(fig,'style','checkbox');
for t = checks'
    text  = get(t,'tag');
    switch text
        case 'checkboxUseOld'
            set(t,'string','Use legacy method instead')
            globals.FigID.checkboxUseOld = t;
    end
end

%% GUI - Set font sizes
set(findall(fig, '-property', 'FontSize'), 'FontSize', 15);

%% GUI - Give callback instructions to buttons
set(globals.FigID.buttonDataset,'callback',@buttonDataset)
set(globals.FigID.buttonCondition,'callback',@buttonCondition)
set(globals.FigID.buttonProcess,'callback',@buttonProcess)
set(globals.FigID.buttonUseOld,'callback',@buttonUseOld)

%% Folders
if ~exist([pwd filesep 'Condition Lists'])
    mkdir([pwd filesep 'Condition Lists'])
end
if ~exist([pwd filesep 'Step 4 Output - Analysis and Conditions'])
    mkdir([pwd filesep 'target(target) Output - Analysis and Conditions'])
end

%% Defaults
globals.filepaths.dataset = [];
globals.filepaths.conditions = [];
globals.condition = [];

catch err
rethrow(err)
end
end

function buttonUseOld(fig, evt)

msg = ['Using the original method produces output that is compatible with older analysis scripts (separate from this pipeline).' ...
        'The legacy output does not contain any new measures or flag information.'];
msgbox(msg,'Legacy Method');

end

function closeAllFigures
%%
%working with gui figs so "close all" won't work
delete(findall(0, 'type', 'figure'))
end

function buttonDataset(fig, evt)
%%
global globals
[filename,folder] = uigetfile([pwd filesep 'Step 3 Output - Confirm and Correct' filesep '*.mat']);
if length(folder) > 1
    globals.filepaths.dataset = [folder filename];
    set(globals.FigID.textDataset,'string',filename)
    set(globals.FigID.textStatus,'string','Dataset found.')
else
    globals.filepaths.dataset = [];
    set(globals.FigID.textDataset,'string',globals.textDefaults.textDataset)
end
end

function buttonCondition(fig, evt)
%%
global globals
[filename,folder] = uigetfile([pwd filesep 'Condition Lists' filesep '*.xls*']);
if length(folder) > 1
    set(globals.FigID.textStatus,'string','Reading excel file...')
    drawnow
    globals.filepaths.conditions = [folder filename];
    %NxM
    [~,~,raw] = xlsread([folder filename]);
    
    numRow = size(raw,1);

    for row = numRow:-1:1
        if isnan(raw{row,1})
            raw(row,:) = [];
        else
            break
        end
    end
    
    globals.condition = sortXLS(raw);
    
    str = sprintf('%dx',globals.condition.numLevel);
    set(globals.FigID.textCondition,'string',sprintf('%s (%s)',filename,str(1:end-1)))
    set(globals.FigID.textStatus,'string','Excel file read.')
else
    globals.filepaths.conditions = [];
    set(globals.FigID.textCondition,'string',globals.textDefaults.textCondition)
    globals.condition = [];
end
end

function buttonProcess(fig, evt)
%%
global globals
if get(globals.FigID.checkboxUseOld,'value')
    processLegacy
else
    process
end
end

function process
%%
global globals

%% Check
if isempty(globals.filepaths.dataset)
    msgbox('No dataset loaded! Please select a dataset before processing.','Error','Error')
    return
end

%% Load
load(globals.filepaths.dataset);

%% if no condition list, create filler list
if isempty(globals.filepaths.conditions)
    globals.condition = [];
    globals.condition.numTrial = alldata.params.numTrial;
    globals.condition.numVar  = 1;
    globals.condition.varNames = {'Default'};
    globals.condition.levelNames{1}{1} = 'AllConditions';
    globals.condition.numLevel = 1;
    globals.condition.trialCond = ones(globals.condition.numTrial,1);
else
    if alldata.params.numTrial ~= globals.condition.numTrial
        msgbox('The number of trials in data and condition file must be the same!','Error!')
        return
    end
end

%% Process
%for each condition
conditionRows = unique(globals.condition.trialCond,'rows');
numCond = size(conditionRows,1);

set(globals.FigID.textStatus,'string','Processing...')
drawnow

fn = globals.filepaths.dataset(find(globals.filepaths.dataset==filesep,1,'last')+1:end);
fn = fn(1:find(fn=='.',1,'last')-1);

list = dir([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep fn '_Measures.xls*']);
for i = 1:length(list)
    delete([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep list(i).name])
end

warning off MATLAB:xlswrite:AddSheet

measureNames = opto_functions('measure_getList');
indMeasureNoSpecificIRED = opto_functions('measure_getIndNoIRED');
pairsToUse = find(cellfun(@(x) x,alldata.load.params.gripap.include));
numIRED = alldata.params.numIRED;

counter = 0; %in case sheet name is too long

for cond = 1:numCond
    counter = counter + 1;
    
    %get level of each var
    levels = conditionRows(cond,:);
    levelNames = cellfun(@(x,y) x{y},globals.condition.levelNames,num2cell(levels),'UniformOutput',false);
    
    %construct cond name
    condName{cond} = levelNames{1};
    for i = 2:length(levelNames)
        condName{cond} = sprintf('%s+%s',condName{cond},levelNames{i});
    end
    
    %cond name for sheet (has a max length)
    if length(condName{cond})>31 %excel can't do sheets with names >31   
        condName_xls{cond} = sprintf('%s_%02d',condName{cond}(1:28),counter)
    else
        condName_xls{cond} = condName{cond};
    end

    %get trial ind
    trials = find(ismember(globals.condition.trialCond,levels,'rows'));
    
    %add each trial if alldata.includeTrial(#)
    data.cond(cond).trial = struct([]);
    data.cond_exclude(cond).trial = struct([]);
    for t = trials'
        
        %clear entry
        clear entry
        
        %on/off/numFrames
        entry.on = alldata.load.ocalc.onset.onsetFrame(t);
        entry.off = alldata.load.ocalc.offset.offsetFrame(t);
        entry.numFrames = entry.off-entry.on+1;
        entry.trial = t;
        
        %measures
        for m = 1:length(measureNames);
            mName = measureNames{m};
            mName_noSpace = strrep(mName,' ','_');
            mName_noSpace_noDash = strrep(mName_noSpace,'-','_');
            
            if any(find(indMeasureNoSpecificIRED==m))
                IREDs = nan;
            else
                IREDs = 1:numIRED;
            end
            
            for i = IREDs
                if isnan(i)
                    c = 1;
                else
                    c = i;
                end
                
                mVal = opto_functions('measure_getValue',alldata.load.odat,alldata.load.ocalc,pairsToUse,mName,i,t);
                mVal = mVal(entry.on:entry.off);
                
                eval(['entry.' mName_noSpace_noDash '(:,c)=mVal;'])
                
            end
            
        end
        
        if alldata.includeTrial(t)
            if ~length(data.cond(cond).trial)
                data.cond(cond).trial = entry;
            else
                ti = length(data.cond(cond).trial) + 1;
                data.cond(cond).trial(ti) = entry;
            end
        else
            if ~length(data.cond_exclude(cond).trial)
                data.cond_exclude(cond).trial = entry;
            else
                ti = length(data.cond_exclude(cond).trial) + 1;
                data.cond_exclude(cond).trial(ti) = entry;
            end
        end
        
    end
    
end

%% Save
%just keep what we need - things are getting bloated
%keep: data, condName, odat, and ocalc
odat = alldata.load.odat;
ocalc = alldata.load.ocalc;
conditions = globals.condition;
conditions.conditionRows = conditionRows;

saveFol = [pwd filesep 'Step 4 Output - Analysis and Conditions'];
if ~exist(saveFol, 'dir')
    mkdir(saveFol);
end
save([saveFol filesep fn],'data','condName','condName_xls','odat','ocalc','conditions')

set(globals.FigID.textStatus,'string',['Saved ' fn '.mat'])
drawnow

if ispc %is windows
    winopen(saveFol)
elseif ismac
    system(['open ',saveFol]);
end

%% reset UI
reset
end

function processLegacy
%%
global globals

%% Check
if isempty(globals.filepaths.dataset)
    msgbox('No dataset loaded! Please select a dataset before processing.','Error','Error')
    return
end

%% Load
load(globals.filepaths.dataset);

%% if no condition list, create filler list
if isempty(globals.filepaths.conditions)
    globals.condition = [];
    globals.condition.numTrial = alldata.params.numTrial;
    globals.condition.numVar  = 1;
    globals.condition.varNames = {'Default'};
    globals.condition.levelNames{1}{1} = 'AllConditions';
    globals.condition.numLevel = 1;
    globals.condition.trialCond = ones(globals.condition.numTrial,1);
else
    if alldata.params.numTrial ~= globals.condition.numTrial
        msgbox('The number of trials in data and condition file must be the same!','Error!')
        return
    end
end

%% Process
%for each condition
conditionRows = unique(globals.condition.trialCond,'rows');
numCond = size(conditionRows,1);

set(globals.FigID.textStatus,'string','Processing (legacy)...')
drawnow

fn = globals.filepaths.dataset(find(globals.filepaths.dataset==filesep,1,'last')+1:end);
fn = fn(1:find(fn=='.',1,'last')-1);

list = dir([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep fn '_Measures.xls*']);
for i = 1:length(list)
    delete([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep list(i).name])
end

warning off MATLAB:xlswrite:AddSheet

counter = 0;

for cond = 1:numCond
    levels = conditionRows(cond,:);
    trials = find(ismember(globals.condition.trialCond,levels,'rows'));

    %preinit
    data.cond(cond).trial = [];
    
    t = 0;
    for trial = trials'
        if ~alldata.includeTrial(trial)
            continue
        end
        t=t+1;
        on = alldata.load.ocalc.onset.onsetFrame(trial);
        off = alldata.load.ocalc.offset.offsetFrame(trial);
        numFrames = off-on+1;
        
        data.cond(cond).trial(t).on = on;
        data.cond(cond).trial(t).off = off;
        data.cond(cond).trial(t).numFrames = numFrames;
        data.cond(cond).trial(t).trial = trial;
        
        for ired = 1:alldata.params.numIRED
            %vel of each ired
            vel = alldata.load.odat.V(on:off,ired,trial);
            data.cond(cond).trial(t).velPeak(ired) = max(vel);
            if isnan(max(vel))
                data.cond(cond).trial(t).velPeakFrame(ired) = nan;
            else
                data.cond(cond).trial(t).velPeakFrame(ired) = find(vel==max(vel),1);
            end
            
            %accel of each ired
            accel = alldata.load.odat.A(on:off,ired,trial);
            data.cond(cond).trial(t).accelPeak(ired) = max(accel);
            if isnan(max(accel))
                data.cond(cond).trial(t).accelPeakFrame(ired) = nan;
            else
                data.cond(cond).trial(t).accelPeakFrame(ired) = find(accel==max(accel),1);
            end
%             data.cond(cond).trial(t).accelMin(ired) = min(accel);
%             data.cond(cond).trial(t).accelMinFrame(ired) = find(accel==min(accel),1);
            
            %deccel of each ired
            decel = accel*-1;
            data.cond(cond).trial(t).decelPeak(ired) = max(decel);
            if isnan(max(decel))
                data.cond(cond).trial(t).decelPeakFrame(ired) = nan;
            else
                data.cond(cond).trial(t).decelPeakFrame(ired) = find(decel==max(decel),1);
            end
%             data.cond(cond).trial(t).decelMin(ired) = min(decel);
%             data.cond(cond).trial(t).decelMinFrame(ired) = find(decel==min(decel),1);
        end
        %grip aps
        for g = 1:3
            if g>length(alldata.load.ocalc.gripap.IREDs) | isempty(alldata.load.ocalc.gripap.IREDs{g})
                %ga not used
                data.cond(cond).trial(t).ga(g).IREDs = [];
                data.cond(cond).trial(t).ga(g).init = nan;
                data.cond(cond).trial(t).ga(g).peak = nan;
                data.cond(cond).trial(t).ga(g).peakFrame = nan;
                data.cond(cond).trial(t).ga(g).fin = nan;
                continue
            end
            data.cond(cond).trial(t).ga(g).IREDs = alldata.load.ocalc.gripap.IREDs{g};
            gaDat = alldata.load.ocalc.gripap.ga{trial}(on:off,g);
            data.cond(cond).trial(t).ga(g).init = gaDat(1);
            p = max(gaDat);
            data.cond(cond).trial(t).ga(g).peak = p;
            if isnan(p)
                data.cond(cond).trial(t).ga(g).peakFrame = nan;
            else
                data.cond(cond).trial(t).ga(g).peakFrame = find(gaDat==p,1);
            end
            data.cond(cond).trial(t).ga(g).fin = gaDat(end);
            data.cond(cond).trial(t).ga(g).oversizing = data.cond(cond).trial(t).ga(g).peak - data.cond(cond).trial(t).ga(g).fin;
        
            %3 new grip-ap measures requested by TC (Added Oct 24, 2014)
            %1. grip-ap velocity (abs change)
            allVel = abs([0; diff(alldata.load.ocalc.gripap.ga{trial}(:,g))]);
            gaVel = allVel(on:off);
            data.cond(cond).trial(t).ga(g).gaABSVel = gaVel;

            %2. grip-ap peak velocity (peak abs change)
            %3. frame of grip-ap peak abs velocity
            [peakVel,indPeakVel] = max(gaVel);
            data.cond(cond).trial(t).ga(g).gaABSVelocityPeak = peakVel;
            data.cond(cond).trial(t).ga(g).gaABSVelocityPeakFrameInMotion = indPeakVel;
            
        end
    end
    
    %write to xls
    output = cell(0);
    output{1,1} = 'Trial';
    for i = 1:t
        output{i+1,1} = data.cond(cond).trial(i).trial;
    end
    
    output{1,2} = 'OnsetFrame';
    for i = 1:t
        output{i+1,2} = data.cond(cond).trial(i).on;
    end
    
    output{1,3} = 'OffsetFrame';
    for i = 1:t
        output{i+1,3} = data.cond(cond).trial(i).off;
    end
    
    output{1,4} = 'NumFrames';
    for i = 1:t
        output{i+1,4} = data.cond(cond).trial(i).numFrames;
    end
    
    c = 4;
    for g = 1:3
        if g>length(alldata.load.ocalc.gripap.IREDs) | isempty(alldata.load.ocalc.gripap.IREDs{g})
            continue
        end
        
        c=c+1;
        output{1,c} = sprintf('GripAp(%s) Initial (mm)',alldata.load.ocalc.gripap.IREDs{g});
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).ga(g).init;
        end
        
        c=c+1;
        output{1,c} = sprintf('GripAp(%s) Final (mm)',alldata.load.ocalc.gripap.IREDs{g});
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).ga(g).fin;
        end
        
        c=c+1;
        output{1,c} = sprintf('GripAp(%s) Peak (mm)',alldata.load.ocalc.gripap.IREDs{g});
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).ga(g).peak;
        end
        
        c=c+1;
        output{1,c} = sprintf('GripAp(%s) Peak Frame (in motion frames)',alldata.load.ocalc.gripap.IREDs{g});
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).ga(g).peakFrame;
        end
        
        c=c+1;
        output{1,c} = sprintf('GripAp(%s) Oversizing (mm)',alldata.load.ocalc.gripap.IREDs{g});
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).ga(g).oversizing;
        end
        
        %3 new grip-ap measures requested by TC (Added Oct 24, 2014)
        
        %1. grip-ap velocity (change)
        %not a single value - can't plot here
        
        %2. grip-ap peak velocity (peak change)
        c=c+1;
        output{1,c} = sprintf('GripAp(%s) Peak Absolute Velocity (mm/FRAME)',alldata.load.ocalc.gripap.IREDs{g});
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).ga(g).gaABSVelocityPeak;
        end
        
        %3. frame of grip-ap peak velocity
        c=c+1;
        output{1,c} = sprintf('GripAp(%s) Peak Frame of Absolute Velocity (in motion frames)',alldata.load.ocalc.gripap.IREDs{g});
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).ga(g).gaABSVelocityPeakFrameInMotion;
        end
        
    end
    
    for ired = 1:alldata.params.numIRED
        c=c+1;
        output{1,c} = sprintf('IRED-%d Vel Peak (mm/sec)',ired);
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).velPeak(ired);
        end
        
        c=c+1;
        output{1,c} = sprintf('IRED-%d Vel Peak Frame (in motion frames)',ired);
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).velPeakFrame(ired);
        end
        
        c=c+1;
        output{1,c} = sprintf('IRED-%d Accel Peak (mm/sec2)',ired);
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).accelPeak(ired);
        end
        
        c=c+1;
        output{1,c} = sprintf('IRED-%d Accel Peak Frame (in motion frames)',ired);
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).accelPeakFrame(ired);
        end
        
%         c=c+1;
%         output{1,c} = sprintf('IRED-%d Accel Min',ired);
%         for i = 1:t
%             output{i+1,c} = data.cond(cond).trial(i).accelMin(ired);
%         end
%         
%         c=c+1;
%         output{1,c} = sprintf('IRED-%d Accel Min Frame',ired);
%         for i = 1:t
%             output{i+1,c} = data.cond(cond).trial(i).accelMinFrame(ired);
%         end
        
        c=c+1;
        output{1,c} = sprintf('IRED-%d Decel Peak (mm/sec2)',ired);
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).decelPeak(ired);
        end
        
        c=c+1;
        output{1,c} = sprintf('IRED-%d Decel Peak Frame (in motion frames)',ired);
        for i = 1:t
            output{i+1,c} = data.cond(cond).trial(i).decelPeakFrame(ired);
        end
        
%         c=c+1;
%         output{1,c} = sprintf('IRED-%d Decel Min',ired);
%         for i = 1:t
%             output{i+1,c} = data.cond(cond).trial(i).decelMin(ired);
%         end
%         
%         c=c+1;
%         output{1,c} = sprintf('IRED-%d Decel Min Frame',ired);
%         for i = 1:t
%             output{i+1,c} = data.cond(cond).trial(i).decelMinFrame(ired);
%         end
    end
    
    fnadd = [];
    for i = 1:length(levels)
%         fnadd = [fnadd ' ' globals.condition.varNames{i} '_' globals.condition.levelNames{i}{levels(i)}];
        fnadd = [fnadd ' ' globals.condition.levelNames{i}{levels(i)}];
    end
    fnadd=fnadd(2:end);
    counter = counter + 1;
    fnadd_xls = fnadd;
    if length(fnadd_xls)>31 %excel can't do sheets with names >31   
        fnadd_xls = fnadd_xls(1:31);
        fnadd_xls(29:31) = sprintf('_%02d',counter);
    end
    
    xlswrite([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep fn '_Measures'],output,fnadd_xls)
    
    condName{cond} = fnadd;
    condName_xls{cond} = fnadd_xls;
end

%% Remove default xls sheet(s)
list = dir([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep fn '_Measures.xls*']);
excelFileName = list(1).name;
sheetName = 'Sheet';
objExcel = actxserver('Excel.Application');
objExcel.Workbooks.Open([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep excelFileName]);
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

%% XLS MotionFrames
list = dir([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep fn '_MotionFrames.xls*']);
for i = 1:length(list)
    delete([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep list(i).name])
end
for cond = 1:numCond
    output = cell(0);
    output{1,1} = 'Trial';
    output{1,2} = 'Frame';
    r = 1;
    numTrialInThisCond = length(data.cond(cond).trial);
    for t = 1:numTrialInThisCond
        trial = data.cond(cond).trial(t).trial;
        on = data.cond(cond).trial(t).on;
        off = data.cond(cond).trial(t).off;
        for frame = on:off
           r=r+1;
           output{r,1} = trial;
           output{r,2} = frame;
           %grip ap
           c=2;
           for g = 1:3
                if g>length(alldata.load.ocalc.gripap.IREDs) | isempty(alldata.load.ocalc.gripap.IREDs{g})
                    continue %if this ga was not used
                end
                c=c+1;
                if t==1 & frame==on
                    output{1,c} = ['GripAp (' alldata.load.ocalc.gripap.IREDs{g} ') (mm)'];
                end
                val = alldata.load.ocalc.gripap.ga{trial}(frame,g);
                output{r,c} = val;
                
                %3 new grip-ap measures requested by TC (Added Oct 24, 2014)
                %1. grip-ap velocity (change)
                c=c+1;
                if t==1 & frame==on
                    output{1,c} = ['GripAp (' alldata.load.ocalc.gripap.IREDs{g} ') Absolute Velocity (mm/FRAME)'];
                end
                if frame == 1
                    val = 0;
                else
                    val = abs(diff(alldata.load.ocalc.gripap.ga{trial}(frame-1:frame,g)));
                end
                output{r,c} = val;
                
           end
           %XYZVA
           names = 'XYZVA';
           numIRED = alldata.params.numIRED;
           for IRED = 1:numIRED
               for n = 1:length(names)
                    name = names(n);
                    c=c+1;
                    if t==1 & frame==on
                        output{1,c} = [name num2str(IRED)];
                    end
                    eval(['val = alldata.load.odat.' name '(frame,IRED,trial);'])
                    output{r,c} = val;
               end
           end
        end
    end
    fnadd = condName{cond};
    fnadd_xls = condName_xls{cond};
    xlswrite([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep fn '_MotionFrames'],output,fnadd_xls)
end
list = dir([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep fn '_MotionFrames.xls*']);
excelFileName = list(1).name;
sheetName = 'Sheet';
objExcel = actxserver('Excel.Application');
objExcel.Workbooks.Open([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep excelFileName]);
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


%% Save
%just keep what we need - things are getting bloated
%keep: data, condName, odat, and ocalc
odat = alldata.load.odat;
ocalc = alldata.load.ocalc;
conditions = globals.condition;
conditions.conditionRows = conditionRows;

save([pwd filesep 'Step 4 Output - Analysis and Conditions' filesep fn],'data','condName','condName_xls','odat','ocalc','conditions')

set(globals.FigID.textStatus,'string',['Saved ' fn '.mat'])
drawnow

saveFol = [pwd filesep 'Step 4 Output - Analysis and Conditions'];
if ispc %is windows
    winopen(saveFol)
elseif ismac
    system(['open ',saveFol]);
end

reset
end

function reset
global globals
globals.filepaths.dataset = [];
globals.filepaths.conditions = [];
set(globals.FigID.textDataset,'string',globals.textDefaults.textDataset)
set(globals.FigID.textCondition,'string',globals.textDefaults.textCondition)
globals.condition = [];
end

function [output] = sortXLS(raw)
output.numTrial = size(raw,1)-1;
output.numVar = size(raw,2)-1;
output.varNames = {raw{1,2:end}};

for var = 1:output.numVar
    vals = {raw{2:( output.numTrial+1 ),var+1}}; %vals = {raw{2:end,var+1}};
    for v = 1:output.numTrial
        if isnumeric(vals{v})
            vals{v} = num2str(vals{v});
        end
    end
    output.levelNames{var} = unique(vals);
    output.numLevel(var) = length(unique(vals));
end

% output.numCond = prod(output.numLevel);

output.trialCond = nan(output.numTrial, output.numVar);
for trial = 1:output.numTrial
    for var = 1:output.numVar
        val = raw{trial+1,var+1};
        if isnumeric(val)
            val = num2str(val);
        end
        val = strcmp(output.levelNames{var},val);
        output.trialCond(trial,var) = find(val);
    end
end

end