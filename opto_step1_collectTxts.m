function opto_step1_collectTxts
try
closeAllFigures
%% GUI- Load
fig = hgload([pwd filesep 'GUI' filesep 'opto_step1_collectTxts' '.fig']);

%% GUI - Global vars that need to transfer to GUI
global globals

%% GUI - Set text
name = 'Script 1: Collect Data From Txt Files';
set(fig,'name',name);
texts = findall(fig, 'style', 'text');
for t = texts'
    text  = get(t,'tag');
    switch text
        case 'textTitle'
            set(t,'string',name)
        case 'textInstructions'
            inst = sprintf('1. Click the Load button\n\n2. Select any txt file containing opto data\n\n3. All files sharing the name will be processed\n\n4. Check the # of IREDs and missing files');
            set(t,'string',inst)
        case 'textMissingL'
            set(t,'string','Files: ')
        case 'textMissing'
            set(t,'string','')
            globals.files = t;
        case 'textNumIREDL'
            set(t,'string','IREDs Found: ')
        case 'textNumIRED'
            set(t,'string','')
            globals.numIRED = t;
        case 'textProcessedL'
            set(t,'string','Processing: ')
        case 'textProcessed'
            set(t,'string','')
            globals.processing = t;
    end
end
bClose = findall(fig, 'tag', 'buttonClose');
set(bClose,'string','Close');
set(bClose,'callback',@button_callback);
bLoad = findall(fig, 'tag', 'buttonLoad');

%% GUI - Set font sizes
set(findall(fig, '-property', 'FontSize'), 'FontSize', 15);

%% GUI - Give callback instructions to button
set(bClose,'callback',@closeAllFigures);
set(bLoad,'callback',@button_callback);

catch err
closeAllFigures
rethrow(err)
end
end

function closeAllFigures(fig, evt)
%working with gui figs so "close all" won't work
delete(findall(0, 'type', 'figure'))
end

function button_callback(fig, evt)
try
global globals
%% Pick file
[FileName,PathName,FilterIndex] = uigetfile('.txt');
if ~FilterIndex %closed window
    return
elseif FilterIndex > 1 %selected non-txt
    msgbox('Please select a txt file.','Error','error')
    set(globals.processing,'string','error')
    set(globals.numIRED,'string','error')
    set(globals.files,'string','error')
    return
end

%% Create list of all similar files
fn = [PathName FileName];
fn = fn(1:find(fn=='_',1,'last'));
list = dir([fn '*.txt']);
numFile = length(list);

%% Indicate missing
minNum = list(1).name([length(fn)+1:length(fn)+3]-length(PathName));
maxNum = str2num(list(numFile).name([length(fn)+1:length(fn)+3]-length(PathName)));
missing=[];
if maxNum > numFile
    for i = 1:maxNum
        if ~exist(sprintf('%s%03d.txt',fn,i))
            missing=[missing i];
        end
    end
    set(globals.files,'string',[minNum '-' num2str(maxNum) ' except ' num2str(missing)])
else
    set(globals.files,'string',[minNum '-' num2str(maxNum)])
end

%% Cycle through, loading into a matrix
trial = 0;
for i = 1:numFile
    str = sprintf('%03d of %03d',i,numFile);
    set(globals.processing,'string',str)
    drawnow
    
    %read in
    file = load([PathName list(i).name]);
    
    %params
    trial = trial + 1;
    numIred(trial) = (size(file,2)-2)/5;
    
    if i == 1
        set(globals.numIRED,'string',num2str(numIred(trial)))
    end
    
    %check that we can work with it
    if numIred(trial) ~= round(numIred(trial))
        msgbox('Incorrect number of columns found.','Error','error')
        set(globals.processing,'string','error')
        set(globals.numIRED,'string','error')
        set(globals.files,'string','error')
        return
    end
    
    %convert blocked from 100000.0 to NaN
    file(file==100000) = nan;
    
    for row = 1:size(file,1)
        %put in XYZVA
        IRED = 1;
        for col = 1:(numIred*5)
            which = mod(col-1,5)+1;
            switch which
                case 1%X
                    odat.X(row,IRED,trial) = file(row,col);
                case 2%Y
                    odat.Y(row,IRED,trial) = file(row,col);
                case 3%Z
                    odat.Z(row,IRED,trial) = file(row,col);
                case 4%V
                    odat.V(row,IRED,trial) = file(row,col);
                case 5%A
                    odat.A(row,IRED,trial) = file(row,col);
                    IRED = IRED + 1;
            end
        end
    end
end

%% Any warnings
if sum(numIred ~= min(numIred))
    msgbox('The number of IREDs is not consistent across trials.','Error','error')
    set(globals.processing,'string','error')
    set(globals.numIRED,'string','error')
    set(globals.files,'string','error')
    return
end

%% Create output folder if it doesn't exist
if ~exist([pwd filesep 'Step 1 Output - Opto Data'])
    mkdir('Step 1 Output - Opto Data')
end

%% Save
f = fn(find(fn==filesep,1,'last')+1:end-1);
odat.optoFiles = [fn '###.txt'];
odat.legend = 'var(frame,ired,trial)';
save([pwd filesep 'Step 1 Output - Opto Data' filesep f],'odat');
set(globals.processing,'string',['Complete (' f '.mat)'])

saveFol = [pwd filesep 'Step 1 Output - Opto Data'];
if ispc %is windows
    winopen(saveFol)
elseif ismac
    system(['open ',saveFol]);
end

catch err
closeAllFigures
rethrow(err)
end
end