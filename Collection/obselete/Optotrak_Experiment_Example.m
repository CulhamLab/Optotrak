%Requires PsychToolbox
%For use with systems in rooms 3145 (2x Certus) and 3151 (3x 3020s)
function Optotrak_Experiment_Template(participant_number, run_number)

nargin = 2
participant_number = 1
run_number = 1

%% Check number of inputs
if nargin ~= 2
    error('Incorrect number of input arguments!')
elseif ~isnumeric(participant_number) | ~isnumeric(run_number)
    error('Input arguments must be numeric!')
elseif length(participant_number)~=1 | length(run_number)~=1
    error('Input arguments must each be a single number!')
end

%% Debug mode (disables hardware)
p.DEBUG = true;

%% Parameters (make changes here)

%optotrak (must match parameters in OTCOllect)
p.OPTO.DURATION_SECONDS = 3;
p.OPTO.SAMPLE_RATE = 100;

%paths
p.PATHS.FOLDER_ORDERS = ['.' filesep 'Orders' filesep];
p.PATHS.FOLDER_OUTPUT = ['.' filesep 'Data' filesep];
p.PATHS.FOLDER_OPTO = ['.' filesep 'Opto' filesep];

%key names (to check a key's name, enter KbName in the command window and then press the key)
p.KEYS.CONTINUE.NAME = 'SPACE';
p.KEYS.EXIT.NAME = 'ESCAPE';
p.KEYS.FLAG.NAME = 'BACKSPACE';

%filesname format
p.FILENAME.INPUT_ORDER = sprintf('PAR%02d_RUN%02d.xls', participant_number, run_number);
p.FILENAME.OPTO_DAT = sprintf('PAR%02d', participant_number); %if the opto files are called PAR01_opto_###.dat then PAR01 is the filename

%% Constants (shouldn't need to change these)

%dio
p.IO.DIO.BOARD_NUMBER = 0;
p.IO.DIO.OPTO.PIN = 3;
p.IO.DIO.OPTO.HIGH = 1;
p.IO.DIO.OPTO.LOW = 0;
p.IO.DIO.GOGGLE.PIN = [1 2];
p.IO.DIO.GOGGLE.CLOSED = [0 0];
p.IO.DIO.GOGGLE.RIGHT_ONLY = [1 0];
p.IO.DIO.GOGGLE.LEFT_ONLY = [0 1];
p.IO.DIO.GOGGLE.BOTH = [1 1];

%opto
p.OPTO.BUFFER_SECONDS = 0.75;

%% Setup

%create timestamp: YYYY-MM-DD_HH_MM_SS
timestamp = sprintf('%04d-%02d-%02d_%02d-%02d-%02d',round(clock));

%calculate time after trigger to expect opto dat
d.time_opto_dat = p.OPTO.DURATION_SECONDS + p.OPTO.BUFFER_SECONDS;

%set Key Values
KbName('UnifyKeyNames');
for key = fields(p.KEYS)'
    key = key{1};
    eval(sprintf('p.KEYS.%s.VALUE = KbName(p.KEYS.%s.NAME);', key, key))
end

%warn if debug is on (require key press to continue is debug is enabled)
if p.DEBUG
    warning('Debug is enabled so hardware use is disabled! Press %s to continue or %s to exit.', p.KEYS.CONTINUE.NAME, p.KEYS.EXIT.NAME)
    while 1
        [~,keys,~] = KbWait(-1);
        if keys(p.KEYS.EXIT.VALUE)
            error('Exit key pressed.')
        elseif keys(p.KEYS.CONTINUE.VALUE)
            break;
        end
    end
end

%read order from excel
%TODO

%create output folder if it doesn't yet exist
if ~exist(p.PATHS.FOLDER_OUTPUT, 'dir')
    mkdir(p.PATHS.FOLDER_OUTPUT);
end

%generate output filename
d.filename = sprintf('PAR%02d_RUN%02d_%s', participant_number, run_number, timestamp);


%% Test Opto

if ~p.DEBUG
    %check that opto folder exists
    if ~exist(p.PATHS.FOLDER_OPTO, 'dir')
        error('Optotrak data folder could not be found: %s', p.PATHS.FOLDER_OPTO)
    end

    %get list of existing dat files
    filenames = dir([p.PATHS.FOLDER_OPTO p.FILENAME.OPTO_DAT '_opto_*.dat'])
    filenames = filenames(~cellfun(@isempty, regexp(filenames, [p.FILENAME.OPTO_DAT '_opto_\w\w\w.dat'])))
    trials_found = cellfun(@(x) str2num(x(find(x=='_',1,'last')+1:find(x=='.',1,'last')-1)), filenames)

    %display opto paramters and instructions
    fprintf('\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\nOptotrak Setup\n\nPath to dat files:\t%s\nDat Filename:\t\t%s\nDuration (sec):\t\t%d\nSample Rate:\t\t%d\n\n1. Launch OTCollect on the collection PC\n2. Confirm that the above parameters match the parameters entered in OTCollect\n3. Press "Start" in OTCollect\n\nPress %s to continue or %s to exit...\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~', ...
        p.PATHS.FOLDER_OPTO, [p.FILENAME.OPTO_DAT '_opto_###.dat'], p.OPTO.DURATION_SECONDS, p.OPTO.SAMPLE_RATE, p.KEYS.CONTINUE.NAME, p.KEYS.EXIT.NAME);

    %wait for key press
    while 1
        [~,keys,~] = KbWait(-1);
        if keys(p.KEYS.EXIT.VALUE)
            error('Exit key pressed.')
        elseif keys(p.KEYS.CONTINUE.VALUE)
            break;
        end
    end

    %setup dio (will trigger a recording if OTCollect has been started)
    try
        dio = digitalio('mcc', p.IO.DIO.BOARD_NUMBER);
    catch
        error('Could not connect to Optotrak trigger hardware!')
    end
    % Define line 1 to 40 as output
    addline(dio,0:7,1,'Out');	% First Port B
    addline(dio,0:7,4,'Out');	% Second Port A
    addline(dio,0:7,5,'Out');	% Second Port B
    addline(dio,0:3,2,'Out');	% First Port CL
    addline(dio,0:3,3,'Out');	% First Port CH
    addline(dio,0:3,6,'Out');	% Second Port CL
    addline(dio,0:3,7,'Out');	% Second Port CH
    % Define line 41 to 48 as input
    addline(dio,0:7,0,'In');     % First Port A
    % Set output to zeros for line 1 to 40
    putvalue(dio.line(1:40), zeros(1,40));

    %make sure opto starts low
    putvalue(dio.line(p.IO.DIO.OPTO.PIN), p.IO.DIO.OPTO.LOW);

    %open goggles
    putvalue(dio.line(p.IO.DIO.GOGGLE.PIN), p.IO.DIO.GOGGLE.BOTH);
       
    %wait until end of recording
    WaitSecs(d.time_opto_dat);

    %read recording
    %TODO
    
end


%% Run

t0 = GetSecs;

%% Complete
