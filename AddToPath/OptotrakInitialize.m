%OptotrakInitialize(parameters)
%
%TODO: description
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
%  DEBUG          (defaults to false. if true, prevents use of hardware and causes all functions to return immediately - for testing on other PCs)
%  PLAY_SOUNDS    (defaults to true. when data cannot be found or contains blockage, beeps will be played. all other activity will be haulted while beeps play)
%  TIMEOUT_MSEC   (defaults to 2000. time after data should have been available to stop looking and flag as an error)
%
%  Any constant in the opto struct can be overriden by passing a matching field in the parameters structure
%  Any other fields in the parameter structure will be ignored
%
function OptotrakInitialize(parameters)

parameters.NUMBER_IREDS = 3;
parameters.RECORD_MSEC = 1000;
parameters.SAMPLE_RATE_HZ = 200;

parameters.DIRECTORY_DATA = [pwd filesep 'Opto' filesep];
parameters.FILENAME_DATA = 'p03_opto';

parameters.DEBUG = true;

%% Global Struct
global opto

%% Clear prior global
%close audio player if opened
%TODO

%clear global
opto = struct;

%% Set Constants
%debug
opto.DEBUG = false; %if true, prevents use of hardware and causes all functions to return immediately - for testing on other PCs

%sound
opto.PLAY_SOUNDS = true; %when data cannot be found or contains blockage, beeps will be played. all other activity will be haulted while beeps play
opto.SOUND.LATENCY = .050;
opto.SOUND.CHANNELS = 2;
opto.SOUND.PLAY_FREQUENCY = 44100;
opto.SOUND.VOLUME = 1;

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

% % % %if DEBUG is enabled, then nothing else is needed
% % % if opto.DEBUG
% % %     %require key press to make sure this message is seen)
% % %     warning(sprintf('Debug mode is enabled. Hardware will not be used and functions will not do anything.\n\nPress any key to continue.'));
% % %     pause;
% % %     return;
% % % end
   
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

%% Initialize
opto.time_start = GetSecs;

opto.warnings = cell(0);

opto.trigger.time_allow_trigger_start = 0;
opto.trigger.time_start = 0;
opto.trigger.time_allow_trigger_stop = 0;
opto.trigger.time_stop = 0;
opto.trigger.time_expected_recording_end = 0;
opto.trigger.time_timeout = opto.trigger.time_expected_recording_end + (opto.TIMING.TIMEOUT_MSEC / 1000);

%% Check that PsychToolbox is installed and working
try
    AssertOpenGL();
catch err
    warning('PsychToolbox might not be installed or setup correctly!')
    rethrow(err)
end

%% Set key values (uses PTB)
KbName('UnifyKeyNames');
for key = fields(opto.KEYS)'
    key = key{1};
    eval(sprintf('opto.KEYS.%s.VALUE = KbName(opto.KEYS.%s.NAME);', key, key))
end

%% Check that opto directory exists and is visible (local or via network)
%add filesep to the end if not present
if opto.DIRECTORY_DATA(end) ~= filesep
    opto.DIRECTORY_DATA(end+1) = filesep;
end

%check for dir
if ~exist(opto.DIRECTORY_DATA, 'dir')
    error('Data directory does not exist or is inaccessible: %s\n', opto.DIRECTORY_DATA)
end

%% Create filename format
opto.FILENAME_DATA = [opto.FILENAME_DATA '_###.dat'];

%% Prompt user to "Start" OTCollect and then press a button to continue
%display OTCollect fields otcollect_fields
fprintf('\nExpected OTCollect parameters...\n')
for f = otcollect_fields
    f = f{1};
    fprintf('%s:\t%s\n', f, format(getfield(opto, f)))
end
warning(sprintf('\n1. Check that the above parameters match what you entered in OTCollect\n2. Click "Start" in OTCollect\n3. Pres %s to continue or %s to stop.\n', opto.KEYS.CONTINUE.NAME, opto.KEYS.STOP.NAME))
% % % while 1
% % %     [~,keys] = KbWait(-1);
% % %     if keys(opto.KEYS.STOP.VALUE)
% % %         error('Stop key pressed.')
% % %     elseif keys(opto.KEYS.CONTINUE.VALUE)
% % %         break;
% % %     end
% % % end

%% Setup dio, which will trigger a recording
fprintf('\nSetting up connection to Optotrak (via mcc digital aquisition device...')

%open dio (triggers first recording if OTCollect is started)
if ~opto.DEBUG
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
end
%send trigger now even though it shouldn't be needed (this is done to set timing data)
OptotrakTriggerFull;
global opto
fprintf('connection established.\n')

%% Wait for data to become available
fprintf('\nThe expected filename is %s\n', opto.next_recording.filename);
fprintf('If OTCollect was not started on time, press %s to send a trigger.\n', opto.KEYS.TRIGGER.NAME);
fprintf('If a trial is recorded but this script does not find it, check the path and filename.\n');
fprintf('You may press %s to stop the script if needed.\n', opto.KEYS.STOP.NAME);

if opto.next_recording.trial_number ~= 1
    warning('The expected next trial (%s) is not trial 1. This is okay so long as it matches OTCollect''s trial number. This may occur if initialization is repeated without restarting OTCollect.\n', opto.next_recording.filename)
end

fprintf('\nWaiting for %s to become available...\n', opto.next_recording.filename);

filepath = [opto.DIRECTORY_DATA opto.next_recording.filename];
recording_should_be_done = false;
timed_out = false;
while 1
    t = GetSecs;
    
    %look for file
    if exist(filepath, 'file')
        break;
    end
    
    %check if file should be available by now
    if ~recording_should_be_done && (t > opto.trigger.time_expected_recording_end)
        recording_should_be_done = true;
        fprintf('Recording should be completed by now\n')
    end
    
    %check if past timeout
    if ~timed_out && (t > opto.trigger.time_timeout)
        timed_out = true;
        warning('If this were a trial, it would have timed out waiting for data file to be found!')
    end
    
    %handle keys
    [~,~,keys] = KbCheck(-1);
    if keys(opto.KEYS.STOP.VALUE)
        error('Stop key pressed.')
    elseif keys(opto.KEYS.TRIGGER.VALUE)
        fprintf('Sending another trigger (may be delayed if prior trigger was recent)...\n');
        OptotrakTriggerFull;
        global opto
        filepath = [opto.DIRECTORY_DATA opto.next_recording.filename];
        fprintf('Trigger sent! Waiting for %s\n', opto.next_recording.filename);
        recording_should_be_done = false;
        timed_out = false;
        WaitSecs(1);
    end
end
fprintf('\n%s found!', opto.next_recording.filename);

%% Read data file to check inputs

%% Open an audio player and make beeps


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