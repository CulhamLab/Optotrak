%Initialize(parameters)
%
%TODO: description
%
%Use in parallel with OTCollect in rooms 3145 (2x Certus) and 3151 (3x 3020s)
%
%PARAMETERS
%  Required parameters:
%  NUMBER_IREDS   (must match OTCollect)
%  RECORD_MSEC    (must match OTCollect)
%  SAMPLE_RATE_HZ (must match OTCollect)
%  DIRECTORY_DATA (must match OTCollect)
%  FILENAME_DATA  (must match OTCollect not including the "_###.dat" that is automatically added)
%
%  Common override parameters (optional):
%  DEBUG             (defaults to false. if true, prevents use of hardware for testing on other PCs - still excpects data files to appear unless NO_FILES is also set true)
%  NO_FILES          (defaults to false. if true, data files will not be searched for or checked)
%  SOUND.PLAY_SOUNDS (defaults to true. when data cannot be found or contains blockage, beeps will be played. all other activity will be haulted while beeps play)
%  TIMEOUT_MSEC      (defaults to 2000. time after data should have been available to stop looking and flag as an error)
%
%  Any constant in the opto struct can be overriden by passing a matching field in the parameters structure
%  Any other fields in the parameter structure will be ignored
%
function Initialize(parameters)

%% Global Struct
global opto

%% Clear prior global
if isfield(opto, 'sound_handle')
    try
        PsychPortAudio('Close', opto.sound_handle);
    end
end

%clear global
opto = struct;

%% Set Constants
%debug
opto.DEBUG = false; %if true, prevents use of hardware for testing on other PCs - still excpects data files to appear unless NO_FILES is also set true
opto.NO_FILES = false; %if true, data files will not be searched for or checked

%sound
opto.SOUND.PLAY_SOUNDS = true; %when data cannot be found or contains blockage, beeps will be played. all other activity will be haulted while beeps play (triggered by CheckData)
opto.SOUND.LATENCY = .050;
opto.SOUND.CHANNELS = 2;
opto.SOUND.PLAY_FREQUENCY = 44100;
opto.SOUND.VOLUME = 1;
opto.SOUND.BEEP_DURATION_SEC = 0.25;
opto.SOUND.BEEP_FREQUENCY = 400;
opto.SOUND.BEEP_NUMBER = 5;
opto.SOUND.BEEP_SPACING_SEC = 0.15;

%keys
opto.KEYS.STOP.NAME = 'ESCAPE';
opto.KEYS.CONTINUE.NAME = 'SPACE';
opto.KEYS.TRIGGER.NAME = 'T';

%timing
opto.TIMING.TIMEOUT_MSEC = 2000; %time after data should have been available to stop looking and flag as an error
opto.TIMING.BUFFER_FILE_READ_MSEC = 500; %time after file is seen before allowing read (to ensure file write is complete)
opto.TIMING.BUFFER_TRIGGER_MSEC = 500; %time after prior trial completes before alowing next trigger
opto.TIMING.MINIMUM_BETWEEN_HIGH_LOW_MSEC = 10; %minimum time between setting opto pin high/low (to ensure that signal is detected) (set 0 to disable)

%dio
opto.DIO.BOARD_NUMBER = 0;
opto.DIO.PIN = 3;
opto.DIO.HIGH = 1;
opto.DIO.LOW = 0;

%% Handle Inputs
if ~exist('parameters', 'var') || ~isstruct(parameters)
    help(mfilename)
    error('Input parameters must be passed as a structure. See help text for more details.')
end

%do overrides
list = fields(opto);
while 1
    list_next = cell(0);
    for f = list'
        f = f{1};
        
        ind = find(f=='.', 1, 'last');
        if ~isempty(ind)
            eval(sprintf('p_test = parameters.%s;', f(1:ind-1)))
            eval(sprintf('o_test = opto.%s;', f(1:ind-1)))
            f_test = f(ind+1:end);
        else
            p_test = parameters;
            o_test = opto;
            f_test = f;
        end
        
        if isfield(p_test, f_test)
            p_value = getfield(p_test, f_test);
            o_value = getfield(o_test, f_test);
            
            if isstruct(p_value) == isstruct(o_value)
                if isstruct(p_value)
                    %look in subfield
                    list_next = [list_next; cellfun(@(x) [f '.' x], fields(o_value), 'UniformOutput', false)];
                else
                    %override field in opto with parameter
                    fprintf('Overriding: %s (%s ==> %s)\n', f, format(o_value), format(p_value))
                    eval(sprintf('opto.%s = parameters.%s;', f, f))
                end
            end
        end
    end
    
    list = list_next;
    if isempty(list)
        break;
    end
end
   
%check and set required fields
otcollect_fields = {'NUMBER_IREDS' 'RECORD_MSEC' 'SAMPLE_RATE_HZ' 'DIRECTORY_DATA' 'FILENAME_DATA'};
for f = otcollect_fields
    f = f{1};
    if ~isfield(parameters, f)
        help(mfilename)
        error('Missing required parameters: %s', f)
    else
        opto = setfield(opto, f, getfield(parameters, f));
    end
end

%create default check
opto.DEFAULT_CHECK.ireds_for_percent_check = 1:parameters.NUMBER_IREDS; %ireds to check for the min percent (default to all IREDs) (all of these IREDs must be available for a frame to be considered valid)
opto.DEFAULT_CHECK.minimum_percent_present = 70; %check fails if less than this % of frames are unblocked
opto.DEFAULT_CHECK.required_ireds_at_frames = []; %[N-by-2] with rows of [ired# frame#] for an ired# that must be unblocked at frame#

%% Initialize
opto.time_start = GetSecs;
opto.initialized = false; %initializing not yet complete
opto.warnings = cell(0);

opto.trigger.time_allow_trigger_start = 0; %ready to prepare trigger

opto.trigger.file_searched = true;
opto.trigger.file_found = true;
opto.trigger.file_checked = true;
opto.trigger.file_located_filepath = [];

opto.trigger.started = true; %ready to prepare trigger
opto.trigger.stopped = true; %ready to prepare trigger

%% Check that PsychToolbox is installed and working
try
    AssertOpenGL();
catch err
    Warning('PsychToolbox might not be installed or setup correctly!')
    rethrow(err)
end

%% Set key values (uses PTB)
KbName('UnifyKeyNames');
for key = fields(opto.KEYS)'
    key = key{1};
    eval(sprintf('opto.KEYS.%s.VALUE = KbName(opto.KEYS.%s.NAME);', key, key))
end

%% Warn and require key press if debug is on
if opto.DEBUG
    Warning(sprintf('Debug mode is enabled. Hardware will not be used.\n\nPres %s to continue or %s to stop.\n', opto.KEYS.CONTINUE.NAME, opto.KEYS.STOP.NAME))
    pressed = false;
    while 1
        [~,~,keys] = KbCheck(-1);
        if keys(opto.KEYS.STOP.VALUE)
            error('Stop key pressed.')
        elseif keys(opto.KEYS.CONTINUE.VALUE)
            pressed = true;
        elseif pressed && ~keys(opto.KEYS.CONTINUE.VALUE)
            break;
        end
    end
end

%% Check that opto directory exists and is visible (local or via network)
%add filesep to the end if not present
if opto.DIRECTORY_DATA(end) ~= filesep
    opto.DIRECTORY_DATA(end+1) = filesep;
end

%check for dir
if ~exist(opto.DIRECTORY_DATA, 'dir') && ~opto.NO_FILES
    error('Data directory does not exist or is inaccessible: %s\n', opto.DIRECTORY_DATA)
end

%% Create filename for save
c = round(clock);
timestamp = sprintf('_%d-%d-%d_%d-%d_%d',c([4 5 6 3 2 1]));
opto.FILENAME_SAVE = [opto.FILENAME_DATA timestamp '.mat'];

%% Create filename format for data search
opto.FILENAME_DATA = [opto.FILENAME_DATA '_opto_###.dat'];

%% Open audio player and make/add beep
if opto.SOUND.PLAY_SOUNDS
    InitializePsychSound(1);
    
    beep = repmat(MakeBeep(opto.SOUND.BEEP_FREQUENCY, opto.SOUND.BEEP_DURATION_SEC, opto.SOUND.PLAY_FREQUENCY), [opto.SOUND.CHANNELS 1]);
    opto.beep = [beep repmat([zeros(opto.SOUND.CHANNELS, round(opto.SOUND.PLAY_FREQUENCY * opto.SOUND.BEEP_SPACING_SEC)) beep], [1 (opto.SOUND.BEEP_NUMBER - 1)])]; 
    
    opto.sound_handle = PsychPortAudio('Open', [], 1, [], opto.SOUND.PLAY_FREQUENCY, opto.SOUND.CHANNELS, [], opto.SOUND.LATENCY);
    PsychPortAudio('Volume', opto.sound_handle, opto.SOUND.VOLUME);
    PsychPortAudio('FillBuffer', opto.sound_handle, opto.beep);
end 

%% Prompt user to "Start" OTCollect and then press a button to continue
%display OTCollect fields otcollect_fields
fprintf('\nExpected OTCollect parameters...\n')
for f = otcollect_fields
    f = f{1};
    fprintf('%s:\t%s\n', f, format(getfield(opto, f)))
end
warning(sprintf('\n1. Check that the above parameters match what you entered in OTCollect\n2. Click "Start" in OTCollect\n3. Pres %s to continue or %s to stop.\n', opto.KEYS.CONTINUE.NAME, opto.KEYS.STOP.NAME))
pressed = false;
while 1
    [~,~,keys] = KbCheck(-1);
    if keys(opto.KEYS.STOP.VALUE)
        error('Stop key pressed.')
    elseif keys(opto.KEYS.CONTINUE.VALUE)
        pressed = true;
    elseif pressed && ~keys(opto.KEYS.CONTINUE.VALUE)
        break;
    end
end

%% Setup dio, which will trigger a recording
fprintf('\nSetting up connection to Optotrak (via mcc digital aquisition device...')

%prepare to trigger
PrepareTrigger;

%update global to get latest filename (required to updated global on older versions of MATLAB) 
global opto

%open dio (triggers first recording if OTCollect is started)
if ~opto.DEBUG
    try
        opto.dio = digitalio('mcc', opto.DIO.BOARD_NUMBER);

        %define line 1 to 40 as output
        addline(opto.dio,0:7,1,'Out');	% First Port B
        addline(opto.dio,0:7,4,'Out');	% Second Port A
        addline(opto.dio,0:7,5,'Out');	% Second Port B
        addline(opto.dio,0:3,2,'Out');	% First Port CL
        addline(opto.dio,0:3,3,'Out');	% First Port CH
        addline(opto.dio,0:3,6,'Out');	% Second Port CL
        addline(opto.dio,0:3,7,'Out');	% Second Port CH

        %define line 41 to 48 as input
        addline(opto.dio,0:7,0,'In');     % First Port A

        %set output to zeros for line 1 to 40
        putvalue(opto.dio.line(1:40), zeros(1,40)); 
    catch err
        Warning(err);
        error('Could not connect to Optotrak PC via dio. Most likely, this is the result of running the script on another PC without enabling DEBUG.')
    end
else
    opto.dio = [];
end

%send an actual trigger even though it shouldn't be needed (this is done to set timing data)
TriggerFull;

fprintf('connection established.\n')

%% Wait for data to become available + check data
%repeat until successful
while 1
    try
        %display details of search
        fprintf('\nThe expected filename is %s\n', opto.trigger.filename);
        fprintf('If OTCollect was not started on time, press %s to send a trigger.\n', opto.KEYS.TRIGGER.NAME);
        fprintf('If a trial is recorded but this script does not find it, check the path and filename.\n');
        fprintf('You may press %s to stop the script if needed.\n', opto.KEYS.STOP.NAME);

        %if this isn't trial 1, warn the user and explain circumstances
        if opto.trigger.filename_number ~= 1
            warning('The expected next trial (%s) is not trial 1. This is okay so long as it matches OTCollect''s trial number. This may occur if initialization is repeated without restarting OTCollect.\n', opto.trigger.filename)
        end

        %wait for file
        fprintf('\nWaiting for %s to become available...\n', opto.trigger.filename);
        found = LookForData;

        if found
            %update global to get latest filename (required to updated global on older versions of MATLAB) 
            global opto
            fprintf('\n%s found!', opto.trigger.filename);
            
            %if data is good, complete
            if CheckData
                break
            end
        end
    catch err
        Warning(err.message);
    end
    
    fprintf('\nAn issue occured (see above). Press %s when you are ready to send another test trigger.\n', opto.KEYS.TRIGGER.NAME);
    
    pressed = false;
    while 1
        [~,~,keys] = KbCheck(-1);
        if keys(opto.KEYS.STOP.VALUE)
            error('Stop key pressed.')
        elseif keys(opto.KEYS.TRIGGER.VALUE)
            pressed = true;
        elseif pressed && ~keys(opto.KEYS.TRIGGER.VALUE)
            break;
        end
    end
    
    PrepareTrigger;
    TriggerFull;
    global opto
end

%store first file number
opto.first_filename_number = opto.trigger.filename_number;

%% Initialization Successful
opto.initialized = true;
fprintf('\nOptotrak initialization has completed successfully!\n');


%% Functions
function [string] = format(value)
if isempty(value)
    string = 'empty';
else
    if isnumeric(value) && length(value)==1
        string = num2str(value);
    elseif islogical(value) && length(value)==1
        if value
            string = 'True';
        else
            string = 'False';
        end
    elseif isstruct(value)
        string = 'struct?';
    elseif ischar(value)
        string = value;
    elseif iscell(value)
        strings = cellfun(@format, value, 'UniformOutput', false);
        string = ['{' sprintf('%s', strings{1}) sprintf(', %s', strings{2:end}) '}'];
    elseif ismatrix(value)
        strings = arrayfun(@format, value, 'UniformOutput', false);
        string = ['[' sprintf('%s', strings{1}) sprintf(' %s', strings{2:end}) ']'];
    end
end