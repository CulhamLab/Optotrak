%Merges 2 or more sets of opto TXT files into a single set.
%
%Select any one file from each set in the order that you want the sets combined.
%Close the file selection dialogue instead of selecting a file when you
%have entered all sets.
%
%You will then be prompted to select an output directory and new filename
%(excluding the _###.txt part).
function opto_aux__mergeTxtSets

%% Select any file from each set
prior_dir = [pwd filesep];
set = 0;
fprintf('\nSelect any one file from each set in the order that you want the sets combined.\nClose the file selection dialogue instead of selecting a file when you have entered all sets.\n');
while 1
    set = set + 1;
    
    [filename_set{set}, directory_set{set}] = uigetfile([prior_dir '*.txt'], sprintf('Select any TXT file from set %d', set));
    if isnumeric(filename_set{set})
        if set == 1
            error('No sets selected')
        end
        number_of_sets = set - 1;
        fprintf('\nEnd of set selection\n');
        break;
    end
    filename_set{set} = [filename_set{set}(1:end-7) '###.txt'];
    fprintf('\nSet %d: %s\n', set, [directory_set{set} filename_set{set}]);

    list{set} = dir([directory_set{set} '*.txt']);
    fileset{set} = {list{set}(~cellfun(@isempty, regexp({list{set}.name}, strrep(filename_set{set},'#','\d')))).name};
    number_files(set) = length(fileset{set});
    fprintf('Contains %d files\n', number_files(set));

    prior_dir = directory_set{set};
end

%% Select location for new set
directory_output = uigetdir(pwd, 'Select location to save new set');
if isnumeric(directory_output)
    error('No directory selected. Script will abort.')
end
if directory_output(end) ~= filesep
    directory_output(end+1) = filesep;
end
fprintf('\nOutput Directory: %s\n', directory_output);

%% Enter name for new set
filename_output = inputdlg('Name of new file set (not including _###.txt)', 'Filename');
filename_output = filename_output{1};
if isempty(filename_output)
    error('No filename entered. Script will abort.')
end
fprintf('Output Filenames: %s_###.txt\n', filename_output);

%% Check if would overwrite before any copying
filepaths = arrayfun(@(x) sprintf('%s%s_%03d.txt', directory_output, filename_output, x), 1:sum(number_files), 'UniformOutput', false);
files_exist = cellfun(@(x) exist(x, 'file'), filepaths);
if any(files_exist)
    error('One or more of the files that would be created already exist. Script will abort.')
end

%% Process
trial = 0;
fprintf('Creating new set...\n');
for set = 1:number_of_sets
    for filename = fileset{set}
        trial = trial + 1;
        
        fp_source = [directory_set{set} filename{1}];
        fp_target = sprintf('%s%s_%03d.txt', directory_output, filename_output, trial);
        
        copyfile(fp_source, fp_target);
    end
end

%% Done
disp Complete!
